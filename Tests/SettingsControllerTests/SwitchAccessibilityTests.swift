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

        // This Swift-package test has no UIApplicationMain host. Exercise the
        // actual installed target/action directly instead of UIApplication dispatch.
        var targets: [(NSObject, String)] = []
        for target in cell.switchControl.allTargets {
            guard let object = target.base as? NSObject else { continue }
            let actions = cell.switchControl.actions(forTarget: object, forControlEvent: .valueChanged) ?? []
            for action in actions { targets.append((object, action)) }
        }
        XCTAssertEqual(targets.count, 1)
        cell.switchControl.isOn = false
        for (target, action) in targets {
            _ = target.perform(NSSelectorFromString(action), with: cell.switchControl)
        }
        XCTAssertEqual(observed, false)

        cell.prepareForReuse()
        observed = nil
        XCTAssertNil(cell.switchControl.accessibilityLabel)
        for (target, action) in targets {
            _ = target.perform(NSSelectorFromString(action), with: cell.switchControl)
        }
        XCTAssertNil(observed)
    }
}
