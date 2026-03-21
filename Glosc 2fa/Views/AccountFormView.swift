//
//  AccountFormView.swift
//  Glosc 2fa
//
//  Created by GitHub Copilot on 2026/3/19.
//

import SwiftUI

enum AccountFormMode: Identifiable {
    case add
    case edit(OTPAccountRecord)

    var id: String {
        switch self {
        case .add:
            return "add"
        case let .edit(account):
            return "edit-\(account.id.uuidString)"
        }
    }

    var title: String {
        switch self {
        case .add:
            return L10n.tr("common.add_account", default: "添加账号")
        case .edit:
            return L10n.tr("account.form.edit_title", default: "编辑账号")
        }
    }

    var initialDraft: OTPAccountDraft {
        switch self {
        case .add:
            return OTPAccountDraft()
        case let .edit(account):
            return OTPAccountDraft(record: account)
        }
    }
}

private enum AccountInputMode: String, CaseIterable, Identifiable {
    case manual
    case otpauth
    case scan

    var id: String { rawValue }

    var title: String {
        switch self {
        case .manual:
            return L10n.tr("account.input.manual", default: "手动")
        case .otpauth:
            return L10n.tr("account.input.link", default: "链接导入")
        case .scan:
            return L10n.tr("account.input.scan", default: "扫码")
        }
    }
}

struct AccountFormView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var operationFeedbackController: OperationFeedbackController

    let mode: AccountFormMode
    let onSubmit: (OTPAccountDraft) throws -> Void

    @State private var inputMode: AccountInputMode = .manual
    @State private var importURI: String = ""
    @State private var draft: OTPAccountDraft
    @State private var errorMessage: String?
    @State private var isScannerPresented = false

    init(mode: AccountFormMode, onSubmit: @escaping (OTPAccountDraft) throws -> Void) {
        self.mode = mode
        self.onSubmit = onSubmit
        _draft = State(initialValue: mode.initialDraft)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(L10n.tr("account.form.input_mode", default: "录入方式"), selection: $inputMode) {
                        ForEach(AccountInputMode.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if inputMode == .otpauth {
                    Section {
                        TextField(L10n.tr("account.form.import_uri_placeholder", default: "otpauth://totp/..."), text: $importURI, axis: .vertical)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .accessibilityIdentifier("importURITextField")

                        Button(L10n.tr("account.form.import_from_link", default: "从链接填充")) {
                            importFromURI()
                        }
                        .accessibilityIdentifier("importURIButton")
                    } header: {
                        Text(L10n.tr("account.form.otpauth_section", default: "otpauth 链接"))
                    } footer: {
                        Text(L10n.tr("account.form.otpauth_footer", default: "支持 TOTP 与 HOTP，issuer、secret、digits、period、counter、algorithm 会自动解析。"))
                    }
                }

                if inputMode == .scan {
                    Section {
                        Button(L10n.tr("scanner.open", default: "打开二维码扫描器")) {
                            isScannerPresented = true
                        }
                        .accessibilityIdentifier("openScannerButton")

                        if !importURI.isEmpty {
                            Text(importURI)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text(L10n.tr("scanner.import_section", default: "二维码导入"))
                    } footer: {
                        Text(L10n.tr("scanner.import_footer", default: "扫描 otpauth 二维码后会自动填充账号表单。模拟器无摄像头时可继续使用链接导入。"))
                    }
                }

                Section {
                    TextField(L10n.tr("account.form.issuer_placeholder", default: "发行方，例如 GitHub"), text: $draft.issuer)
                        .accessibilityIdentifier("issuerTextField")

                    TextField(L10n.tr("account.form.account_name_placeholder", default: "账号名称，例如 alice@example.com"), text: $draft.accountName)
                        .textInputAutocapitalization(.never)
                        .accessibilityIdentifier("accountNameTextField")
                } header: {
                    Text(L10n.tr("account.form.account_section", default: "账号信息"))
                }

                Section {
                    TextField(L10n.tr("account.form.secret_placeholder", default: "Base32 共享密钥"), text: $draft.secret)
                        .textInputAutocapitalization(.characters)
                        .disableAutocorrection(true)
                        .accessibilityIdentifier("secretTextField")
                } header: {
                    Text(L10n.tr("account.form.secret_section", default: "密钥"))
                } footer: {
                    Text(L10n.tr("account.form.secret_footer", default: "会自动移除空格和连字符，并校验 Base32 格式。"))
                }

                Section {
                    Picker(L10n.tr("account.form.kind", default: "类型"), selection: $draft.kind) {
                        ForEach(OTPKind.allCases) { kind in
                            Text(kind.title).tag(kind)
                        }
                    }

                    Picker(L10n.tr("account.form.algorithm", default: "算法"), selection: $draft.algorithm) {
                        ForEach(OTPAlgorithm.allCases) { algorithm in
                            Text(algorithm.rawValue).tag(algorithm)
                        }
                    }

                    Picker(L10n.tr("account.form.digits", default: "位数"), selection: $draft.digits) {
                        ForEach(6...8, id: \.self) { digits in
                            Text(L10n.format("account.form.digits.option", default: "%d 位", digits)).tag(digits)
                        }
                    }

                    if draft.kind == .totp {
                        Stepper(L10n.format("account.form.period", default: "时间步长：%d 秒", draft.period), value: $draft.period, in: 5...120, step: 5)
                    } else {
                        Stepper(L10n.format("account.form.counter", default: "起始计数器：%d", draft.counter), value: $draft.counter, in: 0...999_999)
                    }
                } header: {
                    Text(L10n.tr("account.form.config_section", default: "配置"))
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .top) {
                if let feedback = operationFeedbackController.currentFeedback {
                    OperationFeedbackToastView(feedback: feedback)
                        .padding(.top, 12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.tr("common.cancel", default: "取消")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.tr("common.save", default: "保存")) {
                        save()
                    }
                    .bold()
                    .accessibilityIdentifier("saveAccountButton")
                }
            }
            .alert(L10n.tr("account.form.save_failed_title", default: "无法保存账号"), isPresented: Binding(
                get: { errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        errorMessage = nil
                    }
                }
            )) {
                Button(L10n.tr("common.ok", default: "知道了"), role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .animation(.easeInOut(duration: 0.2), value: operationFeedbackController.currentFeedback)
            .sheet(isPresented: $isScannerPresented) {
                QRCodeScannerView { scannedValue in
                    importURI = scannedValue
                    importFromURI()
                    isScannerPresented = false
                    inputMode = .manual
                }
            }
        }
    }

    private func importFromURI() {
        do {
            draft = try OTPAuthURIParser.parse(importURI)
            operationFeedbackController.showSuccess(message: L10n.tr("feedback.import.success", default: "导入成功，已填充表单"))
        } catch {
            errorMessage = error.localizedDescription
            operationFeedbackController.showError(message: L10n.tr("feedback.import.failed", default: "导入失败"))
        }
    }

    private func save() {
        do {
            try onSubmit(draft)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            operationFeedbackController.showError(message: L10n.tr("feedback.save.failed", default: "保存失败"))
        }
    }
}
