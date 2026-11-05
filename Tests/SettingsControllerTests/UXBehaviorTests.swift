import UIKit
import XCTest

@testable import SettingsController

@MainActor
final class UXBehaviorTests: XCTestCase {
    private func presentedMail(type: MailType = .supportRequest) -> (UIWindow, MailController, UINavigationController) {
        let mail = MailController(type: type, email: "support@example.com")
        let navigation = UINavigationController(rootViewController: mail)
        let window = mountedWindow(navigation)
        mail.loadViewIfNeeded()
        return (window, mail, navigation)
    }

    func testTypedMessageBlocksSwipeDismissalAndEmptyMessageDoesNot() {
        let (window, mail, navigation) = presentedMail()
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        let cell = MailCell(style: .default, reuseIdentifier: nil)
        mail.mailCell(cell, didChangeText: "Something broke", needsHeightUpdate: false)
        XCTAssertTrue(navigation.isModalInPresentation)
        mail.mailCell(cell, didChangeText: "   \n", needsHeightUpdate: false)
        XCTAssertFalse(navigation.isModalInPresentation, "Whitespace alone is not worth protecting")
    }

    func testRequirementLineCountsMissingCharactersAndDisappears() {
        let cell = MailCell(style: .default, reuseIdentifier: nil)
        XCTAssertTrue(cell.showMissingCharacters(7), "The line appears")
        XCTAssertFalse(cell.showMissingCharacters(3), "Changing the count keeps the height")
        XCTAssertTrue(cell.showMissingCharacters(0), "The line disappears once Send is enabled")
        XCTAssertEqual(MailType.supportRequest.missingCharacters(in: " 12345 "), 5)
    }

    func testFormClosesItselfOnlyAfterTheMailAppOpened() async throws {
        for opened in [true, false] {
            let mail = MailController(type: .languageRequest, email: "support@example.com")
            mail.openURL = { _ in opened }
            let navigation = PresentedNavigation(rootViewController: mail)
            let window = mountedWindow(navigation)
            defer {
                window.isHidden = true
                window.rootViewController = nil
            }
            mail.mailCell(MailCell(style: .default, reuseIdentifier: nil), didChangeText: "Tamil", needsHeightUpdate: false)
            mail.prepareMail()
            await mail.mailTask?.value
            XCTAssertEqual(navigation.dismissals, opened ? 1 : 0)
            if !opened { mail.dismiss(animated: false) }
        }
    }

    func testRowsUseChevronsOnlyForScreens() {
        XCTAssertEqual(
            DisplayRow.item(.defaultRow(.about(appID: "1", privacyURL: URL(string: "https://a.b")!, termsURL: URL(string: "https://a.b")!)))
                .accessory, .disclosure)
        XCTAssertEqual(DisplayRow.item(.defaultRow(.rateApp(appID: "1"))).accessory, .external)
        XCTAssertEqual(DisplayRow.item(.defaultRow(.language)).accessory, .external)
        XCTAssertEqual(DisplayRow.item(.defaultRow(.shareApp(appID: "1"))).accessory, .none)
        XCTAssertEqual(DisplayRow.item(.defaultRow(.contactDeveloper(email: "a@b.c"))).accessory, .none)
        let action = SettingsRow(title: "A", icon: SettingsIcon(image: nil, color: .blue), destination: .action { _ in })
        XCTAssertEqual(DisplayRow.item(.row(action)).accessory, .none)
    }

    func testSecondTapOnAnOpeningAppDoesNotRestartTheRequest() async throws {
        let settings = SettingsController(configuration: SettingsConfiguration(sections: []))
        let window = mountedWindow(settings)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        let gate = ControlledValue<Bool>()
        var loads = 0
        settings.loadStoreProduct = { _ in
            loads += 1
            _ = try await gate.value()
            return nil
        }
        settings.openURL = { _ in true }
        let url = URL(string: "https://apps.apple.com/app/id7")!
        settings.openApp(7, url: url)
        let first = try XCTUnwrap(settings.storeProductTask)
        await gate.waitUntilStarted()
        XCTAssertEqual(settings.openingStoreAppID, 7)
        settings.openApp(7, url: url)
        XCTAssertEqual(settings.storeProductTask, first)
        XCTAssertEqual(loads, 1)
        gate.complete(.success(true))
        await first.value
        XCTAssertNil(settings.openingStoreAppID)
    }

    func testAboutOffersCopyForDiagnosticValuesAndLocalizedPremiumStatus() {
        let about = makeAbout()
        about.loadViewIfNeeded()
        let bundleRow = IndexPath(row: 0, section: 0)
        XCTAssertNotNil(about.tableView(about.tableView, contextMenuConfigurationForRowAt: bundleRow, point: .zero))
        let account = about.data.firstIndex { $0.section == .account }!
        let premium = about.data[account].items[1]
        XCTAssertNotEqual(premium.value, "false")
    }
}

/// Reports a presenter so the form behaves as a presented sheet inside a test window.
@MainActor
private final class PresentedNavigation: UINavigationController {
    private let presenter = UIViewController()
    var dismissals = 0
    override var presentingViewController: UIViewController? { presenter }
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        dismissals += 1
        completion?()
    }
}

@MainActor
final class ExternalLinkTests: XCTestCase {
    private func opened(appInstalled: Bool, _ action: (SettingsController) -> Void) async -> [URL] {
        let settings = SettingsController(configuration: SettingsConfiguration(sections: []))
        var urls: [URL] = []
        let done = ControlledValue<Bool>()
        settings.openURL = { url in
            urls.append(url)
            let isApp = url.scheme != "https"
            if !isApp || appInstalled { done.complete(.success(true)) }
            return isApp ? appInstalled : true
        }
        action(settings)
        _ = try? await done.value()
        return urls
    }

    func testTelegramFallsBackToTheWebWithoutQuerySchemes() async {
        let urls = await opened(appInstalled: false) { $0.openTelegramChannel("my channel") }
        XCTAssertEqual(urls.map(\.absoluteString), ["tg://resolve?domain=my%20channel", "https://t.me/my%20channel"])
    }

    func testInstalledAppOpensOnce() async {
        let urls = await opened(appInstalled: true) { $0.openVKGroup("42") }
        XCTAssertEqual(urls.map(\.absoluteString), ["vk://vk.com/club42"])
    }

    func testReviewUsesTheStoreAppThenTheWebPage() async {
        let urls = await opened(appInstalled: false) { $0.rateApp("123") }
        XCTAssertEqual(
            urls.map(\.absoluteString),
            ["itms-apps://itunes.apple.com/app/id123?action=write-review", "https://apps.apple.com/app/id123?action=write-review"])
    }
}
