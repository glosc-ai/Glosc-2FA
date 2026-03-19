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
    typealias AuthenticationHandler = @MainActor (_ reason: String, _ completion: @escaping (Result<Void, Error>) -> Void) -> Void
    typealias AvailabilityHandler = @MainActor () -> Bool

    @Published private(set) var isLocked = false
    @Published private(set) var isAuthenticating = false
    @Published var errorMessage: String?

    private let preferences: AppPreferences
    private let canAuthenticateDeviceOwnerHandler: AvailabilityHandler
    private let canUseBiometricsHandler: AvailabilityHandler
    private let authenticationHandler: AuthenticationHandler

    init(
        preferences: AppPreferences,
        canAuthenticateDeviceOwnerHandler: AvailabilityHandler? = nil,
        canUseBiometricsHandler: AvailabilityHandler? = nil,
        authenticationHandler: AuthenticationHandler? = nil
    ) {
        self.preferences = preferences
        self.canAuthenticateDeviceOwnerHandler = canAuthenticateDeviceOwnerHandler ?? { BiometricAuthService.canAuthenticateDeviceOwner }
        self.canUseBiometricsHandler = canUseBiometricsHandler ?? { BiometricAuthService.canUseBiometrics }
        self.authenticationHandler = authenticationHandler ?? BiometricAuthService.authenticateDeviceOwner
        self.isLocked = preferences.requireBiometricUnlock
    }

    var canAuthenticateDeviceOwner: Bool {
        canAuthenticateDeviceOwnerHandler()
    }

    var canUseBiometrics: Bool {
        canUseBiometricsHandler()
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

        authenticate(reason: "解锁 Glosc 2FA 以查看验证码和账号信息") { [weak self] result in
            guard let self else {
                return
            }

            switch result {
            case .success:
                self.isLocked = false
            case .failure:
                self.isLocked = true
            }
        }
    }

    func enableProtection(completion: ((Result<Void, Error>) -> Void)? = nil) {
        authenticate(reason: "开启身份验证保护前，请先验证你本人身份") { [weak self] result in
            guard let self else {
                return
            }

            switch result {
            case .success:
                self.preferences.requireBiometricUnlock = true
                self.isLocked = false
            case .failure:
                self.preferences.requireBiometricUnlock = false
                self.isLocked = false
            }

            completion?(result)
        }
    }

    func disableProtectionAfterAuthentication(completion: ((Result<Void, Error>) -> Void)? = nil) {
        authenticate(reason: "关闭身份验证保护前，请先验证你本人身份") { [weak self] result in
            guard let self else {
                return
            }

            switch result {
            case .success:
                self.preferences.requireBiometricUnlock = false
                self.isLocked = false
            case .failure:
                self.preferences.requireBiometricUnlock = true
            }

            completion?(result)
        }
    }

    func disableProtection() {
        isLocked = false
        errorMessage = nil
        preferences.requireBiometricUnlock = false
    }

    private func authenticate(reason: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard !isAuthenticating else {
            return
        }

        guard canAuthenticateDeviceOwner else {
            let error = BiometricAuthServiceError.unavailable
            errorMessage = error.localizedDescription
            completion(.failure(error))
            return
        }

        isAuthenticating = true
        errorMessage = nil

        authenticationHandler(reason) { [weak self] result in
            guard let self else {
                return
            }

            self.isAuthenticating = false

            switch result {
            case .success:
                self.errorMessage = nil
                completion(.success(()))
            case let .failure(error):
                self.errorMessage = error.localizedDescription
                completion(.failure(error))
            }
        }
    }
}