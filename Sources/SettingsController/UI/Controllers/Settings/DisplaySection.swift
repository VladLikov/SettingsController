import Foundation

/// A row of the developer's app catalog while it loads, after it loads, or after it failed.
enum AppStoreAppRowState: Equatable {
    case placeholder
    case loaded(AppItem)
    case failed
}

/// A row as displayed: a configured item, or a catalog row generated from an `ourApps` section.
enum DisplayRow {
    case item(SettingsRowItem)
    case app(AppStoreAppRowState)

    var item: SettingsRowItem? {
        if case .item(let item) = self { return item }
        return nil
    }
}

/// A configured section projected with the current state. See `SettingsSectionRenderer`.
struct DisplaySection {
    enum Kind {
        case rows([DisplayRow])
        case premiumCard(PremiumCardPayload)
    }

    let title: String?
    var kind: Kind
}
