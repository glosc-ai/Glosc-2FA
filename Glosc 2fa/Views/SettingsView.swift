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
                    Toggle("启用生物识别锁定", isOn: $preferences.requireBiometricUnlock)
                        .accessibilityIdentifier("requireBiometricUnlockToggle")
                    Toggle("详情页显示完整共享密钥", isOn: $preferences.showFullSecretInDetail)
                        .accessibilityIdentifier("showFullSecretInDetailToggle")
                } header: {
                    Text("安全")
                } footer: {
                    Text("启用后，应用回到前台时会尝试使用 Face ID 或 Touch ID 解锁。")
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .accessibilityIdentifier("closeSettingsButton")
                }
            }
        }
    }
}