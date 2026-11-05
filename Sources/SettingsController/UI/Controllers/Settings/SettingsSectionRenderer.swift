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
    static func render(_ definitions: [SettingsSection], state: SettingsRenderState) -> (sections: [SettingsSection], ids: [Int]) {
        var result: [SettingsSection] = []
        var ids: [Int] = []
        for (id, definition) in definitions.enumerated() {
            var section = definition
            switch definition.kind {
            case .ourApps(_, let limit, _):
                switch state.catalogStates[id] ?? (limit > 0 ? .loading : .empty) {
                case .empty: continue
                case .loading:
                    guard limit > 0 else { continue }
                    // Match the last received count so the section does not jump when apps arrive.
                    let count = min(limit, max(1, state.placeholderCount(definition.kind) ?? limit))
                    section.kind = .rows(Array(repeating: .app(.placeholder), count: count))
                case .loaded(let apps):
                    guard !apps.isEmpty else { continue }
                    section.kind = .rows(apps.map { .app(.loaded($0)) })
                case .failed: section.kind = .rows([.app(.failed)])
                }
            case .premiumCard(let card):
                let premium = state.premiumColorOverride.map { card.premium.withColor($0) } ?? card.premium
                if state.isPremium {
                    section.kind = .rows([.defaultRow(.premium(premium.withPremiumStatus(true)))])
                } else if state.premiumColorOverride != nil {
                    section.kind = .premiumCard(
                        PremiumCardPayload(
                            image: card.image, title: card.title,
                            tierTitle: card.tierTitle, subtitle: card.subtitle, buttonTitle: card.buttonTitle, premium: premium))
                }
            case .rows(let rows):
                section.kind = .rows(
                    rows.map { row in
                        switch row {
                        case .defaultRow(.premium(let payload)):
                            let premium = state.premiumColorOverride.map { payload.withColor($0) } ?? payload
                            return .defaultRow(.premium(premium.withPremiumStatus(state.isPremium)))
                        case .defaultRow(.user(_, _, let type)):
                            guard let user = state.currentUser else { return row }
                            return .defaultRow(.user(user.name, user.avatar, type))
                        case .defaultRow(.userFactory(_, _, let factory)):
                            guard let user = state.currentUser else { return row }
                            return .defaultRow(.userFactory(user.name, user.avatar, factory))
                        default: return row
                        }
                    })
            }
            result.append(section)
            ids.append(id)
        }
        return (result, ids)
    }
}
