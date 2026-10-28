import XCTest
import UIKit
@testable import SettingsController

@MainActor
final class RoutingRegressionTests: XCTestCase {
    func testCustomActionRevokesLateStoreSuccessWithoutCancellingIndependentLoads() async throws {
        try await verifyCustomActionRevokesStore(fails: false)
    }

    func testCustomActionRevokesLateStoreErrorWithoutCancellingIndependentLoads() async throws {
        try await verifyCustomActionRevokesStore(fails: true)
    }

    private func verifyCustomActionRevokesStore(fails: Bool) async throws {
        let store = ControlledValue<Bool>(), catalog = ControlledValue<[AppItem]>()
        var calls = 0
        let row = SettingsRow(title: "Custom", icon: SettingsIcon(image: nil, color: .blue), action: { path, table, presenter in
            calls += 1
            XCTAssertEqual(path, IndexPath(row: 0, section: 0))
            let settings = presenter as! SettingsController
            XCTAssertTrue(table === settings.tableView)
            // Cancellation must happen before host code executes.
            XCTAssertNil(settings.storeProductTask)
            XCTAssertFalse(settings.appLoadTasks[1]?.isCancelled ?? true)
        })
        let settings = SettingsController(configuration: SettingsConfiguration(sections: [
            SettingsSection(kind: .rows([.row(row)])),
            SettingsSection(kind: .ourApps(developerID: "fixture", limit: 1, excludeAppID: "0"))
        ]))
        settings.needsStateRefresh = false
        settings.fetchApps = { _, _, _ in try await catalog.value() }
        let window = mountedWindow(settings)
        defer { settings.dismiss(animated: false); window.isHidden = true; window.rootViewController = nil }
        await catalog.waitUntilStarted()
        let catalogTask = try XCTUnwrap(settings.appLoadTasks[1])
        let url = URL(string: "https://fixture.example/\(UUID().uuidString).png")!
        let png = try XCTUnwrap(UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).image { c in
            UIColor.red.setFill(); c.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }.pngData())
        await FixtureServer.shared.register(url, data: png, hold: true)
        let session = fixtureSession()
        defer { session.invalidateAndCancel() }
        let loader = RemoteImageLoader(session: session)
        let imageTask = Task { try await loader.image(from: url, maxPixelSize: 8, scale: 1) }
        await FixtureServer.shared.waitForRequest(url)
        let product = UIViewController()
        var externalOpens = 0
        settings.openURL = { _ in externalOpens += 1; return true }
        settings.loadStoreProduct = { _ in
            _ = try await store.value()
            if fails { throw URLError(.notConnectedToInternet) }
            return product
        }
        settings.openApp(1, url: URL(string: "https://apps.apple.com/app/id1")!)
        let stale = try XCTUnwrap(settings.storeProductTask)
        await store.waitUntilStarted()
        settings.tableView(settings.tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        XCTAssertEqual(calls, 1)
        XCTAssertTrue(stale.isCancelled)
        XCTAssertFalse(catalogTask.isCancelled)
        XCTAssertFalse(imageTask.isCancelled)
        let activeImages = await loader.activeConsumerCount
        XCTAssertEqual(activeImages, 1)
        store.complete(.success(true)); await stale.value
        XCTAssertNil(settings.presentedViewController)
        XCTAssertEqual(externalOpens, 0)
        catalog.complete(.success([])); await catalogTask.value
        XCTAssertEqual(settings.catalogStates[1], .empty)
        await FixtureServer.shared.release(url)
        let image = try await imageTask.value
        XCTAssertNotNil(image.cgImage)
        let requests = await FixtureServer.shared.requestCount(url)
        XCTAssertEqual(requests, 1)
    }

