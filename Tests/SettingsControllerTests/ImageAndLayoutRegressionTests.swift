import XCTest
import UIKit
@testable import SettingsController

@MainActor
final class ImageAndLayoutRegressionTests: XCTestCase {
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
        XCTAssertNil(icon.generateSettingsImage(size: CGSize(width: .infinity, height: 30)))
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
        first.cancel()
        await FixtureServer.shared.release(url)
        do { _ = try await first.value; XCTFail("Cancelled waiter must not receive an image") }
        catch { XCTAssertTrue(error is CancellationError) }
        let image = try await second.value
        XCTAssertNotNil(image.cgImage)
        let requests = await FixtureServer.shared.requestCount(url)
        XCTAssertEqual(requests, 1)
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
