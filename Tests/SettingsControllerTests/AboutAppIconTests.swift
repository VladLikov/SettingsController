import UIKit
import XCTest

@testable import SettingsController

@MainActor
final class AboutAppIconTests: XCTestCase {
    func testLoadsCompiledPNGInsteadOfCatalogIconName() throws {
        let bundle = try makeBundle(info: primaryIcon(name: "AppLock", files: ["AppLock60x60"]))
        try writePNG("AppLock60x60@2x.png", size: 120, in: bundle)
        let image = try XCTUnwrap(AboutAppHeaderView.appIcon(in: bundle))
        XCTAssertEqual(image.cgImage?.width, 120)
    }

    func testCatalogNameAloneDoesNotTriggerNamedImageLoading() throws {
        let bundle = try makeBundle(info: primaryIcon(name: "AppIcon", files: []))
        // Even an image with this name must not be resolved through the asset catalog.
        try writePNG("AppIcon.png", size: 32, in: bundle)
        XCTAssertNil(AboutAppHeaderView.appIcon(in: bundle))
    }

    func testSkipsMissingAndInvalidFilesToLoadEarlierIcon() throws {
        let bundle = try makeBundle(info: primaryIcon(name: "AppIcon", files: ["Small.png", "Invalid", "Missing"]))
        try writePNG("Small.png", size: 32, in: bundle)
        try Data("not an image".utf8).write(to: bundle.bundleURL.appendingPathComponent("Invalid@3x.png"))
        XCTAssertEqual(AboutAppHeaderView.appIcon(in: bundle)?.cgImage?.width, 32)
    }

    func testUsesCurrentDevicesPrimaryIcon() throws {
        var info = primaryIcon(name: "AppIcon", files: ["Phone60x60"])
        info["CFBundleIcons~ipad"] = ["CFBundlePrimaryIcon": ["CFBundleIconFiles": ["Phone60x60", "Tablet76x76"]]]
        let bundle = try makeBundle(info: info)
        try writePNG("Phone60x60@2x.png", size: 120, in: bundle)
        try writePNG("Tablet76x76@2x~ipad.png", size: 152, in: bundle)
        XCTAssertEqual(AboutAppHeaderView.appIcon(in: bundle)?.cgImage?.width, UIDevice.current.userInterfaceIdiom == .pad ? 152 : 120)
    }

    func testIPadFallsBackToPhoneIconWhenTabletFileIsMissing() throws {
        var info = primaryIcon(name: "AppIcon", files: ["Phone"])
        info["CFBundleIcons~ipad"] = ["CFBundlePrimaryIcon": ["CFBundleIconFiles": ["Phone", "MissingTablet"]]]
        let bundle = try makeBundle(info: info)
        try writePNG("Phone@2x.png", size: 120, in: bundle)
        XCTAssertNotNil(AboutAppHeaderView.appIcon(in: bundle))
    }

    func testLegacyExplicitFilenameAndMissingMetadata() throws {
        let legacy = try makeBundle(info: ["CFBundleIconFiles": ["Legacy@2x.png"]])
        try writePNG("Legacy@2x.png", size: 64, in: legacy)
        XCTAssertNotNil(AboutAppHeaderView.appIcon(in: legacy))
        XCTAssertNil(AboutAppHeaderView.appIcon(in: try makeBundle(info: [:])))
    }

    func testMissingRasterStillBuildsHeaderWithPlaceholder() throws {
        let bundle = try makeBundle(info: primaryIcon(name: "LayeredIcon", files: ["Missing"]))
        let header = AboutAppHeaderView(
            icon: AboutAppHeaderView.appIcon(in: bundle), name: "Example", version: "1.0", bundleID: "test.example")
        let stack = try XCTUnwrap(header.subviews.first as? UIStackView)
        let icon = try XCTUnwrap(stack.arrangedSubviews.first as? UIImageView)
        XCTAssertNotNil(icon.image)
    }

    private func primaryIcon(name: String, files: [String]) -> [String: Any] {
        ["CFBundleIcons": ["CFBundlePrimaryIcon": ["CFBundleIconName": name, "CFBundleIconFiles": files]]]
    }

    private func makeBundle(info: [String: Any]) throws -> Bundle {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".bundle")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock { try FileManager.default.removeItem(at: url) }
        var info = info
        info["CFBundleIdentifier"] = "test.icons." + UUID().uuidString
        let data = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
        try data.write(to: url.appendingPathComponent("Info.plist"))
        return try XCTUnwrap(Bundle(url: url))
    }

    private func writePNG(_ name: String, size: CGFloat, in bundle: Bundle) throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: size, height: size), format: format).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: size, height: size))
        }
        try XCTUnwrap(image.pngData()).write(to: bundle.bundleURL.appendingPathComponent(name))
    }
}
