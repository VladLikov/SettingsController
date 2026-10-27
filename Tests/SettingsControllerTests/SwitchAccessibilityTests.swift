import XCTest
import UIKit
import SettingsController

@MainActor
final class SwitchAccessibilityTests: XCTestCase {
    func testSwitchHasOneNamedAccessibleControlAndClearsReuseState() {
        let cell = SwitchCell(style: .default, reuseIdentifier: nil)
        var observed: Bool?
        cell.configure(title: "Automatic theme", isOn: true, onTintColor: .blue) { observed = $0 }
        XCTAssertEqual(cell.switchControl.accessibilityLabel, "Automatic theme")
        XCTAssertFalse(cell.isAccessibilityElement)
        XCTAssertEqual(cell.accessibilityElements?.count, 1)
        cell.switchControl.isOn = false
        cell.switchControl.sendActions(for: .valueChanged)
        XCTAssertEqual(observed, false)
        cell.prepareForReuse()
        observed = nil
        XCTAssertNil(cell.switchControl.accessibilityLabel)
        cell.switchControl.sendActions(for: .valueChanged)
        XCTAssertNil(observed)
    }
}
