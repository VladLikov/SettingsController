//
//  AboutAppController.swift
//  SettingsController
//
//  Created by Влад Лыков on 16.04.2026.
//

import UIKit
import SafariServices
import AlertKit
import SafeSFSymbols

// MARK: - AboutAppController

final class AboutAppController: UITableViewController {

    private enum AboutSection {
        case build
        case links
        case device
        case account
        case locale

        var title: String? {
            switch self {
            case .build:
                return NSLocalizedString("Build", bundle: .module, comment: "")
            case .links:
                return nil
            case .device:
                return NSLocalizedString("Device", bundle: .module, comment: "")
            case .account:
                return NSLocalizedString("Account", bundle: .module, comment: "")
            case .locale:
                return NSLocalizedString("Locale", bundle: .module, comment: "")
            }
        }

        var footer: String? {
            switch self {
            case .account:
                return NSLocalizedString("Tap User ID to copy. Support may request it.", bundle: .module, comment: "")
            case .build, .links, .device, .locale:
                return nil
            }
        }
    }

    private enum AboutAction {
        case none
        case copyUserID
        case checkForUpdate
        case privacyPolicy
        case terms
    }

    private struct AboutItem {
        let title: String
        let subtitle: String?
        let value: String?
        let icon: SettingsIcon?
        let action: AboutAction

        var isSelectable: Bool {
            switch action {
            case .none:
                return false
            case .copyUserID, .checkForUpdate, .privacyPolicy, .terms:
                return true
            }
        }
    }

    private enum Metrics {
        static let iconSize = CGSize(width: 30, height: 30)
        static let iconCornerRadius: CGFloat = 7.5
        static let imageToTextPadding: CGFloat = 15
        static let verticalPadding: CGFloat = 6
    }

    private var data: [(section: AboutSection, items: [AboutItem])] = []
    private(set) var checkUpdateTask: Task<Void, Never>?
    
    private(set) var isPremium: Bool
    private(set) var userID: String?
    weak var dataProvider: (any SettingsControllerDataProvider)?
    var openURL: OpenURLOperation = SystemActions.openURL
    var loadUpdate: @Sendable (String) async throws -> AppUpdate? = AppUpdateLookup.fetch
    var currentVersion: @MainActor () -> String? = { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String }
    var currentOSVersion: @MainActor () -> String = { UIDevice.current.systemVersion }
    var onAccountUpdate: (@MainActor (SettingsMailInfo?, Bool) -> Void)?
    private(set) var accountTask: Task<Void, Never>?
    private let accountLifetime = RequestLifetime()
    private let updateLifetime = RequestLifetime()
    private var accountResolved = false
    private let appID: String
    private let privacyURL: URL
    private let termsURL: URL
    
    init(isPremium: Bool, userID: String?, appID: String, privacyURL: URL, termsURL: URL) {
        self.isPremium = isPremium
        self.userID = userID
        self.appID = appID
        self.privacyURL = privacyURL
        self.termsURL = termsURL
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        checkUpdateTask?.cancel()
        accountTask?.cancel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 58

        setupData()
        observeAppearance()
        loadAccountInfo()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if settingsIsLeavingHierarchy { cancelRequests() }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !accountResolved && accountTask == nil { loadAccountInfo() }
    }

    func cancelAccountRequest() {
        accountLifetime.invalidate()
        accountTask?.cancel()
        accountTask = nil
    }

    func acceptAccountInfo(_ info: SettingsMailInfo?, premium: Bool) {
        cancelAccountRequest()
        accountResolved = true
        applyAccountInfo(info, premium: premium)
    }

    func cancelRequests() {
        cancelAccountRequest()
        updateLifetime.invalidate()
        checkUpdateTask?.cancel()
        checkUpdateTask = nil
        accountResolved = false
    }

    func applyAccountInfo(_ info: SettingsMailInfo?, premium: Bool) {
        let changed = userID != info?.userID || isPremium != premium
        userID = info?.userID
        isPremium = premium
        if changed, isViewLoaded { setupData(); tableView.reloadData() }
    }

    func loadAccountInfo() {
        guard let provider = dataProvider else { return }
        let lifetime = accountLifetime
        let request = lifetime.begin()
        accountTask?.cancel()
        let fallback = isPremium
        accountTask = Task { @MainActor [weak self] in
            defer { if lifetime.finish(request) { self?.accountTask = nil } }
            let result = await MailInfoResolver.resolve(provider: provider, fallbackPremium: fallback)
            guard !Task.isCancelled, lifetime.isCurrent(request) else { return }
            self?.accountResolved = true
            self?.applyAccountInfo(result.info, premium: result.isPremium ?? fallback)
            self?.onAccountUpdate?(result.info, result.isPremium ?? fallback)
        }
    }

