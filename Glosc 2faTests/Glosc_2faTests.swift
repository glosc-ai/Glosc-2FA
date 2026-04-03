//
//  Glosc_2faTests.swift
//  Glosc 2faTests
//
//  Created by XiaoM on 2026/3/19.
//

import Foundation
import SwiftUI
import Testing
@testable import Glosc_2fa

@Suite(.serialized)
struct Glosc_2faTests {

    @MainActor
    private func withAppLanguage<T>(_ language: AppLanguage, perform: () -> T) -> T {
        let defaults = UserDefaults.standard
        let originalValue = defaults.string(forKey: AppPreferences.appLanguageDefaultsKey)

        defaults.set(language.rawValue, forKey: AppPreferences.appLanguageDefaultsKey)
        defer {
            if let originalValue {
                defaults.set(originalValue, forKey: AppPreferences.appLanguageDefaultsKey)
            } else {
                defaults.removeObject(forKey: AppPreferences.appLanguageDefaultsKey)
            }
        }

        return perform()
    }

    private struct MockAuthenticationError: LocalizedError {
        var errorDescription: String? {
            L10n.tr("test.mock_auth_failed", default: "身份验证失败")
        }
    }

    @Test func base32DecoderHandlesNormalizedInput() throws {
        let decoded = try Base32Decoder.decode("JBSW Y3DP-EHPK3PXP")

        #expect(decoded == Data([0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x21, 0xDE, 0xAD, 0xBE, 0xEF]))
    }

    @Test func hotpMatchesRfc4226Vectors() throws {
        let secret = Data("12345678901234567890".utf8)
        let expected = [
            "755224",
            "287082",
            "359152",
            "969429",
            "338314",
            "254676",
            "287922",
            "162583",
            "399871",
            "520489",
        ]

        for (counter, code) in expected.enumerated() {
            let generated = try OTPCodeGenerator.generateCode(secret: secret, counter: UInt64(counter), digits: 6, algorithm: .sha1)
            #expect(generated == code)
        }
    }

    @Test func totpMatchesRfc6238Vectors() throws {
        let cases: [(OTPAlgorithm, Data, [(TimeInterval, String)])] = [
            (
                .sha1,
                Data("12345678901234567890".utf8),
                [
                    (59, "94287082"),
                    (1111111109, "07081804"),
                    (1111111111, "14050471"),
                    (1234567890, "89005924"),
                    (2000000000, "69279037"),
                    (20000000000, "65353130"),
                ]
            ),
            (
                .sha256,
                Data("12345678901234567890123456789012".utf8),
                [
                    (59, "46119246"),
                    (1111111109, "68084774"),
                    (1111111111, "67062674"),
                    (1234567890, "91819424"),
                    (2000000000, "90698825"),
                    (20000000000, "77737706"),
                ]
            ),
            (
                .sha512,
                Data("1234567890123456789012345678901234567890123456789012345678901234".utf8),
                [
                    (59, "90693936"),
                    (1111111109, "25091201"),
                    (1111111111, "99943326"),
                    (1234567890, "93441116"),
                    (2000000000, "38618901"),
                    (20000000000, "47863826"),
                ]
            ),
        ]

        for (algorithm, secret, vectors) in cases {
            for (timestamp, expectedCode) in vectors {
                let counter = UInt64(timestamp / 30)
                let generated = try OTPCodeGenerator.generateCode(secret: secret, counter: counter, digits: 8, algorithm: algorithm)
                #expect(generated == expectedCode)
            }
        }
    }

    @Test func otpAuthParserBuildsDraft() throws {
        let draft = try OTPAuthURIParser.parse("otpauth://totp/GitHub:alice@example.com?secret=JBSWY3DPEHPK3PXP&issuer=GitHub&algorithm=SHA256&digits=8&period=45")

        #expect(draft.kind == .totp)
        #expect(draft.issuer == "GitHub")
        #expect(draft.accountName == "alice@example.com")
        #expect(draft.algorithm == .sha256)
        #expect(draft.digits == 8)
        #expect(draft.period == 45)
    }

