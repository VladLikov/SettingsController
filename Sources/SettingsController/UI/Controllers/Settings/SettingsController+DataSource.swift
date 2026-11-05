import UIKit

// MARK: - UITableViewDataSource

extension SettingsController {

    public override func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section].kind {
        case .rows(let rows): rows.count
        case .premiumCard: 1
        }
    }

    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
