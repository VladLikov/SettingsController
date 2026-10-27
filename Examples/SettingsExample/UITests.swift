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

    func testAutomaticAppearanceHelpIsVisible() {
        let app = launch()
        app.buttons["open-fullscreen"].tap()
        let appearance = app.staticTexts["Appearance"].firstMatch
        XCTAssertTrue(appearance.waitForExistence(timeout: 10))
        appearance.tap()
        let automatic = app.switches["Automatically"].firstMatch
        if !automatic.isHittable { app.tables.element(boundBy: app.tables.count - 1).swipeUp() }
        XCTAssertTrue(automatic.waitForExistence(timeout: 5))
        let help = app.staticTexts["When the switch is on, the system appearance is used."].firstMatch
        XCTAssertTrue(help.waitForExistence(timeout: 5))
        attach(app, name: "appearance-automatic-footer")
    }

    func testSimulatedRestoreActivatesPremium() {
        let app = launch()
        app.buttons["open-fullscreen"].tap()
        let premium = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "All example features")).firstMatch
        XCTAssertTrue(premium.waitForExistence(timeout: 10))
        premium.tap()
        XCTAssertTrue(app.buttons["restore"].waitForExistence(timeout: 5))
        app.buttons["restore"].tap()
        XCTAssertTrue(app.staticTexts["Active"].firstMatch.waitForExistence(timeout: 5))
        attach(app, name: "simulated-restore")
    }

    func testStandaloneMailCanTypeAndCloseWithoutSending() {
        let app = launch()
        app.buttons["open-fullscreen"].tap()
        let standalone = app.staticTexts["Standalone mail"].firstMatch
        XCTAssertTrue(standalone.waitForExistence(timeout: 10))
        if !standalone.isHittable { app.tables.firstMatch.swipeUp() }
        standalone.tap()
        let field = app.textViews.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        // A fresh simulator can show the system QuickPath introduction above the keyboard.
        let keyboardIntroduction = app.buttons["Continue"].firstMatch
        if keyboardIntroduction.exists && keyboardIntroduction.isHittable { keyboardIntroduction.tap() }
        XCTAssertTrue(app.keyboards.firstMatch.exists)
        field.typeText("Message & plus + 10% = #?\nhttps://example.com?a=1&b=2")
        XCTAssertTrue(app.buttons["Send"].firstMatch.isEnabled)
        attach(app, name: "standalone-mail-keyboard")
        app.navigationBars["Contact"].buttons["close"].tap()
        XCTAssertTrue(app.cells["Demo User"].firstMatch.waitForExistence(timeout: 5))
    }

    private func attach(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = name + "-hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
    }
}
