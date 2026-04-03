//
//  OTPAccountRecord.swift
//  Glosc 2fa
//
//  Created by GitHub Copilot on 2026/3/19.
//

import Foundation
import SwiftData

@Model
final class OTPAccountRecord {
    @Attribute(.unique) var id: UUID
    var issuer: String
    var accountName: String
    var secretStorageKey: String
    var legacySecret: String
    var secretPreview: String
    var algorithmRawValue: String
    var digits: Int
    var period: Int
    var kindRawValue: String
    var counter: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        issuer: String,
        accountName: String,
        secret: String,
        algorithm: OTPAlgorithm,
        digits: Int,
        period: Int,
        kind: OTPKind,
        counter: Int,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.issuer = issuer
        self.accountName = accountName
        self.secretStorageKey = id.uuidString
        self.legacySecret = secret
        self.secretPreview = Self.maskedSecret(secret)
        self.algorithmRawValue = algorithm.rawValue
        self.digits = digits
        self.period = period
        self.kindRawValue = kind.rawValue
        self.counter = counter
        self.createdAt = createdAt
        self.updatedAt = updatedAt

        _ = migrateLegacySecretIfNeeded()
    }

    var secret: String {
        if let secret = try? KeychainSecretStore.shared.loadSecret(for: secretStorageKey), !secret.isEmpty {
            return secret
        }

        return legacySecret
    }

    var algorithm: OTPAlgorithm {
        get { OTPAlgorithm(rawValue: algorithmRawValue) ?? .sha1 }
        set { algorithmRawValue = newValue.rawValue }
    }

    var kind: OTPKind {
        get { OTPKind(rawValue: kindRawValue) ?? .totp }
        set { kindRawValue = newValue.rawValue }
    }

    var displayIssuer: String {
        issuer.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var displayName: String {
        accountName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var navigationTitle: String {
        displayIssuer.isEmpty ? displayName : "\(displayIssuer) · \(displayName)"
    }

    @discardableResult
    func updateSecret(_ secret: String) throws -> Bool {
        let normalized = secret
            .uppercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")

        if secretStorageKey.isEmpty {
            secretStorageKey = id.uuidString
        }

        try KeychainSecretStore.shared.saveSecret(normalized, for: secretStorageKey)
        legacySecret = ""
        secretPreview = Self.maskedSecret(normalized)
        return true
    }

    @discardableResult
    func migrateLegacySecretIfNeeded() -> Bool {
        guard !legacySecret.isEmpty else {
            return false
        }

        do {
            try updateSecret(legacySecret)
            return true
        } catch {
            return false
        }
    }

    func removeSecretFromSecureStore() {
        try? KeychainSecretStore.shared.deleteSecret(for: secretStorageKey)
        legacySecret = ""
    }

    var cloudPayload: CloudAccountPayload {
        CloudAccountPayload(
            id: id,
            issuer: issuer,
            accountName: accountName,
            secret: secret,
            algorithmRawValue: algorithmRawValue,
            digits: digits,
            period: period,
            kindRawValue: kindRawValue,
            counter: counter,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    convenience init(cloudPayload: CloudAccountPayload) throws {
        self.init(
            id: cloudPayload.id,
            issuer: cloudPayload.issuer,
            accountName: cloudPayload.accountName,
            secret: cloudPayload.secret,
            algorithm: OTPAlgorithm(rawValue: cloudPayload.algorithmRawValue) ?? .sha1,
            digits: cloudPayload.digits,
            period: cloudPayload.period,
            kind: OTPKind(rawValue: cloudPayload.kindRawValue) ?? .totp,
            counter: cloudPayload.counter,
            createdAt: cloudPayload.createdAt,
            updatedAt: cloudPayload.updatedAt
        )
    }

    func apply(cloudPayload: CloudAccountPayload) throws {
        issuer = cloudPayload.issuer
        accountName = cloudPayload.accountName
        try updateSecret(cloudPayload.secret)
        algorithmRawValue = cloudPayload.algorithmRawValue
        digits = cloudPayload.digits
        period = cloudPayload.period
        kindRawValue = cloudPayload.kindRawValue
        counter = cloudPayload.counter
        createdAt = cloudPayload.createdAt
        updatedAt = cloudPayload.updatedAt
    }

    private static func maskedSecret(_ secret: String) -> String {
        let sanitized = secret
            .uppercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")

        guard sanitized.count > 8 else {
            return sanitized
        }

        let prefix = sanitized.prefix(4)
        let suffix = sanitized.suffix(4)
        return "\(prefix)••••\(suffix)"
    }
}