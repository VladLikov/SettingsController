import XCTest
@testable import SettingsController

@MainActor
final class MailInfoResolverTests: XCTestCase {
    private final class ModernProvider: SettingsControllerDataProvider {
        let info: SettingsMailInfo?
        var premiumRequests = 0
        var mailRequests = 0
        init(_ info: SettingsMailInfo?) { self.info = info }
        func settingsCurrentUserInfo() async -> UserInfo? { nil }
        func settingsIsPremiumActive() async -> Bool {
            premiumRequests += 1
            return true
        }
        func settingsMailInfo() async -> SettingsMailInfo? {
            mailRequests += 1
            return info
        }
    }

    private final class LegacyProvider: SettingsControllerDataProvider {
        func settingsCurrentUserInfo() async -> UserInfo? { nil }
        func settingsIsPremiumActive() async -> Bool { true }
    }

    func testModernProviderUsesTypedPremiumWithoutDuplicateLookup() async {
        let provider = ModernProvider(SettingsMailInfo(
            adaptyProfileID: "profile-123",
            productID: "yearly",
            isPremium: false
        ))
        let result = await MailInfoResolver.resolve(provider: provider, fallbackPremium: true)
        XCTAssertEqual(result.info?.adaptyProfileID, "profile-123")
        XCTAssertEqual(result.info?.productID, "yearly")
        XCTAssertEqual(result.isPremium, false)
        XCTAssertEqual(provider.mailRequests, 1)
        XCTAssertEqual(provider.premiumRequests, 0)
    }

    func testMissingPremiumFallsBackToExistingProvider() async {
        let provider = ModernProvider(SettingsMailInfo(adaptyProfileID: "profile"))
        let result = await MailInfoResolver.resolve(provider: provider, fallbackPremium: false)
        XCTAssertEqual(result.info?.adaptyProfileID, "profile")
        XCTAssertEqual(result.isPremium, true)
        XCTAssertEqual(provider.premiumRequests, 1)
    }

    func testLegacyProvidersRemainCompatible() async {
        let result = await MailInfoResolver.resolve(provider: LegacyProvider(), fallbackPremium: false)
        XCTAssertNil(result.info)
        XCTAssertEqual(result.isPremium, true)
    }

    func testNoProviderUsesLegacyFallback() async {
        let result = await MailInfoResolver.resolve(provider: nil, fallbackPremium: nil)
        XCTAssertNil(result.info)
        XCTAssertNil(result.isPremium)
    }
}
