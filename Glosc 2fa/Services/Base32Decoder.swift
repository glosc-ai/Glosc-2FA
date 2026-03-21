//
//  Base32Decoder.swift
//  Glosc 2fa
//
//  Created by GitHub Copilot on 2026/3/19.
//

import Foundation

enum Base32DecoderError: LocalizedError {
    case emptyInput
    case invalidCharacter(Character)

    var errorDescription: String? {
        switch self {
        case .emptyInput:
            return L10n.tr("base32.empty", default: "Base32 内容为空。")
        case let .invalidCharacter(character):
            return L10n.format("base32.invalid_character", default: "Base32 内容包含非法字符：%@。", String(character))
        }
    }
}

enum Base32Decoder {
    private static let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
    private static let lookup: [Character: UInt8] = {
        Dictionary(uniqueKeysWithValues: alphabet.enumerated().map { ($0.element, UInt8($0.offset)) })
    }()

    static func decode(_ input: String) throws -> Data {
        let sanitized = input
            .uppercased()
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")

        guard !sanitized.isEmpty else {
            throw Base32DecoderError.emptyInput
        }

        var buffer: UInt32 = 0
        var bitsLeft = 0
        var bytes: [UInt8] = []

        for character in sanitized {
            guard let value = lookup[character] else {
                throw Base32DecoderError.invalidCharacter(character)
            }

            buffer = (buffer << 5) | UInt32(value)
            bitsLeft += 5

            while bitsLeft >= 8 {
                let byte = UInt8((buffer >> UInt32(bitsLeft - 8)) & 0xFF)
                bytes.append(byte)
                bitsLeft -= 8
            }
        }

        return Data(bytes)
    }
}
