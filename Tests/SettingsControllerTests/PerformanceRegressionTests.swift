import XCTest
import UIKit
@testable import SettingsController

@MainActor
final class PerformanceRegressionTests: XCTestCase {
    private func probe(_ controller: SettingsController) -> (UIWindow, UpdateRecordingTable) {
        controller.loadViewIfNeeded()
        let table = UpdateRecordingTable(frame: CGRect(x: 0, y: 0, width: 390, height: 844), style: .insetGrouped)
        table.dataSource = controller
        table.delegate = controller
        table.register(SettingsCell.self)
        table.register(UserCell.self)
        table.register(AppCell.self)
        table.register(PremiumCell.self)
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 53
        controller.tableView = table
        let window = mountedWindow(controller)
        table.layoutIfNeeded()
        table.reset()
        return (window, table)
    }

    func testVisiblePremiumTransitionsPreserveUnrelatedCellAndSelection() throws {
        let controller = SettingsController(configuration: SettingsConfiguration(sections: [
            SettingsSection(kind: .premiumCard(premiumCard())),
            SettingsSection(kind: .rows([.defaultRow(.language)]))
        ]))
        let (window, table) = probe(controller)
        defer { window.isHidden = true; window.rootViewController = nil }
        let path = IndexPath(row: 0, section: 1)
        let unaffected = try XCTUnwrap(table.cellForRow(at: path))
        table.selectRow(at: path, animated: false, scrollPosition: .none)
        for premium in [true, false, true, false] {
            controller.applyResolvedState(info: nil, premium: premium, user: nil, includesAccount: true)
            table.layoutIfNeeded()
            XCTAssertTrue(table.cellForRow(at: path) === unaffected)
            XCTAssertEqual(table.indexPathForSelectedRow, path)
            XCTAssertEqual(table.numberOfSections, 2)
            XCTAssertEqual(table.numberOfRows(inSection: 0), 1)
            XCTAssertEqual(table.cellForRow(at: IndexPath(row: 0, section: 0)) is PremiumCell, !premium)
        }
        XCTAssertEqual(table.fullReloads, 0)
        XCTAssertEqual(table.replacedSections, [0, 0, 0, 0])
    }

    func testProfileReconfiguresOnlyItsRowAndSameRevisionIsNoOp() throws {
        let avatar = UIImage(systemName: "person")!
        let controller = SettingsController(configuration: SettingsConfiguration(sections: [
            SettingsSection(kind: .rows([.defaultRow(.user("Initial", nil, UIViewController.self)), .defaultRow(.language)]))
        ]))
        let (window, table) = probe(controller)
        defer { window.isHidden = true; window.rootViewController = nil }
        let path = IndexPath(row: 1, section: 0)
        let unaffected = try XCTUnwrap(table.cellForRow(at: path))
        controller.applyResolvedState(info: nil, premium: nil, user: UserInfo(name: "New", avatar: avatar, avatarRevision: "account:1"), includesAccount: false)
        XCTAssertEqual(table.reconfigured, [IndexPath(row: 0, section: 0)])
        XCTAssertTrue(table.cellForRow(at: path) === unaffected)
        table.reset()
        controller.applyResolvedState(info: nil, premium: nil, user: UserInfo(name: "New", avatar: UIImage(systemName: "person"), avatarRevision: "account:1"), includesAccount: false)
        XCTAssertTrue(table.reconfigured.isEmpty)
        XCTAssertEqual(table.fullReloads, 0)
        controller.applyResolvedState(info: nil, premium: nil, user: UserInfo(name: "New", avatar: nil, avatarRevision: "account:1"), includesAccount: false)
        XCTAssertNil(controller.currentUser?.avatar)
        XCTAssertEqual(table.reconfigured, [IndexPath(row: 0, section: 0)])
    }

