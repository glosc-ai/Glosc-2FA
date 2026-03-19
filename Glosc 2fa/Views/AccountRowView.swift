//
//  AccountRowView.swift
//  Glosc 2fa
//
//  Created by GitHub Copilot on 2026/3/19.
//

import SwiftUI

struct AccountRowView: View {
    @EnvironmentObject private var preferences: AppPreferences
    @EnvironmentObject private var securityController: AppSecurityController

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

                    if let remaining = OTPCodeGenerator.remainingSeconds(for: account, at: context.date) {
                        Label("\(remaining)s", systemImage: "timer")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("HOTP")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
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
}