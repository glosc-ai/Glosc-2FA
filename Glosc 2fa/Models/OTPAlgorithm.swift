//
//  OTPAlgorithm.swift
//  Glosc 2fa
//
//  Created by GitHub Copilot on 2026/3/19.
//

import CryptoKit
import Foundation

enum OTPAlgorithm: String, CaseIterable, Codable, Identifiable {
    case sha1 = "SHA1"
    case sha256 = "SHA256"
    case sha512 = "SHA512"

    var id: String { rawValue }

    func authenticate(message: Data, secret: Data) -> Data {
        let key = SymmetricKey(data: secret)

        switch self {
        case .sha1:
            return Data(HMAC<Insecure.SHA1>.authenticationCode(for: message, using: key))
        case .sha256:
            return Data(HMAC<SHA256>.authenticationCode(for: message, using: key))
        case .sha512:
            return Data(HMAC<SHA512>.authenticationCode(for: message, using: key))
        }
    }
}