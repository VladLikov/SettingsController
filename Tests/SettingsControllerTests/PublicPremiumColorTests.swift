import XCTest
import UIKit
import SwiftUI
import SettingsController

@MainActor
final class PublicPremiumColorTests: XCTestCase {
    func testHostCanUpdatePremiumColorThroughPublicAPI() {
        let settings = SettingsController(configuration: SettingsConfiguration(sections: [
            SettingsSection(kind: .premiumCard(PremiumCardPayload(title: "App", tierTitle: "PRO",
                buttonTitle: "Upgrade", premium: PremiumPayload(isPremium: false, color: .blue))))
        ]))
        settings.updatePremiumColor(.systemRed)
        settings.loadViewIfNeeded()
        XCTAssertEqual(settings.numberOfSections(in: settings.tableView), 1)
        XCTAssertEqual(settings.tableView(settings.tableView, numberOfRowsInSection: 0), 1)
        settings.updatePremiumColor(.systemRed)
        settings.updatePremiumColor(.systemGreen)
        XCTAssertEqual(settings.tableView(settings.tableView, numberOfRowsInSection: 0), 1)
    }
}
