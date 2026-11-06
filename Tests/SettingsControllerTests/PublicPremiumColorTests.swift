import SettingsController
import SwiftUI
import UIKit
import XCTest

@MainActor
final class PublicPremiumColorTests: XCTestCase {
    func testHostCanUpdatePremiumColorThroughPublicAPI() {
        let settings = SettingsController(
            configuration: SettingsConfiguration(sections: [
                SettingsSection(
                    kind: .premiumCard(
                        PremiumCardPayload(
                            title: "App", tierTitle: "PRO",
                            buttonTitle: "Upgrade", premium: PremiumPayload(isPremium: false, color: .blue))))
            ]))
        settings.updatePremiumColor(.systemRed)
        settings.loadViewIfNeeded()
        XCTAssertEqual(settings.tableView.numberOfSections, 1)
        XCTAssertEqual(settings.tableView.numberOfRows(inSection: 0), 1)
        settings.updatePremiumColor(.systemRed)
        settings.updatePremiumColor(.systemGreen)
        XCTAssertEqual(settings.tableView.numberOfRows(inSection: 0), 1)
    }
}
