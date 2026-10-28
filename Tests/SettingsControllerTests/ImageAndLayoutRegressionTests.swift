import XCTest
import UIKit
@testable import SettingsController

@MainActor
final class ImageAndLayoutRegressionTests: XCTestCase {
    func testEmptyDetailScrollViewportExtendsBehindSafeArea() throws {
        let controller = UIViewController()
        controller.view = EmptyStateView(title: "Select", subtitle: "Detail")
        controller.additionalSafeAreaInsets = UIEdgeInsets(top: 40, left: 80, bottom: 60, right: 50)
        let window = mountedWindow(controller)
        defer { window.isHidden = true; window.rootViewController = nil }
        let scroll = try XCTUnwrap(controller.view.subviews.first as? UIScrollView)
        controller.view.layoutIfNeeded()
        XCTAssertEqual(scroll.frame, controller.view.bounds)
        XCTAssertEqual(scroll.contentInsetAdjustmentBehavior, .always)
        let content = try XCTUnwrap(scroll.subviews.first)
        XCTAssertEqual(content.bounds.width, controller.view.safeAreaLayoutGuide.layoutFrame.width, accuracy: 0.5)
        XCTAssertGreaterThan(content.bounds.width, 0)
    }

    func testPremiumPaletteKeepsWhiteTextAndContrastAcrossHostTints() {
        func contrast(_ color: UIColor) -> Double {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
            color.getRed(&r, green: &g, blue: &b, alpha: &a)
            let v = [r, g, b].map { c -> Double in
                let x = Double(c); return x <= 0.04045 ? x / 12.92 : pow((x + 0.055) / 1.055, 2.4)
            }
            return 1.05 / (0.2126 * v[0] + 0.7152 * v[1] + 0.0722 * v[2] + 0.05)
        }
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            for color in [UIColor.systemBlue, .systemIndigo, .white, .yellow, .black] {
                let palette = PremiumCardPalette(color: color, traits: traits)
                XCTAssertTrue(palette.text.isEqual(UIColor.white))
                XCTAssertGreaterThanOrEqual(contrast(palette.base), 5.99)
                XCTAssertGreaterThanOrEqual(contrast(palette.end), 5.99)
            }
        }
    }

    func testNilAndZeroInsetDoNotCollide() throws {
        SettingsIconGenerator.removeAllCachedImages()
        let image = UIImage(systemName: "square.fill")!
        let nilInset = SettingsIcon(image: image, color: .red, inset: nil, cacheIdentifier: "same")
        let zeroInset = SettingsIcon(image: image, color: .red, inset: Inset(0), cacheIdentifier: "same")
        let a = try XCTUnwrap(nilInset.generateSettingsImage())
        let b = try XCTUnwrap(zeroInset.generateSettingsImage())
        XCTAssertFalse(a === b)
        XCTAssertNotEqual(a.pngData(), b.pngData())
        XCTAssertTrue(a === nilInset.generateSettingsImage())
        XCTAssertTrue(b === zeroInset.generateSettingsImage())
    }

    func testSettingsIconRejectsNonfiniteGeometry() {
        let icon = SettingsIcon(image: UIImage(systemName: "star"), color: .blue)
        XCTAssertNil(icon.generateSettingsImage(size: CGSize(width: CGFloat.infinity, height: 30)))
        XCTAssertNil(icon.generateSettingsImage(cornerRadius: .nan))
        let invalid = SettingsIcon(image: UIImage(systemName: "star"), color: .blue, inset: Inset(.infinity))
        XCTAssertNil(invalid.generateSettingsImage())
    }

    func testLargeSourceProducesDestinationSizedBitmap() throws {
        let source = UIGraphicsImageRenderer(size: CGSize(width: 1024, height: 2048)).image { context in
            UIColor.black.setFill(); context.fill(CGRect(x: 0, y: 0, width: 1024, height: 2048))
        }
        let icon = SettingsIcon(image: source, color: .blue, inset: Inset(20))
        let traits = UITraitCollection(displayScale: 2)
        let result = try XCTUnwrap(icon.generateSettingsImage(traitCollection: traits))
        XCTAssertEqual(result.cgImage?.width, 60)
        XCTAssertEqual(result.cgImage?.height, 60)
        XCTAssertEqual(result.scale, 2)
    }

    func testDynamicColorUsesSeparateTraitResults() throws {
        let color = UIColor { $0.userInterfaceStyle == .dark ? .black : .white }
        let icon = SettingsIcon(image: UIImage(systemName: "star.fill"), color: color, cacheIdentifier: "dynamic")
        let light = try XCTUnwrap(icon.generateSettingsImage(traitCollection: UITraitCollection(userInterfaceStyle: .light)))
        let dark = try XCTUnwrap(icon.generateSettingsImage(traitCollection: UITraitCollection(userInterfaceStyle: .dark)))
        XCTAssertNotEqual(light.pngData(), dark.pngData())
    }

    func testLegacyHostingDoesNotAccumulateChildrenOrConstraints() {
        let parent = UIViewController()
        let cell = PremiumCell(style: .default, reuseIdentifier: nil)
        for _ in 0..<30 {
            cell.configure(payload: premiumCard(), parent: parent, forceLegacyHosting: true) {}
            XCTAssertEqual(parent.children.count, 1)
            XCTAssertEqual(cell.contentView.constraints.count, 4)
        }
        let size = cell.systemLayoutSizeFitting(CGSize(width: 320, height: 0), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        XCTAssertGreaterThanOrEqual(size.height, 100)
        cell.prepareForReuse()
        XCTAssertTrue(parent.children.isEmpty)
        XCTAssertTrue(cell.contentView.constraints.isEmpty)
    }

    func testAutomaticAppearanceExplanationBelongsToSwitchSection() {
        let theme = RegressionTheme()
        let controller = AppearanceController(themeStorage: theme, colors: SameColor.allCases, eventHandler: nil)
        controller.loadViewIfNeeded()
        XCTAssertEqual(controller.numberOfSections(in: controller.tableView), 2)
        XCTAssertNotNil(controller.tableView(controller.tableView, titleForFooterInSection: 1))
        theme.autoTheme = false
        XCTAssertEqual(controller.numberOfSections(in: controller.tableView), 3)
        XCTAssertNotNil(controller.tableView(controller.tableView, titleForFooterInSection: 1))
        XCTAssertNil(controller.tableView(controller.tableView, titleForFooterInSection: 2))
    }

    func testRemovedSavedColorDoesNotPreventSelection() {
        let theme = RegressionTheme()
        let provider = RegressionProvider()
        theme.appColorRawValue = "deleted"
        let controller = AppearanceController(themeStorage: theme, colors: SameColor.allCases, eventHandler: provider)
        controller.loadViewIfNeeded()
        controller.tableView(controller.tableView, didSelectRowAt: IndexPath(row: 1, section: 0))
        XCTAssertEqual(theme.appColorRawValue, "second")
        XCTAssertEqual(provider.themeUpdates, 1)
        let first = controller.tableView(controller.tableView, cellForRowAt: IndexPath(row: 0, section: 0))
        let second = controller.tableView(controller.tableView, cellForRowAt: IndexPath(row: 1, section: 0))
        XCTAssertEqual(first.accessoryType, .none)
        XCTAssertEqual(second.accessoryType, .checkmark)
    }

    func testOneCancelledImageWaiterDoesNotCancelSharedLoad() async throws {
        let url = URL(string: "https://fixture.example/\(UUID().uuidString).png")!
        let data = try pngData()
        await FixtureServer.shared.register(url, data: data, hold: true)
        let session = fixtureSession()
        defer { session.invalidateAndCancel() }
        let loader = RemoteImageLoader(session: session)
        let first = Task { try await loader.image(from: url, maxPixelSize: 40, scale: 2) }
        await FixtureServer.shared.waitForRequest(url)
        let second = Task { try await loader.image(from: url, maxPixelSize: 40, scale: 2) }
        // Wait for both consumers to acquire the shared request before cancelling one.
        for _ in 0..<1000 {
            if await loader.activeConsumerCount == 2 { break }
            await Task.yield()
        }
        let consumers = await loader.activeConsumerCount
        XCTAssertEqual(consumers, 2)
        first.cancel()
        await FixtureServer.shared.release(url)
        do { _ = try await first.value; XCTFail("Cancelled waiter must not receive an image") }
        catch { XCTAssertTrue(error is CancellationError) }
        let image = try await second.value
        XCTAssertNotNil(image.cgImage)
        let requests = await FixtureServer.shared.requestCount(url)
        XCTAssertEqual(requests, 1)
    }

    func testLastCancelledImageConsumerReleasesFlightAndCanRetry() async throws {
        let url = URL(string: "https://fixture.example/\(UUID().uuidString).png")!
        await FixtureServer.shared.register(url, data: try pngData(), hold: true)
        let session = fixtureSession()
        defer { session.invalidateAndCancel() }
        let loader = RemoteImageLoader(session: session)
        let first = Task { try await loader.image(from: url, maxPixelSize: 30, scale: 2) }
        await FixtureServer.shared.waitForRequest(url)
        first.cancel()
        for _ in 0..<1000 {
            if await loader.activeRequestCount == 0 { break }
            await Task.yield()
        }
        let active = await loader.activeRequestCount
        XCTAssertEqual(active, 0)
        await FixtureServer.shared.release(url)
        do { _ = try await first.value; XCTFail("Cancelled consumer received image") }
        catch { XCTAssertTrue(error is CancellationError) }
        let image = try await loader.image(from: url, maxPixelSize: 30, scale: 2)
        XCTAssertNotNil(image.cgImage)
        let requests = await FixtureServer.shared.requestCount(url)
        XCTAssertEqual(requests, 2)
    }

    func testImageScaleIsPartOfCacheKeyAndFailuresCanRetry() async throws {
        let url = URL(string: "https://fixture.example/\(UUID().uuidString).png")!
        await FixtureServer.shared.register(url, data: try pngData())
        let session = fixtureSession()
        defer { session.invalidateAndCancel() }
        let loader = RemoteImageLoader(session: session)
        let retina = try await loader.image(from: url, maxPixelSize: 20, scale: 2)
        let standard = try await loader.image(from: url, maxPixelSize: 40, scale: 1)
        XCTAssertEqual(retina.scale, 2)
        XCTAssertEqual(standard.scale, 1)
        let requests = await FixtureServer.shared.requestCount(url)
        XCTAssertEqual(requests, 2)
        let bad = URL(string: "https://fixture.example/\(UUID().uuidString).png")!
        await FixtureServer.shared.register(bad, data: Data(), status: 500)
        do { _ = try await loader.image(from: bad, maxPixelSize: 20, scale: 1); XCTFail("Expected error") }
        catch { XCTAssertEqual((error as? URLError)?.code, .badServerResponse) }
        await FixtureServer.shared.register(bad, data: try pngData())
        let retried = try await loader.image(from: bad, maxPixelSize: 20, scale: 1)
        XCTAssertNotNil(retried.cgImage)
    }

    private func pngData() throws -> Data {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100)).image { context in
            UIColor.blue.setFill(); context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        }
        return try XCTUnwrap(image.pngData())
    }
}

private final class RegressionTheme: ThemeStorage {
    var appColor: UIColor = .blue
    var appColorRawValue = "first"
    var autoTheme = true
    var interfaceStyle = 1
}

private enum SameColor: String, CaseIterable, AppColorType {
    case first, second
    var title: String { rawValue }
    var color: UIColor { .blue }
}