    private func observeAppearance() {
        if #available(iOS 17, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self, UITraitAccessibilityContrast.self, UITraitDisplayScale.self]) { (controller: AboutAppController, _: UITraitCollection) in
                controller.tableView.reloadData()
            }
        }
    }

    @available(iOS, introduced: 8, deprecated: 17)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #unavailable(iOS 17), isViewLoaded { tableView.reloadData() }
    }
}

// MARK: - Data

private extension AboutAppController {

    static func icon(_ systemName: String, color: UIColor = .systemGray, inset: Inset? = Inset()) -> SettingsIcon {
        SettingsIcon(
            image: UIImage(systemName: systemName),
            color: color,
            inset: inset,
            cacheIdentifier: "sf:\(systemName)"
        )
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
        
        let region = Locale.current.regionCode ?? "-"
        
        data = [
            (
                .build,
                [
                    .init(
                        title: NSLocalizedString("Bundle ID", bundle: .module, comment: ""),
                        subtitle: bundleID,
                        value: nil,
                        icon: Self.icon("info.circle.fill"),
                        action: .none
                    ),
                    .init(
                        title: NSLocalizedString("App Version", bundle: .module, comment: ""),
                        subtitle: nil,
                        value: fullVersion,
                        icon: Self.icon("doc.fill"),
                        action: .none
                    ),
                    .init(
                        title: NSLocalizedString("Check for Update", bundle: .module, comment: ""),
                        subtitle: nil,
                        value: nil,
                        icon: nil,
                        action: .checkForUpdate
                    )
                ]
            ),
            (
                .links,
                [
                    .init(
                        title: NSLocalizedString("Privacy Policy", bundle: .module, comment: ""),
                        subtitle: nil,
                        value: nil,
                        icon: Self.icon("hand.raised.fill"),
                        action: .privacyPolicy
                    ),
                    .init(
                        title: NSLocalizedString("Terms of Use", bundle: .module, comment: ""),
                        subtitle: nil,
                        value: nil,
                        icon: Self.icon("doc.text.fill"),
                        action: .terms
                    )
                ]
            ),
            (
                .device,
                [
                    .init(
                        title: NSLocalizedString("OS Version", bundle: .module, comment: ""),
                        subtitle: osVersion,
                        value: nil,
                        icon: Self.icon("gearshape.fill"),
                        action: .none
                    ),
                    .init(
                        title: NSLocalizedString("Device Model", bundle: .module, comment: ""),
                        subtitle: deviceModel,
                        value: nil,
                        icon: Self.icon("iphone"),
                        action: .none
                    )
                ]
            ),
            (
                .account,
                [
                    .init(
                        title: NSLocalizedString("User ID", bundle: .module, comment: ""),
                        subtitle: userID ?? "-",
                        value: nil,
                        icon: Self.icon("person.fill"),
                        action: userID == nil ? .none : .copyUserID
                    ),
                    .init(
                        title: NSLocalizedString("Premium", bundle: .module, comment: ""),
                        subtitle: nil,
                        value: isPremium ? "true" : "false",
                        icon: Self.icon("star.fill"),
                        action: .none
                    )
                ]
            ),
            (
                .locale,
                [
                    .init(
                        title: NSLocalizedString("Preferred Language", bundle: .module, comment: ""),
                        subtitle: nil,
                        value: systemLanguage,
                        icon: Self.icon("keyboard.fill"),
                        action: .none
                    ),
                    .init(
                        title: NSLocalizedString("App Language", bundle: .module, comment: ""),
                        subtitle: nil,
                        value: appLanguage,
                        icon: Self.icon("at"),
                        action: .none
                    ),
                    .init(
                        title: NSLocalizedString("App Region", bundle: .module, comment: ""),
                        subtitle: nil,
                        value: region.lowercased(),
                        icon: Self.icon("globe"),
                        action: .none
                    )
                ]
            )
        ]
    }
}

// MARK: - UITableViewDataSource

