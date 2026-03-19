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
                    Toggle("启用生物识别锁定", isOn: $preferences.requireBiometricUnlock)
                    Toggle("详情页显示完整共享密钥", isOn: $preferences.showFullSecretInDetail)
                } header: {
                    Text("安全")
                } footer: {
                    Text("启用后，应用回到前台时会尝试使用 Face ID 或 Touch ID 解锁。")
                }

                Section {
                    Toggle("列表页隐藏验证码", isOn: $preferences.hideCodesInList)
                } header: {
                    Text("显示")
                }

                Section {
                    Label("支持手动添加和 otpauth / 二维码导入", systemImage: "qrcode.viewfinder")
                    Label("支持 TOTP、HOTP 与三种 HMAC 算法", systemImage: "key.fill")
                    Label("密钥已迁移到 Keychain 安全存储", systemImage: "lock.shield")
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
                }
            }
        }
    }
}