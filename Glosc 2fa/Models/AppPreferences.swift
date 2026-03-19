//
//  AppPreferences.swift
//  Glosc 2fa
//
//  Created by GitHub Copilot on 2026/3/19.
//

import Combine
import Foundation

@MainActor
final class AppPreferences: ObservableObject {
    private enum Keys {
        static let requireBiometricUnlock = "preferences.requireBiometricUnlock"
        static let hideCodesInList = "preferences.hideCodesInList"
        static let showFullSecretInDetail = "preferences.showFullSecretInDetail"
    }

    @Published var requireBiometricUnlock: Bool {
        didSet { UserDefaults.standard.set(requireBiometricUnlock, forKey: Keys.requireBiometricUnlock) }
    }

    @Published var hideCodesInList: Bool {
        didSet { UserDefaults.standard.set(hideCodesInList, forKey: Keys.hideCodesInList) }
    }

    @Published var showFullSecretInDetail: Bool {
        didSet { UserDefaults.standard.set(showFullSecretInDetail, forKey: Keys.showFullSecretInDetail) }
    }

    init() {
        requireBiometricUnlock = UserDefaults.standard.bool(forKey: Keys.requireBiometricUnlock)

        if UserDefaults.standard.object(forKey: Keys.hideCodesInList) == nil {
            hideCodesInList = false
        } else {
            hideCodesInList = UserDefaults.standard.bool(forKey: Keys.hideCodesInList)
        }

        if UserDefaults.standard.object(forKey: Keys.showFullSecretInDetail) == nil {
            showFullSecretInDetail = false
        } else {
            showFullSecretInDetail = UserDefaults.standard.bool(forKey: Keys.showFullSecretInDetail)
        }
    }
}