extension AboutAppController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        data.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        data[section].items.count
    }
    
    override func tableView(
        _ tableView: UITableView,
        titleForHeaderInSection section: Int
    ) -> String? {
        data[section].section.title
    }

    override func tableView(
        _ tableView: UITableView,
        titleForFooterInSection section: Int
    ) -> String? {
        data[section].section.footer
    }
    
    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        
        let item = data[indexPath.section].items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withClass: UITableViewCell.self, for: indexPath)
        
        var config = item.subtitle == nil
            ? UIListContentConfiguration.valueCell()
            : UIListContentConfiguration.subtitleCell()

        if let icon = item.icon {
            config.image = icon.generateSettingsImage(
                size: Metrics.iconSize,
                cornerRadius: Metrics.iconCornerRadius,
                traitCollection: traitCollection
            )
            config.imageProperties.maximumSize = Metrics.iconSize
            config.imageProperties.reservedLayoutSize = Metrics.iconSize
            config.imageProperties.cornerRadius = Metrics.iconCornerRadius
        } else {
            config.image = nil
            config.imageProperties.reservedLayoutSize = .zero
        }

        config.imageToTextPadding = Metrics.imageToTextPadding
        config.directionalLayoutMargins.top = Metrics.verticalPadding
        config.directionalLayoutMargins.bottom = Metrics.verticalPadding

        config.text = item.title
        config.textProperties.color = item.action == .checkForUpdate ? view.tintColor : .label
        config.textProperties.numberOfLines = 0
        config.textProperties.lineBreakMode = .byWordWrapping

        config.secondaryText = item.action == .checkForUpdate && checkUpdateTask != nil
            ? NSLocalizedString("Checking…", bundle: .module, comment: "Update check in progress")
            : item.subtitle ?? item.value
        config.secondaryTextProperties.color = .secondaryLabel
        config.secondaryTextProperties.numberOfLines = 0
        config.secondaryTextProperties.lineBreakMode = .byWordWrapping

        cell.accessoryType = accessoryType(for: item)
        cell.accessoryView = nil
        cell.selectionStyle = item.isSelectable ? .default : .none
        cell.contentConfiguration = config
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension AboutAppController {

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = data[indexPath.section].items[indexPath.row]

        switch item.action {
        case .privacyPolicy:
            pushSafari(with: privacyURL)
            
        case .terms:
            pushSafari(with: termsURL)

        case .copyUserID:
            if let userID {
                UIPasteboard.general.string = userID
                AlertKitAPI.present(
                    title: NSLocalizedString("Copied", bundle: .module, comment: ""),
                    icon: .custom(UIImage(.doc.onClipboard)),
                    style: .iOS17AppleMusic,
                    haptic: .success
                )
            }
            
        case .checkForUpdate:
            checkForUpdate()

        case .none:
            break
        }

    }

    private func accessoryType(for item: AboutItem) -> UITableViewCell.AccessoryType {
        switch item.action {
        case .privacyPolicy, .terms:
            return .disclosureIndicator
        case .copyUserID, .checkForUpdate, .none:
            return .none
        }
    }

    private func pushSafari(with url: URL) {
        
        let safari = SFSafariViewController(url: url)
        present(safari, animated: true)
    }
}

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
                    self?.tableView.reloadData()
                }
            }
            do {
                guard let version, let update = try await lookup(appID) else { throw URLError(.cannotParseResponse) }
                guard !Task.isCancelled, lifetime.isCurrent(request), self?.settingsCanPresent == true else { return }
                if AppUpdateLookup.compare(version, update.version) != .orderedAscending {
                    self?.showUpdateMessage(NSLocalizedString("Latest version is installed", bundle: .module, comment: ""))
                } else if AppUpdateLookup.compare(osVersion, update.minimumOSVersion) == .orderedAscending {
                    self?.showUpdateMessage(NSLocalizedString("Update requires a newer iOS version", bundle: .module, comment: "Update cannot run on this OS"))
                } else {
                    self?.showAvailableUpdate(update)
                }
            } catch {
                guard !Task.isCancelled, !(error is CancellationError), (error as? URLError)?.code != .cancelled,
                      lifetime.isCurrent(request), self?.settingsCanPresent == true else { return }
                self?.showUpdateMessage(NSLocalizedString("Unable to check for updates", bundle: .module, comment: "Retry the update check later"))
            }
        }
        tableView.reloadData()
    }

    private func showUpdateMessage(_ title: String) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", bundle: .module, comment: ""), style: .default))
        present(alert, animated: true)
    }

    private func showAvailableUpdate(_ update: AppUpdate) {
        let alert = UIAlertController(
            title: NSLocalizedString("Update available", bundle: .module, comment: "App Store update"),
            message: String(format: NSLocalizedString("Version %@ is available.", bundle: .module, comment: "App version number"), update.version),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("Not Now", bundle: .module, comment: ""), style: .cancel))
        let open = openURL
        let action = UIAlertAction(title: NSLocalizedString("Update", bundle: .module, comment: ""), style: .default) { _ in
            Task { @MainActor in _ = await open(update.url) }
        }
        alert.addAction(action)
        alert.preferredAction = action
        present(alert, animated: true)
    }
}
