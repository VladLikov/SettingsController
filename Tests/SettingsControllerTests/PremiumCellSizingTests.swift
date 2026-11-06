import SwiftUI
import UIKit
import XCTest

@testable import SettingsController

@MainActor
final class PremiumCellSizingTests: XCTestCase {
    override func setUp() async throws {
        PremiumCardHeightCache.removeAll()
        PremiumCardSizingStatistics.reset()
    }

    private func makeConfiguration(card: PremiumCardPayload = premiumCard()) -> SettingsConfiguration {
        SettingsConfiguration(
            title: "Settings",
            sections: [
                SettingsSection(kind: .premiumCard(card)),
                SettingsSection(kind: .rows([.defaultRow(.language), .defaultRow(.redeemCode), .defaultRow(.shareApp(appID: "1"))])),
            ])
    }

    private func mount(width: CGFloat = 375, card: PremiumCardPayload = premiumCard()) -> (UIWindow, SettingsController) {
        let root = SettingsController.makeSplitPresentation(configuration: makeConfiguration(card: card))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: 812))
        // A phone-sized window on an iPad simulator would otherwise expand the split into narrow columns.
        if #available(iOS 17, *) { window.traitOverrides.horizontalSizeClass = .compact }
        window.rootViewController = root
        window.makeKeyAndVisible()
        root.view.layoutIfNeeded()
        let navigation = (root as? UISplitViewController)?.viewControllers.first as? UINavigationController
        let settings = navigation?.viewControllers.first as! SettingsController
        settings.tableView.layoutIfNeeded()
        return (window, settings)
    }

    /// Returns (cell sizing calls, SwiftUI measurements) since the last report.
    private func report(_ label: String) -> (cell: Int, swiftUI: Int) {
        let result = (PremiumCardSizingStatistics.cellSizingCount, PremiumCardSizingStatistics.measurementCount)
        let ms = PremiumCardSizingStatistics.measurementDuration * 1000
        print("PREMIUM-SIZING \(label) cellSizing=\(result.0) measurements=\(result.1) total=\(String(format: "%.2f", ms))ms")
        PremiumCardSizingStatistics.reset()
        return result
    }

    private let horizontalCard = PremiumCardPayload(
        title: "App", tierTitle: "PRO", buttonTitle: "Go",
        premium: PremiumPayload(isPremium: false, color: .systemBlue))

    func testHorizontalCardIsSizedOnceAndLaterPassesUseTheCache() throws {
        let (window, settings) = mount(card: horizontalCard)
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        let cell = try XCTUnwrap(settings.tableView.visibleCells.first { $0 is PremiumCell })
        XCTAssertGreaterThanOrEqual(cell.bounds.height, PremiumCardMetrics.minimumHeight)
        let first = report("horizontal first-open")
        // UIKit asks a self-sizing cell during creation and again while computing row heights;
        // only the first call may run a SwiftUI layout, later calls read the cache.
        XCTAssertLessThanOrEqual(first.cell, 2)
        XCTAssertEqual(first.swiftUI, 1)

        settings.tableView.reloadData()
        settings.tableView.layoutIfNeeded()
        XCTAssertEqual(report("horizontal reload").swiftUI, 0)

        let (second, _) = mount(card: horizontalCard)
        defer {
            second.isHidden = true
            second.rootViewController = nil
        }
        XCTAssertEqual(report("horizontal second-open").swiftUI, 0)

        let (wider, _) = mount(width: 430, card: horizontalCard)
        defer {
            wider.isHidden = true
            wider.rootViewController = nil
        }
        XCTAssertLessThanOrEqual(report("horizontal wider-open").swiftUI, 1, "A new width is measured once")
    }

    func testStackedCardIsMeasuredOnceToo() {
        let (window, _) = mount()  // "Premium Plus" + "Continue" does not fit 343 pt and stacks, as in 4.0.8.
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        let first = report("stacked first-open")
        XCTAssertLessThanOrEqual(first.cell, 2)
        XCTAssertEqual(first.swiftUI, 1, "One layout in the cell, whichever arrangement ViewThatFits picks")
        let (second, _) = mount()
        defer {
            second.isHidden = true
            second.rootViewController = nil
        }
        XCTAssertEqual(report("stacked second-open").swiftUI, 0)
    }

    func testEstimateUsesTheMeasuredHeight() {
        let (window, settings) = mount()
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        let measured = settings.tableView.rectForRow(at: IndexPath(row: 0, section: 0)).height
        let estimate = settings.tableView(settings.tableView, estimatedHeightForRowAt: IndexPath(row: 0, section: 0))
        XCTAssertEqual(estimate, measured, accuracy: 0.5)
    }

    func testHeightCacheIsKeyedByWidthAndTextSize() {
        let payload = premiumCard()
        let large = UITraitCollection(preferredContentSizeCategory: .large)
        let larger = UITraitCollection(preferredContentSizeCategory: .extraExtraLarge)
        PremiumCardHeightCache.store(72, for: payload, width: 343, traits: large)
        XCTAssertEqual(PremiumCardHeightCache.height(for: payload, width: 343, traits: large), 72)
        XCTAssertNil(PremiumCardHeightCache.height(for: payload, width: 361, traits: large))
        XCTAssertNil(PremiumCardHeightCache.height(for: payload, width: 343, traits: larger))
        XCTAssertEqual(PremiumCardHeightCache.estimatedHeight(for: payload, traits: large), 72)
    }
}
