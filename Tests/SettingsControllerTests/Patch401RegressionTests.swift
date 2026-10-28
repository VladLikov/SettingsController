import XCTest
import UIKit
import SafariServices
@testable import SettingsController

@MainActor
final class Patch401RegressionTests: XCTestCase {
    func testAnonymousIconIdentitySurvivesCopyWithoutRetainingReleasedSource() throws {
        SettingsIconGenerator.removeAllCachedImages()
        defer { SettingsIconGenerator.removeAllCachedImages() }
        weak var sourceReference: UIImage?
        var previousTile: UIImage?
        autoreleasepool {
            let source = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100)).image { c in
                UIColor.red.setFill(); c.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
            }
            sourceReference = source
            let definition = SettingsIcon(image: source, color: .blue)
            let copied = definition
            previousTile = definition.generateSettingsImage()
            XCTAssertTrue(previousTile === copied.generateSettingsImage())
        }
        XCTAssertNil(sourceReference)
        XCTAssertNotNil(previousTile)
        let next = SettingsIcon(image: UIImage(systemName: "circle.fill"), color: .blue)
        XCTAssertFalse(previousTile === next.generateSettingsImage())
        XCTAssertTrue(next.generateSettingsImage() === next.generateSettingsImage())
    }

    func testExplicitIconRevisionAndSymbolIdentityRemainStable() throws {
        SettingsIconGenerator.removeAllCachedImages()
        let source = UIImage(systemName: "star.fill")!
        let first = SettingsIcon(image: source, color: .blue, cacheIdentifier: "brand:v1")
        let same = SettingsIcon(image: source, color: .blue, cacheIdentifier: "brand:v1")
        let revised = SettingsIcon(image: source, color: .blue, cacheIdentifier: "brand:v2")
        XCTAssertTrue(first.generateSettingsImage() === same.generateSettingsImage())
        XCTAssertFalse(first.generateSettingsImage() === revised.generateSettingsImage())
        XCTAssertTrue(SettingsIconGenerator.generate(systemName: "star.fill", backgroundColor: .blue)
            === SettingsIconGenerator.generate(systemName: "star.fill", backgroundColor: .blue))
    }

    private func wideSettings() throws -> (UIWindow, SplitController, SettingsController) {
        let settings = SettingsController(configuration: SettingsConfiguration(sections: []))
        settings.needsStateRefresh = false
        let split = SplitController.makeDefault(for: UINavigationController(rootViewController: settings))
        let window: UIWindow
        if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
            window = UIWindow(windowScene: scene)
        } else { window = UIWindow(frame: UIScreen.main.bounds) }
        window.rootViewController = split; window.makeKeyAndVisible()
        split.loadViewIfNeeded(); split.view.layoutIfNeeded()
        guard !split.isCollapsed, settings.view.window != nil else {
            window.isHidden = true; window.rootViewController = nil
            throw XCTSkip("Requires a genuinely expanded primary/secondary split; covered on iPad")
        }
        return (window, split, settings)
    }

    func testNewSplitDetailRevokesLateStoreSuccessAndErrorWithoutCancellingCatalogs() async throws {
        for fails in [false, true] {
            let (window, split, settings) = try wideSettings()
            defer { settings.dismiss(animated: false); window.isHidden = true; window.rootViewController = nil }
            let gate = ControlledValue<Bool>()
            let product = UIViewController()
            var opens = 0
            settings.openURL = { _ in opens += 1; return true }
            settings.loadStoreProduct = { _ in
                _ = try await gate.value()
                if fails { throw URLError(.notConnectedToInternet) }
                return product
            }
            let catalog = Task { @MainActor in await Task.yield() }
            settings.appLoadTasks[99] = catalog
            settings.openApp(1, url: URL(string: "https://apps.apple.com/app/id1")!)
            let task = try XCTUnwrap(settings.storeProductTask)
            await gate.waitUntilStarted()
            let detail = UIViewController()
            settings.pushViewController(detail, navigationTitle: "New detail")
            XCTAssertFalse(split.isCollapsed)
            XCTAssertNotNil(settings.view.window)
            XCTAssertTrue((split.viewController(for: .secondary) as? UINavigationController)?.viewControllers.first === detail)
            XCTAssertTrue(task.isCancelled)
            XCTAssertNotNil(settings.appLoadTasks[99])
            XCTAssertFalse(catalog.isCancelled)
            gate.complete(.success(true)); await task.value
            XCTAssertEqual(opens, 0)
            XCTAssertNil(settings.presentedViewController)
            XCTAssertNil(settings.storeProductTask)
        }
    }

    func testOrdinaryLateStoreSuccessStillPresentsOnce() async throws {
        let settings = SettingsController(configuration: SettingsConfiguration(sections: []))
        let window = mountedWindow(settings)
        defer { settings.dismiss(animated: false); window.isHidden = true; window.rootViewController = nil }
        let gate = ControlledValue<Bool>(), product = UIViewController()
        settings.loadStoreProduct = { _ in _ = try await gate.value(); return product }
        settings.openApp(1, url: URL(string: "https://apps.apple.com/app/id1")!)
        let task = try XCTUnwrap(settings.storeProductTask)
        await gate.waitUntilStarted(); gate.complete(.success(true)); await task.value
        XCTAssertTrue(settings.presentedViewController === product)
        XCTAssertNil(settings.storeProductTask)
    }

    func testCustomMinimumIsSafeForEveryIntAndUsesGraphemes() throws {
        for (minimum, text, enabled) in [
            (Int.min, "", true), (-1, "", true), (0, "", true), (1, "", false),
            (1, "👨‍👩‍👧‍👦", true), (2, "👨‍👩‍👧‍👦", false),
            (1, "e\u{301}", true), (2, "e\u{301}\n", true),
            (10, "123456789", false), (10, "1234567890", true), (Int.max, "message", false)
        ] {
            let type = MailType.custom(placeholder: "", minCharactersCount: minimum, navigationTitle: "Test", subject: "Test")
            let mail = MailController(type: type, email: "support@example.com")
            mail.loadViewIfNeeded()
            let send = try XCTUnwrap(mail.navigationItem.rightBarButtonItem)
            XCTAssertEqual(send.isEnabled, max(0, minimum) == 0)
            mail.mailCell(MailCell(style: .default, reuseIdentifier: nil), didChangeText: text, needsHeightUpdate: false)
            XCTAssertEqual(send.isEnabled, enabled)
        }
        XCTAssertEqual(MailType.supportRequest.minCharactersCount, 10)
        XCTAssertEqual(MailType.languageRequest.minCharactersCount, 2)
    }

    func testZeroMinimumCannotSendTwiceWhilePendingAndRestoresAfterCancel() async throws {
        let gate = ControlledValue<SettingsMailInfo?>(), provider = RegressionProvider()
        provider.mailOperation = { try? await gate.value() }
        let mail = MailController(type: .custom(placeholder: "", minCharactersCount: 0, navigationTitle: "Test", subject: "Test"),
                                  email: "support@example.com", dataProvider: provider)
        let window = mountedWindow(mail)
        defer { window.isHidden = true; window.rootViewController = nil }
        let send = try XCTUnwrap(mail.navigationItem.rightBarButtonItem)
        var opens = 0; mail.openURL = { _ in opens += 1; return true }
        XCTAssertTrue(send.isEnabled)
        mail.prepareMail(); let task = try XCTUnwrap(mail.mailTask)
        await gate.waitUntilStarted()
        XCTAssertFalse(send.isEnabled)
        mail.prepareMail(); XCTAssertEqual(provider.mailRequests, 1)
        mail.cancelMailPreparation(); XCTAssertTrue(send.isEnabled)
        gate.complete(.success(nil)); await task.value
        XCTAssertEqual(opens, 0)
    }

    func testEditingPendingMailRevokesOldSnapshotAndFreshSendUsesNewText() async throws {
        let gate = ControlledValue<SettingsMailInfo?>(), provider = RegressionProvider()
        provider.mailOperation = { try? await gate.value() }
        let mail = MailController(type: .supportRequest, email: "support@example.com", dataProvider: provider)
        let window = mountedWindow(mail)
        defer { window.isHidden = true; window.rootViewController = nil }
        var opened: [URL] = []; mail.openURL = { opened.append($0); return true }
        let cell = MailCell(style: .default, reuseIdentifier: nil)
        mail.mailCell(cell, didChangeText: "Original message before waiting", needsHeightUpdate: false)
        mail.prepareMail(); let stale = try XCTUnwrap(mail.mailTask)
        await gate.waitUntilStarted()
        mail.mailCell(cell, didChangeText: "Edited message while waiting", needsHeightUpdate: false)
        XCTAssertTrue(stale.isCancelled)
        XCTAssertTrue(mail.navigationItem.rightBarButtonItem?.isEnabled == true)
        gate.complete(.success(nil)); await stale.value
        XCTAssertTrue(opened.isEmpty)
        provider.mailOperation = nil
        mail.prepareMail(); await mail.mailTask?.value
        let url = try XCTUnwrap(opened.first)
        let body = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "body" })?.value)
        XCTAssertEqual(opened.count, 1)
        XCTAssertTrue(body.contains("Edited message while waiting"))
        XCTAssertFalse(body.contains("Original message before waiting"))
    }

    func testSafariValidationPreservesValidURLComponents() throws {
        for value in ["https://example.com/a?x=1%2B2&y=a%26b#fragment", "HTTP://example.com/a?x=1#f", "https://пример.рф/путь?q=тест"] {
            let input = try XCTUnwrap(URL(string: value))
            let valid = try XCTUnwrap(AboutAppController.validatedWebURL(input))
            XCTAssertTrue(["http", "https"].contains(valid.scheme ?? ""))
            XCTAssertEqual(valid.host, input.host)
            XCTAssertEqual(valid.query, input.query)
            XCTAssertEqual(valid.fragment, input.fragment)
        }
    }

    func testInvalidSafariRouteShowsAlertWithoutCreatingSafariOrOpeningExternally() throws {
        for value in ["/privacy", "file:///tmp/privacy", "mailto:support@example.com", "javascript:alert(1)", "custom://privacy", "https://"] {
            let url = try XCTUnwrap(URL(string: value))
            XCTAssertNil(AboutAppController.validatedWebURL(url))
            let about = AboutAppController(isPremium: false, userID: nil, appID: "1", privacyURL: url,
                                           termsURL: URL(string: "https://example.com/terms")!)
            let window = mountedWindow(about)
            defer { about.dismiss(animated: false); window.isHidden = true; window.rootViewController = nil }
            var opens = 0; about.openURL = { _ in opens += 1; return true }
            about.tableView(about.tableView, didSelectRowAt: IndexPath(row: 0, section: 1))
            XCTAssertTrue(about.presentedViewController is UIAlertController)
            XCTAssertFalse(about.presentedViewController is SFSafariViewController)
            XCTAssertEqual(opens, 0)
        }
    }

    func testAccessibilityPrimaryWidthRestoresAndNeverOverridesDivision() throws {
        guard #available(iOS 27.1, *) else { throw XCTSkip("Combined accessibility/division policy requires 27.1; covered on Duo") }
        let split = SplitController.makeDefault(for: UINavigationController(rootViewController: UIViewController()))
        split.traitOverrides.horizontalSizeClass = .regular
        split.preferredPrimaryColumnWidthFraction = 0.31
        split.maximumPrimaryColumnWidth = 350
        split.traitOverrides.preferredContentSizeCategory = .accessibilityExtraExtraExtraLarge
        split.updateAccessibilityColumnWidth()
        XCTAssertEqual(split.preferredPrimaryColumnWidthFraction, 0.45)
        split.applyDivisionLayout(hasActiveDivision: true)
        XCTAssertEqual(split.preferredPrimaryColumnWidthFraction, 0.5)
        split.updateAccessibilityColumnWidth()
        XCTAssertEqual(split.preferredPrimaryColumnWidthFraction, 0.5)
        split.applyDivisionLayout(hasActiveDivision: false)
        XCTAssertEqual(split.preferredPrimaryColumnWidthFraction, 0.45)
        split.traitOverrides.preferredContentSizeCategory = .large
        split.updateAccessibilityColumnWidth()
        XCTAssertEqual(split.preferredPrimaryColumnWidthFraction, 0.31)
        XCTAssertEqual(split.maximumPrimaryColumnWidth, 350)
    }
}
