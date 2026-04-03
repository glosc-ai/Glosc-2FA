//
//  CloudSyncKeyStore.swift
//  Glosc 2fa
//
//  Created by GitHub Copilot on 2026/4/2.
//

import CryptoKit
import Foundation

final class CloudSyncKeyStore {
    static let shared = CloudSyncKeyStore()

    private let keyPrefix = "cloud-sync-key."

    private init() {}

    func saveKey(_ key: SymmetricKey, for userID: String) throws {
        try KeychainSecretStore.shared.saveSecret(CloudSyncCrypto.exportKey(key), for: storageKey(for: userID))
    }

    func loadKey(for userID: String) throws -> SymmetricKey {
        let encoded = try KeychainSecretStore.shared.loadSecret(for: storageKey(for: userID))
        return try CloudSyncCrypto.importKey(encoded)
    }

    func deleteKey(for userID: String) throws {
        try KeychainSecretStore.shared.deleteSecret(for: storageKey(for: userID))
    }

    private func storageKey(for userID: String) -> String {
        keyPrefix + userID
    }
}