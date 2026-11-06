import SafeSFSymbols
import UIKit

// MARK: - MailController

@MainActor
public class MailController: UITableViewController {

    // MARK: Properties [Private]

    private let type: MailType
    private let email: String
    private let isPremium: Bool?
    private let productID: String?
    private weak var dataProvider: (any SettingsControllerDataProvider)?
    private let mailRequest = CancellableRequest()
    private var dataSource: TitledDataSource<Section, Item>?
    var mailTask: Task<Void, Never>? { mailRequest.task }
    private var isPreparingMail = false
    private var pendingMailFallback: MailDraft?
    private var fallbackPresentationScheduled = false
    var openURL: OpenURLOperation = SystemActions.openURL

    private var currentText: String = ""

    // MARK: UI Elements [Private]

    private lazy var sendButton: UIBarButtonItem = {

        let button = UIBarButtonItem(
            image: UIImage(.arrow.up),
            primaryAction: .init { [weak self] _ in

                self?.prepareMail()
            })

        if #available(iOS 26.0, *) {
            button.style = .prominent
        }

        button.accessibilityIdentifier = "settings.mail.send"
        button.accessibilityLabel = NSLocalizedString(
            "Send", bundle: .module, comment: "Mail navigation action preparing an external draft; it does not send the email itself.")
        button.isEnabled = type.minCharactersCount == 0

        return button
    }()

    private lazy var closeButton = UIBarButtonItem(
        systemItem: .close,
        primaryAction: .init { [weak self] _ in self?.closeRequested() })

    // MARK: Life Cycle

    public init(
        type: MailType, email: String, isPremium: Bool? = nil, productID: String? = nil,
        dataProvider: (any SettingsControllerDataProvider)? = nil
    ) {
        self.type = type
        self.email = email
        self.isPremium = isPremium
        self.productID = productID
        self.dataProvider = dataProvider

        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        NotificationCenter.default.addObserver(
            self, selector: #selector(retryMailFallbackAfterActivation(_:)),
            name: UIApplication.didBecomeActiveNotification, object: nil
        )
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if settingsIsLeavingHierarchy { cancelMailPreparation() }
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if presentPendingMailFallbackIfPossible() { return }

        guard let cell = tableView.cellForRow(at: Self.messageIndexPath) as? MailCell else {
            return
        }
        cell.beginEditing()
    }
}

// MARK: - Setup View

extension MailController {

    private func setupView() {

        tableView.register(MailCell.self)
        tableView.register(UITableViewCell.self)
        installDataSource()

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100

        setupNavigationBar()
    }

    private func setupNavigationBar() {

        title = type.navigationTitle

        navigationItem.largeTitleDisplayMode = .never

        closeButton.accessibilityIdentifier = "settings.mail.close"
        navigationItem.leftBarButtonItem = closeButton
        navigationItem.rightBarButtonItem = sendButton
    }
}

// MARK: - Data source

extension MailController {

    /// One section with the message field. The cell keeps its text view, so typing never re-creates it.
    enum Section: Hashable, Sendable {
        case recipient, message, diagnostics
    }

    enum Item: Hashable, Sendable {
        case recipient
        case message
        case diagnostic(Int)
    }

    static let messageIndexPath = IndexPath(row: 0, section: 1)

