//
//  AppPreferences.swift
//  Glosc 2fa
//
//  Created by GitHub Copilot on 2026/3/19.
//

import Combine
import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case simplifiedChinese = "zh-Hans"
    case english = "en"
    case japanese = "ja"
    case french = "fr"
    case german = "de"
    case spanish = "es"
    case italian = "it"
    case korean = "ko"
    case portugueseBrazil = "pt-BR"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return L10n.tr("language.system", default: "跟随系统")
        case .simplifiedChinese:
            return L10n.tr("language.zh_hans", default: "简体中文")
        case .english:
            return L10n.tr("language.en", default: "English")
        case .japanese:
            return L10n.tr("language.ja", default: "日本語")
        case .french:
            return L10n.tr("language.fr", default: "Français")
        case .german:
            return L10n.tr("language.de", default: "Deutsch")
        case .spanish:
            return L10n.tr("language.es", default: "Español")
        case .italian:
            return L10n.tr("language.it", default: "Italiano")
        case .korean:
            return L10n.tr("language.ko", default: "한국어")
        case .portugueseBrazil:
            return L10n.tr("language.pt_br", default: "Português (Brasil)")
        }
    }

    var locale: Locale {
        switch self {
        case .system:
            return .autoupdatingCurrent
        case .simplifiedChinese:
            return Locale(identifier: "zh-Hans")
        case .english:
            return Locale(identifier: "en")
        case .japanese:
            return Locale(identifier: "ja")
        case .french:
            return Locale(identifier: "fr")
        case .german:
            return Locale(identifier: "de")
        case .spanish:
            return Locale(identifier: "es")
        case .italian:
            return Locale(identifier: "it")
        case .korean:
            return Locale(identifier: "ko")
        case .portugueseBrazil:
            return Locale(identifier: "pt-BR")
        }
    }

    var localizationIdentifier: String? {
        switch self {
        case .system:
            return nil
        case .simplifiedChinese, .english, .japanese, .french, .german, .spanish, .italian, .korean, .portugueseBrazil:
            return rawValue
        }
    }
}

@MainActor
final class AppPreferences: ObservableObject {
    static let appIdentifier = "com.gloscai.com.Glosc-2fa"
    static let appLanguageDefaultsKey = "preferences.appLanguage"

    private enum Keys {
        static let requireBiometricUnlock = "preferences.requireBiometricUnlock"
        static let hideCodesInList = "preferences.hideCodesInList"
        static let showFullSecretInDetail = "preferences.showFullSecretInDetail"
        static let appTheme = "preferences.appTheme"
        static let appLanguage = AppPreferences.appLanguageDefaultsKey
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

    @Published var appLanguage: AppLanguage {
        didSet { UserDefaults.standard.set(appLanguage.rawValue, forKey: Keys.appLanguage) }
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
        appLanguage = AppLanguage(rawValue: UserDefaults.standard.string(forKey: Keys.appLanguage) ?? "") ?? .system
    }

    static var currentAppLanguage: AppLanguage {
        AppLanguage(rawValue: UserDefaults.standard.string(forKey: appLanguageDefaultsKey) ?? "") ?? .system
    }

    static func resetForTesting() {
        UserDefaults.standard.removePersistentDomain(forName: appIdentifier)
        UserDefaults.standard.synchronize()
    }
}