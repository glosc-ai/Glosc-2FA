//
//  OTPAuthURIParser.swift
//  Glosc 2fa
//
//  Created by GitHub Copilot on 2026/3/19.
//

import Foundation

enum OTPAuthURIParserError: LocalizedError, Equatable {
    case invalidScheme
    case invalidKind
    case missingSecret
    case invalidLabel
    case invalidDigits
    case invalidPeriod
    case invalidCounter
    case unsupportedAlgorithm(String)

    var errorDescription: String? {
        switch self {
        case .invalidScheme:
            return "只支持 otpauth:// 链接。"
        case .invalidKind:
            return "链接中的 OTP 类型无效。"
        case .missingSecret:
            return "otpauth 链接缺少 secret 参数。"
        case .invalidLabel:
            return "otpauth 链接缺少可识别的账号标签。"
        case .invalidDigits:
            return "otpauth 链接中的 digits 参数无效。"
        case .invalidPeriod:
            return "otpauth 链接中的 period 参数无效。"
        case .invalidCounter:
            return "otpauth 链接中的 counter 参数无效。"
        case let .unsupportedAlgorithm(value):
            return "暂不支持算法 \(value)。"
        }
    }
}

enum OTPAuthURIParser {
    static func parse(_ rawValue: String) throws -> OTPAccountDraft {
        guard let components = URLComponents(string: rawValue.trimmingCharacters(in: .whitespacesAndNewlines)),
              components.scheme?.lowercased() == "otpauth" else {
            throw OTPAuthURIParserError.invalidScheme
        }

        guard let host = components.host?.lowercased(), let kind = OTPKind(rawValue: host) else {
            throw OTPAuthURIParserError.invalidKind
        }

        let label = try parseLabel(components.path)
        let queryItems = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { item in
            (item.name.lowercased(), item.value ?? "")
        })

        let secret = queryItems["secret", default: ""]
        guard !secret.isEmpty else {
            throw OTPAuthURIParserError.missingSecret
        }

        let issuer = queryItems["issuer"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? label.issuer
        let algorithm = try parseAlgorithm(queryItems["algorithm"])
        let digits = try parseDigits(queryItems["digits"])
        let period = try parsePeriod(queryItems["period"], kind: kind)
        let counter = try parseCounter(queryItems["counter"], kind: kind)

        var draft = OTPAccountDraft()
        draft.issuer = issuer
        draft.accountName = label.accountName
        draft.secret = secret
        draft.algorithm = algorithm
        draft.digits = digits
        draft.period = period
        draft.kind = kind
        draft.counter = counter
        return draft
    }

    private static func parseLabel(_ path: String) throws -> (issuer: String, accountName: String) {
        let trimmedPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let decoded = trimmedPath.removingPercentEncoding?.trimmingCharacters(in: .whitespacesAndNewlines),
              !decoded.isEmpty else {
            throw OTPAuthURIParserError.invalidLabel
        }

        if let separatorIndex = decoded.firstIndex(of: ":") {
            let issuer = decoded[..<separatorIndex].trimmingCharacters(in: .whitespacesAndNewlines)
            let name = decoded[decoded.index(after: separatorIndex)...].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else {
                throw OTPAuthURIParserError.invalidLabel
            }

            return (issuer: String(issuer), accountName: String(name))
        }

        return (issuer: "", accountName: decoded)
    }

    private static func parseAlgorithm(_ rawValue: String?) throws -> OTPAlgorithm {
        guard let rawValue, !rawValue.isEmpty else {
            return .sha1
        }

        guard let algorithm = OTPAlgorithm(rawValue: rawValue.uppercased()) else {
            throw OTPAuthURIParserError.unsupportedAlgorithm(rawValue)
        }

        return algorithm
    }

    private static func parseDigits(_ rawValue: String?) throws -> Int {
        guard let rawValue, !rawValue.isEmpty else {
            return 6
        }

        guard let digits = Int(rawValue), (6...8).contains(digits) else {
            throw OTPAuthURIParserError.invalidDigits
        }

        return digits
    }

    private static func parsePeriod(_ rawValue: String?, kind: OTPKind) throws -> Int {
        guard kind == .totp else {
            return 30
        }

        guard let rawValue, !rawValue.isEmpty else {
            return 30
        }

        guard let period = Int(rawValue), period > 0 else {
            throw OTPAuthURIParserError.invalidPeriod
        }

        return period
    }

    private static func parseCounter(_ rawValue: String?, kind: OTPKind) throws -> Int {
        guard kind == .hotp else {
            return 0
        }

        guard let rawValue, !rawValue.isEmpty else {
            return 0
        }

        guard let counter = Int(rawValue), counter >= 0 else {
            throw OTPAuthURIParserError.invalidCounter
        }

        return counter
    }
}