    /// Like a Mail draft: who it goes to, the message, and the device details that will be attached.
    func installDataSource() {
        let diagnostics = Self.diagnostics()
        let dataSource = TitledDataSource<Section, Item>(tableView: tableView) { [unowned self] tableView, indexPath, item in
            switch item {
            case .recipient:
                let cell = tableView.dequeueReusableCell(withClass: UITableViewCell.self, for: indexPath)
                var configuration = UIListContentConfiguration.subtitleCell()
                configuration.text = email
                configuration.secondaryText = "\(MailEnvironment.current().appName) \(type.subject)"
                configuration.secondaryTextProperties.color = .secondaryLabel
                configuration.applySettingsRowLayout()
                configuration.applySettingsIcon(
                    SettingsIcon(
                        image: UIImage(systemName: "envelope.fill"), color: .systemBlue, padding: IconPadding(),
                        cacheIdentifier: "sf:envelope.fill"
                    )
                    .generateSettingsImage(traitCollection: traitCollection))
                cell.contentConfiguration = configuration
                cell.selectionStyle = .none
                cell.accessibilityIdentifier = "settings.mail.recipient"
                return cell

            case .message:
                let cell = tableView.dequeueReusableCell(withClass: MailCell.self, for: indexPath)
                cell.delegate = self
                cell.configure(type: type, text: currentText)
                cell.showMissingCharacters(type.missingCharacters(in: currentText))
                return cell

            case .diagnostic(let index):
                let cell = tableView.dequeueReusableCell(withClass: UITableViewCell.self, for: indexPath)
                var configuration = UIListContentConfiguration.valueCell()
                configuration.text = diagnostics[index].title
                configuration.secondaryText = diagnostics[index].value
                configuration.applySettingsRowLayout()
                cell.contentConfiguration = configuration
                cell.selectionStyle = .none
                return cell
            }
        }
        dataSource.header = { section in
            switch section {
            case .recipient: nil
            case .message: NSLocalizedString("Message", bundle: .module, comment: "Section heading for the editable support message.")
            case .diagnostics:
                NSLocalizedString("Device", bundle: .module, comment: "About section heading for operating system and device model.")
            }
        }
        dataSource.footer = { section in
            guard section == .diagnostics else { return nil }
            return NSLocalizedString(
                "After tapping Send, a draft opens in your mail app. Review it and send it there.", bundle: .module,
                comment: "Mail form footer explaining that the external mail app opens a draft and the user sends it there.")
        }
        self.dataSource = dataSource
        tableView.dataSource = dataSource
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.recipient, .message, .diagnostics])
        snapshot.appendItems([.recipient], toSection: .recipient)
        snapshot.appendItems([.message], toSection: .message)
        snapshot.appendItems(diagnostics.indices.map { .diagnostic($0) }, toSection: .diagnostics)
        UIView.performWithoutAnimation { dataSource.apply(snapshot, animatingDifferences: false) }
    }

    /// The device details the draft carries, shown so the user knows what is sent.
    private static func diagnostics() -> [(title: String, value: String)] {
        let info = Bundle.main.infoDictionary
        let version = "\(info?["CFBundleShortVersionString"] as? String ?? "-") (\(info?["CFBundleVersion"] as? String ?? "-"))"
        return [
            (
                NSLocalizedString("App Version", bundle: .module, comment: "Diagnostic label for the installed app version and build."),
                version
            ),
            (
                NSLocalizedString("OS Version", bundle: .module, comment: "Diagnostic label for the operating system version."),
                AboutAppController.systemVersionDescription
            ),
            (
                NSLocalizedString(
                    "Device Model", bundle: .module,
                    comment: "Diagnostic label for the hardware model, without a user-assigned device name."),
                DeviceModel.supportDescription
            ),
        ]
    }
}

// MARK: - MailCellDelegate

extension MailController: MailCellDelegate {

    func mailCell(_ cell: MailCell, didChangeText text: String, needsHeightUpdate: Bool) {

        if currentText != text { pendingMailFallback = nil }
        // A later edit revokes the pending snapshot instead of opening stale text.
        if isPreparingMail && currentText != text { cancelMailPreparation() }
        currentText = text

        sendButton.isEnabled = !isPreparingMail && type.allowsSending(text)
        updateDiscardProtection()

        let requirementChanged = cell.showMissingCharacters(type.missingCharacters(in: text))
        if needsHeightUpdate || requirementChanged {
            UIView.performWithoutAnimation {
                tableView.beginUpdates()
                tableView.endUpdates()
            }
            // The row grows with the text; keep the caret above the keyboard.
            if let caret = cell.caretRect(in: tableView) {
                tableView.scrollRectToVisible(caret.insetBy(dx: 0, dy: -8), animated: false)
            }
        }
    }
}

extension MailController {
    func cancelMailPreparation() {
        pendingMailFallback = nil
        mailRequest.cancel()
        setPreparingMail(false)
    }

    private func setPreparingMail(_ preparing: Bool) {
        isPreparingMail = preparing
        sendButton.isEnabled = !preparing && type.allowsSending(currentText)
        navigationItem.rightBarButtonItem = sendButton
    }

    func prepareMail() {
        guard !isPreparingMail, type.allowsSending(currentText) else { return }
        pendingMailFallback = nil
        setPreparingMail(true)
        let text = currentText
        let provider = dataProvider
        let fallback = isPremium
        let recipient = email
        let type = type
        let product = productID
        let open = openURL

        mailRequest.start { [weak self] token in
            let diagnostics = await MailInfoResolver.resolve(provider: provider, fallbackPremium: fallback)
            guard token.isCurrent, self?.settingsCanPresent == true else {
                self?.finishMailPreparation(token)
                return
            }
            let draft = MailBuilder.makeDraft(
                with: text, recipient: recipient, type: type,
                isPremium: diagnostics.isPremium, productID: product,
                mailInfo: diagnostics.info, environment: .current()
            )
            let opened: Bool
            if let url = draft.url { opened = await open(url) } else { opened = false }
            guard token.isCurrent else { return }
            self?.finishMailPreparation(token)
            if opened {
                self?.closeAfterOpeningMail()
            } else {
                self?.pendingMailFallback = draft
                self?.presentPendingMailFallbackIfPossible()
            }
        }
    }

