import UIKit
import XCTest

@testable import SettingsController

@MainActor
final class StateRegressionTests: XCTestCase {
    func testStaticRowsNeverRequestAccountOrUser() async {
        let provider = RegressionProvider()
        let settings = SettingsController(
            configuration: SettingsConfiguration(
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
        let settings = SettingsController(
            configuration: SettingsConfiguration(sections: [SettingsSection(kind: .premiumCard(card))], dataProvider: provider))
        provider.info = SettingsMailInfo(userID: "first", isPremium: true)
        await settings.refreshState()
        XCTAssertTrue(settings.isPremium)
        guard case .rows(let rows) = settings.sections[0].kind,
            case .item(.defaultRow(.premium(let active))) = rows[0]
        else { return XCTFail("Expected Active row") }
        XCTAssertTrue(active.isPremium)
        provider.info = SettingsMailInfo(userID: "second", isPremium: false)
        await settings.refreshState()
        XCTAssertFalse(settings.isPremium)
        guard case .premiumCard(let restored) = settings.sections[0].kind else { return XCTFail("Expected restored card") }
        XCTAssertEqual(restored.title, card.title)
        XCTAssertEqual(restored.tierTitle, card.tierTitle)
        XCTAssertEqual(restored.subtitle, card.subtitle)
        XCTAssertEqual(restored.buttonTitle, card.buttonTitle)
        XCTAssertEqual(provider.premiumRequests, 0)
        XCTAssertEqual(settings.currentMailInfo?.userID, "second")
    }

    func testAllPremiumRowsShareResolvedStatus() async {
        let provider = RegressionProvider()
        provider.info = SettingsMailInfo(isPremium: true)
        let payload = PremiumPayload(isPremium: false, color: .blue)
        let settings = SettingsController(
            configuration: SettingsConfiguration(
                sections: [
                    SettingsSection(
                        kind: .rows([
                            .defaultRow(.premium(payload)), .defaultRow(.premium(payload)),
                        ]))
                ], dataProvider: provider))
        await settings.refreshState()
        guard case .rows(let rows) = settings.sections[0].kind else { return XCTFail("Expected rows") }
        for row in rows {
            guard case .item(.defaultRow(.premium(let premium))) = row else { return XCTFail("Expected premium") }
            XCTAssertTrue(premium.isPremium)
        }
        XCTAssertEqual(provider.mailRequests, 1)
    }

    func testNilProfilePreservesSnapshotAndExplicitGuestClearsAvatar() async {
        let provider = RegressionProvider()
        let avatar = UIImage(systemName: "person.fill")!
        let settings = SettingsController(
            configuration: SettingsConfiguration(
                sections: [
                    SettingsSection(
                        kind: .rows([
                            .defaultRow(.user(name: "Initial", avatar: avatar, destination: .controller(UIViewController.self)))
                        ]))
                ], dataProvider: provider))
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
        let first = ControlledValue<SettingsMailInfo?>()
        let second = ControlledValue<SettingsMailInfo?>()
        let provider = RegressionProvider()
        var request = 0
        provider.mailOperation = {
            request += 1
            return try? await (request == 1 ? first : second).value()
        }
        let settings = SettingsController(
            configuration: SettingsConfiguration(sections: [SettingsSection(kind: .premiumCard(premiumCard()))], dataProvider: provider))
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
        let first = ControlledValue<SettingsMailInfo?>()
        let second = ControlledValue<SettingsMailInfo?>()
        let provider = RegressionProvider()
        var request = 0
        provider.mailOperation = {
            request += 1
            return try? await (request == 1 ? first : second).value()
        }
        let settings = SettingsController(
            configuration: SettingsConfiguration(sections: [SettingsSection(kind: .premiumCard(premiumCard()))], dataProvider: provider))
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
        let delayedProvider = RegressionProvider()
        delayedProvider.mailOperation = { try? await gate.value() }
        let freshProvider = RegressionProvider()
        freshProvider.info = SettingsMailInfo(userID: "fresh", isPremium: true)
        let settings = SettingsController(
            configuration: SettingsConfiguration(
                sections: [SettingsSection(kind: .premiumCard(premiumCard()))], dataProvider: freshProvider))
        let about = makeAbout()
        // Finish view setup before attaching a controlled provider, so UIKit
        // cannot start an untracked second account request while this test waits.
        about.loadViewIfNeeded()
        about.dataProvider = delayedProvider
        settings.activeAboutController = about
        about.onAccountUpdate = { [weak settings] info, premium in
            settings?.applyResolvedState(info: info, premium: premium, user: nil, includesAccount: true)
        }
        about.loadAccountInfo()
        let old = try XCTUnwrap(about.accountTask)
        await gate.waitUntilStarted()
        let fresh = try XCTUnwrap(settings.startStateRefresh())
        XCTAssertTrue(old.isCancelled)
        await fresh.value
        XCTAssertEqual(about.userID, "fresh")
        // The old provider deliberately ignores cancellation and responds last.
        gate.complete(.success(SettingsMailInfo(userID: "stale", isPremium: false)))
        await old.value
        XCTAssertTrue(settings.isPremium)
        XCTAssertTrue(about.isPremium)
        XCTAssertEqual(about.userID, "fresh")
        XCTAssertEqual(freshProvider.mailRequests, 1)
        XCTAssertEqual(delayedProvider.mailRequests, 1)
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

@MainActor
final class StateRefreshConcurrencyTests: XCTestCase {
    func testProfileIsRequestedWhileTheAccountRequestIsPending() async throws {
        let mail = ControlledValue<SettingsMailInfo?>()
        let provider = RegressionProvider()
        provider.user = UserInfo(name: "Profile")
        provider.mailOperation = { try? await mail.value() ?? nil }
        let settings = SettingsController(
            configuration: SettingsConfiguration(
                sections: [
                    SettingsSection(kind: .rows([.defaultRow(.user(name: "Initial", destination: .controller(UIViewController.self)))])),
                    SettingsSection(kind: .premiumCard(premiumCard())),
                ], dataProvider: provider))
        let task = try XCTUnwrap(settings.startStateRefresh())
        await mail.waitUntilStarted()
        for _ in 0..<20 where provider.userRequests == 0 { await Task.yield() }
        XCTAssertEqual(provider.userRequests, 1, "The profile must not wait for the account request")
        mail.complete(.success(SettingsMailInfo(userID: "u", isPremium: true)))
        await task.value
        XCTAssertEqual(settings.currentUser?.name, "Profile")
        XCTAssertTrue(settings.isPremium)
    }
}

@MainActor
final class SettingsSectionRendererTests: XCTestCase {
    private let definitions = [
        SettingsSection(kind: .ourApps(developerID: "d", limit: 3, excludeAppID: "0")),
        SettingsSection(kind: .premiumCard(premiumCard())),
        SettingsSection(kind: .rows([.defaultRow(.user(name: "Initial", destination: .controller(UIViewController.self)))])),
    ]

    private func state(_ catalog: AppCatalogState, premium: Bool = false, user: UserInfo? = nil) -> SettingsRenderState {
        SettingsRenderState(catalogStates: [0: catalog], isPremium: premium, premiumColorOverride: nil, currentUser: user)
    }

    func testEmptyCatalogIsHiddenAndIDsKeepConfigurationIndexes() {
        let rendered = SettingsSectionRenderer.render(definitions, state: state(.empty))
        XCTAssertEqual(rendered.ids, [1, 2])
    }

    func testLoadingCatalogUsesTheLastKnownCountForPlaceholders() {
        var loading = state(.loading)
        loading.placeholderCount = { _ in 2 }
        let rendered = SettingsSectionRenderer.render(definitions, state: loading)
        guard case .rows(let rows) = rendered.sections[0].kind else { return XCTFail("Expected rows") }
        XCTAssertEqual(rows.count, 2)
    }

    func testActivePremiumReplacesTheCardAndUserRowShowsTheProfile() {
        let rendered = SettingsSectionRenderer.render(definitions, state: state(.failed, premium: true, user: UserInfo(name: "New")))
        guard case .rows(let premiumRows) = rendered.sections[1].kind, case .item(.defaultRow(.premium(let payload))) = premiumRows[0]
        else {
            return XCTFail("Expected an active premium row")
        }
        XCTAssertTrue(payload.isPremium)
        guard case .rows(let userRows) = rendered.sections[2].kind, case .item(.defaultRow(.user(let name, _, _))) = userRows[0] else {
            return XCTFail("Expected the user row")
        }
        XCTAssertEqual(name, "New")
        guard case .rows(let catalogRows) = rendered.sections[0].kind, case .app(.failed) = catalogRows[0] else {
            return XCTFail("Expected the retry row")
        }
    }
}
