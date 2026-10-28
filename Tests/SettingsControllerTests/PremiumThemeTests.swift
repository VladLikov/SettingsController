import XCTest
import UIKit
@testable import SettingsController

@MainActor
final class PremiumThemeTests: XCTestCase {
    func testAppearanceSelectionUpdatesExistingCardWithoutReopening() throws {
        let theme = TestTheme()
        let card = premiumCard()
        let settings = SettingsController(configuration: SettingsConfiguration(sections: [
            SettingsSection(kind: .premiumCard(card)),
            SettingsSection(kind: .rows([.defaultRow(.appearance(theme: theme, colors: TestColor.allCases))]))
        ]))
        let navigation = UINavigationController(rootViewController: settings)
        settings.loadViewIfNeeded()
        settings.tableView(settings.tableView, didSelectRowAt: IndexPath(row: 0, section: 1))
        let appearance = try XCTUnwrap(navigation.topViewController as? AppearanceController)
        appearance.loadViewIfNeeded()
        appearance.tableView(appearance.tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        guard case .premiumCard(let updated) = settings.sections[0].kind else { return XCTFail("Expected card") }
        XCTAssertEqual(updated.premium.color, UIColor.systemRed)
        XCTAssertEqual(updated.tierTitle, card.tierTitle)
        settings.rebuildSections(reload: false)
        guard case .premiumCard(let rebuilt) = settings.sections[0].kind else { return XCTFail("Expected card") }
        XCTAssertEqual(rebuilt.premium.color, UIColor.systemRed)
    }
    func testNewColorSurvivesPremiumActivationAndRestoration() throws {
        let original = premiumCard()
        let settings = SettingsController(configuration: SettingsConfiguration(sections: [
            SettingsSection(kind: .premiumCard(original))
        ]))
        settings.updatePremiumColor(.systemGreen)
        settings.applyResolvedState(info: nil, premium: true, user: nil, includesAccount: true)
        guard case .rows(let rows) = settings.sections[0].kind,
              case .defaultRow(.premium(let active)) = rows[0] else { return XCTFail("Expected active row") }
        XCTAssertEqual(active.color, UIColor.systemGreen)
        settings.applyResolvedState(info: nil, premium: false, user: nil, includesAccount: true)
        guard case .premiumCard(let restored) = settings.sections[0].kind else { return XCTFail("Expected restored card") }
        XCTAssertEqual(restored.premium.color, UIColor.systemGreen)
        XCTAssertEqual(restored.title, original.title)
        XCTAssertEqual(restored.tierTitle, original.tierTitle)
        XCTAssertEqual(original.premium.color, UIColor.systemBlue)
    }

}

private final class TestTheme: ThemeStorage {
    var appColor: UIColor = .blue
    var appColorRawValue = "blue"
    var autoTheme = true
    var interfaceStyle = 1
}
private enum TestColor: String, CaseIterable, AppColorType {
    case red
    var title: String { rawValue }
    var color: UIColor { .systemRed }
}
