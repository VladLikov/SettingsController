import XCTest
@testable import SettingsController

@MainActor
final class MailBuilderTests: XCTestCase {
    func testProductIDIsIncludedForEveryMailType() throws {
        let configuration = SettingsConfiguration(sections: [], productID: "com.example.premium.monthly")
        let types: [MailType] = [
            .supportRequest,
            .languageRequest,
            .custom(placeholder: "Message", minCharactersCount: 1, navigationTitle: "Contact", subject: "Question")
        ]

        for type in types {
            let url = MailBuilder.buildMail(
                with: "Please help",
                recipient: "support@example.com",
                type: type,
                userID: "user-456",
                isPremium: true,
                productID: configuration.productID
            )
            let body = try mailBody(from: url)
            XCTAssertTrue(body.contains("User ID: user-456\nProduct ID: com.example.premium.monthly\nPro Status: true"))
            XCTAssertTrue(body.contains("Please help"))
            XCTAssertFalse(body.contains("Adapty Profile ID:"))
            XCTAssertFalse(body.contains("Device Name:"))
            XCTAssertTrue(body.contains("Device Model: "))
            XCTAssertTrue(body.contains("Device Type: "))
            XCTAssertTrue(body.contains("\nSystem Language: "))
            XCTAssertTrue(body.contains("\nApp Language: "))
            XCTAssertTrue(body.contains("\nApp Region: "))
            XCTAssertFalse(body.contains("Subscription ID:"))
        }
    }

    func testMissingProductIDUsesPlaceholderWithExistingArguments() throws {
        XCTAssertNil(SettingsConfiguration(sections: []).productID)
        let url = MailBuilder.buildMail(
            with: "Please help",
            recipient: "support@example.com",
            type: .supportRequest,
            userID: nil,
            isPremium: false
        )
        let body = try mailBody(from: url)
        XCTAssertTrue(body.contains("Product ID: -"))
        XCTAssertTrue(body.contains("Pro Status: false"))
    }

    func testTypedMailInfoOverridesOldValuesForEveryMailType() throws {
        let types: [MailType] = [
            .supportRequest,
            .languageRequest,
            .custom(placeholder: "Custom", minCharactersCount: 1, navigationTitle: "Contact", subject: "Question")
        ]
        for type in types {
            let url = MailBuilder.buildMail(
                with: "Help",
                recipient: "support@example.com",
                type: type,
                userID: "user-1",
                isPremium: true,
                productID: "old",
                mailInfo: SettingsMailInfo(productID: "new", isPremium: false)
            )
            let body = try mailBody(from: url)
            XCTAssertTrue(body.contains("User ID: user-1"))
            XCTAssertFalse(body.contains("Adapty Profile ID:"))
            XCTAssertTrue(body.contains("Product ID: new"))
            XCTAssertTrue(body.contains("Pro Status: false"))
            XCTAssertFalse(body.contains("Product ID: old"))
        }
    }

    func testPartialInfoUsesLegacyProductAndPremium() throws {
        let url = MailBuilder.buildMail(
            with: "Help", recipient: "support@example.com",
            type: .supportRequest, userID: nil, isPremium: true,
            productID: "legacy-product",
            mailInfo: SettingsMailInfo()
        )
        let body = try mailBody(from: url)
        XCTAssertTrue(body.contains("User ID: -"))
        XCTAssertFalse(body.contains("Adapty Profile ID:"))
        XCTAssertTrue(body.contains("Product ID: legacy-product"))
        XCTAssertTrue(body.contains("Pro Status: true"))
    }

    func testLegacyAdaptyIDIsNeverPrintedOrUsedAsUserIDFallback() throws {
        let info = SettingsMailInfo(
            adaptyProfileID: "adapty-legacy",
            productID: "premium.annual",
            isPremium: true
        )

        for userID: String? in [nil, "actual-user-id"] {
            let url = MailBuilder.buildMail(
                with: "Please help",
                recipient: "support@example.com",
                type: .supportRequest,
                userID: userID,
                isPremium: false,
                mailInfo: info
            )
            let body = try mailBody(from: url)
            XCTAssertTrue(body.contains("User ID: \\(userID ?? "-")"))
            XCTAssertFalse(body.contains("adapty-legacy"))
            XCTAssertFalse(body.contains("Adapty Profile ID:"))
            XCTAssertTrue(body.contains("Product ID: premium.annual"))
        }
    }

    private func mailBody(from url: String) throws -> String {
        let components = try XCTUnwrap(URLComponents(string: url))
        return try XCTUnwrap(components.queryItems?.first { $0.name == "body" }?.value)
    }
}
