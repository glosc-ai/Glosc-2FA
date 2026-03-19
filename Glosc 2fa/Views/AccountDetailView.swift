//
//  AccountDetailView.swift
//  Glosc 2fa
//
//  Created by GitHub Copilot on 2026/3/19.
//

import SwiftData
import SwiftUI
import UIKit

struct AccountDetailView: View {
    @EnvironmentObject private var preferences: AppPreferences
    @EnvironmentObject private var operationFeedbackController: OperationFeedbackController

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let account: OTPAccountRecord
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var copied = false
    @State private var resetCopiedTask: Task<Void, Never>?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                codeCard
                metadataCard
                actionSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .scrollBounceBehavior(.basedOnSize)
        .navigationTitle(account.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("编辑") {
                    onEdit()
                }
                .accessibilityIdentifier("editAccountButton")

                Button("删除", role: .destructive) {
                    onDelete()
                    dismiss()
                }
                .accessibilityIdentifier("deleteAccountButton")
            }
        }
    }

    private var codeCard: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(alignment: .leading, spacing: 16) {
                if !account.displayIssuer.isEmpty {
                    Text(account.displayIssuer)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                Text((try? OTPCodeGenerator.generateCode(for: account, at: context.date)) ?? "------")
                    .font(.system(size: 42, weight: .bold, design: .monospaced))
                    .minimumScaleFactor(0.55)
                    .lineLimit(1)
                    .accessibilityIdentifier("detailCodeText")

                if let remaining = OTPCodeGenerator.remainingSeconds(for: account, at: context.date),
                   let progress = OTPCodeGenerator.progress(for: account, at: context.date) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .firstTextBaseline) {
                            Label("剩余 \(remaining) 秒", systemImage: "timer")
                            Spacer(minLength: 12)
                            Text("每 \(account.period) 秒更新")
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)

                        ProgressView(value: progress)
                            .tint(progress > 0.75 ? .orange : .accentColor)
                    }
                } else {
                    Text("当前计数器：\(account.counter)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("hotpCounterValue")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .onTapGesture {
                copyCode(at: context.date)
            }
            .onLongPressGesture {
                copyCode(at: context.date)
            }
        }
    }

    private var metadataCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("账号信息")
                .font(.headline)

            VStack(alignment: .leading, spacing: 14) {
                DetailRow(label: "账号名称", value: account.displayName)

                if !account.displayIssuer.isEmpty {
                    DetailRow(label: "签发方", value: account.displayIssuer)
                }

                DetailRow(label: "OTP 类型", value: account.kind.title)
                DetailRow(label: "算法", value: account.algorithm.rawValue)
                DetailRow(label: "位数", value: "\(account.digits)")
                DetailRow(label: "时间步长", value: account.kind == .totp ? "\(account.period) 秒" : "不适用")
                DetailRow(label: "计数器", value: account.kind == .hotp ? "\(account.counter)" : "不适用")
                DetailRow(
                    label: "共享密钥",
                    value: preferences.showFullSecretInDetail ? account.secret : account.secretPreview,
                    valueAccessibilityIdentifier: "secretValueText",
                    usesMonospacedValue: true
                )
            }
        }
        .padding(20)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var actionSection: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(spacing: 12) {
                Button {
                    copyCode(at: context.date)
                } label: {
                    Label(copied ? "已复制验证码" : "复制验证码", systemImage: copied ? "checkmark.circle.fill" : "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                if account.kind == .hotp {
                    Button {
                        account.counter = OTPCodeGenerator.nextCounter(afterUsing: account)
                        account.updatedAt = .now
                        try? modelContext.save()
                    } label: {
                        Label("标记当前 HOTP 已使用", systemImage: "arrow.triangle.2.circlepath")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("advanceHOTPButton")
                }
            }
        }
    }

    private func copyCode(at date: Date) {
        guard let code = try? OTPCodeGenerator.generateCode(for: account, at: date) else {
            operationFeedbackController.showError(message: "复制失败，当前验证码不可用")
            return
        }

        UIPasteboard.general.string = code
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        operationFeedbackController.showSuccess(message: "复制验证码成功")
        copied = true
        resetCopiedTask?.cancel()
        resetCopiedTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            await MainActor.run {
                copied = false
            }
        }
    }
}

private struct DetailRow: View {
    let label: String
    let value: String
    var valueAccessibilityIdentifier: String?
    var usesMonospacedValue = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 72, alignment: .leading)

            Text(value)
                .font(usesMonospacedValue ? .system(.body, design: .monospaced) : .body)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .textSelection(.enabled)
                .accessibilityIdentifier(valueAccessibilityIdentifier ?? "")
        }
    }
}