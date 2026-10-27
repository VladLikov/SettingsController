import XCTest
import UIKit
@testable import SettingsController

@MainActor
final class MailRegressionTests: XCTestCase {
    func testQueryRoundTripPreservesAllSpecialCharacters() throws {
        let text = "A & B + 10% = #? / Привет 👋\nhttps://example.com?a=1&b=2\r\nend"
        let draft = MailDraft(recipient: "support+ios@example.com", subject: text, body: text)
        let url = try XCTUnwrap(draft.url)
        let parts = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        XCTAssertEqual(parts.scheme, "mailto")
        XCTAssertEqual(parts.path, "support+ios@example.com")
        XCTAssertEqual(parts.queryItems?.count, 2)
        XCTAssertEqual(parts.queryItems?.first?.value, text)
        XCTAssertEqual(parts.queryItems?.last?.value, text)
        XCTAssertTrue(url.absoluteString.contains("%2B"))
    }

    func testInvalidRecipientDoesNotCreateURL() {
        for address in ["", "   ", "support@example.com\nBcc:bad@example.com", "a\rb"] {
            XCTAssertNil(MailDraft(recipient: address, subject: "Subject", body: "Body").url)
        }
    }

    func testDeterministicEnvironmentAndSingleUserID() {
        let environment = MailEnvironment(appName: "Fixture", version: "1.2", build: "42",
            deviceModel: "Model", deviceType: "Phone", systemName: "iOS", systemVersion: "15.0",
            battery: "Unknown", locale: "ru_RU", preferredLanguage: "en-GB", appLanguage: "ru",
            region: "ru", timeZone: "UTC", timestamp: "fixed")
        let draft = MailBuilder.makeDraft(with: "Exact message", recipient: "support@example.com",
            type: .supportRequest, isPremium: true, productID: "fallback",
            mailInfo: SettingsMailInfo(userID: "u-123", productID: "annual", isPremium: false), environment: environment)
        XCTAssertTrue(draft.body.contains("User ID: u-123\nProduct ID: annual\nPro Status: false"))
        XCTAssertEqual(draft.body.components(separatedBy: "User ID:").count, 2)
        XCTAssertTrue(draft.body.contains("Preferred Language: en-GB\nApp Language: ru"))
        XCTAssertTrue(draft.body.contains("Timestamp: fixed"))
        XCTAssertFalse(draft.body.contains("Adapty Profile ID"))
        XCTAssertFalse(draft.body.contains("Device Name"))
    }

    func testCancelledPreparationNeverOpensMailAndDoesNotRetainController() async throws {
        let gate = ControlledValue<SettingsMailInfo?>()
        let provider = RegressionProvider()
        provider.mailOperation = { try? await gate.value() }
        var opened: [URL] = []
        var controller: MailController? = MailController(type: .supportRequest, email: "support@example.com", dataProvider: provider)
        let weakController = MailWeakReference(controller)
        controller?.loadViewIfNeeded()
        controller?.openURL = { opened.append($0); return true }
        controller?.mailCell(MailCell(style: .default, reuseIdentifier: nil), didChangeText: "Please help with this", needsHeightUpdate: false)
        controller?.prepareMail()
        let task = try XCTUnwrap(controller?.mailTask)
        await gate.waitUntilStarted()
        controller?.cancelMailPreparation()
        controller = nil
        XCTAssertNil(weakController.value)
        gate.complete(.success(SettingsMailInfo(userID: "123", isPremium: true)))
        await task.value
        XCTAssertTrue(opened.isEmpty)
    }

