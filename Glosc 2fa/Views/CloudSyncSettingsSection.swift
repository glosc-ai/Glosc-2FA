//
//  CloudSyncSettingsSection.swift
//  Glosc 2fa
//
//  Created by GitHub Copilot on 2026/4/2.
//

import SwiftUI
import AuthenticationServices

struct CloudSyncSettingsSection: View {
    @EnvironmentObject private var cloudSyncController: CloudSyncController
    @EnvironmentObject private var operationFeedbackController: OperationFeedbackController

    @Binding var passphraseSheetMode: CloudSyncPassphrasePrompt?

    var body: some View {
        Section {
            if cloudSyncController.isSignedIn {
                LabeledContent(
                    L10n.tr("sync.settings.email", default: "当前账号"),
                    value: cloudSyncController.userEmail ?? L10n.tr("common.not_applicable", default: "不适用")
                )

                LabeledContent(
                    L10n.tr("sync.settings.status", default: "同步状态"),
                    value: statusText
                )

                if let passphrasePrompt = cloudSyncController.passphrasePrompt {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(passphrasePromptDescription(for: passphrasePrompt))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Button(passphrasePromptActionTitle(for: passphrasePrompt)) {
                        passphraseSheetMode = passphrasePrompt
                    }
                    .disabled(cloudSyncController.isBusy)
                    .accessibilityIdentifier("openPassphraseSheetButton")
                } else {
                    Button(L10n.tr("sync.action.sync_now", default: "立即同步")) {
                        Task {
                            await cloudSyncController.syncNow()
                            await MainActor.run {
                                showFeedbackIfNeeded()
                            }
                        }
                    }
                    .disabled(cloudSyncController.isBusy)
                    .accessibilityIdentifier("syncNowButton")
                }

                Button(L10n.tr("sync.action.sign_out", default: "退出登录"), role: .destructive) {
                    do {
                        try cloudSyncController.signOut()
                        operationFeedbackController.showSuccess(message: L10n.tr("sync.feedback.signed_out", default: "已退出云同步账号"))
                    } catch {
                        operationFeedbackController.showError(message: error.localizedDescription)
                    }
                }
                .disabled(cloudSyncController.isBusy)
                .accessibilityIdentifier("signOutButton")
            } else {
                if cloudSyncController.isBusy {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text(L10n.tr("sync.status.authenticating", default: "正在处理登录状态..."))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Button(L10n.tr("sync.action.sign_in_google", default: "使用 Google 登录")) {
                    signInWithGoogle()
                }
                .disabled(cloudSyncController.isBusy)
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("signInWithGoogleButton")

                SignInWithAppleButton(.signIn) { request in
                    cloudSyncController.prepareAppleSignInRequest(request)
                } onCompletion: { result in
                    handleAppleCompletion(result)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .disabled(cloudSyncController.isBusy)
                .signInWithAppleButtonStyle(.black)
                .accessibilityIdentifier("signInWithAppleButton")

                Text(L10n.tr("sync.settings.sign_in_hint", default: "首次开启云同步时，还需要设置一个独立的同步口令来加密云端数据。"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        } header: {
            Text(L10n.tr("sync.settings.section", default: "云同步"))
        } footer: {
            Text(footerText)
        }
    }

    private var statusText: String {
        switch cloudSyncController.syncStatus {
        case .signedOut:
            return L10n.tr("sync.status.signed_out", default: "未登录")
        case .keyUnavailable:
            switch cloudSyncController.passphrasePrompt {
            case .create:
                return L10n.tr("sync.status.passphrase_required_create", default: "需要先设置同步口令")
            case .unlock:
                return L10n.tr("sync.status.passphrase_required_unlock", default: "需要输入同步口令")
            case .none:
                return L10n.tr("sync.status.key_unavailable", default: "需要同步口令才能解锁云端数据")
            }
        case .syncing:
            return L10n.tr("sync.status.syncing", default: "同步中")
        case let .synced(date):
            return L10n.format("sync.status.synced_at", default: "已同步于 %@", formattedDate(date))
        case let .failed(message):
            return message
        }
    }

    private var footerText: String {
        if cloudSyncController.isSignedIn {
            return L10n.tr("sync.settings.footer_signed_in", default: "账号数据会在上传到 Firebase Cloud Firestore 前于本地使用同步口令派生出的 AES-GCM 密钥加密；数据库只保存密文。")
        }

        return L10n.tr("sync.settings.footer_signed_out", default: "登录是可选的。你可以使用 Google 或 Apple 登录；首次启用云同步时，需要设置一个独立的同步口令，用来加密数据库中的 OTP 数据。")
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = AppPreferences.currentAppLanguage.locale
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func showFeedbackIfNeeded() {
        switch cloudSyncController.syncStatus {
        case .failed(let message):
            operationFeedbackController.showError(message: message)
        case .synced:
            operationFeedbackController.showSuccess(message: L10n.tr("sync.feedback.synced", default: "云端同步完成"))
        case .signedOut, .keyUnavailable, .syncing:
            break
        }
    }

    private func passphrasePromptDescription(for prompt: CloudSyncPassphrasePrompt) -> String {
        switch prompt {
        case .create:
            return L10n.tr("sync.status.passphrase_create_hint", default: "这是你第一次在该账号上启用云同步。请先设置同步口令，之后所有云端 OTP 数据都会使用它派生的密钥加密。")
        case .unlock:
            return L10n.tr("sync.status.passphrase_unlock_hint", default: "云端数据已经加密。请输入之前设置过的同步口令以恢复解密能力并继续同步。")
        }
    }

    private func passphrasePromptActionTitle(for prompt: CloudSyncPassphrasePrompt) -> String {
        switch prompt {
        case .create:
            return L10n.tr("sync.action.create_passphrase", default: "设置同步口令")
        case .unlock:
            return L10n.tr("sync.action.unlock_passphrase", default: "输入同步口令")
        }
    }

    private func signInWithGoogle() {
        Task {
            do {
                try await cloudSyncController.signInWithGoogle()
            } catch {
                handleAuthError(error)
            }
        }
    }

    private func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        Task {
            do {
                try await cloudSyncController.handleAppleSignInCompletion(result)
            } catch {
                handleAuthError(error)
            }
        }
    }

    private func handleAuthError(_ error: Error) {
        guard !cloudSyncController.shouldSuppressFeedback(for: error) else {
            return
        }

        operationFeedbackController.showError(message: cloudSyncController.userFacingMessage(for: error))
    }
}