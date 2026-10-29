import XCTest
import UIKit
@testable import SettingsController

@MainActor
final class CloseButtonTimingTests: XCTestCase {
    func testModalNavigationInstallsCloseBeforeDidAppear() {
        let settings = SettingsController(configuration: SettingsConfiguration(sections: []))
        let navigation = ModalNavigationController(rootViewController: settings)
        settings.loadViewIfNeeded()
        settings.viewWillAppear(true)
        XCTAssertNotNil(settings.navigationItem.rightBarButtonItem)
        XCTAssertTrue(settings.navigationItem.rightBarButtonItem?.target === settings)
        withExtendedLifetime(navigation) {}
    }

    func testSplitPresentationInstallsCloseBeforeDidAppear() {
        let settings = SettingsController(configuration: SettingsConfiguration(sections: []))
        let root = ModalNavigationController()
        settings.presentationRoot = root
        settings.loadViewIfNeeded()
        settings.viewWillAppear(true)
        XCTAssertNotNil(settings.navigationItem.rightBarButtonItem)
    }

    func testEmbeddedSettingsDoNotGainModalCloseButton() {
        let settings = SettingsController(configuration: SettingsConfiguration(sections: []))
        let navigation = UINavigationController(rootViewController: settings)
        settings.loadViewIfNeeded()
        settings.viewWillAppear(true)
        XCTAssertNil(settings.navigationItem.rightBarButtonItem)
        withExtendedLifetime(navigation) {}
    }
}

@MainActor
private final class ModalNavigationController: UINavigationController {
    private let presenter = UIViewController()
    override var presentingViewController: UIViewController? { presenter }
}
