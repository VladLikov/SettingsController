import UIKit

/// A stable identity for a displayed row. Sections are configuration indexes, so they never change
/// when other sections appear or disappear.
struct SettingsRowID: Hashable, Sendable {
    enum Kind: Hashable, Sendable {
        /// A configured row, by its index in the section definition.
        case item(Int)
        /// A loaded catalog app, by its App Store ID.
        case app(Int)
        /// A catalog loading placeholder, by position.
        case placeholder(Int)
        /// The catalog retry row.
        case retry
        /// The premium promotion card.
        case premiumCard
    }

    let section: Int
    let kind: Kind
}

/// The settings list data source. Rows come from the rendered model; headers from the configuration.
final class SettingsTableDataSource: UITableViewDiffableDataSource<Int, SettingsRowID> {
    var headerTitle: (Int) -> String? = { _ in nil }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sectionIdentifier(for: section).flatMap(headerTitle)
    }
}

extension DisplaySection {
    /// Identifiers of the rows in this section, in display order.
    func rowIDs(section id: Int) -> [SettingsRowID] {
        switch kind {
        case .premiumCard:
            return [SettingsRowID(section: id, kind: .premiumCard)]
        case .rows(let rows):
            return rows.enumerated().map { index, row in
                switch row {
                case .item: SettingsRowID(section: id, kind: .item(index))
                case .app(.loaded(let app)): SettingsRowID(section: id, kind: .app(app.id))
                case .app(.placeholder): SettingsRowID(section: id, kind: .placeholder(index))
                case .app(.failed): SettingsRowID(section: id, kind: .retry)
                }
            }
        }
    }
}
