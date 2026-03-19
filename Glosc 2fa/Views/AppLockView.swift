//
//  AppLockView.swift
//  Glosc 2fa
//
//  Created by GitHub Copilot on 2026/3/19.
//

import SwiftUI

struct AppLockView: View {
    let errorMessage: String?
    let canAuthenticateDeviceOwner: Bool
    let canUseBiometrics: Bool
    let isAuthenticating: Bool
    let onUnlock: () -> Void
    let onDisableProtection: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: canUseBiometrics ? "faceid" : "lock.fill")
                    .font(.system(size: 42))

                Text("已锁定")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("需要先完成设备身份验证后，才能查看验证码与账号详情。")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                if let errorMessage, !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    onUnlock()
                } label: {
                    Label(isAuthenticating ? "验证中..." : "验证身份", systemImage: canUseBiometrics ? "touchid" : "lock.open")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isAuthenticating || !canAuthenticateDeviceOwner)

                if !canAuthenticateDeviceOwner {
                    Button("关闭身份验证锁定") {
                        onDisableProtection()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(24)
            .frame(maxWidth: 360)
            .background(Color(uiColor: .systemBackground), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .padding()
        }
    }
}