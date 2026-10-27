import XCTest
import UIKit
@testable import SettingsController

@MainActor
final class StateRegressionTests: XCTestCase {
    func testStaticRowsNeverRequestAccountOrUser() async {
        let provider = RegressionProvider()
        let settings = SettingsController(configuration: SettingsConfiguration(
            sections: [SettingsSection(kind: .rows([.defaultRow(.language)]))], dataProvider: provider))
        await settings.refreshState()
        XCTAssertEqual(provider.mailRequests, 0)
        XCTAssertEqual(provider.premiumRequests, 0)
        XCTAssertEqual(provider.userRequests, 0)
    }

    func testTypedFalseWinsAndCardCanBeRestored() async throws {
        let provider = RegressionProvider()
        provider.fallbackPremium = true
        let card = premiumCard()
        let settings = SettingsController(configuration: SettingsConfiguration(sections: [SettingsSection(kind: .premiumCard(card))], dataProvider: provider))
        provider.info = SettingsMailInfo(userID: "first", isPremium: true)
        await settings.refreshState()
        XCTAssertTrue(settings.isPremium)
        guard case .rows(let rows) = settings.sections[0].kind,
              case .defaultRow(.premium(let active)) = rows[0] else { return XCTFail("Expected Active row") }
        XCTAssertTrue(active.isPremium)
        provider.info = SettingsMailInfo(userID: "second", isPremium: false)
        await settings.refreshState()
        XCTAssertFalse(settings.isPremium)
        guard case .premiumCard(let restored) = settings.sections[0].kind else { return XCTFail("Expected restored card") }
        XCTAssertEqual(restored.title, card.title)
        XCTAssertEqual(restored.subtitle, card.subtitle)
        XCTAssertEqual(restored.buttonTitle, card.buttonTitle)
        XCTAssertEqual(provider.premiumRequests, 0)
        XCTAssertEqual(settings.currentMailInfo?.userID, "second")
    }

    func testAllPremiumRowsShareResolvedStatus() async {
        let provider = RegressionProvider()
        provider.info = SettingsMailInfo(isPremium: true)
        let payload = PremiumPayload(isPremium: false, color: .blue)
        let settings = SettingsController(configuration: SettingsConfiguration(sections: [SettingsSection(kind: .rows([
            .defaultRow(.premium(payload)), .defaultRow(.premium(payload))
        ]))], dataProvider: provider))
        await settings.refreshState()
        guard case .rows(let rows) = settings.sections[0].kind else { return XCTFail("Expected rows") }
        for row in rows {
            guard case .defaultRow(.premium(let premium)) = row else { return XCTFail("Expected premium") }
            XCTAssertTrue(premium.isPremium)
        }
        XCTAssertEqual(provider.mailRequests, 1)
    }

    func testNilProfilePreservesSnapshotAndExplicitGuestClearsAvatar() async {
        let provider = RegressionProvider()
        let avatar = UIImage(systemName: "person.fill")!
        let settings = SettingsController(configuration: SettingsConfiguration(sections: [SettingsSection(kind: .rows([
            .defaultRow(.user("Initial", avatar, UIViewController.self))
        ]))], dataProvider: provider))
        provider.user = UserInfo(name: "Updated", avatar: avatar)
        await settings.refreshState()
        provider.user = nil
        await settings.refreshState()
        XCTAssertEqual(settings.currentUser?.name, "Updated")
        XCTAssertTrue(settings.currentUser?.avatar === avatar)
        provider.user = UserInfo(name: "Guest", avatar: nil)
        await settings.refreshState()
        XCTAssertEqual(settings.currentUser?.name, "Guest")
        XCTAssertNil(settings.currentUser?.avatar)
        XCTAssertEqual(provider.mailRequests, 0)
    }

