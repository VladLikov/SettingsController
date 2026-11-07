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

    func testSettingsActionsUseChevronsAndOurAppsUseArrows() {
        for row: SettingsRowItem.DefaultRow in [
            .language, .contactDeveloper(email: "a@b.c"), .rateApp(appID: "1"), .shareApp(appID: "1"), .redeemCode,
            .telegram(id: "t"), .vkGroup(id: "1"),
        ] {
            XCTAssertEqual(DisplayRow.item(.defaultRow(row)).accessory, .disclosure, "\(row)")
        }
        XCTAssertEqual(DisplayRow.item(.defaultRow(.moreApps(developerID: "1"))).accessory, .disclosure)
        let action = SettingsRow(title: "A", icon: SettingsIcon(image: nil, color: .blue), destination: .action { _ in })
        XCTAssertEqual(DisplayRow.item(.row(action)).accessory, .disclosure)
        let inert = SettingsRow(title: "A", icon: SettingsIcon(image: nil, color: .blue), destination: nil)
        XCTAssertEqual(DisplayRow.item(.row(inert)).accessory, .none)
        XCTAssertEqual(DisplayRow.app(.placeholder).accessory, .none)
        XCTAssertEqual(DisplayRow.app(.failed).accessory, .none)
        let app = AppItem(
            id: 1, name: "Example", iconURL: URL(string: "https://example.com/icon.png")!,
            storeURL: URL(string: "https://apps.apple.com/app/id1")!)
        let cell = UITableViewCell()
        DisplayRow.app(.loaded(app)).accessory.apply(to: cell)
        XCTAssertEqual(cell.accessoryType, .none)
        XCTAssertTrue(cell.accessoryView is ExternalArrowView)
        XCTAssertFalse(cell.accessoryView?.bounds.isEmpty ?? true)
        DisplayRow.item(.defaultRow(.moreApps(developerID: "1"))).accessory.apply(to: cell)
        XCTAssertEqual(cell.accessoryType, .disclosureIndicator)
        XCTAssertNil(cell.accessoryView)
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
        let osVersionRow = IndexPath(row: 0, section: 2)
        XCTAssertNotNil(about.tableView(about.tableView, contextMenuConfigurationForRowAt: osVersionRow, point: .zero))
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

@MainActor
final class DoubleTapTests: XCTestCase {
    func testSecondSelectionDoesNotPushTwiceAndFirstSelectionIsNeverBlocked() {
        var created = 0
        let settings = SettingsController(
            configuration: SettingsConfiguration(sections: [
                SettingsSection(
                    kind: .rows([
                        .row(
                            SettingsRow(
                                title: "A", icon: SettingsIcon(image: nil, color: .blue),
                                destination: .factory {
                                    created += 1
                                    return UIViewController()
                                }))
                    ]))
            ]))
        let navigation = UINavigationController(rootViewController: settings)
        let window = mountedWindow(navigation)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        let row = IndexPath(row: 0, section: 0)
        settings.tableView(settings.tableView, didSelectRowAt: row)
        settings.tableView(settings.tableView, didSelectRowAt: row)
        XCTAssertEqual(created, 1)
        XCTAssertEqual(navigation.viewControllers.count, 2)
    }
}

@MainActor
final class TapticScreenTests: XCTestCase {
    private final class Storage: TapticStorage {
        var isTapticEngineEnabled = true
        var tapticStyle = TapticStyle.medium
    }

    func testToggleRemovesStylesAndSelectionMovesTheCheckmark() throws {
        let storage = Storage()
        let controller = TapticEngineController(tapticStorage: storage, eventHandler: nil)
        let window = mountedWindow(controller)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        let table = controller.tableView!
        XCTAssertEqual(table.numberOfSections, 2)
        controller.tableView(table, didSelectRowAt: IndexPath(row: 2, section: 1))
        table.layoutIfNeeded()
        XCTAssertEqual(storage.tapticStyle, .heavy)
        XCTAssertEqual(table.cellForRow(at: IndexPath(row: 2, section: 1))?.accessoryType, .checkmark)
        XCTAssertEqual(table.cellForRow(at: IndexPath(row: 1, section: 1))?.accessoryType, Optional(.none))

        let toggle = try XCTUnwrap(table.cellForRow(at: IndexPath(row: 0, section: 0)) as? SwitchCell)
        toggle.switchControl.isOn = false
        for target in toggle.switchControl.allTargets {
            for action in toggle.switchControl.actions(forTarget: target, forControlEvent: .valueChanged) ?? [] {
                _ = (target as NSObject).perform(NSSelectorFromString(action), with: toggle.switchControl)
            }
        }
        XCTAssertFalse(storage.isTapticEngineEnabled)
        XCTAssertEqual(table.numberOfSections, 1)
    }
}

@MainActor
final class LargeTitleTests: XCTestCase {
    /// A host top inset with rows taller than the screen used to open the list scrolled by that inset,
    /// which showed a collapsed large title until the user scrolled back.
    func testTopInsetWithLongContentOpensAtTheTopWithALargeTitle() {
        let rows = (0..<30).map { index in
            SettingsRowItem.row(SettingsRow(title: "Row \(index)", icon: SettingsIcon(image: nil, color: .blue), destination: nil))
        }
        let settings = SettingsController(
            configuration: SettingsConfiguration(insets: SettingsInsets(top: 25), sections: [SettingsSection(kind: .rows(rows))]))
        let navigation = UINavigationController(rootViewController: settings)
        navigation.navigationBar.prefersLargeTitles = true
        let window = mountedWindow(navigation)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        let table = settings.tableView!
        XCTAssertGreaterThan(table.contentSize.height, table.bounds.height)
        XCTAssertEqual(table.contentOffset.y, -table.adjustedContentInset.top, accuracy: 0.5)
    }
}
