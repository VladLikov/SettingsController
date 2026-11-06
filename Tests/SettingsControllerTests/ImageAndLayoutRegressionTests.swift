import UIKit
import XCTest

@testable import SettingsController

@MainActor
final class ImageAndLayoutRegressionTests: XCTestCase {
    func testEmptyDetailScrollViewportExtendsBehindSafeArea() throws {
        let controller = UIViewController()
        controller.view = EmptyStateView(title: "Select", subtitle: "Detail")
        controller.additionalSafeAreaInsets = UIEdgeInsets(top: 40, left: 80, bottom: 60, right: 50)
        let window = mountedWindow(controller)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        let scroll = try XCTUnwrap(controller.view.subviews.first as? UIScrollView)
        controller.view.layoutIfNeeded()
        XCTAssertEqual(scroll.frame, controller.view.bounds)
        XCTAssertEqual(scroll.contentInsetAdjustmentBehavior, .always)
        let content = try XCTUnwrap(scroll.subviews.first)
        XCTAssertEqual(content.bounds.width, controller.view.safeAreaLayoutGuide.layoutFrame.width, accuracy: 0.5)
        XCTAssertGreaterThan(content.bounds.width, 0)
    }

    func testPremiumPaletteKeepsWhiteTextReadableForEveryAccent() {
        let accents: [UIColor] = AppColor.allCases.map(\.color) + [.white, .black, .yellow]
        for style in [UIUserInterfaceStyle.light, .dark] {
            for contrast in [UIAccessibilityContrast.normal, .high] {
                let traits = UITraitCollection(traitsFrom: [
                    UITraitCollection(userInterfaceStyle: style), UITraitCollection(accessibilityContrast: contrast),
                ])
                let minimum = contrast == .high ? 7.0 : 4.5
                for accent in accents {
                    let palette = PremiumCardPalette(color: accent, traits: traits)
                    XCTAssertTrue(palette.text.isEqual(UIColor.white))
                    let end = rgb(palette.end)
                    let start = rgb(palette.start)
                    let underControl = end.map { $0 + (1 - $0) * PremiumCardPalette.controlFillOpacity }
                    for (name, color) in [("end", end), ("start", start), ("under CTA", underControl)] {
                        XCTAssertGreaterThanOrEqual(
                            PremiumCardPalette.whiteContrast(color), minimum - 0.01, "\(accent) \(style.rawValue) \(name)")
                    }
                    XCTAssertLessThanOrEqual(start.reduce(0, +), end.reduce(0, +), "The gradient starts deeper than it ends")
                }
            }
        }
    }

    func testPremiumPaletteKeepsTheAccentHue() {
        for accent in AppColor.allCases where accent != .gray {
            let palette = PremiumCardPalette(color: accent.color, traits: UITraitCollection(userInterfaceStyle: .light))
            var original: CGFloat = 0
            var shaded: CGFloat = 0
            accent.color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
                .getHue(&original, saturation: nil, brightness: nil, alpha: nil)
            palette.end.getHue(&shaded, saturation: nil, brightness: nil, alpha: nil)
            let difference = min(abs(original - shaded), 1 - abs(original - shaded))
            XCTAssertLessThan(difference, 0.01, "\(accent) keeps its hue")
        }
    }

    private func rgb(_ color: UIColor) -> [CGFloat] {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return [r, g, b]
    }

    func testNilAndZeroInsetDoNotCollide() throws {
        SettingsIconGenerator.removeAllCachedImages()
        let image = UIImage(systemName: "square.fill")!
        let nilInset = SettingsIcon(image: image, color: .red, padding: nil, cacheIdentifier: "same")
        let zeroInset = SettingsIcon(image: image, color: .red, padding: IconPadding(0), cacheIdentifier: "same")
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
        let invalid = SettingsIcon(image: UIImage(systemName: "star"), color: .blue, padding: IconPadding(.infinity))
        XCTAssertNil(invalid.generateSettingsImage())
    }

    func testLargeSourceProducesDestinationSizedBitmap() throws {
        let source = UIGraphicsImageRenderer(size: CGSize(width: 1024, height: 2048)).image { context in
            UIColor.black.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1024, height: 2048))
        }
        let icon = SettingsIcon(image: source, color: .blue, padding: IconPadding(20))
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
        let size = cell.systemLayoutSizeFitting(
            CGSize(width: 320, height: 0), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        XCTAssertGreaterThanOrEqual(size.height, 72)
        cell.prepareForReuse()
        XCTAssertTrue(parent.children.isEmpty)
        XCTAssertTrue(cell.contentView.constraints.isEmpty)
    }

    func testAutomaticAppearanceExplanationBelongsToSwitchSection() throws {
        let theme = RegressionTheme()
        let controller = AppearanceController(themeStorage: theme, colors: SameColor.allCases, eventHandler: nil)
        let window = mountedWindow(controller)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        XCTAssertEqual(controller.numberOfSections(in: controller.tableView), 2)
        XCTAssertNotNil(controller.tableView(controller.tableView, titleForFooterInSection: 1))
        let toggle = try XCTUnwrap(controller.tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? SwitchCell)
        toggle.switchControl.isOn = false
        for target in toggle.switchControl.allTargets {
            for action in toggle.switchControl.actions(forTarget: target, forControlEvent: .valueChanged) ?? [] {
                _ = (target as NSObject).perform(NSSelectorFromString(action), with: toggle.switchControl)
            }
        }
        XCTAssertFalse(theme.followsSystemAppearance)
        XCTAssertEqual(controller.numberOfSections(in: controller.tableView), 3)
        XCTAssertNotNil(controller.tableView(controller.tableView, titleForFooterInSection: 1))
        XCTAssertNil(controller.tableView(controller.tableView, titleForFooterInSection: 2))
    }

    func testRemovedSavedColorDoesNotPreventSelection() {
        let theme = RegressionTheme()
        let provider = RegressionProvider()
        theme.appColorID = "deleted"
        let controller = AppearanceController(themeStorage: theme, colors: SameColor.allCases, eventHandler: provider)
        controller.loadViewIfNeeded()
        controller.tableView(controller.tableView, didSelectRowAt: IndexPath(row: 1, section: 0))
        XCTAssertEqual(theme.appColorID, "second")
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
        do {
            _ = try await first.value
            XCTFail("Cancelled waiter must not receive an image")
        } catch { XCTAssertTrue(error is CancellationError) }
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
        do {
            _ = try await first.value
            XCTFail("Cancelled consumer received image")
        } catch { XCTAssertTrue(error is CancellationError) }
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
        do {
            _ = try await loader.image(from: bad, maxPixelSize: 20, scale: 1)
            XCTFail("Expected error")
        } catch { XCTAssertEqual((error as? URLError)?.code, .badServerResponse) }
        await FixtureServer.shared.register(bad, data: try pngData())
        let retried = try await loader.image(from: bad, maxPixelSize: 20, scale: 1)
        XCTAssertNotNil(retried.cgImage)
    }

    private func pngData() throws -> Data {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100)).image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        }
        return try XCTUnwrap(image.pngData())
    }
}

private final class RegressionTheme: ThemeStorage {
    var appColorID = "first"
    var followsSystemAppearance = true
    var interfaceStyle = InterfaceStyle.light
}

private enum SameColor: String, CaseIterable, AppColorType {
    case first, second
    var title: String { rawValue }
    var color: UIColor { .blue }
}
