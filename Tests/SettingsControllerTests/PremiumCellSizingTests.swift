import SwiftUI
import UIKit
import XCTest

@testable import SettingsController

@MainActor
final class PremiumCellSizingTests: XCTestCase {
    override func setUp() async throws {
        PremiumCardMeasurer.removeAll()
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
        XCTAssertEqual(report("horizontal wider-open").swiftUI, 0, "A horizontal card's size does not depend on the width")
    }

    func testStackedCardMeasuresTheFitCheckAndItsHeightOnlyOnce() {
        let (window, _) = mount()  // "Premium Plus" + "Continue" does not fit 343 pt and stacks, as in 4.0.8.
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        let first = report("stacked first-open")
        XCTAssertLessThanOrEqual(first.cell, 2)
        XCTAssertEqual(first.swiftUI, 2)
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

    func testTextSizeChangeProducesANewMeasurement() {
        let payload = premiumCard()
        _ = PremiumCardMeasurer.resolve(payload, width: 700, traits: traits(.large))
        PremiumCardSizingStatistics.reset()
        _ = PremiumCardMeasurer.resolve(payload, width: 700, traits: traits(.extraExtraLarge))
        XCTAssertEqual(PremiumCardSizingStatistics.measurementCount, 1)
        _ = PremiumCardMeasurer.resolve(payload, width: 700, traits: traits(.extraExtraLarge))
        XCTAssertEqual(PremiumCardSizingStatistics.measurementCount, 1)
    }

    /// The measured layout must match what `ViewThatFits` renders in 4.0.8 for the same width and text size.
    func testMeasuredHeightMatchesTheAutomaticCard() throws {
        guard #available(iOS 16, *) else { throw XCTSkip("ViewThatFits reference requires iOS 16") }
        let payloads = [
            premiumCard(),
            PremiumCardPayload(
                title: "App Lock", tierTitle: "PRO", buttonTitle: "Get PRO",
                premium: PremiumPayload(isPremium: false, color: .systemIndigo)),
            PremiumCardPayload(
                title: "Unlock every advanced feature", tierTitle: "Premium Plus",
                buttonTitle: "Start free trial now", premium: PremiumPayload(isPremium: false, color: .systemPink)),
        ]
        let categories: [UIContentSizeCategory] = [
            .small, .large, .extraExtraExtraLarge, .accessibilityMedium, .accessibilityExtraExtraExtraLarge,
        ]
        let widths: [CGFloat] = [288, 320, 343, 359, 398, 500, 700]
        var stacked = 0
        var horizontal = 0
        for payload in payloads {
            for category in categories {
                for width in widths {
                    let resolution = PremiumCardMeasurer.resolve(payload, width: width, traits: traits(category))
                    let reference = referenceHeight(payload, width: width, category: category)
                    XCTAssertEqual(
                        resolution.height, reference, accuracy: 1,
                        "\(payload.title) \(category.rawValue) width=\(width) layout=\(resolution.layout)")
                    if resolution.layout == .stacked { stacked += 1 } else { horizontal += 1 }
                }
            }
        }
        XCTAssertGreaterThan(stacked, 0)
        XCTAssertGreaterThan(horizontal, 0)
    }

    private func traits(_ category: UIContentSizeCategory) -> UITraitCollection {
        UITraitCollection(traitsFrom: [
            UITraitCollection(preferredContentSizeCategory: category),
            UITraitCollection(displayScale: 3),
            UITraitCollection(legibilityWeight: .regular),
        ])
    }

    @available(iOS 16, *)
    private func referenceHeight(_ payload: PremiumCardPayload, width: CGFloat, category: UIContentSizeCategory) -> CGFloat {
        let card = PremiumCard(
            image: payload.image, title: payload.title, tierTitle: payload.tierTitle, subtitle: payload.subtitle,
            buttonTitle: payload.buttonTitle, color: payload.premium.color, onTap: {})
        let host = UIHostingController(
            rootView:
                card
                .environment(\.dynamicTypeSize, DynamicTypeSize(category) ?? .large)
                .environment(\.legibilityWeight, .regular)
                .environment(\.displayScale, 3))
        return ceil(host.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude)).height)
    }
}
