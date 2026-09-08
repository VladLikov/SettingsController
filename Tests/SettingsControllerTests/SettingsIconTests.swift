import XCTest
import UIKit
@testable import SettingsController

@MainActor
final class SettingsIconTests: XCTestCase {
    func testIdenticalRenderingReusesCacheAndClearInvalidatesIt() throws {
        SettingsIconGenerator.removeAllCachedImages()
        let icon = SettingsIcon(image: UIImage(systemName: "star.fill"), color: .blue)
        let first = try XCTUnwrap(icon.generateSettingsImage())
        XCTAssertTrue(first === icon.generateSettingsImage())
        SettingsIconGenerator.removeAllCachedImages()
        let next = try XCTUnwrap(icon.generateSettingsImage())
        XCTAssertFalse(first === next)
    }

    func testSizeAndTraitsProduceSeparateImages() throws {
        let icon = SettingsIcon(image: UIImage(systemName: "star.fill"), color: .label)
        let light = UITraitCollection(traitsFrom: [UITraitCollection(userInterfaceStyle: .light), UITraitCollection(displayScale: 2)])
        let dark = UITraitCollection(traitsFrom: [UITraitCollection(userInterfaceStyle: .dark), UITraitCollection(displayScale: 2)])
        let small = try XCTUnwrap(icon.generateSettingsImage(traitCollection: light))
        let large = try XCTUnwrap(icon.generateSettingsImage(size: CGSize(width: 60, height: 60), traitCollection: light))
        let darkImage = try XCTUnwrap(icon.generateSettingsImage(traitCollection: dark))
        XCTAssertEqual(small.size, CGSize(width: 30, height: 30))
        XCTAssertEqual(large.size, CGSize(width: 60, height: 60))
        XCTAssertEqual(small.scale, 2)
        XCTAssertFalse(small === large)
        XCTAssertNotEqual(small.pngData(), darkImage.pngData())
    }

    func testInvalidGeometryAndMissingGlyphReturnNil() {
        let icon = SettingsIcon(image: UIImage(systemName: "star.fill"), color: .blue)
        XCTAssertNil(icon.generateSettingsImage(size: .zero))
        XCTAssertNil(icon.generateSettingsImage(cornerRadius: -1))
        XCTAssertNil(SettingsIcon(image: nil, color: .blue).generateSettingsImage())
    }
}
