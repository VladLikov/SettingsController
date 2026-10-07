import XCTest
@testable import SettingsController

@MainActor
final class MailBuilderTests: XCTestCase {
    func testSubscriptionIDIsIncludedForEveryMailType() throws {
        let configuration = SettingsConfiguration(sections: [], subscriptionID: "subscription-123")
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
                subscriptionID: configuration.subscriptionID
            )
            let body = try mailBody(from: url)
            XCTAssertTrue(body.contains("User ID: user-456\nSubscription ID: subscription-123\nPro Status: true"))
            XCTAssertTrue(body.contains("Please help"))
        }
    }

    func testMissingSubscriptionIDUsesPlaceholderWithExistingArguments() throws {
        XCTAssertNil(SettingsConfiguration(sections: []).subscriptionID)
        let url = MailBuilder.buildMail(
            with: "Please help",
            recipient: "support@example.com",
            type: .supportRequest,
            userID: nil,
            isPremium: false
        )
        let body = try mailBody(from: url)
        XCTAssertTrue(body.contains("Subscription ID: -"))
        XCTAssertTrue(body.contains("Pro Status: false"))
    }

    private func mailBody(from url: String) throws -> String {
        let components = try XCTUnwrap(URLComponents(string: url))
        return try XCTUnwrap(components.queryItems?.first { $0.name == "body" }?.value)
    }
}
