import XCTest
@testable import SettingsController

@MainActor
final class SettingsConfigurationTests: XCTestCase {
    private final class Handler: SettingsControllerDelegate {
        func settingsDidDismiss() {}
        func settingsDidUpdateTheme(_ theme: ThemeStorage) {}
        func settingsDidUpdateTaptic(_ taptic: TapticStorage) {}
        func settingsCurrentUserInfo() async -> UserInfo? { nil }
        func settingsIsPremiumActive() async -> Bool { false }
    }

    private final class WeakHandler {
        weak var value: Handler?
        init(_ value: Handler?) { self.value = value }
    }

    func testAboutRowDoesNotRequireUserID() {
        let row = SettingsRowItem.defaultRow(.about(
            appID: "123",
            privacyURL: URL(string: "https://example.com/privacy")!,
            termsURL: URL(string: "https://example.com/terms")!
        ))

        if case .defaultRow(.about(let appID, _, _)) = row {
            XCTAssertEqual(appID, "123")
        } else {
            XCTFail("Expected About row")
        }
    }

    func testDelegateIsNotRetained() {
        var delegate: Handler? = Handler()
        let configuration = SettingsConfiguration(sections: [], delegate: delegate)
        XCTAssertTrue(configuration.eventHandler === delegate)
        XCTAssertTrue(configuration.dataProvider === delegate)
        delegate = nil
        XCTAssertNil(configuration.eventHandler)
        XCTAssertNil(configuration.dataProvider)
    }

    func testSeparateHandlersAreRetainedUntilConfigurationIsReleased() {
        var handler: Handler? = Handler()
        let reference = WeakHandler(handler)
        var configuration: SettingsConfiguration? = SettingsConfiguration(
            sections: [], eventHandler: handler, dataProvider: handler)
        handler = nil
        XCTAssertNotNil(reference.value)
        XCTAssertTrue(configuration?.eventHandler === reference.value)
        XCTAssertTrue(configuration?.dataProvider === reference.value)
        configuration = nil
        XCTAssertNil(reference.value)
    }

    func testExplicitHandlerOverridesDelegateWithIndependentProviderFallback() {
        let delegate = Handler()
        let handler = Handler()
        let configuration = SettingsConfiguration(
            sections: [], eventHandler: handler, delegate: delegate)
        XCTAssertTrue(configuration.eventHandler === handler)
        XCTAssertTrue(configuration.dataProvider === delegate)
    }
}