    func testLatestRefreshWinsWhenOldProviderIgnoresCancellation() async throws {
        let first = ControlledValue<SettingsMailInfo?>(), second = ControlledValue<SettingsMailInfo?>()
        let provider = RegressionProvider()
        var request = 0
        provider.mailOperation = {
            request += 1
            return try? await (request == 1 ? first : second).value()
        }
        let settings = SettingsController(configuration: SettingsConfiguration(sections: [SettingsSection(kind: .premiumCard(premiumCard()))], dataProvider: provider))
        let old = try XCTUnwrap(settings.startStateRefresh())
        await first.waitUntilStarted()
        let latest = try XCTUnwrap(settings.startStateRefresh())
        await second.waitUntilStarted()
        second.complete(.success(SettingsMailInfo(userID: "new", isPremium: true)))
        await latest.value
        first.complete(.success(SettingsMailInfo(userID: "old", isPremium: false)))
        await old.value
        XCTAssertTrue(settings.isPremium)
        XCTAssertEqual(settings.currentMailInfo?.userID, "new")
        XCTAssertNil(settings.stateRefreshTask)
    }

    func testOldCompletionCannotClearNewTaskHandle() async throws {
        let first = ControlledValue<SettingsMailInfo?>(), second = ControlledValue<SettingsMailInfo?>()
        let provider = RegressionProvider()
        var request = 0
        provider.mailOperation = { request += 1; return try? await (request == 1 ? first : second).value() }
        let settings = SettingsController(configuration: SettingsConfiguration(sections: [SettingsSection(kind: .premiumCard(premiumCard()))], dataProvider: provider))
        let old = try XCTUnwrap(settings.startStateRefresh())
        await first.waitUntilStarted()
        let latest = try XCTUnwrap(settings.startStateRefresh())
        await second.waitUntilStarted()
        first.complete(.success(SettingsMailInfo(isPremium: false)))
        await old.value
        XCTAssertNotNil(settings.stateRefreshTask)
        second.complete(.success(SettingsMailInfo(isPremium: true)))
        await latest.value
        XCTAssertNil(settings.stateRefreshTask)
    }

    func testMissingTypedUserIDClearsAboutInsteadOfUsingOldValue() {
        let about = makeAbout()
        about.applyAccountInfo(SettingsMailInfo(userID: "old"), premium: true)
        XCTAssertEqual(about.userID, "old")
        about.applyAccountInfo(nil, premium: false)
        XCTAssertNil(about.userID)
    }

    func testNewRootRefreshInvalidatesPendingAboutAccountResponse() async throws {
        let gate = ControlledValue<SettingsMailInfo?>()
        let provider = RegressionProvider()
        provider.mailOperation = { try? await gate.value() }
        let settings = SettingsController(configuration: SettingsConfiguration(sections: [SettingsSection(kind: .premiumCard(premiumCard()))], dataProvider: provider))
        let about = makeAbout()
        settings.activeAboutController = about
        about.dataProvider = provider
        about.onAccountUpdate = { [weak settings] info, premium in
            settings?.applyResolvedState(info: info, premium: premium, user: nil, includesAccount: true)
        }
        about.loadAccountInfo()
        let old = try XCTUnwrap(about.accountTask)
        await gate.waitUntilStarted()
        provider.mailOperation = nil
        provider.info = SettingsMailInfo(userID: "fresh", isPremium: true)
        await settings.refreshState()
        gate.complete(.success(SettingsMailInfo(userID: "stale", isPremium: false)))
        await old.value
        XCTAssertTrue(settings.isPremium)
        XCTAssertTrue(about.isPremium)
        XCTAssertEqual(about.userID, "fresh")
    }

    func testDismissalNotificationIsExactlyOncePerPresentation() {
        let provider = RegressionProvider()
        let settings = SettingsController(configuration: SettingsConfiguration(sections: [], eventHandler: provider))
        settings.reportDismissal()
        settings.reportDismissal()
        XCTAssertEqual(provider.dismissals, 1)
        settings.beginPresentation()
        settings.reportDismissal()
        XCTAssertEqual(provider.dismissals, 2)
    }
}
