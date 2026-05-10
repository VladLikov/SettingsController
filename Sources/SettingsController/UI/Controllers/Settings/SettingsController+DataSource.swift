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
            return limit
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
                if case .user(let name, let image, _) = defaultRow {
                    let cell = tableView.dequeueReusableCell(withClass: UserCell.self, for: indexPath)
                    cell.configure(title: name, avatar: image)
                    return cell
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
            cell.configure(payload: payload) { [weak self] in
                guard let self else { return }
                pendingRefresh = .premium(indexPath)
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
            ? NSLocalizedString("Active", bundle: .module, comment: "")
            : NSLocalizedString("Not active", bundle: .module, comment: "")
    }
}
