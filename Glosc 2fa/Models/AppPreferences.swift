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
    static let appIdentifier = "com.gloscai.com.Glosc-2fa"

    private enum Keys {
        static let requireBiometricUnlock = "preferences.requireBiometricUnlock"
        static let hideCodesInList = "preferences.hideCodesInList"
        static let showFullSecretInDetail = "preferences.showFullSecretInDetail"
        static let appTheme = "preferences.appTheme"
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

    @Published var appTheme: AppTheme {
        didSet { UserDefaults.standard.set(appTheme.rawValue, forKey: Keys.appTheme) }
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

        appTheme = AppTheme(rawValue: UserDefaults.standard.string(forKey: Keys.appTheme) ?? "") ?? .system
    }

    static func resetForTesting() {
        UserDefaults.standard.removePersistentDomain(forName: appIdentifier)
        UserDefaults.standard.synchronize()
    }
}