//
//  OTPCodeGenerator.swift
//  Glosc 2fa
//
//  Created by GitHub Copilot on 2026/3/19.
//

import Foundation

enum OTPCodeGeneratorError: LocalizedError {
    case invalidDigits
    case invalidPeriod
    case invalidCounter

    var errorDescription: String? {
        switch self {
        case .invalidDigits:
            return L10n.tr("otp.invalid_digits", default: "验证码位数不合法。")
        case .invalidPeriod:
            return L10n.tr("otp.invalid_period", default: "时间步长不合法。")
        case .invalidCounter:
            return L10n.tr("otp.invalid_counter", default: "计数器不合法。")
        }
    }
}

enum OTPCodeGenerator {
    static func generateCode(for account: OTPAccountRecord, at date: Date = .now) throws -> String {
        let secret = try Base32Decoder.decode(account.secret)
        let counter = try movingFactor(for: account, at: date)
        return try generateCode(secret: secret, counter: counter, digits: account.digits, algorithm: account.algorithm)
    }

    static func generateCode(secret: Data, counter: UInt64, digits: Int, algorithm: OTPAlgorithm) throws -> String {
        guard (6...8).contains(digits) else {
            throw OTPCodeGeneratorError.invalidDigits
        }

        var movingFactor = counter.bigEndian
        let message = withUnsafeBytes(of: &movingFactor) { Data($0) }
        let digest = algorithm.authenticate(message: message, secret: secret)

        guard let lastByte = digest.last else {
            throw OTPCodeGeneratorError.invalidCounter
        }

        let offset = Int(lastByte & 0x0F)
        let selected = digest[offset..<(offset + 4)]
        let truncated = selected.reduce(0) { partialResult, byte in
            (partialResult << 8) | UInt32(byte)
        } & 0x7FFF_FFFF

        let divisor = (0..<digits).reduce(1) { partialResult, _ in partialResult * 10 }
        let otp = Int(truncated) % divisor
        return String(format: "%0*d", digits, otp)
    }

    static func remainingSeconds(for account: OTPAccountRecord, at date: Date = .now) -> Int? {
        guard account.kind == .totp else {
            return nil
        }

        guard account.period > 0 else {
            return nil
        }

        let elapsed = Int(date.timeIntervalSince1970) % account.period
        let remaining = account.period - elapsed
        return remaining == 0 ? account.period : remaining
    }

    static func progress(for account: OTPAccountRecord, at date: Date = .now) -> Double? {
        guard account.kind == .totp, account.period > 0 else {
            return nil
        }

        let elapsed = Double(Int(date.timeIntervalSince1970) % account.period)
        return elapsed / Double(account.period)
    }

    static func nextCounter(afterUsing account: OTPAccountRecord) -> Int {
        account.counter + 1
    }

    private static func movingFactor(for account: OTPAccountRecord, at date: Date) throws -> UInt64 {
        switch account.kind {
        case .totp:
            guard account.period > 0 else {
                throw OTPCodeGeneratorError.invalidPeriod
            }

            return UInt64(floor(date.timeIntervalSince1970 / Double(account.period)))
        case .hotp:
            guard account.counter >= 0 else {
                throw OTPCodeGeneratorError.invalidCounter
            }

            return UInt64(account.counter)
        }
    }
}
