import Foundation

@MainActor
enum MailInfoResolver {
    static func resolve(provider: (any SettingsControllerDataProvider)?, fallbackPremium: Bool?) async -> (info: SettingsMailInfo?, isPremium: Bool?) {
        guard let provider else { return (nil, fallbackPremium) }
        let info = await provider.settingsMailInfo()
        if let premium = info?.isPremium { return (info, premium) }
        return (info, await provider.settingsIsPremiumActive())
    }
}
