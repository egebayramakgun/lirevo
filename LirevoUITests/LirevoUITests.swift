// SPDX-License-Identifier: GPL-3.0-or-later

import XCTest

/// M1-T2: Menü çubuğu simgesi paneli açıyor, uygulamanın normal penceresi yok.
final class LirevoUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testStatusItemOpensPanel() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)"]
        app.launch()

        XCTAssertEqual(app.windows.count, 0, "Açılışta pencere olmamalı")

        let statusItem = app.statusItems.firstMatch
        XCTAssertTrue(statusItem.waitForExistence(timeout: 5), "Menü çubuğu simgesi bulunamadı")
        statusItem.click()

        XCTAssertTrue(app.staticTexts["panel.emptyState"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["panel.quit"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
