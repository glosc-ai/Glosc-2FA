//
//  Glosc_2faUITestsLaunchTests.swift
//  Glosc 2faUITests
//
//  Created by XiaoM on 2026/3/19.
//

import XCTest

final class Glosc_2faUITestsLaunchTests: XCTestCase {
    private let resetStateArgument = "UITEST_RESET_STATE"

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments.append(resetStateArgument)
        app.launch()

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
