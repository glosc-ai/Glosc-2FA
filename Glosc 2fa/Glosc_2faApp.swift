//
//  Glosc_2faApp.swift
//  Glosc 2fa
//
//  Created by XiaoM on 2026/3/19.
//

import SwiftUI
import SwiftData

@main
struct Glosc_2faApp: App {
    private static let uiTestingResetArgument = "UITEST_RESET_STATE"

    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var preferences: AppPreferences
    @StateObject private var securityController: AppSecurityController
    @StateObject private var operationFeedbackController = OperationFeedbackController()

    var sharedModelContainer: ModelContainer = {
        let useInMemoryStore = ProcessInfo.processInfo.arguments.contains(uiTestingResetArgument)
        let schema = Schema([
            OTPAccountRecord.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: useInMemoryStore)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        if Self.isRunningUITests {
            AppPreferences.resetForTesting()
            try? KeychainSecretStore.shared.removeAllSecrets()
        }

        let preferences = AppPreferences()
        _preferences = StateObject(wrappedValue: preferences)
        _securityController = StateObject(wrappedValue: AppSecurityController(preferences: preferences))
    }

    private static var isRunningUITests: Bool {
        ProcessInfo.processInfo.arguments.contains(uiTestingResetArgument)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(preferences)
                .environmentObject(securityController)
                .environmentObject(operationFeedbackController)
                .environment(\.locale, preferences.appLanguage.locale)
                .preferredColorScheme(preferences.appTheme.colorScheme)
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase, initial: true) { _, newPhase in
            securityController.handleScenePhase(newPhase)
        }
    }
}
