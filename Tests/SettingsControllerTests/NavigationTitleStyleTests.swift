import XCTest
import UIKit
@testable import SettingsController

@MainActor
final class NavigationTitleStyleTests: XCTestCase {

    func testLibraryPushUsesCompactTitle() {
        let settings = SettingsController(configuration: SettingsConfiguration(sections: []))
        let navigation = UINavigationController(rootViewController: settings)
        settings.loadViewIfNeeded()

        let destination = UIViewController()
        destination.navigationItem.largeTitleDisplayMode = .always

        settings.pushViewController(destination, navigationTitle: "Custom")

        XCTAssertEqual(destination.navigationItem.title, "Custom")
        XCTAssertEqual(destination.navigationItem.largeTitleDisplayMode, .never)
        XCTAssertEqual(settings.navigationItem.largeTitleDisplayMode, .automatic)
        XCTAssertTrue(navigation.navigationBar.prefersLargeTitles)
    }

    func testLibraryPushDisablesLargeTitlesInSuppliedNavigationStack() {
        let root = UIViewController()
        let child = UIViewController()
        root.navigationItem.largeTitleDisplayMode = .always
        child.navigationItem.largeTitleDisplayMode = .always

        let destination = UINavigationController(rootViewController: root)
        destination.setViewControllers([root, child], animated: false)
        destination.navigationBar.prefersLargeTitles = true

        let settings = SettingsController(configuration: SettingsConfiguration(sections: []))
        settings.pushViewController(destination, navigationTitle: "Navigation")

        XCTAssertEqual(destination.navigationItem.largeTitleDisplayMode, .never)
        XCTAssertFalse(destination.navigationBar.prefersLargeTitles)
        XCTAssertEqual(root.navigationItem.largeTitleDisplayMode, .never)
        XCTAssertEqual(child.navigationItem.largeTitleDisplayMode, .never)
    }

    func testPremiumDestinationUsesCompactTitle() throws {
        let settings = SettingsController(configuration: SettingsConfiguration(sections: []))
        PremiumProbeController.lastCreated = nil
        defer { PremiumProbeController.lastCreated = nil }

        let payload = PremiumPayload(
            isPremium: false,
            color: .systemBlue,
            destinationControllerType: PremiumProbeController.self,
            action: nil
        )
        settings.presentPremium(payload)

        let destination = try XCTUnwrap(PremiumProbeController.lastCreated)
        XCTAssertEqual(destination.navigationItem.largeTitleDisplayMode, .never)
    }

    func testMainSettingsControllerKeepsLargeTitle() {
        let settings = SettingsController(configuration: SettingsConfiguration(sections: []))
        let navigation = UINavigationController(rootViewController: settings)
        settings.loadViewIfNeeded()

        XCTAssertEqual(settings.navigationItem.largeTitleDisplayMode, .automatic)
        XCTAssertTrue(navigation.navigationBar.prefersLargeTitles)
    }
}

@MainActor
private final class PremiumProbeController: UIViewController {
    static var lastCreated: PremiumProbeController?

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        Self.lastCreated = self
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        Self.lastCreated = self
    }
}
