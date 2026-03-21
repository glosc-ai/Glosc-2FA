//
//  OTPKind.swift
//  Glosc 2fa
//
//  Created by GitHub Copilot on 2026/3/19.
//

import Foundation

enum OTPKind: String, CaseIterable, Codable, Identifiable {
    case totp
    case hotp

    var id: String { rawValue }

    var title: String {
        switch self {
        case .totp:
            return L10n.tr("otp.kind.totp", default: "TOTP")
        case .hotp:
            return L10n.tr("otp.kind.hotp", default: "HOTP")
        }
    }
}
