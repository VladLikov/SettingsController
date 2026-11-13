import UIKit
import XCTest

@testable import SettingsController

@MainActor
final class PremiumThemeTests: XCTestCase {
    func testAppearanceSelectionUpdatesExistingCardWithoutReopening() throws {
        let theme = TestTheme()
        let card = premiumCard()
        let settings = SettingsController(
            configuration: SettingsConfiguration(sections: [
                SettingsSection(kind: .premiumCard(card)),
                SettingsSection(kind: .rows([.defaultRow(.appearance(theme: theme, colors: TestColor.allCases))])),
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
    func testSelectingCurrentAccentColorCanRefreshItsCheckmark() throws {
        let theme = TestTheme()
        theme.appColorID = TestColor.red.rawValue
        let controller = AppearanceController(themeStorage: theme, colors: TestColor.allCases, eventHandler: nil)
        controller.loadViewIfNeeded()

        let selected = IndexPath(row: 0, section: 0)
        controller.tableView(controller.tableView, didSelectRowAt: selected)

        let dataSource = try XCTUnwrap(controller.dataSource)
        let cell = dataSource.tableView(controller.tableView, cellForRowAt: selected)
        XCTAssertEqual(theme.appColorID, TestColor.red.rawValue)
        XCTAssertEqual(cell.accessoryType, .checkmark)
    }

    func testNewColorSurvivesPremiumActivationAndRestoration() throws {
        let original = premiumCard()
        let settings = SettingsController(
            configuration: SettingsConfiguration(sections: [
                SettingsSection(kind: .premiumCard(original))
            ]))
        settings.updatePremiumColor(.systemGreen)
        settings.applyResolvedState(info: nil, premium: true, user: nil, includesAccount: true)
        guard case .rows(let rows) = settings.sections[0].kind,
            case .item(.defaultRow(.premium(let active))) = rows[0]
        else { return XCTFail("Expected active row") }
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
    var appColorID = "blue"
    var followsSystemAppearance = true
    var interfaceStyle = InterfaceStyle.light
}
private enum TestColor: String, CaseIterable, AppColorType {
    case red
    var title: String { rawValue }
    var color: UIColor { .systemRed }
}
