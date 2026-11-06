import UIKit

/// A diffable table data source whose section headers and footers come from closures.
final class TitledDataSource<Section: Hashable & Sendable, Item: Hashable & Sendable>: UITableViewDiffableDataSource<Section, Item> {
    var header: (Section) -> String? = { _ in nil }
    var footer: (Section) -> String? = { _ in nil }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sectionIdentifier(for: section).flatMap(header)
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        sectionIdentifier(for: section).flatMap(footer)
    }

    /// Re-renders the given items in place if they are shown.
    func reconfigure(_ items: [Item]) {
        var snapshot = snapshot()
        let present = items.filter { snapshot.indexOfItem($0) != nil }
        guard !present.isEmpty else { return }
        snapshot.reconfigureItems(present)
        apply(snapshot, animatingDifferences: false)
    }
}
