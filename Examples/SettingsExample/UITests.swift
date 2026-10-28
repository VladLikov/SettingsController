import XCTest
import UIKit

@MainActor
final class SettingsExampleUITests: XCTestCase {
    private var launchedApp: XCUIApplication?

    override func setUpWithError() throws { continueAfterFailure = false }

    override func tearDown() async throws {
        defer { launchedApp = nil }
        if let app = launchedApp, app.state != .notRunning {
            app.terminate()
            XCTAssertTrue(app.wait(for: .notRunning, timeout: 10), "The previous app must stop before the next UI scenario.")
        }
        try await super.tearDown()
    }

    func testSlowMailKeepsEditorAndCanCloseWithoutOpeningExternalMail() {
        let app = launch(["-demo-slow-provider"])
        app.buttons["open-fullscreen"].tap()
        let standalone = app.staticTexts["Standalone mail"].firstMatch
        XCTAssertTrue(standalone.waitForExistence(timeout: 10))
        if !standalone.isHittable { app.tables.firstMatch.swipeUp() }
        standalone.tap()
        let field = app.textViews.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        let introduction = app.buttons["Continue"].firstMatch
        if introduction.exists && introduction.isHittable { introduction.tap() }
        field.typeText("Please help with this message")
        let send = app.buttons["settings.mail.send"].firstMatch
        XCTAssertTrue(send.isEnabled)
        send.tap()
        XCTAssertFalse(app.staticTexts["Preparing message…"].exists)
        XCTAssertEqual(field.value as? String, "Please help with this message")
        XCTAssertFalse(send.isEnabled)
        attach(app, name: "mail-pending-diagnostics")
        field.typeText(" edited")
        XCTAssertTrue(send.isEnabled)
        send.tap()
        XCTAssertFalse(send.isEnabled)
        app.buttons["settings.mail.close"].firstMatch.tap()
        XCTAssertTrue(app.cells["Demo User"].firstMatch.waitForExistence(timeout: 5))
    }

