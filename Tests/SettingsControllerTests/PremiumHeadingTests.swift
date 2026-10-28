import XCTest
import SwiftUI
@testable import SettingsController

@MainActor
final class PremiumHeadingTests: XCTestCase {
    func testSeparateBrandAndTierKeepDifferentFontWeightsInOneText() {
        for (name, tier) in [("App Lock", "PRO"), ("Ripples", "Plus"), ("تطبيق", "بلاس")] {
            let card = PremiumCard(title: name, tierTitle: tier, buttonTitle: "Upgrade", color: .blue) {}
            let text = card.headingText
            XCTAssertEqual(String(text.characters), name + " " + tier)
            XCTAssertEqual(card.displayTitle, name + " " + tier)
            let runs = Array(text.runs)
            XCTAssertEqual(runs.count, 2)
            XCTAssertEqual(runs.first?.font, Font.title3.weight(.regular))
            XCTAssertEqual(runs.last?.font, Font.title3.weight(.bold))
        }
    }

    func testTierIsOptionalAndWhitespaceDoesNotCreateAnEmptyBadge() {
        for tier in [nil, "", " \n "] as [String?] {
            let card = PremiumCard(title: "App Lock", tierTitle: tier, buttonTitle: "Upgrade", color: .blue) {}
            XCTAssertNil(card.tierTitle)
            XCTAssertEqual(card.displayTitle, "App Lock")
            XCTAssertEqual(String(card.headingText.characters), "App Lock")
        }
        let card = PremiumCard(title: "", tierTitle: " PRO ", buttonTitle: "Upgrade", color: .blue) {}
        XCTAssertEqual(String(card.headingText.characters), "PRO")
        XCTAssertEqual(card.displayTitle, "PRO")
    }

    func testOldPayloadInitializerSignatureAndNewTierInitializerBothWork() {
        let premium = PremiumPayload(isPremium: false, color: .blue)
        let oldInitializer: (Image, String, String, String, PremiumPayload) -> PremiumCardPayload =
            PremiumCardPayload.init(image:title:subtitle:buttonTitle:premium:)
        let old = oldInitializer(Image(systemName: "star.fill"), "Existing title", "Existing subtitle", "Upgrade", premium)
        XCTAssertNil(old.tierTitle)
        XCTAssertEqual(old.title, "Existing title")
        XCTAssertEqual(old.subtitle, "Existing subtitle")
        let oldView = PremiumCard(image: Image(systemName: "star.fill"), title: "Existing PRO", subtitle: "Existing subtitle",
                                  buttonTitle: "Upgrade", color: .blue) {}
        XCTAssertNil(oldView.tierTitle)
        XCTAssertEqual(String(oldView.headingText.characters), "Existing PRO")
        let new = PremiumCardPayload(title: "App Lock", tierTitle: " PRO ", buttonTitle: "Upgrade", premium: premium)
        XCTAssertEqual(new.tierTitle, "PRO")
        XCTAssertEqual(new.subtitle, "")
    }
}
