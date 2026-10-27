import XCTest
import UIKit
@testable import SettingsController

@MainActor
final class NavigationTitleStyleTests: XCTestCase {

    func testPlainDestinationUsesCompactTitle() {
        let destination = UIViewController()
        destination.navigationItem.largeTitleDisplayMode = .always

        SettingsNavigationTitleStyle.applyCompactTitles(to: destination)

        XCTAssertEqual(destination.navigationItem.largeTitleDisplayMode, .never)
    }

    func testCustomNavigationControllerAndItsStackUseCompactTitles() {
        let root = UIViewController()
        let child = UIViewController()
        root.navigationItem.largeTitleDisplayMode = .always
        child.navigationItem.largeTitleDisplayMode = .always

        let navigation = UINavigationController(rootViewController: root)
        navigation.pushViewController(child, animated: false)
        navigation.navigationBar.prefersLargeTitles = true

        SettingsNavigationTitleStyle.applyCompactTitles(to: navigation)

        XCTAssertEqual(navigation.navigationItem.largeTitleDisplayMode, .never)
        XCTAssertFalse(navigation.navigationBar.prefersLargeTitles)
        XCTAssertEqual(root.navigationItem.largeTitleDisplayMode, .never)
        XCTAssertEqual(child.navigationItem.largeTitleDisplayMode, .never)
    }

    func testMainSettingsControllerPreservesLargeTitle() {
        let settings = SettingsController(configuration: SettingsConfiguration(sections: []))
        let navigation = UINavigationController(rootViewController: settings)
        settings.loadViewIfNeeded()

        XCTAssertEqual(settings.navigationItem.largeTitleDisplayMode, .automatic)
        XCTAssertTrue(navigation.navigationBar.prefersLargeTitles)

        let child = UIViewController()
        SettingsNavigationTitleStyle.applyCompactTitles(to: child)

        XCTAssertEqual(child.navigationItem.largeTitleDisplayMode, .never)
        XCTAssertEqual(settings.navigationItem.largeTitleDisplayMode, .automatic)
        XCTAssertTrue(navigation.navigationBar.prefersLargeTitles)
    }
}