    private func launch(_ arguments: [String] = [], language: String = "en") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", language == "ar" ? "ar_SA" : "en_US"] + arguments
        launchedApp = app
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        return app
    }

    func testSettingsAccessibilityAudit() throws {
        try auditSettings(afterScrolling: false)
    }

    func testSettingsAccessibilityAuditAfterScrolling() throws {
        try auditSettings(afterScrolling: true)
    }

    private func auditSettings(afterScrolling: Bool) throws {
        guard #available(iOS 17, *) else { throw XCTSkip("Native accessibility audits require iOS 17 or newer.") }
        let app = launch()
        app.buttons["open-fullscreen"].tap()
        XCTAssertTrue(app.cells["Demo User"].firstMatch.waitForExistence(timeout: 10))
        if afterScrolling { app.tables.firstMatch.swipeUp() }
        // Each viewport gets the complete audit in a fresh app process.
        try app.performAccessibilityAudit { issue in
            print("Accessibility audit: \(issue.compactDescription) — \(issue.detailedDescription)")
            print(issue.element?.debugDescription ?? "No associated element")
            return false // Diagnostic logging only; never suppress an issue.
        }
        attach(app, name: afterScrolling ? "settings-accessibility-audit-scrolled" : "settings-accessibility-audit")
    }

    func testLocalizedMailPreparationAndAboutRussian() {
        assertLocalizedMailPreparationAndAbout(locale: "ru", preferred: "Предпочитаемый язык")
    }

    func testLocalizedMailPreparationAndAboutGerman() {
        assertLocalizedMailPreparationAndAbout(locale: "de", preferred: "Bevorzugte Sprache")
    }

    func testLocalizedMailPreparationAndAboutArabic() {
        assertLocalizedMailPreparationAndAbout(locale: "ar", preferred: "اللغة المفضلة")
    }

    private func assertLocalizedMailPreparationAndAbout(locale: String, preferred: String) {
        let direction = locale == "ar" ? ["-demo-rtl"] : []
        let app = launch(["-demo-open-settings", "-qa-open-mail", "-demo-slow-provider"] + direction, language: locale)
        let field = app.textViews.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        let introduction = app.buttons["Continue"].firstMatch
        if introduction.exists && introduction.isHittable { introduction.tap() }
        field.typeText("Please help with this message")
        let send = app.buttons["settings.mail.send"].firstMatch
        XCTAssertTrue(send.isEnabled)
        send.tap()
        XCTAssertFalse(send.isEnabled)
        attach(app, name: "localized-mail-" + locale)
        app.buttons["settings.mail.close"].firstMatch.tap()
        app.terminate()
        let about = launch(["-demo-open-settings", "-qa-open-about"] + direction, language: locale)
        let label = about.staticTexts[preferred].firstMatch
        for _ in 0..<4 {
            if label.exists && label.isHittable { break }
            about.tables.element(boundBy: about.tables.count - 1).swipeUp()
        }
        XCTAssertTrue(label.exists && label.isHittable)
        attach(about, name: "localized-about-" + locale)
        about.terminate()
    }

    func testPhoneSheetInteractiveCancellation() throws {
        guard UIDevice.current.userInterfaceIdiom == .phone else {
            throw XCTSkip("This test exercises the phone page-sheet drag gesture.")
        }
        let app = launch(["-qa-track-dismissal"])
        app.buttons["open-sheet"].tap()
        XCTAssertTrue(app.cells["Demo User"].firstMatch.waitForExistence(timeout: 10))
        let table = app.tables["qa-settings-table"].firstMatch
        XCTAssertTrue(table.waitForExistence(timeout: 10), "The real sheet probe must be ready before dragging.")
        XCTAssertEqual(table.value as? String, "qa-none")
        let bar = app.navigationBars["Settings"].firstMatch
        print("Cancellation geometry: window=\(app.windows.firstMatch.frame), bar=\(bar.frame), table=\(table.frame)")
        attach(app, name: "interactive-sheet-before-drag")
        let start = bar.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        // A short drag enters the transition without crossing the dismissal threshold.
        let end = start.withOffset(CGVector(dx: 0, dy: 50))
        start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 1.0)
        let cancelled = NSPredicate(format: "value == %@", "qa-cancelled")
        expectation(for: cancelled, evaluatedWith: table)
        waitForExpectations(timeout: 5)
        XCTAssertTrue(app.cells["Demo User"].firstMatch.isHittable)
        app.cells["Demo User"].firstMatch.tap()
        XCTAssertTrue(app.buttons["rename"].waitForExistence(timeout: 5))
        app.buttons["rename"].tap()
        XCTAssertTrue(app.cells["Updated User"].firstMatch.waitForExistence(timeout: 5))
        attach(app, name: "cancelled-interactive-sheet")
    }

    func testProfilePurchaseAndLogout() {
        let app = launch()
        app.buttons["open-fullscreen"].tap()
        let user = app.cells["Demo User"].firstMatch
        XCTAssertTrue(user.waitForExistence(timeout: 10))
        user.tap()
        XCTAssertTrue(app.buttons["rename"].waitForExistence(timeout: 5))
        app.buttons["rename"].tap()
        XCTAssertTrue(app.cells["Updated User"].firstMatch.waitForExistence(timeout: 5), app.debugDescription)
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
        app.buttons["rename"].tap()
        XCTAssertTrue(app.cells["Updated User"].firstMatch.waitForExistence(timeout: 5), app.debugDescription)
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

    func testProminentPremiumCTAAndCardBothOpenPaywall() {
        let app = launch()
        app.buttons["open-fullscreen"].tap()
        let card = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "All example features")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        attach(app, name: "premium-glass-prominent")
        card.coordinate(withNormalizedOffset: CGVector(dx: 0.82, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["restore"].waitForExistence(timeout: 5))
        app.buttons["demo.paywall.close"].tap()
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        card.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.5)).tap()
        XCTAssertTrue(app.buttons["restore"].waitForExistence(timeout: 5))
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

    func testUnavailableMailAppShowsRecoveryAndKeepsText() {
        let app = launch()
        app.buttons["open-fullscreen"].tap()
        app.staticTexts["Contact Developer"].firstMatch.tap()
        let field = app.textViews.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        let keyboardIntroduction = app.buttons["Continue"].firstMatch
        if keyboardIntroduction.exists && keyboardIntroduction.isHittable { keyboardIntroduction.tap() }
        let message = "Please help: preserve this message after opening fails"
        field.typeText(message)
        app.buttons["settings.mail.send"].firstMatch.tap()
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 10), "Run on the QA simulator without a mailto handler")
        XCTAssertTrue(alert.buttons["Copy Address"].exists)
        XCTAssertTrue(alert.buttons["Copy Message"].exists)
        attach(app, name: "mail-open-error")
        alert.buttons["Cancel"].tap()
        XCTAssertEqual(field.value as? String, message)
        XCTAssertTrue(app.buttons["settings.mail.send"].firstMatch.isEnabled)
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
        app.buttons["settings.mail.close"].firstMatch.tap()
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
