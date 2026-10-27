import XCTest
import UIKit
@testable import SettingsController

@MainActor
final class RoutingRegressionTests: XCTestCase {
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

    func testSplitDiscardsOnlyPlaceholder() {
        let primary = UINavigationController(rootViewController: UIViewController())
        let split = SplitController.makeDefault(for: primary)
        XCTAssertTrue(split.splitViewController(split, collapseSecondary: split.viewControllers[1], onto: primary))
        let actual = UINavigationController(rootViewController: UIViewController())
        XCTAssertFalse(split.splitViewController(split, collapseSecondary: actual, onto: primary))
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
