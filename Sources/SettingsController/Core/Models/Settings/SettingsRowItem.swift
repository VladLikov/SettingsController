import UIKit

public enum SettingsRowItem {

    case row(SettingsRow)
    case defaultRow(DefaultRow)

    public enum DefaultRow {

        /// The profile row. `refreshState()` replaces the name and avatar with the provider's `UserInfo`.
        case user(name: String, avatar: UIImage? = nil, destination: SettingsDestination)

        @available(*, deprecated, message: "Use .user(name:avatar:destination:) with .controller(...).")
        public static func user(_ name: String, _ avatar: UIImage?, _ destinationControllerType: UIViewController.Type) -> Self {
            .user(name: name, avatar: avatar, destination: .controller(destinationControllerType))
        }

        @available(*, deprecated, message: "Use .user(name:avatar:destination:) with .factory(...).")
        public static func user(
            _ name: String, _ avatar: UIImage? = nil, destinationFactory: @escaping SettingsDestinationFactory
        ) -> Self {
            .user(name: name, avatar: avatar, destination: .factory(destinationFactory))
        }

        case premium(PremiumPayload)

        case shareApp(appID: String)
        case rateApp(appID: String)
        case moreApps(developerID: String)

        case redeemCode

        case contactDeveloper(email: String)
        case language

        case telegram(id: String)
        case vkGroup(id: String)

        case appearance(theme: ThemeStorage, colors: [any AppColorType] = AppColor.allCases)
        case tapticEngine(taptic: TapticStorage)

        case about(appID: String, privacyURL: URL, termsURL: URL)
    }
}
