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
            return "添加账号"
        case .edit:
            return "编辑账号"
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
            return "手动"
        case .otpauth:
            return "链接导入"
        case .scan:
            return "扫码"
        }
    }
}

struct AccountFormView: View {
    @Environment(\.dismiss) private var dismiss

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
                    Picker("录入方式", selection: $inputMode) {
                        ForEach(AccountInputMode.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if inputMode == .otpauth {
                    Section {
                        TextField("otpauth://totp/...", text: $importURI, axis: .vertical)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .accessibilityIdentifier("importURITextField")

                        Button("从链接填充") {
                            importFromURI()
                        }
                        .accessibilityIdentifier("importURIButton")
                    } header: {
                        Text("otpauth 链接")
                    } footer: {
                        Text("支持 TOTP 与 HOTP，issuer、secret、digits、period、counter、algorithm 会自动解析。")
                    }
                }

                if inputMode == .scan {
                    Section {
                        Button("打开二维码扫描器") {
                            isScannerPresented = true
                        }
                        .accessibilityIdentifier("openScannerButton")

                        if !importURI.isEmpty {
                            Text(importURI)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("二维码导入")
                    } footer: {
                        Text("扫描 otpauth 二维码后会自动填充账号表单。模拟器无摄像头时可继续使用链接导入。")
                    }
                }

                Section("账号信息") {
                    TextField("发行方，例如 GitHub", text: $draft.issuer)
                        .accessibilityIdentifier("issuerTextField")

                    TextField("账号名称，例如 alice@example.com", text: $draft.accountName)
                        .textInputAutocapitalization(.never)
                        .accessibilityIdentifier("accountNameTextField")
                }

                Section {
                    TextField("Base32 共享密钥", text: $draft.secret)
                        .textInputAutocapitalization(.characters)
                        .disableAutocorrection(true)
                        .accessibilityIdentifier("secretTextField")
                } header: {
                    Text("密钥")
                } footer: {
                    Text("会自动移除空格和连字符，并校验 Base32 格式。")
                }

                Section("配置") {
                    Picker("类型", selection: $draft.kind) {
                        ForEach(OTPKind.allCases) { kind in
                            Text(kind.title).tag(kind)
                        }
                    }

                    Picker("算法", selection: $draft.algorithm) {
                        ForEach(OTPAlgorithm.allCases) { algorithm in
                            Text(algorithm.rawValue).tag(algorithm)
                        }
                    }

                    Picker("位数", selection: $draft.digits) {
                        ForEach(6...8, id: \.self) { digits in
                            Text("\(digits) 位").tag(digits)
                        }
                    }

                    if draft.kind == .totp {
                        Stepper("时间步长：\(draft.period) 秒", value: $draft.period, in: 5...120, step: 5)
                    } else {
                        Stepper("起始计数器：\(draft.counter)", value: $draft.counter, in: 0...999_999)
                    }
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        save()
                    }
                    .bold()
                    .accessibilityIdentifier("saveAccountButton")
                }
            }
            .alert("无法保存账号", isPresented: Binding(
                get: { errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        errorMessage = nil
                    }
                }
            )) {
                Button("知道了", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
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
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func save() {
        do {
            try onSubmit(draft)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}