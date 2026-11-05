import Foundation

public enum SettingsSectionKind {
    /// A fixed list of rows.
    case rows([SettingsRowItem])

    /// Apps published by a developer account, loaded from the App Store.
    /// - Parameters:
    ///   - developerID: The App Store developer (artist) identifier.
    ///   - limit: The maximum number of apps to show. Zero or less hides the section.
    ///   - excludeAppID: An app to leave out, usually the host app itself.
    case ourApps(developerID: String, limit: Int, excludeAppID: String)

    /// A premium promotion card; an active entitlement shows a premium row instead.
    case premiumCard(_ payload: PremiumCardPayload)
}

public struct SettingsSection {

    public let title: String?
    public internal(set) var kind: SettingsSectionKind

    public init(title: String? = nil, kind: SettingsSectionKind) {
        self.title = title
        self.kind = kind
    }
}
