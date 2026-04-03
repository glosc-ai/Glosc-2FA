import AuthenticationServices
import Combine
import CryptoKit
import FirebaseAuth
import FirebaseFirestore
import Foundation
import Security
import SwiftData

enum CloudSyncPassphrasePrompt: String, Equatable, Identifiable {
    case create
    case unlock

    var id: String { rawValue }
}

enum CloudSyncAuthError: LocalizedError, Equatable {
    case missingPassphrase
    case passphraseTooShort
    case passphraseMismatch
    case invalidPassphrase
    case passphraseAlreadyConfigured
    case missingGoogleAppID
    case missingCallbackScheme(String)
    case providerDisabled
    case accountExistsWithDifferentProvider
    case invalidIdentityToken
    case appleNonceMissing
    case configurationNotFound
    case appNotAuthorized
    case invalidAPIKey
    case accountDisabled
    case cancelled
    case internalError

    var errorDescription: String? {
        switch self {
        case .missingPassphrase:
            return L10n.tr("sync.passphrase.validation.missing", default: "请输入同步口令。")
        case .passphraseTooShort:
            return L10n.tr("sync.passphrase.validation.too_short", default: "同步口令至少需要 8 位。")
        case .passphraseMismatch:
            return L10n.tr("sync.passphrase.validation.mismatch", default: "两次输入的同步口令不一致。")
        case .invalidPassphrase:
            return L10n.tr("sync.auth.error.invalid_passphrase", default: "同步口令不正确，无法解密云端数据。")
        case .passphraseAlreadyConfigured:
            return L10n.tr("sync.auth.error.passphrase_already_configured", default: "该账号已经设置过同步口令，请改为输入已有口令。")
        case .missingGoogleAppID:
            return L10n.tr("sync.auth.error.missing_google_app_id", default: "当前 Firebase 配置缺少 GOOGLE_APP_ID，无法发起 OAuth 登录。请重新下载 GoogleService-Info.plist。")
        case .missingCallbackScheme(let scheme):
            return L10n.format("sync.auth.error.missing_callback_scheme", default: "当前应用尚未注册 OAuth 回调 URL Scheme：%@。请检查工程 Info.plist 配置。", scheme)
        case .providerDisabled:
            return L10n.tr("sync.auth.error.provider_disabled", default: "当前登录方式尚未在 Firebase Authentication 中启用，请先在控制台开启对应 Provider。")
        case .accountExistsWithDifferentProvider:
            return L10n.tr("sync.auth.error.account_exists_different_provider", default: "该邮箱已绑定其他登录方式。如果这是旧版邮箱账号，需要先迁移或删除旧账号后再继续。")
        case .invalidIdentityToken:
            return L10n.tr("sync.auth.error.invalid_identity_token", default: "登录凭证无效或已过期，请重新尝试。")
        case .appleNonceMissing:
            return L10n.tr("sync.auth.error.apple_nonce", default: "Apple 登录的安全随机数状态丢失，请重新发起登录。")
        case .configurationNotFound:
            return L10n.tr("sync.auth.error.configuration_not_found", default: "当前 Firebase 项目的 Authentication 配置不存在或尚未初始化。请在 Firebase 控制台启用 Authentication，并确认当前 iOS 应用已正确绑定到该项目。")
        case .appNotAuthorized:
            return L10n.tr("sync.auth.error.app_not_authorized", default: "当前应用未被 Firebase 项目授权，请检查 GoogleService-Info.plist 与 Bundle ID。")
        case .invalidAPIKey:
            return L10n.tr("sync.auth.error.invalid_api_key", default: "Firebase API Key 配置无效，请检查项目配置。")
        case .accountDisabled:
            return L10n.tr("sync.auth.error.account_disabled", default: "该账号已被禁用。")
        case .cancelled:
            return L10n.tr("sync.auth.error.cancelled", default: "登录已取消。")
        case .internalError:
            return L10n.tr("sync.auth.error.internal", default: "Firebase 身份验证内部错误，请检查控制台配置或稍后重试。")
        }
    }
}

