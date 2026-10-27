import XCTest
import UIKit

@MainActor
final class SettingsExampleUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testSlowMailShowsPreparationAndCanCloseWithoutOpeningExternalMail() {
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
        XCTAssertTrue(app.staticTexts["Preparing message…"].waitForExistence(timeout: 5))
        XCTAssertFalse(send.isEnabled)
        attach(app, name: "mail-preparing")
        app.buttons["settings.mail.close"].firstMatch.tap()
        XCTAssertTrue(app.cells["Demo User"].firstMatch.waitForExistence(timeout: 5))
    }

    private func launch(_ arguments: [String] = [], language: String = "en") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", language == "ar" ? "ar_SA" : "en_US"] + arguments
        app.launch()
        return app
    }

    func testSettingsAccessibilityAudit() throws {
        guard #available(iOS 17, *) else { throw XCTSkip("Native accessibility audits require iOS 17 or newer.") }
        let app = launch()
        app.buttons["open-fullscreen"].tap()
        XCTAssertTrue(app.cells["Demo User"].firstMatch.waitForExistence(timeout: 10))
        try app.performAccessibilityAudit { issue in
            print("Accessibility audit: \(issue.compactDescription) — \(issue.detailedDescription)")
            print(issue.element?.debugDescription ?? "No associated element")
            return false // Diagnostic logging only; never suppress an issue.
        }
        app.tables.firstMatch.swipeUp()
        try app.performAccessibilityAudit { issue in
            print("Accessibility audit: \(issue.compactDescription) — \(issue.detailedDescription)")
            print(issue.element?.debugDescription ?? "No associated element")
            return false // Diagnostic logging only; never suppress an issue.
        }
        attach(app, name: "settings-accessibility-audit")
    }

    func testLocalizedMailPreparationAndAbout() {
        for (locale, preparing, preferred) in [
            ("ru", "Подготовка сообщения…", "Предпочитаемый язык"),
            ("de", "Nachricht wird vorbereitet…", "Bevorzugte Sprache"),
            ("ar", "جارٍ تحضير الرسالة…", "اللغة المفضلة")
        ] {
            let direction = locale == "ar" ? ["-demo-rtl"] : []
            let app = launch(["-demo-open-settings", "-qa-open-mail", "-demo-slow-provider"] + direction, language: locale)
            let field = app.textViews.firstMatch
            XCTAssertTrue(field.waitForExistence(timeout: 10))
            field.tap()
            let introduction = app.buttons["Continue"].firstMatch
            if introduction.exists && introduction.isHittable { introduction.tap() }
            field.typeText("Please help with this message")
            let send = app.buttons["settings.mail.send"].firstMatch
            XCTAssertTrue(send.isEnabled)
            send.tap()
            XCTAssertTrue(app.staticTexts[preparing].waitForExistence(timeout: 5))
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
    }

    func testPhoneSheetInteractiveCancellation() throws {
        guard UIDevice.current.userInterfaceIdiom == .phone else {
            throw XCTSkip("This test exercises the phone page-sheet drag gesture.")
        }
        let app = launch(["-qa-track-dismissal"])
        app.buttons["open-sheet"].tap()
        XCTAssertTrue(app.cells["Demo User"].firstMatch.waitForExistence(timeout: 10))
        let bar = app.navigationBars["Settings"].firstMatch
        let start = bar.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        let end = start.withOffset(CGVector(dx: 0, dy: 100))
        start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.4)
        let table = app.tables["qa-settings-table"].firstMatch
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
