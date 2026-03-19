//
//  SettingsView.swift
//  Glosc 2fa
//
//  Created by GitHub Copilot on 2026/3/19.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var preferences: AppPreferences
    @EnvironmentObject private var securityController: AppSecurityController
    @EnvironmentObject private var operationFeedbackController: OperationFeedbackController

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("外观主题", selection: $preferences.appTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.title).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("appThemePicker")
                } header: {
                    Text("主题")
                } footer: {
                    Text("可在跟随系统、浅色与深色之间切换。")
                }

                Section {
                    Toggle("启用身份验证锁定", isOn: biometricProtectionBinding)
                        .accessibilityIdentifier("requireBiometricUnlockToggle")
                        .disabled(securityController.isAuthenticating)
                    Toggle("详情页显示完整共享密钥", isOn: $preferences.showFullSecretInDetail)
                        .accessibilityIdentifier("showFullSecretInDetailToggle")
                } header: {
                    Text("安全")
                } footer: {
                    Text("启用或关闭此开关前都会先验证身份。启用后，应用回到前台时会要求通过 Face ID、Touch ID 或设备密码完成解锁。")
                }

                Section {
                    Toggle("列表页隐藏验证码", isOn: $preferences.hideCodesInList)
                        .accessibilityIdentifier("hideCodesInListToggle")
                } header: {
                    Text("显示")
                }

                Section {
                    Label("支持手动添加和 otpauth / 二维码导入", systemImage: "qrcode.viewfinder")
                    Label("支持 TOTP、HOTP 与三种 HMAC 算法", systemImage: "key.fill")
                    Label("密钥已迁移到 Keychain 安全存储", systemImage: "lock.shield")
                    Label("详情页轻点或长按验证码可快速复制", systemImage: "hand.tap")
                    Label("列表长按账号可快速复制当前验证码", systemImage: "hand.point.up.left")
                } header: {
                    Text("当前能力")
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .top) {
                if let feedback = operationFeedbackController.currentFeedback {
                    OperationFeedbackToastView(feedback: feedback)
                        .padding(.top, 12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .accessibilityIdentifier("closeSettingsButton")
                }
            }
            .animation(.easeInOut(duration: 0.2), value: operationFeedbackController.currentFeedback)
        }
        .preferredColorScheme(preferences.appTheme.colorScheme)
    }

    private var biometricProtectionBinding: Binding<Bool> {
        Binding(
            get: { preferences.requireBiometricUnlock },
            set: { newValue in
                updateBiometricProtection(to: newValue)
            }
        )
    }

    private func updateBiometricProtection(to newValue: Bool) {
        guard newValue != preferences.requireBiometricUnlock else {
            return
        }

        if newValue {
            securityController.enableProtection { result in
                switch result {
                case .success:
                    operationFeedbackController.showSuccess(message: "已开启身份验证保护")
                case let .failure(error):
                    operationFeedbackController.showError(message: error.localizedDescription)
                }
            }
        } else {
            securityController.disableProtectionAfterAuthentication { result in
                switch result {
                case .success:
                    operationFeedbackController.showSuccess(message: "已关闭身份验证保护")
                case let .failure(error):
                    operationFeedbackController.showError(message: error.localizedDescription)
                }
            }
        }
    }
}