import XCTest
@testable import SettingsController

@MainActor
final class MailBuilderTests: XCTestCase {

    private let mailTypes: [MailType] = [
        .supportRequest,
        .languageRequest,
        .custom(
            placeholder: "Custom",
            minCharactersCount: 1,
            navigationTitle: "Contact",
            subject: "Question"
        )
    ]

    func testTypedUserAndPurchaseInfoInEveryMailType() throws {
        let diagnostics = SettingsMailInfo(
            userID: "adapty-user-456",
            productID: "com.example.premium.monthly",
            isPremium: true
        )

        for type in mailTypes {
            let url = MailBuilder.buildMail(
                with: "Please help",
                recipient: "support@example.com",
                type: type,
                isPremium: false,
                productID: "legacy-product",
                mailInfo: diagnostics
            )
            let body = try mailBody(from: url)

            XCTAssertTrue(body.contains(
                "User ID: adapty-user-456\nProduct ID: com.example.premium.monthly\nPro Status: true"
            ))
            XCTAssertFalse(body.contains("Adapty Profile ID:"))
            XCTAssertFalse(body.contains("legacy-product"))
            XCTAssertFalse(body.contains("Device Name:"))
            XCTAssertTrue(body.contains("Device Model: "))
            XCTAssertTrue(body.contains("Device Type: "))
            XCTAssertTrue(body.contains("Preferred Language: "))
            XCTAssertTrue(body.contains("App Language: "))
            XCTAssertTrue(body.contains("App Region: "))
        }
    }

    func testMissingUserIDIsNotInferredFromOtherFields() throws {
        let diagnostics = SettingsMailInfo(productID: "annual", isPremium: true)

        for type in mailTypes {
            let url = MailBuilder.buildMail(
                with: "Help",
                recipient: "support@example.com",
                type: type,
                isPremium: false,
                mailInfo: diagnostics
            )
            let body = try mailBody(from: url)

            XCTAssertTrue(body.contains("User ID: -"))
            XCTAssertTrue(body.contains("Product ID: annual"))
            XCTAssertTrue(body.contains("Pro Status: true"))
            XCTAssertFalse(body.contains("Adapty Profile ID:"))
        }
    }

    func testEmptyInfoUsesLegacyProductAndPremiumFallbacks() throws {
        let config = SettingsConfiguration(sections: [], productID: "legacy.monthly")
        let url = MailBuilder.buildMail(
            with: "Help",
            recipient: "support@example.com",
            type: .supportRequest,
            isPremium: false,
            productID: config.productID,
            mailInfo: SettingsMailInfo()
        )
        let body = try mailBody(from: url)

        XCTAssertTrue(body.contains("User ID: -"))
        XCTAssertTrue(body.contains("Product ID: legacy.monthly"))
        XCTAssertTrue(body.contains("Pro Status: false"))
    }

    func testNoDiagnosticsUsesUnknownPlaceholders() throws {
        let url = MailBuilder.buildMail(
            with: "Help",
            recipient: "support@example.com",
            type: .supportRequest,
            isPremium: nil
        )
        let body = try mailBody(from: url)

        XCTAssertTrue(body.contains("User ID: -"))
        XCTAssertTrue(body.contains("Product ID: -"))
        XCTAssertTrue(body.contains("Pro Status: -"))
    }

    private func mailBody(from url: URL?) throws -> String {
        let components = try XCTUnwrap(URLComponents(url: try XCTUnwrap(url), resolvingAgainstBaseURL: false))
        return try XCTUnwrap(components.queryItems?.first { $0.name == "body" }?.value)
    }
}
