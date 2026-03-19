//
//  Glosc_2faUITests.swift
//  Glosc 2faUITests
//
//  Created by XiaoM on 2026/3/19.
//

import XCTest

final class Glosc_2faUITests: XCTestCase {
    private let resetStateArgument = "UITEST_RESET_STATE"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {}

    @MainActor
    func testAddAccountFlow() throws {
        let app = launchApp()

        addManualAccount(app, issuer: "GitHub", accountName: "alice@example.com", secret: "JBSWY3DPEHPK3PXP")

        XCTAssertTrue(app.staticTexts["alice@example.com"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["GitHub"].exists)
    }

    @MainActor
    func testDeleteAccountFlow() throws {
        let app = launchApp()

        addManualAccount(app, issuer: "GitHub", accountName: "alice@example.com", secret: "JBSWY3DPEHPK3PXP")

        app.staticTexts["alice@example.com"].tap()

        let deleteButton = app.buttons["deleteAccountButton"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 2))
        deleteButton.tap()

        XCTAssertTrue(app.buttons["emptyAddAccountButton"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["alice@example.com"].exists)
    }

    @MainActor
    func testSettingsScreenCanOpenAndClose() throws {
        let app = launchApp()

        addManualAccount(app, issuer: "GitHub", accountName: "alice@example.com", secret: "JBSWY3DPEHPK3PXP")

        app.buttons["settingsButton"].tap()

        XCTAssertTrue(app.segmentedControls["appThemePicker"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.switches["requireBiometricUnlockToggle"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.switches["showFullSecretInDetailToggle"].exists)
        XCTAssertTrue(app.switches["hideCodesInListToggle"].exists)

        app.buttons["closeSettingsButton"].tap()
        XCTAssertFalse(app.buttons["closeSettingsButton"].exists)
    }

    @MainActor
    func testHOTPAccountCanAdvanceCounter() throws {
        let app = launchApp()

        app.buttons["emptyAddAccountButton"].tap()
        app.buttons["链接导入"].tap()

        let importField = app.textFields["importURITextField"]
        XCTAssertTrue(importField.waitForExistence(timeout: 2))
        importField.tap()
        importField.typeText("otpauth://hotp/Example:alice@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Example&counter=0")

        app.buttons["importURIButton"].tap()
        app.buttons["saveAccountButton"].tap()

        let accountLabel = app.staticTexts["alice@example.com"]
        XCTAssertTrue(accountLabel.waitForExistence(timeout: 2))
        accountLabel.tap()

        let counterValue = app.staticTexts["hotpCounterValue"]
        XCTAssertTrue(counterValue.waitForExistence(timeout: 2))
        XCTAssertEqual(counterValue.label, "当前计数器：0")

        app.buttons["advanceHOTPButton"].tap()

        XCTAssertTrue(app.staticTexts["当前计数器：1"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            _ = launchApp()
        }
    }

    @discardableResult
    private func launchApp() -> XCUIApplication {
        XCUIDevice.shared.orientation = .portrait

        let app = XCUIApplication()
        app.launchArguments.append(resetStateArgument)
        app.launch()
        return app
    }

    private func addManualAccount(_ app: XCUIApplication, issuer: String, accountName: String, secret: String) {
        app.buttons["emptyAddAccountButton"].tap()

        let issuerField = app.textFields["issuerTextField"]
        XCTAssertTrue(issuerField.waitForExistence(timeout: 2))
        issuerField.tap()
        issuerField.typeText(issuer)

        let accountField = app.textFields["accountNameTextField"]
        accountField.tap()
        accountField.typeText(accountName)

        let secretField = app.textFields["secretTextField"]
        secretField.tap()
        secretField.typeText(secret)

        app.buttons["saveAccountButton"].tap()
    }
}