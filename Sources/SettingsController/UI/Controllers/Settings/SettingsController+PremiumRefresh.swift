//
//  SettingsController+PremiumRefresh.swift
//  SettingsController
//
//  Created by Влад Лыков on 05.05.2026.
//

import UIKit

// MARK: - Premium and User Refresh

extension SettingsController {

    var cachedPremiumStatus: Bool {
        for section in sections {
            switch section.kind {
            case .premiumCard(let payload):
                return payload.premium.isPremium

            case .rows(let rows):
                for row in rows {
                    guard case .defaultRow(let defaultRow) = row,
                          case .premium(let payload) = defaultRow else {
                        continue
                    }

                    return payload.isPremium
                }

            case .ourApps:
                continue
            }
        }

        return isPremium
    }

    func resolvePremiumStatus() async -> Bool {
        guard let dataProvider = configuration.dataProvider else {
            return cachedPremiumStatus
        }

        return await dataProvider.settingsIsPremiumActive()
    }

    func pushAboutController(
        userID: String?,
        appID: String,
        privacyURL: URL,
        termsURL: URL,
        navigationTitle: String?
    ) {
        aboutStatusTask?.cancel()
        aboutStatusTask = Task { @MainActor [weak self] in
            guard let self else { return }

            let isPremium = await resolvePremiumStatus()
            guard !Task.isCancelled else { return }

            self.isPremium = isPremium
            showAboutController(
                isPremium: isPremium,
                userID: userID,
                appID: appID,
                privacyURL: privacyURL,
                termsURL: termsURL,
                navigationTitle: navigationTitle
            )
            aboutStatusTask = nil
        }
    }

    func refreshPendingRowIfNeeded() {
        guard let pendingRefresh else { return }
        self.pendingRefresh = nil

        pendingRefreshTask?.cancel()
        pendingRefreshTask = Task { @MainActor [weak self] in
            guard let self else { return }

            switch pendingRefresh {
            case .premium(let indexPath):
                await refreshPremiumRow(at: indexPath)

            case .user(let indexPath):
                await refreshUserRow(at: indexPath)
            }

            guard !Task.isCancelled else { return }
            pendingRefreshTask = nil
        }
    }

    private func showAboutController(
        isPremium: Bool,
        userID: String?,
        appID: String,
        privacyURL: URL,
        termsURL: URL,
        navigationTitle: String?
    ) {
        let viewController = AboutAppController(
            isPremium: isPremium,
            userID: userID,
            appID: appID,
            privacyURL: privacyURL,
            termsURL: termsURL
        )

        pushViewController(viewController, navigationTitle: navigationTitle)
    }

    private func refreshPremiumRow(at indexPath: IndexPath) async {
        guard containsRow(at: indexPath) else { return }

        let isPremium = await resolvePremiumStatus()
        guard !Task.isCancelled, containsRow(at: indexPath) else { return }

        self.isPremium = isPremium
        updatePremiumStatus(isPremium, at: indexPath)
    }

    private func refreshUserRow(at indexPath: IndexPath) async {
        guard let dataProvider = configuration.dataProvider,
              containsRow(at: indexPath) else { return }

        guard let user = await dataProvider.settingsCurrentUserInfo(),
              !Task.isCancelled,
              containsRow(at: indexPath) else { return }

        updateUserInfo(user, at: indexPath)
    }

    private func updatePremiumStatus(_ isPremium: Bool, at indexPath: IndexPath) {
        guard sections.indices.contains(indexPath.section) else { return }

        switch sections[indexPath.section].kind {
        case .premiumCard(let payload):
            guard payload.premium.isPremium != isPremium else { return }
            sections[indexPath.section].kind = .premiumCard(payload.withPremiumStatus(isPremium))
            tableView?.reloadRows(at: [indexPath], with: .fade)

        case .rows(var rows):
            guard rows.indices.contains(indexPath.row),
                  case .defaultRow(.premium(let payload)) = rows[indexPath.row],
                  payload.isPremium != isPremium else {
                return
            }

            rows[indexPath.row] = .defaultRow(.premium(payload.withPremiumStatus(isPremium)))
            sections[indexPath.section].kind = .rows(rows)
            tableView?.reloadRows(at: [indexPath], with: .fade)

        default:
            break
        }
    }

    private func updateUserInfo(_ user: UserInfo, at indexPath: IndexPath) {
        guard sections.indices.contains(indexPath.section),
              case .rows(var rows) = sections[indexPath.section].kind,
              rows.indices.contains(indexPath.row),
              case .defaultRow(.user(_, _, let destinationControllerType)) = rows[indexPath.row] else {
            return
        }

        rows[indexPath.row] = .defaultRow(.user(user.name, user.avatar, destinationControllerType))
        sections[indexPath.section].kind = .rows(rows)
        tableView?.reloadRows(at: [indexPath], with: .fade)
    }

    private func containsRow(at indexPath: IndexPath) -> Bool {
        guard sections.indices.contains(indexPath.section) else {
            return false
        }

        switch sections[indexPath.section].kind {
        case .rows(let rows):
            return rows.indices.contains(indexPath.row)

        case .ourApps(_, let limit, _):
            return (0..<limit).contains(indexPath.row)

        case .premiumCard:
            return indexPath.row == 0
        }
    }
}

private extension PremiumPayload {

    func withPremiumStatus(_ isPremium: Bool) -> PremiumPayload {
        .init(
            isPremium: isPremium,
            color: color,
            destinationControllerType: destinationControllerType,
            action: action
        )
    }
}

private extension PremiumCardPayload {

    func withPremiumStatus(_ isPremium: Bool) -> PremiumCardPayload {
        .init(
            image: image,
            title: title,
            subtitle: subtitle,
            buttonTitle: buttonTitle,
            premium: premium.withPremiumStatus(isPremium)
        )
    }
}
