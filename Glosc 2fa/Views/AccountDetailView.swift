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

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let account: OTPAccountRecord
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var copied = false

    var body: some View {
        ScrollView {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                VStack(alignment: .leading, spacing: 24) {
                    header(date: context.date)
                    metadata

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
                    }

                    Button {
                        copyCode(at: context.date)
                    } label: {
                        Label(copied ? "已复制验证码" : "复制验证码", systemImage: copied ? "checkmark.circle.fill" : "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .navigationTitle(account.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("编辑") {
                    onEdit()
                }

                Button("删除", role: .destructive) {
                    onDelete()
                    dismiss()
                }
            }
        }
    }

    @ViewBuilder
    private func header(date: Date) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if !account.displayIssuer.isEmpty {
                Text(account.displayIssuer)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            Text((try? OTPCodeGenerator.generateCode(for: account, at: date)) ?? "------")
                .font(.system(size: 42, weight: .bold, design: .monospaced))
                .minimumScaleFactor(0.6)

            if let remaining = OTPCodeGenerator.remainingSeconds(for: account, at: date),
               let progress = OTPCodeGenerator.progress(for: account, at: date) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("剩余 \(remaining) 秒", systemImage: "timer")
                        Spacer()
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
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var metadata: some View {
        VStack(alignment: .leading, spacing: 16) {
            DetailRow(label: "账号名称", value: account.displayName)
            DetailRow(label: "OTP 类型", value: account.kind.title)
            DetailRow(label: "算法", value: account.algorithm.rawValue)
            DetailRow(label: "位数", value: "\(account.digits)")
            DetailRow(label: "时间步长", value: account.kind == .totp ? "\(account.period) 秒" : "不适用")
            DetailRow(label: "计数器", value: account.kind == .hotp ? "\(account.counter)" : "不适用")
            DetailRow(label: "共享密钥", value: preferences.showFullSecretInDetail ? account.secret : account.secretPreview)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func copyCode(at date: Date) {
        UIPasteboard.general.string = try? OTPCodeGenerator.generateCode(for: account, at: date)
        copied = true
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.body)
                .textSelection(.enabled)
        }
    }
}