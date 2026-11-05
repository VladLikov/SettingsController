import SwiftUI
import UIKit
import XCTest

@testable import SettingsController

@MainActor
final class PremiumCellSizingTests: XCTestCase {
    private func makeConfiguration() -> SettingsConfiguration {
        SettingsConfiguration(
            title: "Settings",
            sections: [
                SettingsSection(kind: .premiumCard(premiumCard())),
                SettingsSection(kind: .rows([.defaultRow(.language), .defaultRow(.redeemCode), .defaultRow(.shareApp(appID: "1"))])),
            ])
    }

    private func mount(width: CGFloat = 375) -> (UIWindow, SettingsController) {
        let root = SettingsController.getSplitPresentationSettingsController(configuration: makeConfiguration())
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: 812))
        window.rootViewController = root
        window.makeKeyAndVisible()
        root.view.layoutIfNeeded()
        let navigation = (root as? UISplitViewController)?.viewControllers.first as? UINavigationController
        let settings = navigation?.viewControllers.first as! SettingsController
        settings.tableView.layoutIfNeeded()
        return (window, settings)
    }

    private func report(_ label: String) {
        let ms = PremiumCardSizingStatistics.measurementDuration * 1000
        print("PREMIUM-SIZING \(label) measurements=\(PremiumCardSizingStatistics.measurementCount) total=\(String(format: "%.2f", ms))ms")
        PremiumCardSizingStatistics.reset()
    }

    func testReportSizingWork() {
        PremiumCardSizingStatistics.reset()
        let (window, settings) = mount()
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }
        report("first-open")
        settings.tableView.reloadData()
        settings.tableView.layoutIfNeeded()
        report("reload")
        window.frame.size.width = 390
        window.layoutIfNeeded()
        settings.tableView.layoutIfNeeded()
        report("width-change")
        let (second, _) = mount()
        defer {
            second.isHidden = true
            second.rootViewController = nil
        }
        report("second-open")
    }
}
