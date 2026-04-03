//
//  CloudSyncPassphraseSheetView.swift
//  Glosc 2fa
//
//  Created by GitHub Copilot on 2026/4/3.
//

import SwiftUI

struct CloudSyncPassphraseSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var cloudSyncController: CloudSyncController
    @EnvironmentObject private var operationFeedbackController: OperationFeedbackController

    let mode: CloudSyncPassphrasePrompt

    @State private var passphrase = ""
    @State private var confirmPassphrase = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField(L10n.tr("sync.passphrase.field.passphrase", default: "同步口令"), text: $passphrase)

                    if mode == .create {
                        SecureField(L10n.tr("sync.passphrase.field.confirm", default: "确认同步口令"), text: $confirmPassphrase)
                    }
                } footer: {
                    Text(footerText)
                }

                if cloudSyncController.isBusy {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text(L10n.tr("sync.status.authenticating", default: "正在处理登录状态..."))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.tr("common.cancel", default: "取消")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(submitTitle) {
                        submit()
                    }
                    .disabled(cloudSyncController.isBusy)
                }
            }
            .alert(
                L10n.tr("sync.alert.auth_failed_title", default: "无法完成身份验证"),
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button(L10n.tr("common.done", default: "完成"), role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var title: String {
        switch mode {
        case .create:
            return L10n.tr("sync.passphrase.sheet.create.title", default: "设置同步口令")
        case .unlock:
            return L10n.tr("sync.passphrase.sheet.unlock.title", default: "输入同步口令")
        }
    }

    private var footerText: String {
        switch mode {
        case .create:
            return L10n.tr("sync.passphrase.sheet.create.footer", default: "同步口令只会用于派生加密密钥，不会以明文形式上传。请妥善保存，否则你将无法在其他设备上解密已有云端数据。")
        case .unlock:
            return L10n.tr("sync.passphrase.sheet.unlock.footer", default: "请输入你之前为这个云同步账号设置过的同步口令。输入正确后，应用会恢复解密能力并继续同步。")
        }
    }

    private var submitTitle: String {
        switch mode {
        case .create:
            return L10n.tr("sync.passphrase.action.save", default: "保存")
        case .unlock:
            return L10n.tr("sync.passphrase.action.unlock", default: "解锁")
        }
    }

    private func submit() {
        Task {
            do {
                switch mode {
                case .create:
                    try await cloudSyncController.createSyncPassphrase(passphrase: passphrase, confirmPassphrase: confirmPassphrase)
                    operationFeedbackController.showSuccess(message: L10n.tr("sync.feedback.passphrase_created", default: "同步口令已保存，云同步已解锁"))
                case .unlock:
                    try await cloudSyncController.unlockSync(passphrase: passphrase)
                    operationFeedbackController.showSuccess(message: L10n.tr("sync.feedback.passphrase_unlocked", default: "云同步已解锁"))
                }

                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = cloudSyncController.userFacingMessage(for: error)
                }
            }
        }
    }
}