    @Test func otpAuthParserRejectsUnsupportedAlgorithm() {
        #expect(throws: OTPAuthURIParserError.unsupportedAlgorithm("MD5")) {
            try OTPAuthURIParser.parse("otpauth://totp/Example:alice?secret=JBSWY3DPEHPK3PXP&algorithm=MD5")
        }
    }

    @Test func draftValidationRejectsInvalidSecret() {
        var draft = OTPAccountDraft()
        draft.accountName = "alice@example.com"
        draft.secret = "INVALID*SECRET"

        #expect(throws: OTPAccountValidationError.invalidSecret) {
            _ = try draft.makeRecord()
        }
    }

    @Test func keychainSecretStoreRoundTripsSecret() throws {
        let key = "test.secret.\(UUID().uuidString)"

        try KeychainSecretStore.shared.saveSecret("JBSWY3DPEHPK3PXP", for: key)
        let loaded = try KeychainSecretStore.shared.loadSecret(for: key)

        #expect(loaded == "JBSWY3DPEHPK3PXP")

        try KeychainSecretStore.shared.deleteSecret(for: key)

        #expect(throws: KeychainSecretStoreError.secretNotFound) {
            try KeychainSecretStore.shared.loadSecret(for: key)
        }
    }

    @Test func cloudSyncCryptoDerivesStableKeyForSamePassphraseAndSalt() throws {
        let salt = Data("stable-salt".utf8)
        let firstKey = try CloudSyncCrypto.deriveKey(passphrase: "correct horse battery staple", salt: salt)
        let secondKey = try CloudSyncCrypto.deriveKey(passphrase: "correct horse battery staple", salt: salt)

        #expect(CloudSyncCrypto.exportKey(firstKey) == CloudSyncCrypto.exportKey(secondKey))
    }

    @Test @MainActor func cloudSyncCryptoEncryptsAndDecryptsPayload() throws {
        let salt = Data("payload-salt".utf8)
        let key = try CloudSyncCrypto.deriveKey(passphrase: "sync-passphrase", salt: salt)
        let payload = CloudAccountPayload(
            id: UUID(uuidString: "11111111-2222-3333-4444-555555555555") ?? UUID(),
            issuer: "GitHub",
            accountName: "alice@example.com",
            secret: "JBSWY3DPEHPK3PXP",
            algorithmRawValue: OTPAlgorithm.sha256.rawValue,
            digits: 8,
            period: 45,
            kindRawValue: OTPKind.totp.rawValue,
            counter: 0,
            createdAt: Date(timeIntervalSince1970: 1_711_111_111),
            updatedAt: Date(timeIntervalSince1970: 1_722_222_222)
        )

        let ciphertext = try CloudSyncCrypto.encrypt(payload, using: key)
        let decrypted = try CloudSyncCrypto.decrypt(ciphertext, using: key)

        #expect(decrypted == payload)
    }

    @Test func cloudSyncCryptoCreatesAndVerifiesKeyVerifier() throws {
        let salt = Data("verifier-salt".utf8)
        let key = try CloudSyncCrypto.deriveKey(passphrase: "another sync passphrase", salt: salt)
        let verifier = try CloudSyncCrypto.makeKeyVerifier(using: key)

        #expect(CloudSyncCrypto.verifyKeyVerifier(verifier, using: key))

        let differentKey = try CloudSyncCrypto.deriveKey(passphrase: "different passphrase", salt: salt)
        #expect(CloudSyncCrypto.verifyKeyVerifier(verifier, using: differentKey) == false)
    }

    @Test func cloudSyncCryptoRejectsEmptyPassphrase() {
        #expect(throws: CloudSyncCryptoError.invalidPassword) {
            _ = try CloudSyncCrypto.deriveKey(passphrase: "   ", salt: Data("salt".utf8))
        }
    }

    @Test func cloudSyncPassphraseValidatorRejectsMissingPassphrase() {
        #expect(throws: CloudSyncAuthError.missingPassphrase) {
            _ = try CloudSyncPassphraseValidator.validateUnlock(passphrase: "   ")
        }
    }

    @Test func cloudSyncPassphraseValidatorRejectsMismatch() {
        #expect(throws: CloudSyncAuthError.passphraseMismatch) {
            _ = try CloudSyncPassphraseValidator.validateCreation(passphrase: "secret123", confirmPassphrase: "secret456")
        }
    }

    @Test func cloudSyncPassphraseValidatorAcceptsValidCreationInput() throws {
        let validated = try CloudSyncPassphraseValidator.validateCreation(passphrase: " secret123 ", confirmPassphrase: "secret123")

        #expect(validated == "secret123")
    }

    @Test func cloudSyncCallbackSchemeEncodesFirebaseAppID() {
        let callbackScheme = CloudSyncCallbackScheme.encodedFirebaseAppIDScheme(from: "1:224927712933:ios:4312b74692bb3bfc272f4c")

        #expect(callbackScheme == "app-1-224927712933-ios-4312b74692bb3bfc272f4c")
    }

    @Test func cloudSyncCallbackSchemeReversesClientID() {
        let reversedScheme = CloudSyncCallbackScheme.reversedClientIDScheme(from: "224927712933-abcdefg123.apps.googleusercontent.com")

        #expect(reversedScheme == "com.googleusercontent.apps.224927712933-abcdefg123")
    }

    @Test func cloudSyncCallbackSchemeDetectsRegisteredScheme() {
        let infoDictionary: [String: Any] = [
            "CFBundleURLTypes": [
                [
                    "CFBundleURLSchemes": [
                        "app-1-224927712933-ios-4312b74692bb3bfc272f4c",
                        "com.example.other",
                    ],
                ],
            ],
        ]

        #expect(CloudSyncCallbackScheme.isRegistered("app-1-224927712933-ios-4312b74692bb3bfc272f4c", in: infoDictionary))
        #expect(CloudSyncCallbackScheme.isRegistered("com.example.missing", in: infoDictionary) == false)
    }

    @Test @MainActor func appLanguagePreferencePersistsSelectedLanguage() {
        AppPreferences.resetForTesting()

        let preferences = AppPreferences()
        preferences.appLanguage = .english

        let reloadedPreferences = AppPreferences()
        #expect(reloadedPreferences.appLanguage == .english)
    }

    @Test @MainActor func localizationUsesSelectedAppLanguage() {
        withAppLanguage(.english) {
            #expect(L10n.tr("settings.title", default: "设置") == "Settings")
        }

        withAppLanguage(.simplifiedChinese) {
            #expect(L10n.tr("settings.title", default: "Settings") == "设置")
        }

        withAppLanguage(.korean) {
            #expect(L10n.tr("settings.title", default: "Settings") == "설정")
        }
    }

    @Test @MainActor func enablingProtectionRequiresSuccessfulAuthentication() {
        AppPreferences.resetForTesting()
        let preferences = AppPreferences()
        var capturedReason: String?

        let controller = AppSecurityController(
            preferences: preferences,
            canAuthenticateDeviceOwnerHandler: { true },
            canUseBiometricsHandler: { true },
            authenticationHandler: { reason, completion in
                capturedReason = reason
                completion(.success(()))
            }
        )

        controller.enableProtection()

        #expect(preferences.requireBiometricUnlock)
        #expect(controller.isLocked == false)
        #expect(capturedReason == L10n.tr("security.enable.reason", default: "开启身份验证保护前，请先验证你本人身份"))
    }

    @Test @MainActor func disablingProtectionKeepsLockEnabledWhenAuthenticationFails() {
        AppPreferences.resetForTesting()
        let preferences = AppPreferences()
        preferences.requireBiometricUnlock = true

        let controller = AppSecurityController(
            preferences: preferences,
            canAuthenticateDeviceOwnerHandler: { true },
            canUseBiometricsHandler: { true },
            authenticationHandler: { _, completion in
                completion(.failure(MockAuthenticationError()))
            }
        )

        controller.disableProtectionAfterAuthentication()

        #expect(preferences.requireBiometricUnlock)
        #expect(controller.errorMessage == L10n.tr("test.mock_auth_failed", default: "身份验证失败"))
    }

    @Test @MainActor func activePhaseDoesNotRetryUnlockAfterInactiveBounce() {
        AppPreferences.resetForTesting()
        let preferences = AppPreferences()
        preferences.requireBiometricUnlock = true
        var authenticationCount = 0

        let controller = AppSecurityController(
            preferences: preferences,
            canAuthenticateDeviceOwnerHandler: { true },
            canUseBiometricsHandler: { true },
            authenticationHandler: { _, completion in
                authenticationCount += 1
                completion(.success(()))
            }
        )

        controller.handleScenePhase(.active)
        controller.handleScenePhase(.inactive)
        controller.handleScenePhase(.active)

        #expect(authenticationCount == 1)
        #expect(controller.isLocked == false)
    }

    @Test @MainActor func backgroundThenActiveRequestsUnlockAgain() {
        AppPreferences.resetForTesting()
        let preferences = AppPreferences()
        preferences.requireBiometricUnlock = true
        var authenticationCount = 0

        let controller = AppSecurityController(
            preferences: preferences,
            canAuthenticateDeviceOwnerHandler: { true },
            canUseBiometricsHandler: { true },
            authenticationHandler: { _, completion in
                authenticationCount += 1
                completion(.success(()))
            }
        )

        controller.handleScenePhase(.active)
        controller.handleScenePhase(.background)
        controller.handleScenePhase(.active)

        #expect(authenticationCount == 2)
        #expect(controller.isLocked == false)
    }

}
