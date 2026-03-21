//
//  Localization.swift
//  Glosc 2fa
//
//  Created by GitHub Copilot on 2026/3/21.
//

import Foundation

enum L10n {
    private final class BundleToken {}

    private static let baseBundle = Bundle(for: BundleToken.self)

    static func tr(_ key: String, default defaultValue: String) -> String {
        localizedBundle.localizedString(forKey: key, value: defaultValue, table: "Localizable")
    }

    static func format(_ key: String, default defaultValue: String, _ arguments: CVarArg...) -> String {
        String(format: tr(key, default: defaultValue), locale: AppPreferences.currentAppLanguage.locale, arguments: arguments)
    }

    private static var localizedBundle: Bundle {
        let selectedLanguage = AppPreferences.currentAppLanguage

        if let localizationIdentifier = selectedLanguage.localizationIdentifier,
           let bundlePath = baseBundle.path(forResource: localizationIdentifier, ofType: "lproj"),
           let bundle = Bundle(path: bundlePath) {
            return bundle
        }

        if let preferredLocalization = baseBundle.preferredLocalizations.first,
           let bundlePath = baseBundle.path(forResource: preferredLocalization, ofType: "lproj"),
           let bundle = Bundle(path: bundlePath) {
            return bundle
        }

        return baseBundle
    }
}
