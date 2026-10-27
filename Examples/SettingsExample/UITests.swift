import XCTest

@MainActor
final class SettingsExampleUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func launch(_ arguments: [String] = [], language: String = "en") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", language == "ar" ? "ar_SA" : "en_US"] + arguments
        app.launch()
        return app
    }

    func testProfilePurchaseAndLogout() {
        let app = launch()
        app.buttons["open-fullscreen"].tap()
        let user = app.cells["Demo User"].firstMatch
        XCTAssertTrue(user.waitForExistence(timeout: 10))
        user.tap()
        XCTAssertTrue(app.buttons["rename"].waitForExistence(timeout: 5))
        app.buttons["rename"].tap()
        XCTAssertTrue(app.cells["Updated User"].firstMatch.waitForExistence(timeout: 5))
        let premium = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "All example features")).firstMatch
        XCTAssertTrue(premium.waitForExistence(timeout: 5))
        premium.tap()
        XCTAssertTrue(app.buttons["buy"].waitForExistence(timeout: 5))
        app.buttons["buy"].tap()
        XCTAssertTrue(app.staticTexts["Active"].firstMatch.waitForExistence(timeout: 5))
        app.cells["Updated User"].firstMatch.tap()
        XCTAssertTrue(app.buttons["logout"].waitForExistence(timeout: 5))
        app.buttons["logout"].tap()
        XCTAssertTrue(app.cells["Guest"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(premium.waitForExistence(timeout: 5))
        attach(app, name: "profile-purchase-logout")
    }

    func testSheetAndFactory() {
        let app = launch()
        app.buttons["open-sheet"].tap()
        let destination = app.staticTexts["Injected destination"].firstMatch
        XCTAssertTrue(destination.waitForExistence(timeout: 10))
        destination.tap()
        XCTAssertTrue(app.buttons["rename"].waitForExistence(timeout: 5))
        attach(app, name: "sheet-factory")
    }

    func testDarkLargeTextAndRTLLayout() {
        let app = launch(["-demo-dark", "-demo-rtl", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"], language: "ar")
        app.buttons["open-fullscreen"].tap()
        XCTAssertTrue(app.cells["Demo User"].firstMatch.waitForExistence(timeout: 10))
        attach(app, name: "dark-rtl-large-text")
    }

    private func attach(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
