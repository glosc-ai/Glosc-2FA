//
//  KeychainSecretStore.swift
//  Glosc 2fa
//
//  Created by GitHub Copilot on 2026/3/19.
//

import Foundation
import Security

enum KeychainSecretStoreError: LocalizedError, Equatable {
    case invalidSecretData
    case secretNotFound
    case unexpectedStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .invalidSecretData:
            return L10n.tr("keychain.invalid_data", default: "密钥数据无法写入或读取。")
        case .secretNotFound:
            return L10n.tr("keychain.not_found", default: "未找到对应的安全密钥。")
        case let .unexpectedStatus(status):
            return L10n.format("keychain.unexpected_status", default: "Keychain 操作失败，状态码：%d。", status)
        }
    }
}

final class KeychainSecretStore {
    static let shared = KeychainSecretStore()

    private let service = Bundle.main.bundleIdentifier ?? "com.gloscai.glosc-2fa"

    private init() {}

    func saveSecret(_ secret: String, for key: String) throws {
        guard let data = secret.data(using: .utf8) else {
            throw KeychainSecretStoreError.invalidSecretData
        }

        let query = baseQuery(for: key)
        SecItemDelete(query as CFDictionary)

        var addQuery = query
        addQuery[kSecValueData as String] = data

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainSecretStoreError.unexpectedStatus(status)
        }
    }

    func loadSecret(for key: String) throws -> String {
        var query = baseQuery(for: key)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = true

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound {
            throw KeychainSecretStoreError.secretNotFound
        }

        guard status == errSecSuccess else {
            throw KeychainSecretStoreError.unexpectedStatus(status)
        }

        guard let data = item as? Data, let secret = String(data: data, encoding: .utf8) else {
            throw KeychainSecretStoreError.invalidSecretData
        }

        return secret
    }

    func deleteSecret(for key: String) throws {
        let status = SecItemDelete(baseQuery(for: key) as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainSecretStoreError.unexpectedStatus(status)
        }
    }

    func removeAllSecrets() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainSecretStoreError.unexpectedStatus(status)
        }
    }

    private func baseQuery(for key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
    }
}
