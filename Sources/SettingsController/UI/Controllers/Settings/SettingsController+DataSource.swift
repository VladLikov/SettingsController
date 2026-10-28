//
//  SettingsController+DataSource.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import UIKit

// MARK: - UITableViewDataSource

extension SettingsController {

    public override func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section].kind {
        case .rows(let rows):
            return rows.count
        case .ourApps(_, let limit, _):
            return max(0, limit)
        case .premiumCard:
            return 1
        }
    }

    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section

        switch sections[section].kind {
        case .rows(let rows):
            switch rows[indexPath.row] {
            case .row(let row):
                let cell = tableView.dequeueReusableCell(withClass: SettingsCell.self, for: indexPath)
                cell.configure(title: row.title, icon: row.icon, detail: row.detail)
                return cell

            case .defaultRow(let defaultRow):
                switch defaultRow {
                case .user(let name, let image, _), .userFactory(let name, let image, _):
                    let cell = tableView.dequeueReusableCell(withClass: UserCell.self, for: indexPath)
                    cell.configure(title: name, avatar: image)
                    return cell
                default: break
                }

                let cell = tableView.dequeueReusableCell(withClass: SettingsCell.self, for: indexPath)
                let detail = defaultRow.premiumStatusTitle
                cell.configure(title: defaultRow.title, icon: defaultRow.icon, detail: detail)
                return cell

            case .app(let appRow):
                return makeAppCell(for: tableView, at: indexPath, appRow: appRow)
            }

        case .ourApps:
            return makeAppCell(for: tableView, at: indexPath, appRow: .placeholder)

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

    private func makeAppCell(
        for tableView: UITableView,
        at indexPath: IndexPath,
        appRow: AppStoreAppRowState
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: AppCell.self, for: indexPath)
        cell.configure(with: appRow)
        return cell
    }
}

private extension SettingsRowItem.DefaultRow {

    var premiumStatusTitle: String? {
        guard case .premium(let payload) = self else { return nil }

        return payload.isPremium
            ? NSLocalizedString("Active", bundle: .module, comment: "Status displayed for an active premium entitlement.")
            : NSLocalizedString("Not active", bundle: .module, comment: "Status displayed when premium is inactive.")
    }
}
