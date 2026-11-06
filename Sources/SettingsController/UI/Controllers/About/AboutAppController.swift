import AlertKit
import SafariServices
import SafeSFSymbols
import UIKit

// MARK: - AboutAppController

final class AboutAppController: UITableViewController {

    enum AboutSection {
        case update
        case links
        case device
        case account
        case locale

        var title: String? {
            switch self {
            case .update, .links:
                return nil
            case .device:
                return NSLocalizedString("Device", bundle: .module, comment: "About section heading for operating system and device model.")
            case .account:
                return NSLocalizedString("Account", bundle: .module, comment: "Section heading for the current User ID and premium status.")
            case .locale:
                return NSLocalizedString("Locale", bundle: .module, comment: "About section heading for language and region diagnostics.")
            }
        }

        var footer: String? {
            switch self {
            case .account:
                return NSLocalizedString(
                    "Tap User ID to copy. Support may request it.", bundle: .module,
                    comment: "Account section footer explaining the explicit copy action.")
            case .update, .links, .device, .locale:
                return nil
            }
        }
    }

    enum AboutAction {
        case none
        case copyUserID
        case checkForUpdate
        case privacyPolicy
        case terms
    }

    struct AboutItem {
        let title: String
        let subtitle: String?
        let value: String?
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

    var data: [(section: AboutSection, items: [AboutItem])] = []
    let updateCheck = CancellableRequest()
    var dataSource: TitledDataSource<AboutSection, String>?
    private struct HeaderSizeKey: Equatable {
        let width: CGFloat
        let category: UIContentSizeCategory
    }
    private var headerSizeKey: HeaderSizeKey?
    var checkUpdateTask: Task<Void, Never>? { updateCheck.task }

    private(set) var isPremium: Bool
    private(set) var userID: String?
    weak var dataProvider: (any SettingsControllerDataProvider)?
    var openURL: OpenURLOperation = SystemActions.openURL
    var haptics = SettingsHaptics(storage: nil)
    var loadUpdate: @Sendable (String) async throws -> AppUpdate? = AppUpdateLookup.fetch
    var currentVersion: @MainActor () -> String? = { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String }
    var currentOSVersion: @MainActor () -> String = { UIDevice.current.systemVersion }
    var onAccountUpdate: (@MainActor (SettingsMailInfo?, Bool) -> Void)?
    let accountRequest = CancellableRequest()
    var accountTask: Task<Void, Never>? { accountRequest.task }
    var accountResolved = false
    let appID: String
    let privacyURL: URL
    let termsURL: URL

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

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 58

        setupData()
        installDataSource()
        installHeader()
        observeAppearance()
        loadAccountInfo()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sizeHeader()
    }

    /// The app icon, name, version and bundle ID above the list.
    private func installHeader() {
        let app = Self.appHeader
        tableView.tableHeaderView = AboutAppHeaderView(
            icon: AboutAppHeaderView.appIcon(), name: app.name, version: app.version, bundleID: app.bundleID)
    }

    /// A table header keeps its frame; resize it when the width or the text size changes.
    private func sizeHeader() {
        guard let header = tableView.tableHeaderView else { return }
        let width = tableView.bounds.width
        let key = HeaderSizeKey(width: width, category: traitCollection.preferredContentSizeCategory)
        guard width > 0, key != headerSizeKey else { return }
        headerSizeKey = key
        let height = header.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel
        ).height
        header.frame = CGRect(x: 0, y: 0, width: width, height: ceil(height))
        tableView.tableHeaderView = header
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
        accountRequest.cancel()
    }

    func acceptAccountInfo(_ info: SettingsMailInfo?, premium: Bool) {
        cancelAccountRequest()
        accountResolved = true
        applyAccountInfo(info, premium: premium)
    }

    func cancelRequests() {
        cancelAccountRequest()
        let wasChecking = updateCheck.isRunning
        updateCheck.cancel()
        if wasChecking { refreshUpdateRow() }
        accountResolved = false
    }

    func applyAccountInfo(_ info: SettingsMailInfo?, premium: Bool) {
        let changed = userID != info?.userID || isPremium != premium
        userID = info?.userID
        isPremium = premium
        if changed, isViewLoaded, let section = data.firstIndex(where: { $0.section == .account }) {
            data[section].items = accountItems()
            reconfigureRows(titled: data[section].items.map(\.title))
        }
    }

    func loadAccountInfo() {
        guard let provider = dataProvider else { return }
        let fallback = isPremium
        accountRequest.start { [weak self] token in
            let result = await MailInfoResolver.resolve(provider: provider, fallbackPremium: fallback)
            guard token.isCurrent else { return }
            self?.accountResolved = true
            self?.applyAccountInfo(result.info, premium: result.isPremium ?? fallback)
            self?.onAccountUpdate?(result.info, result.isPremium ?? fallback)
        }
    }

    private func observeAppearance() {
        if #available(iOS 17, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self, UITraitAccessibilityContrast.self, UITraitDisplayScale.self]) {
                (controller: AboutAppController, _: UITraitCollection) in
                controller.refreshVisibleRows()
            }
        }
    }

    @available(iOS, introduced: 8, deprecated: 17)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #unavailable(iOS 17), isViewLoaded,
            previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle
                || previousTraitCollection?.accessibilityContrast != traitCollection.accessibilityContrast
                || previousTraitCollection?.displayScale != traitCollection.displayScale
        {
            refreshVisibleRows()
        }
    }
}

