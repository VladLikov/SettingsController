import UIKit

// MARK: - Data

extension AboutAppController {

    func refreshVisibleRows() {
        guard isViewLoaded else { return }
        reconfigureRows(titled: data.flatMap { $0.items.map(\.title) })
    }

    func refreshUpdateRow() {
        guard isViewLoaded else { return }
        reconfigureRows(titled: data.flatMap { $0.items.filter { $0.action == .checkForUpdate }.map(\.title) })
    }

    func accountItems() -> [AboutItem] {
        [
            .init(
                title: NSLocalizedString(
                    "User ID", bundle: .module, comment: "Diagnostic label for the current account identifier supplied by the host app."),
                subtitle: userID ?? "-",
                value: nil,
                action: userID == nil ? .none : .copyUserID
            ),
            .init(
                title: NSLocalizedString("Premium", bundle: .module, comment: "Title of the premium settings row."),
                subtitle: nil,
                value: isPremium
                    ? NSLocalizedString("Active", bundle: .module, comment: "Status displayed for an active premium entitlement.")
                    : NSLocalizedString("Not active", bundle: .module, comment: "Status displayed when premium is inactive."),
                action: .none
            ),
        ]
    }

    func setupData() {

        let osVersion = Self.systemVersionDescription
        let deviceModel = DeviceModel.supportDescription
        let systemLanguage = Locale.preferredLanguages.first ?? "-"
        let appLanguage = Bundle.main.preferredLocalizations.first ?? "-"

        let region = Locale.current.regionIdentifier ?? "-"

        data = [
            (
                .update,
                [
                    .init(
                        title: NSLocalizedString(
                            "Check for Update", bundle: .module, comment: "Action that checks the App Store for a newer app version."),
                        subtitle: nil,
                        value: nil,
                        action: .checkForUpdate
                    )
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
                        action: .privacyPolicy
                    ),
                    .init(
                        title: NSLocalizedString(
                            "Terms of Use", bundle: .module,
                            comment: "Not translated in the catalog: link title to the host-provided terms page."),
                        subtitle: nil,
                        value: nil,
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
                        subtitle: nil,
                        value: osVersion,
                        action: .none
                    ),
                    .init(
                        title: NSLocalizedString(
                            "Device Model", bundle: .module,
                            comment: "Diagnostic label for the hardware model, without a user-assigned device name."),
                        subtitle: nil,
                        value: deviceModel,
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
                        action: .none
                    ),
                    .init(
                        title: NSLocalizedString(
                            "App Language", bundle: .module, comment: "Diagnostic label for the language selected by the app bundle."),
                        subtitle: nil,
                        value: appLanguage,
                        action: .none
                    ),
                    .init(
                        title: NSLocalizedString("App Region", bundle: .module, comment: "Diagnostic label for the current locale region."),
                        subtitle: nil,
                        value: region.lowercased(),
                        action: .none
                    ),
                ]
            ),
        ]
    }

    /// "iOS 27.2 (24B91016s)": the system name and version, with the build that support needs.
    static var systemVersionDescription: String {
        let device = UIDevice.current
        let description = ProcessInfo.processInfo.operatingSystemVersionString
        let build =
            description.range(of: #"\(.* ([^)]+)\)"#, options: .regularExpression)
            .map { String(description[$0]).split(separator: " ").last.map { String($0.dropLast()) } ?? "" } ?? ""
        return build.isEmpty ? "\(device.systemName) \(device.systemVersion)" : "\(device.systemName) \(device.systemVersion) (\(build))"
    }

    /// Name, version and build for the header.
    static var appHeader: (name: String, version: String, bundleID: String) {
        let info = Bundle.main.infoDictionary
        let name = info?["CFBundleDisplayName"] as? String ?? info?["CFBundleName"] as? String ?? ""
        let version = info?["CFBundleShortVersionString"] as? String ?? "-"
        let build = info?["CFBundleVersion"] as? String ?? "-"
        return (name, "\(version) (\(build))", Bundle.main.bundleIdentifier ?? "-")
    }
}
