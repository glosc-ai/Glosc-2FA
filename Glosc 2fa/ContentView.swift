//
//  ContentView.swift
//  Glosc 2fa
//
//  Created by XiaoM on 2026/3/19.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var preferences: AppPreferences
    @EnvironmentObject private var securityController: AppSecurityController
    @EnvironmentObject private var copyFeedbackController: CopyFeedbackController

    @Query private var accounts: [OTPAccountRecord]

    @State private var formMode: AccountFormMode?
    @State private var isSettingsPresented = false

    init() {
        _accounts = Query(sort: [SortDescriptor(\OTPAccountRecord.createdAt, order: .forward)])
    }

    var body: some View {
        NavigationStack {
            Group {
                if accounts.isEmpty {
                    ContentUnavailableView {
                        Label("还没有账号", systemImage: "key.fill")
                    } description: {
                        Text("支持手动添加账号，或直接粘贴 otpauth 链接完成导入。")
                    } actions: {
                        Button("添加账号") {
                            formMode = .add
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("emptyAddAccountButton")
                    }
                } else {
                    List {
                        ForEach(accounts) { account in
                            NavigationLink {
                                AccountDetailView(account: account) {
                                    formMode = .edit(account)
                                } onDelete: {
                                    delete(account)
                                }
                            } label: {
                                AccountRowView(account: account)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("编辑") {
                                    formMode = .edit(account)
                                }
                                .tint(.blue)

                                Button("删除", role: .destructive) {
                                    delete(account)
                                }
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Glosc 2FA")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isSettingsPresented = true
                    } label: {
                        Label("设置", systemImage: "gearshape")
                    }
                    .accessibilityIdentifier("settingsButton")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        formMode = .add
                    } label: {
                        Label("添加账号", systemImage: "plus")
                    }
                    .accessibilityIdentifier("addAccountButton")
                }
            }
            .sheet(item: $formMode) { mode in
                AccountFormView(mode: mode) { draft in
                    try save(draft, for: mode)
                }
            }
            .sheet(isPresented: $isSettingsPresented) {
                SettingsView()
            }
            .task {
                migrateLegacySecretsIfNeeded()
            }
            .overlay {
                ZStack(alignment: .top) {
                    if let message = copyFeedbackController.message {
                        CopySuccessToast(message: message)
                            .padding(.top, 12)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .zIndex(1)
                    }

                    if securityController.isLocked {
                        AppLockView(
                            errorMessage: securityController.errorMessage,
                            canUseBiometrics: securityController.canUseBiometrics,
                            isAuthenticating: securityController.isAuthenticating,
                            onUnlock: {
                                securityController.requestUnlock()
                            },
                            onDisableProtection: {
                                preferences.requireBiometricUnlock = false
                                securityController.disableProtection()
                            }
                        )
                        .transition(.opacity)
                        .zIndex(2)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: securityController.isLocked)
            .animation(.easeInOut(duration: 0.2), value: copyFeedbackController.message)
        }
    }

    private func save(_ draft: OTPAccountDraft, for mode: AccountFormMode) throws {
        switch mode {
        case .add:
            modelContext.insert(try draft.makeRecord())
        case let .edit(account):
            try draft.apply(to: account)
        }

        try modelContext.save()
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                accounts[index].removeSecretFromSecureStore()
                modelContext.delete(accounts[index])
            }

            try? modelContext.save()
        }
    }

    private func delete(_ account: OTPAccountRecord) {
        withAnimation {
            account.removeSecretFromSecureStore()
            modelContext.delete(account)
            try? modelContext.save()
        }
    }

    private func migrateLegacySecretsIfNeeded() {
        var hasChanges = false

        for account in accounts {
            if account.migrateLegacySecretIfNeeded() {
                hasChanges = true
            }
        }

        if hasChanges {
            try? modelContext.save()
        }
    }
}

private struct CopySuccessToast: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "checkmark.circle.fill")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.green.gradient, in: Capsule())
            .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
            .accessibilityIdentifier("copySuccessToast")
    }
}

#Preview {
    ContentView()
        .modelContainer(for: OTPAccountRecord.self, inMemory: true)
        .environmentObject(AppPreferences())
        .environmentObject(AppSecurityController(preferences: AppPreferences()))
        .environmentObject(CopyFeedbackController())
}