enum CloudSyncPassphraseValidator {
    static let minimumLength = 8

    static func validateUnlock(passphrase: String) throws -> String {
        let normalizedPassphrase = passphrase.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedPassphrase.isEmpty else {
            throw CloudSyncAuthError.missingPassphrase
        }

        return normalizedPassphrase
    }

    static func validateCreation(passphrase: String, confirmPassphrase: String) throws -> String {
        let normalizedPassphrase = try validateUnlock(passphrase: passphrase)
        let normalizedConfirmation = confirmPassphrase.trimmingCharacters(in: .whitespacesAndNewlines)

        guard normalizedPassphrase.count >= minimumLength else {
            throw CloudSyncAuthError.passphraseTooShort
        }

        guard normalizedPassphrase == normalizedConfirmation else {
            throw CloudSyncAuthError.passphraseMismatch
        }

        return normalizedPassphrase
    }
}

@MainActor
final class CloudSyncController: ObservableObject {
    private struct CloudSyncUserProfile {
        let email: String?
        let salt: Data?
        let keyVerifier: String?
    }

    enum SyncStatus: Equatable {
        case signedOut
        case keyUnavailable
        case syncing
        case synced(Date)
        case failed(String)
    }

    @Published private(set) var userEmail: String?
    @Published private(set) var isBusy = false
    @Published private(set) var syncStatus: SyncStatus = .signedOut
    @Published private(set) var passphrasePrompt: CloudSyncPassphrasePrompt?

    var isSignedIn: Bool {
        currentUserID != nil
    }

    var isSyncUnlocked: Bool {
        encryptionKey != nil
    }

    private let auth: Auth
    private let firestore: Firestore
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var snapshotListener: ListenerRegistration?
    private var modelContext: ModelContext?
    private var encryptionKey: SymmetricKey?
    private var hasCompletedInitialSync = false
    private var currentUserID: String?
    private var currentAppleNonce: String?

    init(
        auth: Auth = Auth.auth(),
        firestore: Firestore = Firestore.firestore()
    ) {
        self.auth = auth
        self.firestore = firestore
    }

    deinit {
        snapshotListener?.remove()

        if let authStateListener {
            auth.removeStateDidChangeListener(authStateListener)
        }
    }

    func attach(modelContext: ModelContext) {
        self.modelContext = modelContext
        activateIfNeeded()
        startSyncIfPossible(forceRestart: false)
    }

