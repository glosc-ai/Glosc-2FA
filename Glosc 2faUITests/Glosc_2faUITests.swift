//
//  Glosc_2faUITests.swift
//  Glosc 2faUITests
//
//  Created by XiaoM on 2026/3/19.
//

import XCTest

final class Glosc_2faUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testAddAccountFlow() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["emptyAddAccountButton"].tap()

        let issuerField = app.textFields["issuerTextField"]
        XCTAssertTrue(issuerField.waitForExistence(timeout: 2))
        issuerField.tap()
        issuerField.typeText("GitHub")

        let accountField = app.textFields["accountNameTextField"]
        accountField.tap()
        accountField.typeText("alice@example.com")

        let secretField = app.textFields["secretTextField"]
        secretField.tap()
        secretField.typeText("JBSWY3DPEHPK3PXP")

        app.buttons["saveAccountButton"].tap()

        XCTAssertTrue(app.staticTexts["alice@example.com"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["GitHub"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