    func testLanguageOpensSystemSettingsOnceWithoutNavigationOrProvider() async throws {
        let provider = RegressionProvider()
        let settings = SettingsController(configuration: SettingsConfiguration(sections: [SettingsSection(kind: .rows([.defaultRow(.language)]))], dataProvider: provider))
        let navigation = UINavigationController(rootViewController: settings)
        settings.loadViewIfNeeded()
        let gate = ControlledValue<Bool>()
        var urls: [URL] = []
        settings.openURL = { url in urls.append(url); return (try? await gate.value()) ?? false }
        settings.tableView(settings.tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        settings.tableView(settings.tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        let task = try XCTUnwrap(settings.languageSettingsTask)
        await gate.waitUntilStarted()
        gate.complete(.success(true))
        await task.value
        XCTAssertEqual(urls.map(\.absoluteString), [UIApplication.openSettingsURLString])
        XCTAssertEqual(navigation.viewControllers.count, 1)
        XCTAssertEqual(provider.mailRequests, 0)
        XCTAssertNil(settings.languageSettingsTask)
    }

    func testCustomFactoryIsLazyAndReceivesInjectedDependency() {
        var calls = 0
        let dependency = NSObject()
        let row = SettingsRow(title: "Custom", icon: SettingsIcon(image: nil, color: .blue)) {
            calls += 1
            return DependencyController(dependency)
        }
        let settings = SettingsController(configuration: SettingsConfiguration(sections: [SettingsSection(kind: .rows([.row(row)]))]))
        let navigation = UINavigationController(rootViewController: settings)
        settings.loadViewIfNeeded()
        XCTAssertEqual(calls, 0)
        settings.tableView(settings.tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        XCTAssertEqual(calls, 1)
        XCTAssertTrue((navigation.topViewController as? DependencyController)?.dependency === dependency)
        XCTAssertEqual(navigation.topViewController?.navigationItem.largeTitleDisplayMode, .never)
    }

    func testUserFactoryIsLazyAndOldTypeDestinationStillWorks() {
        var calls = 0
        let settings = SettingsController(configuration: SettingsConfiguration(sections: [SettingsSection(kind: .rows([
            .defaultRow(.user("User", destinationFactory: { calls += 1; return UIViewController() }))
        ]))]))
        let navigation = UINavigationController(rootViewController: settings)
        settings.loadViewIfNeeded()
        XCTAssertEqual(calls, 0)
        settings.tableView(settings.tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        XCTAssertEqual(calls, 1)
        XCTAssertEqual(navigation.viewControllers.count, 2)
        let old = SettingsRow(title: "Old", icon: SettingsIcon(image: nil, color: .blue), destinationControllerType: UIViewController.self)
        XCTAssertNotNil(old.destinationControllerType)
        XCTAssertNil(old.destinationFactory)
    }

    func testCancelledStoreSuccessNeverPresentsOrOpensFallback() async throws {
        let settings = SettingsController(configuration: SettingsConfiguration(sections: []))
        settings.needsStateRefresh = false
        let window = mountedWindow(settings)
        defer { window.isHidden = true; window.rootViewController = nil }
        let gate = ControlledValue<Bool>()
        var opens = 0
        settings.openURL = { _ in opens += 1; return true }
        settings.loadStoreProduct = { _ in _ = try await gate.value(); return UIViewController() }
        settings.openApp(1, url: URL(string: "https://apps.apple.com/app/id1")!)
        let task = try XCTUnwrap(settings.storeProductTask)
        await gate.waitUntilStarted()
        settings.cancelOperations()
        gate.complete(.success(true))
        await task.value
        XCTAssertEqual(opens, 0)
        XCTAssertNil(settings.presentedViewController)
        XCTAssertNil(settings.storeProductTask)
    }

    func testSupersededStoreRequestCannotFallbackOrClearNewTask() async throws {
        let settings = SettingsController(configuration: SettingsConfiguration(sections: []))
        settings.needsStateRefresh = false
        let window = mountedWindow(settings)
        defer { window.isHidden = true; window.rootViewController = nil }
        let a = ControlledValue<Bool>(), b = ControlledValue<Bool>()
        var urls: [URL] = []
        settings.openURL = { urls.append($0); return true }
        settings.loadStoreProduct = { id in _ = try await (id == 1 ? a : b).value(); return nil }
        settings.openApp(1, url: URL(string: "https://apps.apple.com/app/id1")!)
        let old = try XCTUnwrap(settings.storeProductTask)
        await a.waitUntilStarted()
        settings.openApp(2, url: URL(string: "https://apps.apple.com/app/id2")!)
        let latest = try XCTUnwrap(settings.storeProductTask)
        await b.waitUntilStarted()
        a.complete(.success(false))
        await old.value
        XCTAssertTrue(urls.isEmpty)
        XCTAssertNotNil(settings.storeProductTask)
        b.complete(.success(false))
        await latest.value
        XCTAssertEqual(urls.map(\.lastPathComponent), ["id2"])
        XCTAssertNil(settings.storeProductTask)
    }

    func testStoreNetworkCancellationDoesNotBecomeFallback() async throws {
        let settings = SettingsController(configuration: SettingsConfiguration(sections: []))
        settings.needsStateRefresh = false
        let window = mountedWindow(settings)
        defer { window.isHidden = true; window.rootViewController = nil }
        var opens = 0
        settings.openURL = { _ in opens += 1; return true }
        settings.loadStoreProduct = { _ in throw URLError(.cancelled) }
        settings.openApp(1, url: URL(string: "https://apps.apple.com/app/id1")!)
        await settings.storeProductTask?.value
        XCTAssertEqual(opens, 0)
        XCTAssertNil(settings.storeProductTask)
    }

    func testStoreRealErrorFallsBackExactlyOnce() async {
        let settings = SettingsController(configuration: SettingsConfiguration(sections: []))
        settings.needsStateRefresh = false
        let window = mountedWindow(settings)
        defer { window.isHidden = true; window.rootViewController = nil }
        var opens = 0
        settings.openURL = { _ in opens += 1; return true }
        settings.loadStoreProduct = { _ in throw URLError(.notConnectedToInternet) }
        settings.openApp(1, url: URL(string: "https://apps.apple.com/app/id1")!)
        await settings.storeProductTask?.value
        XCTAssertEqual(opens, 1)
    }

    func testSplitDiscardsOnlyPlaceholder() throws {
        let primary = UINavigationController(rootViewController: UIViewController())
        let split = SplitController.makeDefault(for: primary)
        let secondary = split.style == .unspecified ? split.viewControllers[1]
            : try XCTUnwrap(split.viewController(for: .secondary))
        XCTAssertTrue(split.splitViewController(split, collapseSecondary: secondary, onto: primary))
        let actual = UINavigationController(rootViewController: UIViewController())
        XCTAssertFalse(split.splitViewController(split, collapseSecondary: actual, onto: primary))
    }

    func testDivisionMakesNativeColumnsEqualAndRestoresUnfoldedWidths() throws {
        guard #available(iOS 27.1, *) else { throw XCTSkip("Reserved-region column policy requires iOS 27.1; exercised on the Duo runtime.") }
        let split = SplitController.makeDefault(for: UINavigationController(rootViewController: UIViewController()))
        XCTAssertEqual(split.style, .doubleColumn)
        split.traitOverrides.horizontalSizeClass = .regular
        split.preferredPrimaryColumnWidthFraction = 0.31
        split.preferredPrimaryColumnWidth = 300
        split.maximumPrimaryColumnWidth = 350
        split.minimumPrimaryColumnWidth = 220
        split.minimumSecondaryColumnWidth = 300
        split.preferredSecondaryColumnWidthFraction = 0.69
        split.preferredSecondaryColumnWidth = 600
        let secondary = split.viewController(for: .secondary)
        split.applyDivisionLayout(hasActiveDivision: true)
        XCTAssertEqual(split.preferredPrimaryColumnWidthFraction, 0.5)
        XCTAssertEqual(split.preferredSecondaryColumnWidthFraction, 0.5)
        XCTAssertEqual(split.preferredPrimaryColumnWidth, UISplitViewController.automaticDimension)
        XCTAssertGreaterThan(split.maximumPrimaryColumnWidth, 475)
        XCTAssertEqual(split.minimumPrimaryColumnWidth, 0)
        XCTAssertEqual(split.minimumSecondaryColumnWidth, 0)
        split.applyDivisionLayout(hasActiveDivision: true) // Repeated region updates must not overwrite the snapshot.
        split.applyDivisionLayout(hasActiveDivision: false)
        XCTAssertEqual(split.preferredPrimaryColumnWidthFraction, 0.31)
        XCTAssertEqual(split.preferredPrimaryColumnWidth, 300)
        XCTAssertEqual(split.maximumPrimaryColumnWidth, 350)
        XCTAssertEqual(split.minimumPrimaryColumnWidth, 220)
        XCTAssertEqual(split.minimumSecondaryColumnWidth, 300)
        XCTAssertEqual(split.preferredSecondaryColumnWidthFraction, 0.69)
        XCTAssertEqual(split.preferredSecondaryColumnWidth, 600)
        XCTAssertTrue(split.viewController(for: .secondary) === secondary)
    }

    func testModernSplitPreservesSelectedDetailAcrossColumnPolicyChanges() throws {
        guard #available(iOS 27.1, *) else { throw XCTSkip("Column-style Duo policy requires iOS 27.1; exercised on the Duo runtime.") }
        let primary = UINavigationController(rootViewController: UIViewController())
        let split = SplitController.makeDefault(for: primary)
        XCTAssertEqual(split.splitViewController(split, topColumnForCollapsingToProposedTopColumn: .secondary), .primary)
        let detail = UIViewController()
        split.showSettingsDetail(detail)
        let navigation = split.viewController(for: .secondary) as? UINavigationController
        XCTAssertTrue(navigation?.viewControllers.first === detail)
        XCTAssertEqual(navigation?.viewControllers.count, 1)
        XCTAssertEqual(split.splitViewController(split, topColumnForCollapsingToProposedTopColumn: .primary), .secondary)
        split.applyDivisionLayout(hasActiveDivision: true)
        split.applyDivisionLayout(hasActiveDivision: false)
        XCTAssertTrue((split.viewController(for: .secondary) as? UINavigationController)?.viewControllers.first === detail)
        XCTAssertEqual(split.splitViewController(split, displayModeForExpandingToProposedDisplayMode: .secondaryOnly), .oneBesideSecondary)
    }

    func testOverlayRestoresConfiguredBottomInset() {
        let settings = SettingsController(configuration: SettingsConfiguration(insets: SettingsInsets(bottom: 37), sections: []))
        settings.loadViewIfNeeded()
        settings.tableView.contentInset.bottom = 500
        settings.overlayFrame = nil
        settings.updateOverlayInset()
        XCTAssertEqual(settings.tableView.contentInset.bottom, 37)
    }
}

@MainActor
private final class DependencyController: UIViewController {
    let dependency: NSObject
    init(_ dependency: NSObject) { self.dependency = dependency; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("Unused") }
}
