import UIKit

// MARK: - UITableViewDelegate

extension SettingsController {

    func displayRow(at indexPath: IndexPath) -> DisplayRow? {
        guard sections.indices.contains(indexPath.section), case .rows(let rows) = sections[indexPath.section].kind,
            rows.indices.contains(indexPath.row)
        else { return nil }
        return rows[indexPath.row]
    }

    public override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        switch sections[indexPath.section].kind {
        case .rows(let rows):
            if case .item(.defaultRow(.user)) = rows[indexPath.row] { return SettingsMetrics.estimatedUserRowHeight }
            return SettingsMetrics.estimatedRowHeight
        case .premiumCard(let payload):
            // The last measured height avoids a second self-sizing pass caused by a wrong estimate.
            return PremiumCardMeasurer.estimatedHeight(for: payload, traits: traitCollection) ?? PremiumCardMetrics.minimumHeight
        }
    }

    public override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if case .app(.placeholder) = displayRow(at: indexPath) { return false }
        return true
    }

    public override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard self.tableView(tableView, shouldHighlightRowAt: indexPath) else { return nil }
        selectionBeforeTap = tableView.indexPathForSelectedRow
        return indexPath
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let row = displayRow(at: indexPath) else { return }
        let previousSelection = selectionBeforeTap
        selectionBeforeTap = nil

        if splitViewController?.isCollapsed != false {
            tableView.deselectRow(at: indexPath, animated: true)
        } else if !row.opensDetail {
            // Only a row whose screen is shown in the detail column keeps the selection.
            tableView.deselectRow(at: indexPath, animated: true)
            if let previousSelection, previousSelection != indexPath {
                tableView.selectRow(at: previousSelection, animated: false, scrollPosition: .none)
            }
        }

        switch row {
        case .item(.row(let item)):
            perform(item.destination, title: item.title, at: indexPath)
        case .item(.defaultRow(let item)):
            select(item, at: indexPath)
        case .app(.loaded(let app)):
            openApp(app.id, url: app.storeURL)
        case .app(.failed):
            guard visibleSectionIDs.indices.contains(indexPath.section) else { return }
            loadOurApps(for: visibleSectionIDs[indexPath.section])
        case .app(.placeholder):
            break
        }
    }

    /// Shows a destination screen, ignoring taps while a navigation transition is running.
    func show(_ makeViewController: () -> UIViewController?, title: String?) {
        guard navigationController?.transitionCoordinator == nil, let viewController = makeViewController() else { return }
        pushViewController(viewController, navigationTitle: title)
    }

    private func perform(_ destination: SettingsDestination?, title: String?, at indexPath: IndexPath) {
        switch destination {
        case .controller, .factory:
            show({ destination?.makeViewController() }, title: title)
        case .action(let action):
            cancelPendingStoreProduct()
            action(SettingsActionContext(viewController: self, tableView: tableView, indexPath: indexPath))
        case nil:
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
            openLanguageSettings()

        case .appearance(let theme, let colors):
            show(
                { [configuration] in
                    let appearance = AppearanceController(
                        themeStorage: theme, colors: colors, eventHandler: configuration.eventHandler)
                    appearance.onColorChange = { [weak self] color in self?.updatePremiumColor(color) }
                    appearance.haptics = haptics
                    return appearance
                }, title: row.title)

        case .telegram(let channel):
            openTelegramChannel(channel)

        case .vkGroup(let groupID):
            openVKGroup(groupID)

        case .user(_, _, let destination):
            if destination.opensScreen { needsStateRefresh = true }
            perform(destination, title: row.title, at: indexPath)

        case .tapticEngine(let taptic):
            show(
                { [configuration] in TapticEngineController(tapticStorage: taptic, eventHandler: configuration.eventHandler) },
                title: row.title)

        case .redeemCode:
            redeemCode()

        case .about(let appID, let privacyURL, let termsURL):
            guard navigationController?.transitionCoordinator == nil else { return }
            pushAboutController(appID: appID, privacyURL: privacyURL, termsURL: termsURL, navigationTitle: row.title)
        }
    }
}

extension DisplayRow {
    /// Whether selecting the row shows a destination screen rather than performing an action.
    var opensDetail: Bool {
        switch self {
        case .item(.row(let row)):
            return row.destination?.opensScreen ?? false
        case .item(.defaultRow(let row)):
            switch row {
            case .appearance, .tapticEngine, .about: return true
            case .user(_, _, let destination): return destination.opensScreen
            default: return false
            }
        case .app:
            return false
        }
    }
}