    private func finishMailPreparation(_ token: CancellableRequest.Token) {
        guard token.finish() else { return }
        setPreparingMail(false)
    }

    @objc private func retryMailFallbackAfterActivation(_ notification: Notification) {
        presentPendingMailFallbackIfPossible()
    }

    @discardableResult
    private func presentPendingMailFallbackIfPossible(afterTransition: Bool = false) -> Bool {
        guard let draft = pendingMailFallback, settingsCanPresent else { return false }
        if let scene = view.window?.windowScene, scene.activationState != .foregroundActive { return false }
        var ancestor: UIViewController? = self
        while let controller = ancestor {
            guard controller.presentedViewController == nil else { return false }
            if !afterTransition, let transition = controller.transitionCoordinator {
                if !fallbackPresentationScheduled {
                    fallbackPresentationScheduled = true
                    let registered = transition.animate(alongsideTransition: nil) { [weak self] _ in
                        self?.fallbackPresentationScheduled = false
                        self?.presentPendingMailFallbackIfPossible(afterTransition: true)
                    }
                    if !registered { fallbackPresentationScheduled = false }
                }
                return false
            }
            ancestor = controller.parent
        }
        pendingMailFallback = nil
        view.endEditing(true)
        showMailFallback(draft)
        return true
    }

    private func showMailFallback(_ draft: MailDraft) {
        let alert = UIAlertController(
            title: NSLocalizedString(
                "Unable to open a mail app", bundle: .module,
                comment: "Recovery alert title when the external mailto handler cannot be opened."),
            message: NSLocalizedString(
                "Your message is still here. You can copy the support address or message.", bundle: .module,
                comment:
                    "Mail recovery explanation: the editable message is preserved and the user can explicitly copy the address or full draft."
            ),
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(
                title: NSLocalizedString(
                    "Copy Address", bundle: .module,
                    comment: "Mail recovery action copying only the support email address to the clipboard."), style: .default
            ) { _ in
                UIPasteboard.general.string = draft.recipient
            })
        alert.addAction(
            UIAlertAction(
                title: NSLocalizedString(
                    "Copy Message", bundle: .module,
                    comment: "Mail recovery action copying the draft subject and full body to the clipboard."), style: .default
            ) { _ in
                UIPasteboard.general.string = draft.subject + "\n\n" + draft.body
            })
        alert.addAction(
            UIAlertAction(
                title: NSLocalizedString(
                    "Cancel", bundle: .module, comment: "Cancel action dismissing the mail recovery alert without changing the message."),
                style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - Unsaved message protection

extension MailController: UIAdaptivePresentationControllerDelegate {
    private var hasUnsentText: Bool {
        !currentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// A typed message blocks the swipe-down dismissal; the attempt asks before discarding it.
    func updateDiscardProtection() {
        let container = navigationController ?? self
        container.isModalInPresentation = hasUnsentText
        if hasUnsentText, container.presentationController?.delegate == nil {
            container.presentationController?.delegate = self
        }
    }

    public func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        confirmDiscard()
    }

    func closeRequested() {
        guard hasUnsentText else { return close() }
        confirmDiscard()
    }

    private func confirmDiscard() {
        guard presentedViewController == nil else { return }
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(
            UIAlertAction(
                title: NSLocalizedString(
                    "Discard Message", bundle: .module,
                    comment: "Destructive action that closes the support form and deletes the typed message."),
                style: .destructive
            ) { [weak self] _ in self?.close() })
        sheet.addAction(
            UIAlertAction(
                title: NSLocalizedString(
                    "Cancel", bundle: .module,
                    comment: "Cancel action dismissing the mail recovery alert without changing the message."),
                style: .cancel))
        sheet.popoverPresentationController?.barButtonItem = closeButton
        present(sheet, animated: true)
    }

    private func close() {
        cancelMailPreparation()
        (navigationController ?? self).isModalInPresentation = false
        dismiss(animated: true)
    }

    /// After the mail app opened the draft, the form has done its job.
    func closeAfterOpeningMail() {
        let container = navigationController ?? self
        // Only a form presented modally as its own screen closes itself; a pushed form stays for the host.
        guard container.presentingViewController != nil, navigationController.map({ $0.viewControllers.first === self }) ?? true
        else { return }
        container.isModalInPresentation = false
        container.dismiss(animated: true)
    }
}
