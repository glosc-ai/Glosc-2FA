//
//  AccountRowView.swift
//  Glosc 2fa
//
//  Created by GitHub Copilot on 2026/3/19.
//

import SwiftUI
import UIKit

struct AccountRowView: View {
    @EnvironmentObject private var preferences: AppPreferences
    @EnvironmentObject private var securityController: AppSecurityController
    @EnvironmentObject private var operationFeedbackController: OperationFeedbackController

    let account: OTPAccountRecord

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.displayName)
                        .font(.headline)

                    if !account.displayIssuer.isEmpty {
                        Text(account.displayIssuer)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text(displayCode(at: context.date))
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundStyle(codeColor(at: context.date))
                        .accessibilityIdentifier("accountCodeText")

                    if let remaining = OTPCodeGenerator.remainingSeconds(for: account, at: context.date) {
                        Label(L10n.format("account.row.remaining_short", default: "%ds", remaining), systemImage: "timer")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(L10n.tr("otp.kind.hotp", default: "HOTP"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.6)
                    .onEnded { _ in
                        copyCode(at: context.date)
                    }
            )
        }
    }

    private func displayCode(at date: Date) -> String {
        guard !preferences.hideCodesInList, !securityController.isLocked else {
            return "••••••"
        }

        return (try? OTPCodeGenerator.generateCode(for: account, at: date)) ?? "------"
    }

    private func codeColor(at date: Date) -> Color {
        guard OTPCodeGenerator.progress(for: account, at: date).map({ $0 > 0.75 }) == true else {
            return .primary
        }

        return .orange
    }

    private func copyCode(at date: Date) {
        guard let code = try? OTPCodeGenerator.generateCode(for: account, at: date) else {
            operationFeedbackController.showError(message: L10n.tr("feedback.code.copy_failed", default: "复制失败，当前验证码不可用"))
            return
        }

        UIPasteboard.general.string = code
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        operationFeedbackController.showSuccess(message: L10n.tr("feedback.code.copy_success", default: "复制验证码成功"))
    }
}
