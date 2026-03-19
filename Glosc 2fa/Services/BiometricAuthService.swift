//
//  BiometricAuthService.swift
//  Glosc 2fa
//
//  Created by GitHub Copilot on 2026/3/19.
//

import Foundation
import LocalAuthentication

enum BiometricAuthServiceError: LocalizedError {
    case unavailable
    case failed

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "当前设备不可用生物识别。"
        case .failed:
            return "生物识别验证失败。"
        }
    }
}

enum BiometricAuthService {
    static var canUseBiometrics: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    static func authenticate(reason: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            completion(.failure(error ?? BiometricAuthServiceError.unavailable))
            return
        }

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, evaluationError in
            DispatchQueue.main.async {
                if success {
                    completion(.success(()))
                } else {
                    completion(.failure(evaluationError ?? BiometricAuthServiceError.failed))
                }
            }
        }
    }
}