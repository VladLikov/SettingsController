import UIKit

// MARK: - Diffable data source

extension SettingsController {

    /// Creates the diffable data source for the current table and shows the rendered model.
    func installDataSource() {
        let dataSource = makeDataSource()
        self.dataSource = dataSource
        tableView.dataSource = dataSource
        UIView.performWithoutAnimation { dataSource.apply(makeSnapshot(reconfiguring: []), animatingDifferences: false) }
    }

    private func makeDataSource() -> SettingsTableDataSource {
        let dataSource = SettingsTableDataSource(tableView: tableView) { [unowned self] tableView, indexPath, _ in
            makeCell(in: tableView, at: indexPath)
        }
        dataSource.headerTitle = { [unowned self] id in
            configuration.sections.indices.contains(id) ? configuration.sections[id].title : nil
        }
        dataSource.defaultRowAnimation = .automatic
        return dataSource
    }

    /// The snapshot of the rendered model, with the given rows reconfigured if they are still present.
    func makeSnapshot(reconfiguring rows: Set<SettingsRowID>) -> NSDiffableDataSourceSnapshot<Int, SettingsRowID> {
        var snapshot = NSDiffableDataSourceSnapshot<Int, SettingsRowID>()
        for (section, id) in zip(sections, visibleSectionIDs) {
            snapshot.appendSections([id])
            snapshot.appendItems(section.rowIDs(section: id), toSection: id)
        }
        let present = Set(dataSource?.snapshot().itemIdentifiers ?? [])
        let reconfigured = rows.filter { present.contains($0) && snapshot.indexOfItem($0) != nil }
        if !reconfigured.isEmpty { snapshot.reconfigureItems(Array(reconfigured)) }
        return snapshot
    }

    /// Re-renders the given rows in place, without changing the table's structure.
    func reconfigure(_ rows: Set<SettingsRowID>) {
        guard let dataSource, !rows.isEmpty else { return }
        var snapshot = dataSource.snapshot()
        let present = rows.filter { snapshot.indexOfItem($0) != nil }
        guard !present.isEmpty else { return }
        snapshot.reconfigureItems(Array(present))
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func makeCell(in tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        switch sections[indexPath.section].kind {
        case .rows(let rows):
            switch rows[indexPath.row] {
            case .item(let item):
                return makeCell(for: item, accessory: rows[indexPath.row].accessory, in: tableView, at: indexPath)
            case .app(let appRow):
                let cell = tableView.dequeueReusableCell(withClass: AppCell.self, for: indexPath)
                cell.configure(with: appRow, isOpening: isOpeningStoreProduct(for: appRow))
                cell.isAccessibilityElement = !isRedundantPlaceholder(at: indexPath)
                cell.accessibilityElementsHidden = isRedundantPlaceholder(at: indexPath)
                return cell
            }

        case .premiumCard(let payload):
            let cell = tableView.dequeueReusableCell(withClass: PremiumCell.self, for: indexPath)
            cell.configure(payload: payload, parent: self) { [weak self] in
                guard let self else { return }
                needsStateRefresh = true
                presentPremium(payload.premium)
            }
            return cell
        }
    }

    /// VoiceOver reads one "Loading…" per catalog, not one per placeholder.
    private func isRedundantPlaceholder(at indexPath: IndexPath) -> Bool {
        guard indexPath.row > 0, case .app(.placeholder) = displayRow(at: indexPath) else { return false }
        return true
    }

    private func isOpeningStoreProduct(for row: AppStoreAppRowState) -> Bool {
        guard case .loaded(let app) = row else { return false }
        return openingStoreAppID == app.id
    }

    private func makeCell(
        for item: SettingsRowItem, accessory: RowAccessory, in tableView: UITableView, at indexPath: IndexPath
    ) -> UITableViewCell {
        switch item {
        case .row(let row):
            let cell = tableView.dequeueReusableCell(withClass: SettingsCell.self, for: indexPath)
            cell.configure(title: row.title, icon: row.icon, detail: row.detail, accessory: accessory)
            return cell

        case .defaultRow(.user(let name, let avatar, _)):
            let cell = tableView.dequeueReusableCell(withClass: UserCell.self, for: indexPath)
            cell.configure(title: name, avatar: avatar, accessory: accessory)
            return cell

        case .defaultRow(let row):
            let cell = tableView.dequeueReusableCell(withClass: SettingsCell.self, for: indexPath)
            cell.configure(title: row.title, icon: row.icon, detail: row.premiumStatusTitle, accessory: accessory)
            return cell
        }
    }
}

extension SettingsRowItem.DefaultRow {

    fileprivate var premiumStatusTitle: String? {
        guard case .premium(let payload) = self else { return nil }

        return payload.isPremium
            ? NSLocalizedString("Active", bundle: .module, comment: "Status displayed for an active premium entitlement.")
            : NSLocalizedString("Not active", bundle: .module, comment: "Status displayed when premium is inactive.")
    }
}
