import XCTest
import UIKit
import SwiftUI
@testable import SettingsController

@MainActor
final class ControlledValue<Value: Sendable> {
    private var result: Result<Value, Error>?
    private var continuation: CheckedContinuation<Value, Error>?
    private var startWaiters: [CheckedContinuation<Void, Never>] = []
    private(set) var started = false

    func value() async throws -> Value {
        started = true
        let waiters = startWaiters
        startWaiters.removeAll()
        waiters.forEach { $0.resume() }
        if let result { return try result.get() }
        return try await withCheckedThrowingContinuation { continuation = $0 }
    }

    func waitUntilStarted() async {
        if started { return }
        await withCheckedContinuation { startWaiters.append($0) }
    }

    func complete(_ result: Result<Value, Error>) {
        precondition(self.result == nil, "Complete each controlled response only once")
        self.result = result
        continuation?.resume(with: result)
        continuation = nil
    }
}

@MainActor
final class RegressionProvider: SettingsControllerDelegate {
    var info: SettingsMailInfo?
    var user: UserInfo?
    var fallbackPremium = false
    var mailOperation: (@MainActor () async -> SettingsMailInfo?)?
    var userRequests = 0
    var mailRequests = 0
    var premiumRequests = 0
    var dismissals = 0
    var themeUpdates = 0

    func settingsCurrentUserInfo() async -> UserInfo? { userRequests += 1; return user }
    func settingsIsPremiumActive() async -> Bool { premiumRequests += 1; return fallbackPremium }
    func settingsMailInfo() async -> SettingsMailInfo? {
        mailRequests += 1
        if let mailOperation { return await mailOperation() }
        return info
    }
    func settingsDidDismiss() { dismissals += 1 }
    func settingsDidUpdateTheme(_ theme: ThemeStorage) { themeUpdates += 1 }
    func settingsDidUpdateTaptic(_ taptic: TapticStorage) {}
}

@MainActor
func mountedWindow(_ controller: UIViewController) -> UIWindow {
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    window.rootViewController = controller
    window.makeKeyAndVisible()
    controller.loadViewIfNeeded()
    controller.view.frame = window.bounds
    controller.view.layoutIfNeeded()
    return window
}

@MainActor
func premiumCard() -> PremiumCardPayload {
    PremiumCardPayload(image: Image(systemName: "star.fill"), title: "Premium", subtitle: "All features",
                       buttonTitle: "Continue", premium: PremiumPayload(isPremium: false, color: .systemBlue))
}

@MainActor
func makeAbout() -> AboutAppController {
    AboutAppController(isPremium: false, userID: nil, appID: "1",
                       privacyURL: URL(string: "https://example.com/privacy")!,
                       termsURL: URL(string: "https://example.com/terms")!)
}
