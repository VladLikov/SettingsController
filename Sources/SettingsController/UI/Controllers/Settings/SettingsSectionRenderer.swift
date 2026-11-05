import UIKit

/// The mutable state that changes how configured sections are displayed.
struct SettingsRenderState {
    var catalogStates: [Int: AppCatalogState]
    var isPremium: Bool
    var premiumColorOverride: UIColor?
    var currentUser: UserInfo?
    /// The last received app count for a catalog definition, used to size its loading placeholders.
    var placeholderCount: (SettingsSectionKind) -> Int? = { _ in nil }
}

/// Projects the immutable configured sections and the current state into displayed sections.
/// Section IDs are configuration indexes; hidden sections are omitted from both arrays.
@MainActor
enum SettingsSectionRenderer {
    static func render(_ definitions: [SettingsSection], state: SettingsRenderState) -> (sections: [DisplaySection], ids: [Int]) {
        var result: [DisplaySection] = []
        var ids: [Int] = []
        for (id, definition) in definitions.enumerated() {
            let kind: DisplaySection.Kind
            switch definition.kind {
            case .ourApps(_, let limit, _):
                switch state.catalogStates[id] ?? (limit > 0 ? .loading : .empty) {
                case .empty: continue
                case .loading:
                    guard limit > 0 else { continue }
                    // Match the last received count so the section does not jump when apps arrive.
                    let count = min(limit, max(1, state.placeholderCount(definition.kind) ?? limit))
                    kind = .rows(Array(repeating: .app(.placeholder), count: count))
                case .loaded(let apps):
                    guard !apps.isEmpty else { continue }
                    kind = .rows(apps.map { .app(.loaded($0)) })
                case .failed:
                    kind = .rows([.app(.failed)])
                }
            case .premiumCard(let card):
                let premium = state.premiumColorOverride.map { card.premium.withColor($0) } ?? card.premium
                if state.isPremium {
                    kind = .rows([.item(.defaultRow(.premium(premium.withPremiumStatus(true))))])
                } else {
                    kind = .premiumCard(
                        PremiumCardPayload(
                            image: card.image, title: card.title, tierTitle: card.tierTitle, subtitle: card.subtitle,
                            buttonTitle: card.buttonTitle, premium: premium))
                }
            case .rows(let rows):
                kind = .rows(rows.map { .item(render($0, state: state)) })
            }
            result.append(DisplaySection(title: definition.title, kind: kind))
            ids.append(id)
        }
        return (result, ids)
    }

    private static func render(_ row: SettingsRowItem, state: SettingsRenderState) -> SettingsRowItem {
        switch row {
        case .defaultRow(.premium(let payload)):
            let premium = state.premiumColorOverride.map { payload.withColor($0) } ?? payload
            return .defaultRow(.premium(premium.withPremiumStatus(state.isPremium)))
        case .defaultRow(.user(_, _, let destination)):
            guard let user = state.currentUser else { return row }
            return .defaultRow(.user(name: user.name, avatar: user.avatar, destination: destination))
        default:
            return row
        }
    }
}
