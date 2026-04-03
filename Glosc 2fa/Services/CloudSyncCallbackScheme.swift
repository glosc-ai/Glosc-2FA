//
//  CloudSyncCallbackScheme.swift
//  Glosc 2fa
//
//  Created by GitHub Copilot on 2026/4/3.
//

import Foundation

enum CloudSyncCallbackScheme {
    static func reversedClientIDScheme(from clientID: String) -> String {
        clientID
            .split(separator: ".")
            .reversed()
            .joined(separator: ".")
    }

    static func encodedFirebaseAppIDScheme(from googleAppID: String) -> String {
        "app-\(googleAppID.replacingOccurrences(of: ":", with: "-"))"
    }

    static func isRegistered(_ scheme: String, in infoDictionary: [String: Any]? = Bundle.main.infoDictionary) -> Bool {
        guard let urlTypes = infoDictionary?["CFBundleURLTypes"] as? [[String: Any]] else {
            return false
        }

        let normalizedScheme = scheme.lowercased()

        return urlTypes.contains { urlType in
            guard let schemes = urlType["CFBundleURLSchemes"] as? [String] else {
                return false
            }

            return schemes.contains { $0.lowercased() == normalizedScheme }
        }
    }
}