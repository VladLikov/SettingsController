//
//  SettingsController+TableDelegate.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import UIKit

// MARK: - UITableViewDelegate

extension SettingsController {

    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch sections[indexPath.section].kind {
        case .rows(let rows):
            if case .defaultRow(let row) = rows[indexPath.row], case .user = row {
                return userRowHeight
            }

        case .premiumCard:
            return 100

        default:
            break
        }

        return UITableView.automaticDimension
    }

    public override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        switch sections[indexPath.section].kind {
        case .rows(let rows):
            if case .defaultRow(let row) = rows[indexPath.row], case .user = row {
                return userRowHeight
            }

        case .premiumCard:
            return 100

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

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row

        switch sections[section].kind {
        case .rows(let rows):
            let item = rows[row]

            if UIDevice.current.userInterfaceIdiom == .phone {
                tableView.deselectRow(at: indexPath, animated: true)
            } else if case .defaultRow(let row) = item, case .premium = row {
                tableView.deselectRow(at: indexPath, animated: true)
            }

            select(item, at: indexPath, in: tableView)

        default:
            break
        }
    }

    private func select(_ item: SettingsRowItem, at indexPath: IndexPath, in tableView: UITableView) {
        switch item {
        case .row(let row):
            if let destinationControllerType = row.destinationControllerType {
                let viewController = destinationControllerType.init()
                pushViewController(viewController, navigationTitle: row.title)
            } else if let action = row.action {
                tableView.deselectRow(at: indexPath, animated: true)
                action(indexPath, tableView, self)
            }

        case .defaultRow(let row):
            select(row, at: indexPath)

        case .app(.loaded(let app)):
            openApp(app.id, url: app.storeURL)

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
            pendingRefresh = .premium(indexPath)
            presentPremium(payload)

        case .contactDeveloper(let email):
            sendMail(email)

        case .language(let email):
            pushViewController(
                LanguageController(
                    email: email,
                    userID: mailUserID,
                    isPremium: isPremium,
                    productID: configuration.productID
                ),
                navigationTitle: row.title
            )

        case .appearance(let theme, let colors):
            pushViewController(
                AppearanceController(
                    themeStorage: theme,
                    colors: colors,
                    eventHandler: configuration.eventHandler
                ),
                navigationTitle: row.title
            )

        case .telegram(let channelURL):
            openTelegramChannel(channelURL)

        case .vkGroup(let groupID):
            openVKGroup(groupID)

        case .user(_, _, let destinationControllerType):
            pendingRefresh = .user(indexPath)
            pushViewController(destinationControllerType.init(), navigationTitle: row.title)

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

        case .about(let userID, let appID, let privacyURL, let termsURL):
            pushAboutController(
                userID: userID,
                appID: appID,
                privacyURL: privacyURL,
                termsURL: termsURL,
                navigationTitle: row.title
            )
        }
    }
}
