//
//  AppSecurityController.swift
//  Glosc 2fa
//
//  Created by GitHub Copilot on 2026/3/19.
//

import Combine
import SwiftUI

@MainActor
final class AppSecurityController: ObservableObject {
    @Published private(set) var isLocked = false
    @Published private(set) var isAuthenticating = false
    @Published var errorMessage: String?

    private let preferences: AppPreferences

    init(preferences: AppPreferences) {
        self.preferences = preferences
        self.isLocked = preferences.requireBiometricUnlock
    }

    var canUseBiometrics: Bool {
        BiometricAuthService.canUseBiometrics
    }

    func handleScenePhase(_ scenePhase: ScenePhase) {
        switch scenePhase {
        case .background, .inactive:
            if preferences.requireBiometricUnlock {
                isLocked = true
            }
        case .active:
            if preferences.requireBiometricUnlock {
                isLocked = true
                requestUnlock()
            } else {
                isLocked = false
            }
        @unknown default:
            break
        }
    }

    func requestUnlock() {
        guard preferences.requireBiometricUnlock else {
            isLocked = false
            return
        }

        guard !isAuthenticating else {
            return
        }

        isAuthenticating = true
        errorMessage = nil

        BiometricAuthService.authenticate(reason: "解锁 Glosc 2FA 以查看验证码和账号信息") { [weak self] result in
            guard let self else {
                return
            }

            self.isAuthenticating = false

            switch result {
            case .success:
                self.isLocked = false
                self.errorMessage = nil
            case let .failure(error):
                self.isLocked = true
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func disableProtection() {
        isLocked = false
        errorMessage = nil
    }
}