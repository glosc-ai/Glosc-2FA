//
//  OTPAccountDraft.swift
//  Glosc 2fa
//
//  Created by GitHub Copilot on 2026/3/19.
//

import Foundation

struct OTPAccountDraft {
    var issuer: String = ""
    var accountName: String = ""
    var secret: String = ""
    var algorithm: OTPAlgorithm = .sha1
    var digits: Int = 6
    var period: Int = 30
    var kind: OTPKind = .totp
    var counter: Int = 0

    init() {}

    init(record: OTPAccountRecord) {
        issuer = record.issuer
        accountName = record.accountName
        secret = record.secret
        algorithm = record.algorithm
        digits = record.digits
        period = record.period
        kind = record.kind
        counter = record.counter
    }

    var normalizedIssuer: String {
        issuer.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedAccountName: String {
        accountName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedSecret: String {
        secret
            .uppercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func makeRecord() throws -> OTPAccountRecord {
        try OTPAccountValidator.validate(self)

        return OTPAccountRecord(
            issuer: normalizedIssuer,
            accountName: normalizedAccountName,
            secret: normalizedSecret,
            algorithm: algorithm,
            digits: digits,
            period: kind == .totp ? period : 30,
            kind: kind,
            counter: kind == .hotp ? counter : 0
        )
    }

    func apply(to record: OTPAccountRecord) throws {
        try OTPAccountValidator.validate(self)

        record.issuer = normalizedIssuer
        record.accountName = normalizedAccountName
        try record.updateSecret(normalizedSecret)
        record.algorithm = algorithm
        record.digits = digits
        record.period = kind == .totp ? period : 30
        record.kind = kind
        record.counter = kind == .hotp ? counter : 0
        record.updatedAt = .now
    }
}

enum OTPAccountValidationError: LocalizedError, Equatable {
    case missingAccountName
    case missingSecret
    case invalidDigits
    case invalidPeriod
    case invalidCounter
    case invalidSecret

    var errorDescription: String? {
        switch self {
        case .missingAccountName:
            return L10n.tr("validation.missing_account_name", default: "请输入账号名称。")
        case .missingSecret:
            return L10n.tr("validation.missing_secret", default: "请输入共享密钥。")
        case .invalidDigits:
            return L10n.tr("validation.invalid_digits", default: "验证码位数目前支持 6 到 8 位。")
        case .invalidPeriod:
            return L10n.tr("validation.invalid_period", default: "时间步长必须大于 0 秒。")
        case .invalidCounter:
            return L10n.tr("validation.invalid_counter", default: "HOTP 计数器不能为负数。")
        case .invalidSecret:
            return L10n.tr("validation.invalid_secret", default: "共享密钥不是有效的 Base32 内容。")
        }
    }
}

enum OTPAccountValidator {
    static func validate(_ draft: OTPAccountDraft) throws {
        guard !draft.normalizedAccountName.isEmpty else {
            throw OTPAccountValidationError.missingAccountName
        }

        guard !draft.normalizedSecret.isEmpty else {
            throw OTPAccountValidationError.missingSecret
        }

        guard (6...8).contains(draft.digits) else {
            throw OTPAccountValidationError.invalidDigits
        }

        guard draft.period > 0 else {
            throw OTPAccountValidationError.invalidPeriod
        }

        guard draft.counter >= 0 else {
            throw OTPAccountValidationError.invalidCounter
        }

        do {
            _ = try Base32Decoder.decode(draft.normalizedSecret)
        } catch {
            throw OTPAccountValidationError.invalidSecret
        }
    }
}