    func testSendIsSingleFlightAndFalseOpenKeepsText() async throws {
        let gate = ControlledValue<SettingsMailInfo?>()
        let provider = RegressionProvider()
        provider.mailOperation = { try? await gate.value() }
        let controller = MailController(type: .supportRequest, email: "support@example.com", dataProvider: provider)
        let window = mountedWindow(UINavigationController(rootViewController: controller))
        defer { window.isHidden = true; window.rootViewController = nil }
        var opens = 0
        controller.openURL = { _ in opens += 1; return false }
        let text = "Do not lose my message & details"
        controller.mailCell(MailCell(style: .default, reuseIdentifier: nil), didChangeText: text, needsHeightUpdate: false)
        controller.prepareMail()
        controller.prepareMail()
        let task = try XCTUnwrap(controller.mailTask)
        await gate.waitUntilStarted()
        XCTAssertEqual(provider.mailRequests, 1)
        gate.complete(.success(SettingsMailInfo(isPremium: false)))
        await task.value
        XCTAssertEqual(opens, 1)
        XCTAssertNil(controller.mailTask)
        XCTAssertNotNil(controller.presentedViewController as? UIAlertController)
        XCTAssertTrue(controller.navigationItem.rightBarButtonItem?.isEnabled == true)
        let cell = try XCTUnwrap(controller.tableView(controller.tableView, cellForRowAt: IndexPath(row: 0, section: 0)) as? MailCell)
        let textViews = cell.contentView.subviews.compactMap { $0 as? UITextView }
        XCTAssertEqual(textViews.first?.text, text)
        controller.dismiss(animated: false)
    }

    func testPreparingMailKeepsStandardSendButtonDisabled() async throws {
        let gate = ControlledValue<SettingsMailInfo?>()
        let provider = RegressionProvider()
        provider.mailOperation = { try? await gate.value() }
        let controller = MailController(type: .supportRequest, email: "support@example.com", dataProvider: provider)
        controller.loadViewIfNeeded()
        let window = mountedWindow(controller)
        defer { window.isHidden = true; window.rootViewController = nil }
        controller.mailCell(MailCell(style: .default, reuseIdentifier: nil), didChangeText: "Please help with this", needsHeightUpdate: false)
        let send = try XCTUnwrap(controller.navigationItem.rightBarButtonItem)
        controller.prepareMail()
        let task = try XCTUnwrap(controller.mailTask)
        await gate.waitUntilStarted()
        XCTAssertTrue(controller.navigationItem.rightBarButtonItem === send)
        XCTAssertNil(controller.navigationItem.rightBarButtonItem?.customView)
        XCTAssertEqual(send.accessibilityIdentifier, "settings.mail.send")
        XCTAssertEqual(controller.navigationItem.leftBarButtonItem?.accessibilityIdentifier, "settings.mail.close")
        XCTAssertFalse(send.isEnabled)
        controller.view.layoutIfNeeded()
        let header = try XCTUnwrap(controller.tableView.tableHeaderView)
        let stack = try XCTUnwrap(header.subviews.first as? UIStackView)
        let indicator = try XCTUnwrap(stack.arrangedSubviews.first as? UIActivityIndicatorView)
        XCTAssertTrue(indicator.isAnimating)
        XCTAssertGreaterThan(header.bounds.height, 0)
        XCTAssertFalse((stack.arrangedSubviews.last as? UILabel)?.text?.isEmpty ?? true)
        controller.cancelMailPreparation()
        XCTAssertNil(controller.tableView.tableHeaderView)
        XCTAssertFalse(indicator.isAnimating)
        XCTAssertTrue(controller.navigationItem.rightBarButtonItem === send)
        XCTAssertTrue(send.isEnabled)
        gate.complete(.success(nil))
        await task.value
    }

    func testStandaloneMailProviderIsWeak() {
        var provider: RegressionProvider? = RegressionProvider()
        let weakProvider = MailWeakReference(provider)
        let controller = MailController(type: .languageRequest, email: "support@example.com", dataProvider: provider)
        provider = nil
        XCTAssertNil(weakProvider.value)
        withExtendedLifetime(controller) {}
    }
}

@MainActor
private final class MailWeakReference<Value: AnyObject> {
    weak var value: Value?
    init(_ value: Value?) { self.value = value }
}
