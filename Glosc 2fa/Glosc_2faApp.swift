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
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var preferences: AppPreferences
    @StateObject private var securityController: AppSecurityController

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            OTPAccountRecord.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        let preferences = AppPreferences()
        _preferences = StateObject(wrappedValue: preferences)
        _securityController = StateObject(wrappedValue: AppSecurityController(preferences: preferences))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(preferences)
                .environmentObject(securityController)
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase, initial: true) { _, newPhase in
            securityController.handleScenePhase(newPhase)
        }
    }
}