    func activateIfNeeded() {
        guard authStateListener == nil else {
            return
        }

        authStateListener = auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.handleAuthStateChange(user)
            }
        }

        handleAuthStateChange(auth.currentUser)
    }

    func signInWithGoogle() async throws {
        try ensureOAuthCallbackSchemeRegistered()

        let provider = OAuthProvider(providerID: AuthProviderID.google.rawValue, auth: auth)
        provider.customParameters = ["prompt": "select_account"]

        isBusy = true
        defer { isBusy = false }

        do {
            let credential = try await provider.credential(with: nil)
            _ = try await auth.signIn(with: credential)
        } catch {
            throw translatedAuthError(from: error)
        }
    }

    func prepareAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomNonceString()
        currentAppleNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
    }

    func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) async throws {
        isBusy = true
        defer {
            isBusy = false
            currentAppleNonce = nil
        }

        do {
            let authorization = try result.get()

            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                throw CloudSyncAuthError.invalidIdentityToken
            }

            guard let rawNonce = currentAppleNonce else {
                throw CloudSyncAuthError.appleNonceMissing
            }

            guard let identityToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: identityToken, encoding: .utf8) else {
                throw CloudSyncAuthError.invalidIdentityToken
            }

            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString, rawNonce: rawNonce, fullName: appleIDCredential.fullName)
            _ = try await auth.signIn(with: credential)
        } catch {
            throw translatedAuthError(from: error)
        }
    }

    func createSyncPassphrase(passphrase: String, confirmPassphrase: String) async throws {
        guard let user = auth.currentUser,
              let currentUserID else {
            throw CloudSyncAuthError.internalError
        }

        let normalizedPassphrase = try CloudSyncPassphraseValidator.validateCreation(passphrase: passphrase, confirmPassphrase: confirmPassphrase)

        isBusy = true
        defer { isBusy = false }

        let profile = try await loadUserProfile(for: currentUserID)
        guard profile.salt == nil else {
            throw CloudSyncAuthError.passphraseAlreadyConfigured
        }

        let salt = CloudSyncCrypto.makeSalt()
        let key = try CloudSyncCrypto.deriveKey(passphrase: normalizedPassphrase, salt: salt)
        let keyVerifier = try CloudSyncCrypto.makeKeyVerifier(using: key)

        try await upsertUserProfile(for: user, salt: salt, keyVerifier: keyVerifier)
        try CloudSyncKeyStore.shared.saveKey(key, for: currentUserID)

        encryptionKey = key
        userEmail = user.email ?? profile.email
        passphrasePrompt = nil
        syncStatus = .syncing

        startSyncIfPossible(forceRestart: true)
    }

    func unlockSync(passphrase: String) async throws {
        guard let user = auth.currentUser,
              let currentUserID else {
            throw CloudSyncAuthError.internalError
        }

        let normalizedPassphrase = try CloudSyncPassphraseValidator.validateUnlock(passphrase: passphrase)

        isBusy = true
        defer { isBusy = false }

        let profile = try await loadUserProfile(for: currentUserID)

        guard let salt = profile.salt else {
            throw CloudSyncAuthError.passphraseAlreadyConfigured
        }

        let key = try CloudSyncCrypto.deriveKey(passphrase: normalizedPassphrase, salt: salt)

        if let keyVerifier = profile.keyVerifier {
            guard CloudSyncCrypto.verifyKeyVerifier(keyVerifier, using: key) else {
                throw CloudSyncAuthError.invalidPassphrase
            }
        } else {
            let canDecryptRemoteData = try await validateKeyAgainstRemoteData(key, for: currentUserID)
            guard canDecryptRemoteData else {
                throw CloudSyncAuthError.invalidPassphrase
            }

            let keyVerifier = try CloudSyncCrypto.makeKeyVerifier(using: key)
            try await upsertUserProfile(for: user, salt: salt, keyVerifier: keyVerifier)
        }

        try CloudSyncKeyStore.shared.saveKey(key, for: currentUserID)

        encryptionKey = key
        userEmail = user.email ?? profile.email
        passphrasePrompt = nil
        syncStatus = .syncing

        startSyncIfPossible(forceRestart: true)
    }

    func signOut() throws {
        let signedInUserID = currentUserID

        clearSyncSession()
        userEmail = nil
        currentUserID = nil
        syncStatus = .signedOut

        try auth.signOut()

        if let signedInUserID {
            try? CloudSyncKeyStore.shared.deleteKey(for: signedInUserID)
        }
    }

    func userFacingMessage(for error: Error) -> String {
        userMessage(for: error)
    }

    func shouldSuppressFeedback(for error: Error) -> Bool {
        guard let authError = translatedAuthError(from: error) as? CloudSyncAuthError else {
            return false
        }

        return authError == .cancelled
    }

    func syncNow() async {
        guard let modelContext, isSyncUnlocked else {
            return
        }

        startSyncIfPossible(forceRestart: false)
        syncStatus = .syncing

        do {
            for account in try fetchAllAccounts(in: modelContext) {
                try await upload(account)
            }
            syncStatus = .synced(.now)
        } catch {
            syncStatus = .failed(userMessage(for: error))
        }
    }

    func scheduleUpsert(_ account: OTPAccountRecord) {
        guard isSignedIn, isSyncUnlocked else {
            return
        }

        Task {
            do {
                try await upload(account)
                await MainActor.run {
                    self.syncStatus = .synced(.now)
                }
            } catch {
                await MainActor.run {
                    self.syncStatus = .failed(self.userMessage(for: error))
                }
            }
        }
    }

    func scheduleDeletion(for accountID: UUID) {
        guard isSignedIn, isSyncUnlocked else {
            return
        }

        Task {
            do {
                try await deleteRemoteAccount(withID: accountID)
                await MainActor.run {
                    self.syncStatus = .synced(.now)
                }
            } catch {
                await MainActor.run {
                    self.syncStatus = .failed(self.userMessage(for: error))
                }
            }
        }
    }

    private func handleAuthStateChange(_ user: User?) {
        clearSyncSession()
        currentAppleNonce = nil

        guard let user else {
            userEmail = nil
            currentUserID = nil
            syncStatus = .signedOut
            return
        }

        currentUserID = user.uid
        userEmail = user.email
        syncStatus = .keyUnavailable

        Task {
            await restoreSession(for: user)
        }
    }

    private func restoreSession(for user: User) async {
        guard currentUserID == user.uid else {
            return
        }

        if let restoredKey = try? CloudSyncKeyStore.shared.loadKey(for: user.uid) {
            encryptionKey = restoredKey
            passphrasePrompt = nil
            syncStatus = .syncing
            startSyncIfPossible(forceRestart: true)

            if let profile = try? await loadUserProfile(for: user.uid),
               profile.keyVerifier == nil,
               let salt = profile.salt,
               let verifier = try? CloudSyncCrypto.makeKeyVerifier(using: restoredKey) {
                try? await upsertUserProfile(for: user, salt: salt, keyVerifier: verifier)
            }

            return
        }

        do {
            let profile = try await loadUserProfile(for: user.uid)

            guard currentUserID == user.uid else {
                return
            }

            passphrasePrompt = profile.salt == nil ? .create : .unlock
            syncStatus = .keyUnavailable
        } catch {
            guard currentUserID == user.uid else {
                return
            }

            syncStatus = .failed(userMessage(for: error))
        }
    }

    private func clearSyncSession() {
        snapshotListener?.remove()
        snapshotListener = nil
        encryptionKey = nil
        hasCompletedInitialSync = false
        passphrasePrompt = nil
    }

    private func ensureOAuthCallbackSchemeRegistered() throws {
        if let clientID = auth.app?.options.clientID,
           !clientID.isEmpty {
            let reverseClientIDScheme = CloudSyncCallbackScheme.reversedClientIDScheme(from: clientID)
            if CloudSyncCallbackScheme.isRegistered(reverseClientIDScheme) {
                return
            }
        }

        guard let googleAppID = auth.app?.options.googleAppID,
              !googleAppID.isEmpty else {
            throw CloudSyncAuthError.missingGoogleAppID
        }

        let callbackScheme = CloudSyncCallbackScheme.encodedFirebaseAppIDScheme(from: googleAppID)

        guard CloudSyncCallbackScheme.isRegistered(callbackScheme) else {
            throw CloudSyncAuthError.missingCallbackScheme(callbackScheme)
        }
    }

    private func startSyncIfPossible(forceRestart: Bool) {
        guard let currentUserID, let modelContext, let _ = encryptionKey else {
            return
        }

        if forceRestart {
            snapshotListener?.remove()
            snapshotListener = nil
            hasCompletedInitialSync = false
        }

        guard snapshotListener == nil else {
            return
        }

        syncStatus = .syncing

        snapshotListener = accountCollection(for: currentUserID).addSnapshotListener { [weak self] snapshot, error in
            Task { @MainActor in
                guard let self else {
                    return
                }

                if let error {
                    self.syncStatus = .failed(self.userMessage(for: error))
                    return
                }

                guard let snapshot else {
                    self.syncStatus = .failed(L10n.tr("sync.error.unavailable", default: "同步服务暂时不可用。"))
                    return
                }

                await self.consume(snapshot: snapshot, modelContext: modelContext)
            }
        }
    }

    private func consume(snapshot: QuerySnapshot, modelContext: ModelContext) async {
        do {
            if hasCompletedInitialSync {
                try await applyIncrementalChanges(snapshot.documentChanges, to: modelContext)
            } else {
                try await reconcileInitialSnapshot(snapshot.documents, in: modelContext)
                hasCompletedInitialSync = true
            }

            syncStatus = .synced(.now)
        } catch {
            if shouldPromptForPassphraseRecovery(after: error) {
                handleDecryptionFailure()
            } else {
                syncStatus = .failed(userMessage(for: error))
            }
        }
    }

    private func handleDecryptionFailure() {
        if let currentUserID {
            try? CloudSyncKeyStore.shared.deleteKey(for: currentUserID)
        }

        clearSyncSession()
        passphrasePrompt = .unlock
        syncStatus = .keyUnavailable
    }

    private func shouldPromptForPassphraseRecovery(after error: Error) -> Bool {
        guard let cryptoError = error as? CloudSyncCryptoError else {
            return false
        }

        switch cryptoError {
        case .invalidCiphertext, .malformedPayload:
            return true
        case .invalidPassword, .invalidSalt:
            return false
        }
    }

    private func reconcileInitialSnapshot(_ documents: [QueryDocumentSnapshot], in modelContext: ModelContext) async throws {
        let remotePayloads = try decodeRemotePayloads(from: documents)
        let localAccounts = try fetchAllAccounts(in: modelContext)
        let localMap = Dictionary(uniqueKeysWithValues: localAccounts.map { ($0.id, $0) })
        let remoteIDs = Set(remotePayloads.map(\.id))

        var hasLocalMutations = false

        for payload in remotePayloads {
            if let localAccount = localMap[payload.id] {
                if payload.updatedAt > localAccount.updatedAt {
                    try localAccount.apply(cloudPayload: payload)
                    hasLocalMutations = true
                } else if localAccount.updatedAt > payload.updatedAt {
                    try await upload(localAccount)
                }
            } else {
                modelContext.insert(try OTPAccountRecord(cloudPayload: payload))
                hasLocalMutations = true
            }
        }

        for account in localAccounts where !remoteIDs.contains(account.id) {
            try await upload(account)
        }

        if hasLocalMutations {
            try modelContext.save()
        }
    }

    private func applyIncrementalChanges(_ changes: [DocumentChange], to modelContext: ModelContext) async throws {
        var hasLocalMutations = false

        for change in changes {
            let accountID = UUID(uuidString: change.document.documentID)

            switch change.type {
            case .removed:
                guard let accountID, let account = try account(withID: accountID, in: modelContext) else {
                    continue
                }

                account.removeSecretFromSecureStore()
                modelContext.delete(account)
                hasLocalMutations = true
            case .added, .modified:
                let payload = try decodePayload(from: change.document)

                if let account = try account(withID: payload.id, in: modelContext) {
                    guard payload.updatedAt > account.updatedAt else {
                        continue
                    }

                    try account.apply(cloudPayload: payload)
                    hasLocalMutations = true
                } else {
                    modelContext.insert(try OTPAccountRecord(cloudPayload: payload))
                    hasLocalMutations = true
                }
            }
        }

        if hasLocalMutations {
            try modelContext.save()
        }
    }

    private func upload(_ account: OTPAccountRecord) async throws {
        guard let currentUserID, let encryptionKey else {
            return
        }

        let payload = account.cloudPayload
        let ciphertext = try CloudSyncCrypto.encrypt(payload, using: encryptionKey)

        try await accountCollection(for: currentUserID)
            .document(account.id.uuidString)
            .setData([
                "ciphertext": ciphertext,
                "createdAt": Timestamp(date: account.createdAt),
                "updatedAt": Timestamp(date: account.updatedAt),
                "schemaVersion": 1,
            ])
    }

    private func deleteRemoteAccount(withID accountID: UUID) async throws {
        guard let currentUserID else {
            return
        }

        try await accountCollection(for: currentUserID)
            .document(accountID.uuidString)
            .delete()
    }

    private func loadUserProfile(for userID: String) async throws -> CloudSyncUserProfile {
        let snapshot = try await userDocument(for: userID).getDocument()
        let data = snapshot.data() ?? [:]

        let encodedSalt = data["kdfSalt"] as? String
        let salt = encodedSalt.flatMap { Data(base64Encoded: $0) }

        return CloudSyncUserProfile(
            email: data["email"] as? String,
            salt: salt,
            keyVerifier: data["keyVerifier"] as? String
        )
    }

    private func upsertUserProfile(for user: User, salt: Data?, keyVerifier: String?) async throws {
        let userDocument = userDocument(for: user.uid)
        let snapshot = try await userDocument.getDocument()

        var data: [String: Any] = [
            "updatedAt": FieldValue.serverTimestamp(),
            "providerIDs": user.providerData.map(\.providerID),
        ]

        if !snapshot.exists {
            data["createdAt"] = FieldValue.serverTimestamp()
        }

        if let email = user.email, !email.isEmpty {
            data["email"] = email.lowercased()
        }

        if let displayName = user.displayName, !displayName.isEmpty {
            data["displayName"] = displayName
        }

        if let salt {
            data["kdfSalt"] = salt.base64EncodedString()
        }

        if let keyVerifier {
            data["keyVerifier"] = keyVerifier
        }

        try await userDocument.setData(data, merge: true)
    }

    private func validateKeyAgainstRemoteData(_ key: SymmetricKey, for userID: String) async throws -> Bool {
        let snapshot = try await accountCollection(for: userID).limit(to: 1).getDocuments()

        guard let document = snapshot.documents.first,
              let ciphertext = document.data()["ciphertext"] as? String else {
            return true
        }

        return (try? CloudSyncCrypto.decrypt(ciphertext, using: key)) != nil
    }

    private func decodeRemotePayloads(from documents: [QueryDocumentSnapshot]) throws -> [CloudAccountPayload] {
        try documents.map(decodePayload(from:))
    }

    private func decodePayload(from document: QueryDocumentSnapshot) throws -> CloudAccountPayload {
        guard let encryptionKey,
              let ciphertext = document.data()["ciphertext"] as? String else {
            throw CloudSyncCryptoError.invalidCiphertext
        }

        return try CloudSyncCrypto.decrypt(ciphertext, using: encryptionKey)
    }

    private func fetchAllAccounts(in modelContext: ModelContext) throws -> [OTPAccountRecord] {
        let descriptor = FetchDescriptor<OTPAccountRecord>(sortBy: [SortDescriptor(\OTPAccountRecord.createdAt, order: .forward)])
        return try modelContext.fetch(descriptor)
    }

    private func account(withID accountID: UUID, in modelContext: ModelContext) throws -> OTPAccountRecord? {
        let descriptor = FetchDescriptor<OTPAccountRecord>(predicate: #Predicate<OTPAccountRecord> { account in
            account.id == accountID
        })
        return try modelContext.fetch(descriptor).first
    }

    private func userDocument(for userID: String) -> DocumentReference {
        firestore.collection("users").document(userID)
    }

    private func accountCollection(for userID: String) -> CollectionReference {
        userDocument(for: userID).collection("accounts")
    }

    private func userMessage(for error: Error) -> String {
        if let authError = translatedAuthError(from: error) as? CloudSyncAuthError {
            return authError.localizedDescription
        }

        let nsError = error as NSError

        if nsError.domain == AuthErrorDomain,
           let code = AuthErrorCode(rawValue: nsError.code) {
            switch code {
            case .networkError, .webNetworkRequestFailed:
                return L10n.tr("sync.auth.error.network", default: "网络异常，请稍后重试。")
            case .tooManyRequests:
                return L10n.tr("sync.auth.error.too_many_requests", default: "尝试次数过多，请稍后再试。")
            case .webContextAlreadyPresented:
                return L10n.tr("sync.auth.error.web_context_busy", default: "已有一个登录窗口正在显示，请先完成或关闭它。")
            default:
                return L10n.tr("sync.auth.error.generic", default: "登录状态处理失败，请稍后重试。")
            }
        }

        if nsError.domain == FirestoreErrorDomain {
            switch FirestoreErrorCode(_nsError: nsError).code {
            case .permissionDenied:
                return L10n.tr("sync.error.permission_denied", default: "云端权限校验失败，请检查 Firebase 规则配置。")
            case .unavailable, .deadlineExceeded:
                return L10n.tr("sync.error.network", default: "云同步暂时不可用，请稍后重试。")
            default:
                return L10n.tr("sync.error.generic", default: "云同步失败，请稍后重试。")
            }
        }

        return error.localizedDescription
    }

    private func translatedAuthError(from error: Error) -> Error {
        if let authError = error as? CloudSyncAuthError {
            return authError
        }

        let nsError = error as NSError

        if nsError.domain == ASAuthorizationError.errorDomain,
           let code = ASAuthorizationError.Code(rawValue: nsError.code),
           code == .canceled {
            return CloudSyncAuthError.cancelled
        }

        if let resolvedAuthError = resolvedAuthError(from: nsError) {
            return resolvedAuthError
        }

        if nsError.domain == AuthErrorDomain,
           let code = AuthErrorCode(rawValue: nsError.code) {
            switch code {
            case .operationNotAllowed:
                return CloudSyncAuthError.providerDisabled
            case .accountExistsWithDifferentCredential, .credentialAlreadyInUse:
                return CloudSyncAuthError.accountExistsWithDifferentProvider
            case .invalidCredential:
                return CloudSyncAuthError.invalidIdentityToken
            case .missingOrInvalidNonce:
                return CloudSyncAuthError.appleNonceMissing
            case .webContextCancelled:
                return CloudSyncAuthError.cancelled
            case .appNotAuthorized:
                return CloudSyncAuthError.appNotAuthorized
            case .invalidAPIKey:
                return CloudSyncAuthError.invalidAPIKey
            case .userDisabled:
                return CloudSyncAuthError.accountDisabled
            case .internalError:
                return CloudSyncAuthError.internalError
            default:
                break
            }
        }

        return error
    }

    private func resolvedAuthError(from error: NSError) -> CloudSyncAuthError? {
        if let nestedError = error.userInfo[NSUnderlyingErrorKey] as? NSError,
           let resolvedNestedError = resolvedAuthError(from: nestedError) {
            return resolvedNestedError
        }

        guard error.domain == AuthErrorDomain else {
            return nil
        }

        let detail = authDiagnosticDetail(from: error)

        if detail.contains("configuration_not_found") ||
            detail.contains("config not found") ||
            detail.contains("identity toolkit api has not been used") ||
            detail.contains("authentication configuration") && detail.contains("not found") {
            return .configurationNotFound
        }

        if detail.contains("operation_not_allowed") || detail.contains("not enabled") {
            return .providerDisabled
        }

        if detail.contains("invalid api key") ||
            detail.contains("api key not valid") ||
            detail.contains("api_key_invalid") {
            return .invalidAPIKey
        }

        if detail.contains("app not authorized") ||
            detail.contains("requests from this ios client application") ||
            detail.contains("bundle id") ||
            detail.contains("bundle identifier") ||
            detail.contains("client is unauthorized") {
            return .appNotAuthorized
        }

        if detail.contains("account exists with different credential") ||
            detail.contains("credential already in use") {
            return .accountExistsWithDifferentProvider
        }

        return nil
    }

    private func authDiagnosticDetail(from error: NSError) -> String {
        let directValues = error.userInfo.values.compactMap { value -> String? in
            if let string = value as? String {
                return string
            }

            if let nestedError = value as? NSError {
                return nestedError.localizedDescription
            }

            return nil
        }

        var details = directValues

        if let response = error.userInfo["FIRAuthErrorUserInfoDeserializedResponseKey"] {
            details.append(String(describing: response))
        }

        if let errorName = error.userInfo["FIRAuthErrorUserInfoNameKey"] as? String {
            details.append(errorName)
        }

        return details.joined(separator: " ").lowercased()
    }

    private static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)

        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        result.reserveCapacity(length)

        var remainingLength = length

        while remainingLength > 0 {
            var randomBytes = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)

            if status != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(status)")
            }

            randomBytes.forEach { random in
                guard remainingLength > 0 else {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    private static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}