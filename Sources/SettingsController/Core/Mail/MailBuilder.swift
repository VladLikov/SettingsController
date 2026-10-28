import Foundation

struct MailDraft: Sendable {
    let recipient: String
    let subject: String
    let body: String

    var url: URL? {
        guard !recipient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !recipient.contains("\r"), !recipient.contains("\n") else { return nil }
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = recipient
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        // Some mail handlers interpret + as a form-encoded space.
        components.percentEncodedQuery = components.percentEncodedQuery?
            .replacingOccurrences(of: "+", with: "%2B")
        return components.url
    }
}

@MainActor
enum MailBuilder {
    static func buildMail(
        with text: String, recipient: String, type: MailType,
        isPremium: Bool?, productID: String? = nil,
        mailInfo: SettingsMailInfo? = nil
    ) -> URL? {
        makeDraft(with: text, recipient: recipient, type: type, isPremium: isPremium,
                  productID: productID, mailInfo: mailInfo, environment: .current()).url
    }

    static func makeDraft(
        with text: String, recipient: String, type: MailType,
        isPremium: Bool?, productID: String? = nil,
        mailInfo: SettingsMailInfo? = nil, environment e: MailEnvironment
    ) -> MailDraft {
        let premium = (mailInfo?.isPremium ?? isPremium).map { $0 ? "true" : "false" } ?? "-"
        let body = """
        \(type == .languageRequest ? "Language needed: " : "")\(text)


        ===== DEVICE INFO =====

        Device Model: \(e.deviceModel)
        Device Type: \(e.deviceType)

        OS: \(e.systemName) \(e.systemVersion)

        Battery: \(e.battery)

        ===== APP INFO =====

        App: \(e.appName)
        Version: \(e.version)
        Build: \(e.build)

        ===== USER INFO =====

        User ID: \(mailInfo?.userID ?? "-")
        Product ID: \(mailInfo?.productID ?? productID ?? "-")
        Pro Status: \(premium)

        ===== ENVIRONMENT =====

        Locale: \(e.locale)
        Preferred Language: \(e.preferredLanguage)
        App Language: \(e.appLanguage)
        App Region: \(e.region)
        Time Zone: \(e.timeZone)

        Timestamp: \(e.timestamp)

        """
        return MailDraft(recipient: recipient, subject: "\(e.appName) \(type.subject)", body: body)
    }
}
