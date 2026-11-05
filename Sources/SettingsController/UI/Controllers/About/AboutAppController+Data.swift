import SafeSFSymbols
import UIKit

// MARK: - Data

extension AboutAppController {

    static func icon(_ systemName: String, color: UIColor = .systemGray, padding: IconPadding? = IconPadding()) -> SettingsIcon {
        SettingsIcon(
            image: UIImage(systemName: systemName),
            color: color,
            padding: padding,
            cacheIdentifier: "sf:\(systemName)"
        )
    }

    func refreshVisibleRows() {
        guard isViewLoaded else { return }
        guard tableView.window != nil else {
            tableView.reloadData()
            return
        }
        guard let paths = tableView.indexPathsForVisibleRows, !paths.isEmpty else { return }
        UIView.performWithoutAnimation { tableView.reconfigureRows(at: paths) }
    }

    func refreshUpdateRow() {
        guard isViewLoaded else { return }
        guard tableView.window != nil else {
            tableView.reloadData()
            return
        }
        let paths = data.enumerated().flatMap { section, group in
            group.items.enumerated().compactMap { row, item in
                item.action == .checkForUpdate ? IndexPath(row: row, section: section) : nil
            }
        }
        UIView.performWithoutAnimation { tableView.reconfigureRows(at: paths) }
    }

    func accountItems() -> [AboutItem] {
        [
            .init(
                title: NSLocalizedString(
                    "User ID", bundle: .module, comment: "Diagnostic label for the current account identifier supplied by the host app."),
                subtitle: userID ?? "-",
                value: nil,
                icon: Self.icon("person.fill"),
                action: userID == nil ? .none : .copyUserID
            ),
            .init(
                title: NSLocalizedString("Premium", bundle: .module, comment: "Title of the premium settings row."),
                subtitle: nil,
                value: isPremium
                    ? NSLocalizedString("Active", bundle: .module, comment: "Status displayed for an active premium entitlement.")
                    : NSLocalizedString("Not active", bundle: .module, comment: "Status displayed when premium is inactive."),
                icon: Self.icon("star.fill"),
                action: .none
            ),
        ]
    }

    func setupData() {

        let bundle = Bundle.main

        let appVersion = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let build = bundle.infoDictionary?["CFBundleVersion"] as? String ?? "-"

        let fullVersion = "\(appVersion) (\(build))"
        let bundleID = bundle.bundleIdentifier ?? "-"
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let deviceModel = DeviceModel.supportDescription
        let systemLanguage = Locale.preferredLanguages.first ?? "-"
        let appLanguage = Bundle.main.preferredLocalizations.first ?? "-"

        let region = Locale.current.regionIdentifier ?? "-"

        data = [
            (
                .build,
                [
                    .init(
                        title: NSLocalizedString(
                            "Bundle ID", bundle: .module, comment: "Not translated: technical diagnostic label in About."),
                        subtitle: bundleID,
                        value: nil,
                        icon: Self.icon("info.circle.fill"),
                        action: .none
                    ),
                    .init(
                        title: NSLocalizedString(
                            "App Version", bundle: .module, comment: "Diagnostic label for the installed app version and build."),
                        subtitle: nil,
                        value: fullVersion,
                        icon: Self.icon("doc.fill"),
                        action: .none
                    ),
                    .init(
                        title: NSLocalizedString(
                            "Check for Update", bundle: .module, comment: "Action that checks the App Store for a newer app version."),
                        subtitle: nil,
                        value: nil,
                        icon: nil,
                        action: .checkForUpdate
                    ),
                ]
            ),
            (
                .links,
                [
                    .init(
                        title: NSLocalizedString(
                            "Privacy Policy", bundle: .module,
                            comment: "Not translated in the catalog: link title to the host-provided policy page."),
                        subtitle: nil,
                        value: nil,
                        icon: Self.icon("hand.raised.fill"),
                        action: .privacyPolicy
                    ),
                    .init(
                        title: NSLocalizedString(
                            "Terms of Use", bundle: .module,
                            comment: "Not translated in the catalog: link title to the host-provided terms page."),
                        subtitle: nil,
                        value: nil,
                        icon: Self.icon("doc.text.fill"),
                        action: .terms
                    ),
                ]
            ),
            (
                .device,
                [
                    .init(
                        title: NSLocalizedString(
                            "OS Version", bundle: .module, comment: "Diagnostic label for the operating system version."),
                        subtitle: osVersion,
                        value: nil,
                        icon: Self.icon("gearshape.fill"),
                        action: .none
                    ),
                    .init(
                        title: NSLocalizedString(
                            "Device Model", bundle: .module,
                            comment: "Diagnostic label for the hardware model, without a user-assigned device name."),
                        subtitle: deviceModel,
                        value: nil,
                        icon: Self.icon("iphone"),
                        action: .none
                    ),
                ]
            ),
            (.account, accountItems()),
            (
                .locale,
                [
                    .init(
                        title: NSLocalizedString(
                            "Preferred Language", bundle: .module,
                            comment:
                                "About diagnostic label for the first public Locale.preferredLanguages value; not an independently read global system language."
                        ),
                        subtitle: nil,
                        value: systemLanguage,
                        icon: Self.icon("keyboard.fill"),
                        action: .none
                    ),
                    .init(
                        title: NSLocalizedString(
                            "App Language", bundle: .module, comment: "Diagnostic label for the language selected by the app bundle."),
                        subtitle: nil,
                        value: appLanguage,
                        icon: Self.icon("at"),
                        action: .none
                    ),
                    .init(
                        title: NSLocalizedString("App Region", bundle: .module, comment: "Diagnostic label for the current locale region."),
                        subtitle: nil,
                        value: region.lowercased(),
                        icon: Self.icon("globe"),
                        action: .none
                    ),
                ]
            ),
        ]
    }
}
