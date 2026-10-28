import XCTest
import UIKit
@testable import SettingsController

@MainActor
final class AboutRegressionTests: XCTestCase {
    func testUpdateResultsDistinguishCurrentVersionIncompatibleOSAndAvailableVersion() async throws {
        for (installed, os, expectedTitle, expectedActions) in [
            ("2.0", "27.0", "Latest version is installed", 1),
            ("1.0", "15.0", "Update requires a newer iOS version", 1),
            ("1.0", "27.0", "Update available", 2)
        ] {
            let about = makeAbout()
            let window = mountedWindow(about)
            about.currentVersion = { installed }
            about.currentOSVersion = { os }
            about.loadUpdate = { _ in AppUpdate(version: "2.0", minimumOSVersion: "16.0", url: URL(string: "https://apps.apple.com/app/id1")!) }
            about.checkForUpdate()
            await about.checkUpdateTask?.value
            let alert = try XCTUnwrap(about.presentedViewController as? UIAlertController)
            XCTAssertEqual(alert.title, expectedTitle)
            XCTAssertEqual(alert.actions.count, expectedActions)
            XCTAssertNil(about.checkUpdateTask)
            about.dismiss(animated: false)
            window.isHidden = true
            window.rootViewController = nil
        }
    }

    func testVersionComparisonPadsZeroComponents() {
        XCTAssertEqual(AppUpdateLookup.compare("2.0", "2.0.0"), .orderedSame)
        XCTAssertEqual(AppUpdateLookup.compare("1.9", "1.10"), .orderedAscending)
        XCTAssertEqual(AppUpdateLookup.compare("2", "1.99.9"), .orderedDescending)
        XCTAssertEqual(AppUpdateLookup.compare("1.0.1", "1.0"), .orderedDescending)
    }

    func testUpdateLookupIsSingleFlightAndCancelledSuccessDoesNotPresent() async throws {
        let about = makeAbout()
        let window = mountedWindow(about)
        defer { window.isHidden = true; window.rootViewController = nil }
        about.currentVersion = { "1.0" }
        about.currentOSVersion = { "15.0" }
        let gate = ControlledValue<AppUpdate?>()
        about.loadUpdate = { _ in try await gate.value() }
        about.checkForUpdate()
        let task = try XCTUnwrap(about.checkUpdateTask)
        about.checkForUpdate()
        await gate.waitUntilStarted()
        let path = IndexPath(row: 2, section: 0)
        let cell = try XCTUnwrap(about.tableView.cellForRow(at: path))
        let indicator = try XCTUnwrap(cell.accessoryView as? UIActivityIndicatorView)
        XCTAssertTrue(indicator.isAnimating)
        XCTAssertNil((cell.contentConfiguration as? UIListContentConfiguration)?.secondaryText)
        XCTAssertEqual(cell.accessibilityIdentifier, "settings.about.checkUpdate")
        about.cancelRequests()
        XCTAssertNil(cell.accessoryView)
        XCTAssertFalse(indicator.isAnimating)
        gate.complete(.success(AppUpdate(version: "2.0", minimumOSVersion: "15.0", url: URL(string: "https://apps.apple.com/app/id1")!)))
        await task.value
        XCTAssertNil(about.presentedViewController)
        XCTAssertNil(about.checkUpdateTask)
    }

    func testUpdateNetworkFailureShowsRecoverableError() async {
        let about = makeAbout()
        let window = mountedWindow(about)
        defer { window.isHidden = true; window.rootViewController = nil }
        about.currentVersion = { "1.0" }
        about.loadUpdate = { _ in throw URLError(.notConnectedToInternet) }
        about.checkForUpdate()
        await about.checkUpdateTask?.value
        XCTAssertNotNil(about.presentedViewController as? UIAlertController)
        XCTAssertNil(about.checkUpdateTask)
        about.dismiss(animated: false)
    }

    func testAboutNavigationDoesNotWaitForProvider() async throws {
        let gate = ControlledValue<SettingsMailInfo?>()
        let provider = RegressionProvider()
        provider.mailOperation = { try? await gate.value() }
        let settings = SettingsController(configuration: SettingsConfiguration(sections: [], dataProvider: provider))
        let navigation = UINavigationController(rootViewController: settings)
        settings.pushAboutController(appID: "1", privacyURL: URL(string: "https://example.com/privacy")!, termsURL: URL(string: "https://example.com/terms")!, navigationTitle: "About")
        let about = try XCTUnwrap(navigation.topViewController as? AboutAppController)
        about.loadViewIfNeeded()
        let task = try XCTUnwrap(about.accountTask)
        await gate.waitUntilStarted()
        XCTAssertEqual(navigation.viewControllers.count, 2)
        about.cancelRequests()
        gate.complete(.success(SettingsMailInfo(userID: "late", isPremium: true)))
        await task.value
        XCTAssertNil(about.userID)
    }
}
