import UIKit

// MARK: - Update check

extension AboutAppController {
    func checkForUpdate() {
        guard checkUpdateTask == nil else { return }
        let lifetime = updateLifetime
        let request = lifetime.begin()
        let lookup = loadUpdate
        let appID = appID
        let version = currentVersion()
        let osVersion = currentOSVersion()
        checkUpdateTask = Task { @MainActor [weak self] in
            defer {
                if lifetime.finish(request) {
                    self?.checkUpdateTask = nil
                    self?.refreshUpdateRow()
                }
            }
            do {
                guard let version, let update = try await lookup(appID) else { throw URLError(.cannotParseResponse) }
                guard !Task.isCancelled, lifetime.isCurrent(request), self?.settingsCanPresent == true else { return }
                if AppUpdateLookup.compare(version, update.version) != .orderedAscending {
                    self?.showUpdateMessage(
                        NSLocalizedString(
                            "Latest version is installed", bundle: .module,
                            comment: "Update check result when no newer version is available."))
                } else if AppUpdateLookup.compare(osVersion, update.minimumOSVersion) == .orderedAscending {
                    self?.showUpdateMessage(
                        NSLocalizedString(
                            "Update requires a newer iOS version", bundle: .module,
                            comment: "About alert explaining that the available version cannot run on the current operating system."))
                } else {
                    self?.showAvailableUpdate(update)
                }
            } catch {
                guard !Task.isCancelled, !(error is CancellationError), (error as? URLError)?.code != .cancelled,
                    lifetime.isCurrent(request), self?.settingsCanPresent == true
                else { return }
                self?.showUpdateMessage(
                    NSLocalizedString(
                        "Unable to check for updates", bundle: .module,
                        comment: "About alert title when retrieving App Store update information fails."))
            }
        }
        refreshUpdateRow()
    }

    func showUpdateMessage(_ title: String) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(
                title: NSLocalizedString(
                    "OK", bundle: .module, comment: "Confirmation button dismissing an informational or recoverable error alert."),
                style: .default))
        present(alert, animated: true)
    }

    func showAvailableUpdate(_ update: AppUpdate) {
        let alert = UIAlertController(
            title: NSLocalizedString(
                "Update available", bundle: .module,
                comment: "About alert title when the App Store version is newer than the installed version."),
            message: String(
                format: NSLocalizedString(
                    "Version %@ is available.", bundle: .module,
                    comment: "Available-update alert message. %@ is the App Store version number, for example 4.0.1."), update.version),
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(
                title: NSLocalizedString(
                    "Not Now", bundle: .module, comment: "Dismiss the optional available-update alert without opening the App Store."),
                style: .cancel))
        let open = openURL
        let action = UIAlertAction(
            title: NSLocalizedString(
                "Update", bundle: .module, comment: "Action opening the App Store page from the available-update alert."), style: .default
        ) { _ in
            Task { @MainActor in _ = await open(update.url) }
        }
        alert.addAction(action)
        alert.preferredAction = action
        present(alert, animated: true)
    }
}
