//
//  AppLockView.swift
//  Glosc 2fa
//
//  Created by GitHub Copilot on 2026/3/19.
//

import SwiftUI

struct AppLockView: View {
    let errorMessage: String?
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

                Text("需要通过生物识别解锁后，才能查看验证码与账号详情。")
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
                    Label(isAuthenticating ? "验证中..." : "立即解锁", systemImage: canUseBiometrics ? "touchid" : "lock.open")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isAuthenticating)

                if !canUseBiometrics {
                    Button("关闭生物识别锁定") {
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