//
//  SettingsController+TableDelegate.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import UIKit

// MARK: - UITableViewDelegate

extension SettingsController {

    public override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        switch sections[indexPath.section].kind {
        case .rows(let rows):
            switch rows[indexPath.row] {
            case .defaultRow(.user), .defaultRow(.userFactory): return userRowHeight
            default: break
            }

        case .premiumCard(let payload):
            // The last measured height avoids a second self-sizing pass caused by a wrong estimate.
            return PremiumCardMeasurer.estimatedHeight(for: payload, traits: traitCollection) ?? PremiumCardMetrics.minimumHeight

        default:
            break
        }

        return defaultRowEstimatedHeight
    }

    var defaultRowEstimatedHeight: CGFloat {
        if #available(iOS 26, *) {
            53
        } else {
            45
        }
    }

    private var userRowHeight: CGFloat {
        if #available(iOS 26, *) {
            73
        } else {
            65
        }
    }

    public override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        guard case .rows(let rows) = sections[indexPath.section].kind, rows.indices.contains(indexPath.row) else { return true }
        if case .app(.placeholder) = rows[indexPath.row] { return false }
        return true
    }

    public override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard self.tableView(tableView, shouldHighlightRowAt: indexPath) else { return nil }
        selectionBeforeTap = tableView.indexPathForSelectedRow
        return indexPath
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row

        switch sections[section].kind {
        case .rows(let rows):
            let item = rows[row]
            let previousSelection = selectionBeforeTap
            selectionBeforeTap = nil

            if splitViewController?.isCollapsed != false {
                tableView.deselectRow(at: indexPath, animated: true)
            } else if !item.opensDetail {
                // Only a row whose screen is shown in the detail column keeps the selection.
                tableView.deselectRow(at: indexPath, animated: true)
                if let previousSelection, previousSelection != indexPath {
                    tableView.selectRow(at: previousSelection, animated: false, scrollPosition: .none)
                }
            }

            select(item, at: indexPath, in: tableView)

        default:
            break
        }
    }

    private func select(_ item: SettingsRowItem, at indexPath: IndexPath, in tableView: UITableView) {
        switch item {
        case .row(let row):
            if let factory = row.destinationFactory {
                guard navigationController?.transitionCoordinator == nil else { return }
                pushViewController(factory(), navigationTitle: row.title)
            } else if let destinationControllerType = row.destinationControllerType {
                let viewController = destinationControllerType.init()
                pushViewController(viewController, navigationTitle: row.title)
            } else if let action = row.action {
                tableView.deselectRow(at: indexPath, animated: true)
                cancelPendingStoreProduct()
                action(indexPath, tableView, self)
            }

        case .defaultRow(let row):
            select(row, at: indexPath)

        case .app(.loaded(let app)):
            openApp(app.id, url: app.storeURL)

        case .app(.failed):
            tableView.deselectRow(at: indexPath, animated: true)
            guard visibleSectionIDs.indices.contains(indexPath.section) else { return }
            loadOurApps(for: visibleSectionIDs[indexPath.section])

        default:
            break
        }
    }

    private func select(_ row: SettingsRowItem.DefaultRow, at indexPath: IndexPath) {
        switch row {
        case .shareApp(let appID):
            shareApp(appID, at: indexPath)

        case .rateApp(let appID):
            rateApp(appID)

        case .moreApps(let developerID):
            moreApps(developerID)

        case .premium(let payload):
            needsStateRefresh = true
            presentPremium(payload)

        case .contactDeveloper(let email):
            sendMail(email)

        case .language:
            tableView.deselectRow(at: indexPath, animated: true)
            openLanguageSettings()

        case .appearance(let theme, let colors):
            let appearance = AppearanceController(
                themeStorage: theme, colors: colors,
                eventHandler: configuration.eventHandler)
            appearance.onColorChange = { [weak self] color in self?.updatePremiumColor(color) }
            pushViewController(appearance, navigationTitle: row.title)

        case .telegram(let channelURL):
            openTelegramChannel(channelURL)

        case .vkGroup(let groupID):
            openVKGroup(groupID)

        case .user(_, _, let destinationControllerType):
            needsStateRefresh = true
            pushViewController(destinationControllerType.init(), navigationTitle: row.title)

        case .userFactory(_, _, let factory):
            guard navigationController?.transitionCoordinator == nil else { return }
            needsStateRefresh = true
            pushViewController(factory(), navigationTitle: row.title)

        case .tapticEngine(let taptic):
            pushViewController(
                TapticEngineController(
                    tapticStorage: taptic,
                    eventHandler: configuration.eventHandler
                ),
                navigationTitle: row.title
            )

        case .redeemCode:
            redeemCode()

        case .about(let appID, let privacyURL, let termsURL):
            pushAboutController(
                appID: appID,
                privacyURL: privacyURL,
                termsURL: termsURL,
                navigationTitle: row.title
            )
        }
    }
}

extension SettingsRowItem {
    /// Whether selecting the row shows a destination screen rather than performing an action.
    var opensDetail: Bool {
        switch self {
        case .row(let row):
            return row.destinationFactory != nil || row.destinationControllerType != nil
        case .defaultRow(let row):
            switch row {
            case .appearance, .tapticEngine, .about, .user, .userFactory: return true
            default: return false
            }
        case .app: return false
        }
    }
}
