import Foundation

@MainActor
enum MailInfoResolver {
    static func resolve(provider: (any SettingsControllerDataProvider)?, fallbackPremium: Bool?) async -> (info: SettingsMailInfo?, isPremium: Bool?) {
        guard !Task.isCancelled else { return (nil, fallbackPremium) }
        guard let provider else { return (nil, fallbackPremium) }
        let info = await provider.settingsMailInfo()
        guard !Task.isCancelled else { return (nil, fallbackPremium) }
        if let premium = info?.isPremium { return (info, premium) }
        return (info, await provider.settingsIsPremiumActive())
    }
}