// MARK: - Data source

extension AboutAppController {

    private func installDataSource() {
        let dataSource = TitledDataSource<AboutSection, String>(tableView: tableView) { [unowned self] tableView, indexPath, _ in
            makeCell(in: tableView, at: indexPath)
        }
        dataSource.header = { $0.title }
        dataSource.footer = { $0.footer }
        self.dataSource = dataSource
        tableView.dataSource = dataSource
        var snapshot = NSDiffableDataSourceSnapshot<AboutSection, String>()
        for group in data {
            snapshot.appendSections([group.section])
            snapshot.appendItems(group.items.map(\.title), toSection: group.section)
        }
        UIView.performWithoutAnimation { dataSource.apply(snapshot, animatingDifferences: false) }
    }

    /// Re-renders the rows with the given titles, which identify About rows.
    func reconfigureRows(titled titles: [String]) {
        dataSource?.reconfigure(titles)
    }

    private func makeCell(in tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let item = data[indexPath.section].items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withClass: UITableViewCell.self, for: indexPath)

        // As in Settings › General › About: the label on the left, its value on the right.
        // A long value, such as a User ID, goes under its label instead.
        var config =
            item.subtitle == nil
            ? UIListContentConfiguration.valueCell()
            : UIListContentConfiguration.subtitleCell()
        config.applySettingsRowLayout()

        config.text = item.title
        config.textProperties.color = item.action == .checkForUpdate ? view.tintColor : .label

        let isChecking = item.action == .checkForUpdate && checkUpdateTask != nil
        config.secondaryText = isChecking ? nil : item.subtitle ?? item.value
        config.secondaryTextProperties.color = .secondaryLabel

        cell.accessoryType = accessoryType(for: item)
        if isChecking {
            let indicator = (cell.accessoryView as? UIActivityIndicatorView) ?? UIActivityIndicatorView(style: .medium)
            indicator.isAccessibilityElement = false
            indicator.startAnimating()
            cell.accessoryView = indicator
        } else {
            (cell.accessoryView as? UIActivityIndicatorView)?.stopAnimating()
            cell.accessoryView = nil
        }
        cell.accessibilityIdentifier = item.action == .checkForUpdate ? "settings.about.checkUpdate" : nil
        cell.accessibilityValue =
            isChecking
            ? NSLocalizedString(
                "Checking…", bundle: .module,
                comment: "VoiceOver status of the About update-check row while its activity indicator is spinning.")
            : nil
        cell.selectionStyle = item.isSelectable && !isChecking ? .default : .none
        cell.contentConfiguration = config

        return cell
    }
}

// MARK: - UITableViewDelegate

extension AboutAppController {

    /// Every diagnostic value can be copied for support, not only the User ID.
    override func tableView(
        _ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint
    ) -> UIContextMenuConfiguration? {
        let item = data[indexPath.section].items[indexPath.row]
        guard let text = item.subtitle ?? item.value, !text.isEmpty, text != "-" else { return nil }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(children: [
                UIAction(
                    title: NSLocalizedString(
                        "Copy", bundle: .module, comment: "Context menu action copying a diagnostic value from About."),
                    image: UIImage(systemName: "doc.on.doc")
                ) { _ in
                    UIPasteboard.general.string = text
                    UIAccessibility.post(
                        notification: .announcement,
                        argument: NSLocalizedString(
                            "Copied", bundle: .module, comment: "Confirmation after the user explicitly copies an identifier."))
                }
            ])
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = data[indexPath.section].items[indexPath.row]

        switch item.action {
        case .privacyPolicy:
            presentSafari(with: privacyURL)

        case .terms:
            presentSafari(with: termsURL)

        case .copyUserID:
            if let userID {
                UIPasteboard.general.string = userID
                AlertKitAPI.present(
                    title: NSLocalizedString(
                        "Copied", bundle: .module, comment: "Confirmation after the user explicitly copies an identifier."),
                    icon: .custom(UIImage(.doc.onClipboard)),
                    style: .settingsConfirmation,
                    haptic: haptics.alertHaptic
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

    static func validatedWebURL(_ url: URL) -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let scheme = components.scheme?.lowercased(), ["http", "https"].contains(scheme),
            let host = components.host, !host.isEmpty
        else { return nil }
        components.scheme = scheme
        return components.url
    }

    private func presentSafari(with url: URL) {
        guard let url = Self.validatedWebURL(url) else {
            let alert = UIAlertController(
                title: NSLocalizedString(
                    "Unable to open link", bundle: .module,
                    comment: "About error when the configured Privacy or Terms link is not an absolute HTTP or HTTPS URL."),
                message: nil, preferredStyle: .alert
            )
            alert.addAction(
                UIAlertAction(
                    title: NSLocalizedString("OK", bundle: .module, comment: "Dismiss the invalid Privacy or Terms link alert."),
                    style: .cancel))
            present(alert, animated: true)
            return
        }
        present(SFSafariViewController(url: url), animated: true)
    }
}
