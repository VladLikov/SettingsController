import Foundation

public enum MailType: Equatable {
    case supportRequest,
        languageRequest
    case
        custom(placeholder: String, minCharactersCount: Int, navigationTitle: String, subject: String)

    public var navigationTitle: String {
        switch self {
        case .supportRequest:
            return NSLocalizedString("Ask Support a Question", bundle: .module, comment: "Navigation title of the support message form.")

        case .languageRequest:
            return NSLocalizedString(
                "Request a Language", bundle: .module, comment: "Navigation title of the standalone language request form.")

        case .custom(_, _, let navigationTitle, _):
            return navigationTitle
        }
    }

    public var placeholder: String {
        switch self {
        case .supportRequest:
            return NSLocalizedString(
                "What went wrong? Add at least 10 characters. The more detail, the faster we can help.", bundle: .module,
                comment: "Placeholder in the support form; a message needs at least ten characters.")

        case .languageRequest:
            return NSLocalizedString(
                "Which language would you like to see in the app?", bundle: .module,
                comment: "Placeholder asking for a desired language in the standalone language request form.")

        case .custom(let placeholder, _, _, _):
            return placeholder
        }
    }

    public var minCharactersCount: Int {
        switch self {
        case .supportRequest:
            return 10
        case .languageRequest:
            return 2
        case .custom(_, let minCharactersCount, _, _):
            return max(0, minCharactersCount)
        }
    }

    public var subject: String {
        switch self {
        case .supportRequest:
            return NSLocalizedString("Support Request", bundle: .module, comment: "")

        case .languageRequest:
            return NSLocalizedString("Language Request", bundle: .module, comment: "")

        case .custom(_, _, _, let subject):
            return subject
        }
    }
}
