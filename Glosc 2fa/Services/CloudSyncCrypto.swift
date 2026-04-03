//
//  CloudSyncCrypto.swift
//  Glosc 2fa
//
//  Created by GitHub Copilot on 2026/4/2.
//

import CryptoKit
import Foundation

enum CloudSyncCryptoError: LocalizedError, Equatable {
    case invalidPassword
    case invalidSalt
    case invalidCiphertext
    case malformedPayload

    var errorDescription: String? {
        switch self {
        case .invalidPassword:
            return L10n.tr("sync.error.invalid_password", default: "密码不能为空。")
        case .invalidSalt:
            return L10n.tr("sync.error.invalid_salt", default: "同步密钥参数无效。")
        case .invalidCiphertext:
            return L10n.tr("sync.error.invalid_ciphertext", default: "云端数据无法解密。")
        case .malformedPayload:
            return L10n.tr("sync.error.malformed_payload", default: "云端数据格式无效。")
        }
    }
}

struct CloudAccountPayload: Codable, Equatable {
    let id: UUID
    let issuer: String
    let accountName: String
    let secret: String
    let algorithmRawValue: String
    let digits: Int
    let period: Int
    let kindRawValue: String
    let counter: Int
    let createdAt: Date
    let updatedAt: Date
}

private struct CloudSyncKeyVerifierPayload: Codable, Equatable {
    let marker: String
    let version: Int
}

enum CloudSyncCrypto {
    private static let keyByteCount = 32
    private static let iterationCount = 120_000
    private static let keyVerifierMarker = "glosc.sync.key"
    private static let keyVerifierVersion = 1

    static func makeSalt(length: Int = 32) -> Data {
        Data((0..<length).map { _ in UInt8.random(in: 0...UInt8.max) })
    }

    static func deriveKey(passphrase: String, salt: Data) throws -> SymmetricKey {
        let normalizedPassphrase = passphrase.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedPassphrase.isEmpty else {
            throw CloudSyncCryptoError.invalidPassword
        }

        guard !salt.isEmpty else {
            throw CloudSyncCryptoError.invalidSalt
        }

        return SymmetricKey(data: pbkdf2SHA256(password: Data(normalizedPassphrase.utf8), salt: salt, iterations: iterationCount, keyLength: keyByteCount))
    }

    static func deriveKey(password: String, salt: Data) throws -> SymmetricKey {
        try deriveKey(passphrase: password, salt: salt)
    }

    static func encrypt(_ payload: CloudAccountPayload, using key: SymmetricKey) throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970

        let plaintext = try encoder.encode(payload)
        let sealedBox = try AES.GCM.seal(plaintext, using: key)

        guard let combined = sealedBox.combined else {
            throw CloudSyncCryptoError.invalidCiphertext
        }

        return combined.base64EncodedString()
    }

    static func decrypt(_ ciphertext: String, using key: SymmetricKey) throws -> CloudAccountPayload {
        guard let combined = Data(base64Encoded: ciphertext) else {
            throw CloudSyncCryptoError.invalidCiphertext
        }

        let sealedBox = try AES.GCM.SealedBox(combined: combined)
        let decrypted = try AES.GCM.open(sealedBox, using: key)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970

        do {
            return try decoder.decode(CloudAccountPayload.self, from: decrypted)
        } catch {
            throw CloudSyncCryptoError.malformedPayload
        }
    }

    static func exportKey(_ key: SymmetricKey) -> String {
        key.withUnsafeBytes { Data($0).base64EncodedString() }
    }

    static func importKey(_ encoded: String) throws -> SymmetricKey {
        guard let data = Data(base64Encoded: encoded), !data.isEmpty else {
            throw CloudSyncCryptoError.invalidCiphertext
        }

        return SymmetricKey(data: data)
    }

    static func makeKeyVerifier(using key: SymmetricKey) throws -> String {
        let payload = CloudSyncKeyVerifierPayload(marker: keyVerifierMarker, version: keyVerifierVersion)
        let plaintext = try JSONEncoder().encode(payload)
        let sealedBox = try AES.GCM.seal(plaintext, using: key)

        guard let combined = sealedBox.combined else {
            throw CloudSyncCryptoError.invalidCiphertext
        }

        return combined.base64EncodedString()
    }

    static func verifyKeyVerifier(_ verifier: String, using key: SymmetricKey) -> Bool {
        guard let combined = Data(base64Encoded: verifier),
              let sealedBox = try? AES.GCM.SealedBox(combined: combined),
              let plaintext = try? AES.GCM.open(sealedBox, using: key),
              let payload = try? JSONDecoder().decode(CloudSyncKeyVerifierPayload.self, from: plaintext) else {
            return false
        }

        return payload == CloudSyncKeyVerifierPayload(marker: keyVerifierMarker, version: keyVerifierVersion)
    }

    private static func pbkdf2SHA256(password: Data, salt: Data, iterations: Int, keyLength: Int) -> Data {
        let blockCount = Int(ceil(Double(keyLength) / Double(SHA256.Digest.byteCount)))
        var derivedKey = Data()
        derivedKey.reserveCapacity(keyLength)

        for blockIndex in 1...blockCount {
            var saltBlock = Data()
            saltBlock.append(salt)
            saltBlock.append(contentsOf: [
                UInt8((blockIndex >> 24) & 0xff),
                UInt8((blockIndex >> 16) & 0xff),
                UInt8((blockIndex >> 8) & 0xff),
                UInt8(blockIndex & 0xff),
            ])

            let passwordKey = SymmetricKey(data: password)
            var accumulated = Data(HMAC<SHA256>.authenticationCode(for: saltBlock, using: passwordKey))
            var current = accumulated

            if iterations > 1 {
                for _ in 2...iterations {
                    current = Data(HMAC<SHA256>.authenticationCode(for: current, using: passwordKey))
                    for byteIndex in accumulated.indices {
                        accumulated[byteIndex] ^= current[byteIndex]
                    }
                }
            }

            derivedKey.append(accumulated)
        }

        return derivedKey.prefix(keyLength)
    }
}