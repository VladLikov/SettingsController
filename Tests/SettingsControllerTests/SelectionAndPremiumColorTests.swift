import SwiftUI
import UIKit
import XCTest

@testable import SettingsController

@MainActor
final class SelectionAndPremiumColorTests: XCTestCase {
    func testColorChangeReconfiguresVisibleActivePremiumRow() throws {
        let card = PremiumCardPayload(
            title: "App", tierTitle: "PRO", buttonTitle: "Upgrade",
            premium: PremiumPayload(isPremium: true, color: .systemBlue))
        let settings = SettingsController(
            configuration: SettingsConfiguration(sections: [
                SettingsSection(kind: .premiumCard(card)),
                SettingsSection(kind: .rows([.defaultRow(.language)])),
            ]))
        let window = mountedWindow(settings)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        let path = IndexPath(row: 0, section: 0)
        let before = try XCTUnwrap(settings.tableView.cellForRow(at: path) as? SettingsCell)
        let initialImage = try XCTUnwrap((before.contentConfiguration as? UIListContentConfiguration)?.image)

        settings.updatePremiumColor(.systemGreen)
        settings.tableView.layoutIfNeeded()

        let after = try XCTUnwrap(settings.tableView.cellForRow(at: path) as? SettingsCell)
        let updatedImage = try XCTUnwrap((after.contentConfiguration as? UIListContentConfiguration)?.image)
        XCTAssertFalse(initialImage === updatedImage, "The visible active premium row must render the new color")
    }

    func testRowsOpeningDetailAreDistinguishedFromActions() {
        XCTAssertTrue(SettingsRowItem.defaultRow(.appearance(theme: StubTheme())).opensDetail)
        XCTAssertTrue(SettingsRowItem.defaultRow(.user("Name", nil, UIViewController.self)).opensDetail)
        XCTAssertTrue(SettingsRowItem.row(SettingsRow(title: "A", icon: icon(), destinationFactory: { UIViewController() })).opensDetail)
        XCTAssertFalse(SettingsRowItem.defaultRow(.shareApp(appID: "1")).opensDetail)
        XCTAssertFalse(SettingsRowItem.defaultRow(.rateApp(appID: "1")).opensDetail)
        XCTAssertFalse(SettingsRowItem.defaultRow(.redeemCode).opensDetail)
        XCTAssertFalse(SettingsRowItem.row(SettingsRow(title: "A", icon: icon(), action: { _, _, _ in })).opensDetail)
    }

    func testActionRowRestoresDetailSelectionInExpandedSplit() throws {
        guard #available(iOS 17, *) else { throw XCTSkip("Trait overrides require iOS 17") }
        var actions = 0
        let configuration = SettingsConfiguration(sections: [
            SettingsSection(
                kind: .rows([
                    .row(SettingsRow(title: "Detail", icon: icon(), destinationFactory: { UIViewController() })),
                    .row(SettingsRow(title: "Action", icon: icon(), action: { _, _, _ in actions += 1 })),
                ]))
        ])
        let root = SettingsController.getSplitPresentationSettingsController(configuration: configuration)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1180, height: 820))
        window.traitOverrides.horizontalSizeClass = .regular
        window.rootViewController = root
        window.makeKeyAndVisible()
        root.view.layoutIfNeeded()
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        let split = try XCTUnwrap(root as? UISplitViewController)
        try XCTSkipIf(split.isCollapsed, "The split did not expand in this environment")
        let settings = try XCTUnwrap(
            ((split.viewControllers.first as? UINavigationController)?.viewControllers.first) as? SettingsController)
        let table = settings.tableView!
        let detail = IndexPath(row: 0, section: 0)
        let action = IndexPath(row: 1, section: 0)

        tap(detail, in: table, settings: settings)
        XCTAssertEqual(table.indexPathForSelectedRow, detail)

        tap(action, in: table, settings: settings)
        XCTAssertEqual(actions, 1)
        XCTAssertEqual(table.indexPathForSelectedRow, detail, "An action row must not steal the detail selection")
    }

    func testLoadingPlaceholderIsNotHighlightable() {
        let settings = SettingsController(
            configuration: SettingsConfiguration(sections: [
                SettingsSection(kind: .ourApps(developerID: "1", limit: 2, excludeAppID: "0"))
            ]))
        settings.fetchApps = { _, _, _ in
            try await Task.sleep(nanoseconds: 60_000_000_000)
            return []
        }
        settings.loadViewIfNeeded()
        let path = IndexPath(row: 0, section: 0)
        XCTAssertFalse(settings.tableView(settings.tableView, shouldHighlightRowAt: path))
        XCTAssertNil(settings.tableView(settings.tableView, willSelectRowAt: path))
        settings.cancelOperations()
    }

    private func tap(_ path: IndexPath, in table: UITableView, settings: SettingsController) {
        guard let target = settings.tableView(table, willSelectRowAt: path) else { return }
        table.selectRow(at: target, animated: false, scrollPosition: .none)
        settings.tableView(table, didSelectRowAt: target)
    }

    private func icon() -> SettingsIcon {
        SettingsIcon(image: UIImage(systemName: "star"), color: .systemBlue, cacheIdentifier: "test:star")
    }
}

private final class StubTheme: ThemeStorage {
    var appColor: UIColor = .systemBlue
    var appColorRawValue = "blue"
    var autoTheme = true
    var interfaceStyle = 1
}