    func testVisibleCatalogRemovalThenLaterCompletionKeepsStableSection() async throws {
        let first = ControlledValue<[AppItem]>(), second = ControlledValue<[AppItem]>()
        let controller = SettingsController(configuration: SettingsConfiguration(sections: [
            SettingsSection(kind: .ourApps(developerID: "first", limit: 2, excludeAppID: "0")),
            SettingsSection(kind: .ourApps(developerID: "second", limit: 1, excludeAppID: "0")),
            SettingsSection(kind: .rows([.defaultRow(.language)]))
        ]))
        controller.fetchApps = { developer, _, _ in try await (developer == "first" ? first : second).value() }
        let (window, table) = probe(controller)
        defer { window.isHidden = true; window.rootViewController = nil }
        let a = try XCTUnwrap(controller.appLoadTasks[0]), b = try XCTUnwrap(controller.appLoadTasks[1])
        await first.waitUntilStarted(); await second.waitUntilStarted()
        let cell = try XCTUnwrap(table.cellForRow(at: IndexPath(row: 0, section: 2)))
        first.complete(.success([])); await a.value
        XCTAssertEqual(controller.visibleSectionIDs, [1, 2])
        XCTAssertEqual(table.numberOfSections, 2)
        second.complete(.success([AppItem(id: 3, name: "App", iconURL: URL(string: "https://example.com/icon")!, storeURL: URL(string: "https://apps.apple.com/app/id3")!)])); await b.value
        table.layoutIfNeeded()
        XCTAssertEqual(table.fullReloads, 0)
        XCTAssertEqual(table.replacedSections, [0])
        XCTAssertEqual(table.numberOfRows(inSection: 0), 1)
        XCTAssertTrue(table.cellForRow(at: IndexPath(row: 0, section: 1)) === cell)
    }

    func testAboutAccountChangedOffscreenIsFreshWhenShownAgain() throws {
        let controller = makeAbout()
        let window = mountedWindow(controller)
        defer { window.isHidden = true; window.rootViewController = nil }
        window.isHidden = true
        window.rootViewController = nil
        controller.applyAccountInfo(SettingsMailInfo(userID: "fresh", isPremium: true), premium: true)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.layoutIfNeeded()
        let cell = try XCTUnwrap(controller.tableView.cellForRow(at: IndexPath(row: 0, section: 3)))
        XCTAssertEqual((cell.contentConfiguration as? UIListContentConfiguration)?.secondaryText, "fresh")
    }

    func testPresentationAndProviderReleaseAcrossThirtyCycles() {
        for _ in 0..<30 {
            weak var weakSettings: SettingsController?
            weak var weakRoot: UIViewController?
            weak var weakProvider: RegressionProvider?
            autoreleasepool {
                let provider = RegressionProvider()
                let controller = SettingsController(configuration: SettingsConfiguration(
                    sections: [SettingsSection(kind: .premiumCard(premiumCard()))], dataProvider: provider))
                let root = SplitController.makeDefault(for: UINavigationController(rootViewController: controller))
                weakSettings = controller
                weakRoot = root
                weakProvider = provider
                controller.loadViewIfNeeded()
                controller.cancelOperations()
            }
            XCTAssertNil(weakSettings)
            XCTAssertNil(weakRoot)
            XCTAssertNil(weakProvider)
        }
    }

    func testSettingsCellReconfigurationClearsPreviousDetailAndIcon() {
        let cell = SettingsCell(style: .default, reuseIdentifier: nil)
        cell.configure(title: "First", icon: SettingsIcon(image: UIImage(systemName: "star"), color: .blue), detail: "Detail")
        cell.configure(title: "Second", icon: nil)
        let configuration = cell.contentConfiguration as? UIListContentConfiguration
        XCTAssertEqual(configuration?.text, "Second")
        XCTAssertNil(configuration?.secondaryText)
        XCTAssertNil(configuration?.image)
    }

    func testAppCellsReuseSamePlaceholderBitmap() {
        // Placeholder identity is shared even when different rows are configured.
        let a = AppCell(style: .default, reuseIdentifier: nil)
        let b = AppCell(style: .default, reuseIdentifier: nil)
        a.configure(with: .placeholder); b.configure(with: .failed)
        let first = (a.contentConfiguration as? UIListContentConfiguration)?.image
        let second = (b.contentConfiguration as? UIListContentConfiguration)?.image
        XCTAssertNotNil(first)
        XCTAssertTrue(first === second)
    }
}

@MainActor
private final class UpdateRecordingTable: UITableView {
    var fullReloads = 0
    var replacedSections: [Int] = []
    var reconfigured: [IndexPath] = []
    func reset() { fullReloads = 0; replacedSections = []; reconfigured = [] }
    override func reloadData() { fullReloads += 1; super.reloadData() }
    override func reloadSections(_ sections: IndexSet, with animation: UITableView.RowAnimation) {
        replacedSections.append(contentsOf: sections)
        super.reloadSections(sections, with: animation)
    }
    override func reconfigureRows(at indexPaths: [IndexPath]) {
        reconfigured += indexPaths
        super.reconfigureRows(at: indexPaths)
    }
}
