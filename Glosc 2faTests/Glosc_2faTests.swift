//
//  Glosc_2faTests.swift
//  Glosc 2faTests
//
//  Created by XiaoM on 2026/3/19.
//

import Foundation
import SwiftUI
import Testing
@testable import Glosc_2fa

struct Glosc_2faTests {

    private struct MockAuthenticationError: LocalizedError {
        var errorDescription: String? {
            "身份验证失败"
        }
    }

    @Test func base32DecoderHandlesNormalizedInput() throws {
        let decoded = try Base32Decoder.decode("JBSW Y3DP-EHPK3PXP")

        #expect(decoded == Data([0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x21, 0xDE, 0xAD, 0xBE, 0xEF]))
    }

    @Test func hotpMatchesRfc4226Vectors() throws {
        let secret = Data("12345678901234567890".utf8)
        let expected = [
            "755224",
            "287082",
            "359152",
            "969429",
            "338314",
            "254676",
            "287922",
            "162583",
            "399871",
            "520489",
        ]

        for (counter, code) in expected.enumerated() {
            let generated = try OTPCodeGenerator.generateCode(secret: secret, counter: UInt64(counter), digits: 6, algorithm: .sha1)
            #expect(generated == code)
        }
    }

    @Test func totpMatchesRfc6238Vectors() throws {
        let cases: [(OTPAlgorithm, Data, [(TimeInterval, String)])] = [
            (
                .sha1,
                Data("12345678901234567890".utf8),
                [
                    (59, "94287082"),
                    (1111111109, "07081804"),
                    (1111111111, "14050471"),
                    (1234567890, "89005924"),
                    (2000000000, "69279037"),
                    (20000000000, "65353130"),
                ]
            ),
            (
                .sha256,
                Data("12345678901234567890123456789012".utf8),
                [
                    (59, "46119246"),
                    (1111111109, "68084774"),
                    (1111111111, "67062674"),
                    (1234567890, "91819424"),
                    (2000000000, "90698825"),
                    (20000000000, "77737706"),
                ]
            ),
            (
                .sha512,
                Data("1234567890123456789012345678901234567890123456789012345678901234".utf8),
                [
                    (59, "90693936"),
                    (1111111109, "25091201"),
                    (1111111111, "99943326"),
                    (1234567890, "93441116"),
                    (2000000000, "38618901"),
                    (20000000000, "47863826"),
                ]
            ),
        ]

        for (algorithm, secret, vectors) in cases {
            for (timestamp, expectedCode) in vectors {
                let counter = UInt64(timestamp / 30)
                let generated = try OTPCodeGenerator.generateCode(secret: secret, counter: counter, digits: 8, algorithm: algorithm)
                #expect(generated == expectedCode)
            }
        }
    }

    @Test func otpAuthParserBuildsDraft() throws {
        let draft = try OTPAuthURIParser.parse("otpauth://totp/GitHub:alice@example.com?secret=JBSWY3DPEHPK3PXP&issuer=GitHub&algorithm=SHA256&digits=8&period=45")

        #expect(draft.kind == .totp)
        #expect(draft.issuer == "GitHub")
        #expect(draft.accountName == "alice@example.com")
        #expect(draft.algorithm == .sha256)
        #expect(draft.digits == 8)
        #expect(draft.period == 45)
    }

    @Test func otpAuthParserRejectsUnsupportedAlgorithm() {
        #expect(throws: OTPAuthURIParserError.unsupportedAlgorithm("MD5")) {
            try OTPAuthURIParser.parse("otpauth://totp/Example:alice?secret=JBSWY3DPEHPK3PXP&algorithm=MD5")
        }
    }

    @Test func draftValidationRejectsInvalidSecret() {
        var draft = OTPAccountDraft()
        draft.accountName = "alice@example.com"
        draft.secret = "INVALID*SECRET"

        #expect(throws: OTPAccountValidationError.invalidSecret) {
            _ = try draft.makeRecord()
        }
    }

    @Test func keychainSecretStoreRoundTripsSecret() throws {
        let key = "test.secret.\(UUID().uuidString)"

        try KeychainSecretStore.shared.saveSecret("JBSWY3DPEHPK3PXP", for: key)
        let loaded = try KeychainSecretStore.shared.loadSecret(for: key)

        #expect(loaded == "JBSWY3DPEHPK3PXP")

        try KeychainSecretStore.shared.deleteSecret(for: key)

        #expect(throws: KeychainSecretStoreError.secretNotFound) {
            try KeychainSecretStore.shared.loadSecret(for: key)
        }
    }

    @Test @MainActor func enablingProtectionRequiresSuccessfulAuthentication() {
        AppPreferences.resetForTesting()
        let preferences = AppPreferences()
        var capturedReason: String?

        let controller = AppSecurityController(
            preferences: preferences,
            canAuthenticateDeviceOwnerHandler: { true },
            canUseBiometricsHandler: { true },
            authenticationHandler: { reason, completion in
                capturedReason = reason
                completion(.success(()))
            }
        )

        controller.enableProtection()

        #expect(preferences.requireBiometricUnlock)
        #expect(controller.isLocked == false)
        #expect(capturedReason == "开启身份验证保护前，请先验证你本人身份")
    }

    @Test @MainActor func disablingProtectionKeepsLockEnabledWhenAuthenticationFails() {
        AppPreferences.resetForTesting()
        let preferences = AppPreferences()
        preferences.requireBiometricUnlock = true

        let controller = AppSecurityController(
            preferences: preferences,
            canAuthenticateDeviceOwnerHandler: { true },
            canUseBiometricsHandler: { true },
            authenticationHandler: { _, completion in
                completion(.failure(MockAuthenticationError()))
            }
        )

        controller.disableProtectionAfterAuthentication()

        #expect(preferences.requireBiometricUnlock)
        #expect(controller.errorMessage == "身份验证失败")
    }

    @Test @MainActor func activePhaseDoesNotRetryUnlockAfterInactiveBounce() {
        AppPreferences.resetForTesting()
        let preferences = AppPreferences()
        preferences.requireBiometricUnlock = true
        var authenticationCount = 0

        let controller = AppSecurityController(
            preferences: preferences,
            canAuthenticateDeviceOwnerHandler: { true },
            canUseBiometricsHandler: { true },
            authenticationHandler: { _, completion in
                authenticationCount += 1
                completion(.success(()))
            }
        )

        controller.handleScenePhase(.active)
        controller.handleScenePhase(.inactive)
        controller.handleScenePhase(.active)

        #expect(authenticationCount == 1)
        #expect(controller.isLocked == false)
    }

    @Test @MainActor func backgroundThenActiveRequestsUnlockAgain() {
        AppPreferences.resetForTesting()
        let preferences = AppPreferences()
        preferences.requireBiometricUnlock = true
        var authenticationCount = 0

        let controller = AppSecurityController(
            preferences: preferences,
            canAuthenticateDeviceOwnerHandler: { true },
            canUseBiometricsHandler: { true },
            authenticationHandler: { _, completion in
                authenticationCount += 1
                completion(.success(()))
            }
        )

        controller.handleScenePhase(.active)
        controller.handleScenePhase(.background)
        controller.handleScenePhase(.active)

        #expect(authenticationCount == 2)
        #expect(controller.isLocked == false)
    }

}
