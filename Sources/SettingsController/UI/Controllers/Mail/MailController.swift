//
//  MailController.swift
//  SettingsController
//
//  Created by Влад Лыков on 11.04.2026.
//

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

        guard let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? MailCell else {
            return
        }
        cell.textViewBecomeFirstResponder()
    }
}

// MARK: - Setup View

extension MailController {

    private func setupView() {

        tableView.register(MailCell.self)

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100

        setupNavigationBar()
    }

    private func setupNavigationBar() {

        title = type.navigationTitle

        navigationItem.largeTitleDisplayMode = .never

        let closeButton = UIBarButtonItem(
            systemItem: .close,
            primaryAction: .init { [weak self] _ in
                self?.cancelMailPreparation()
                self?.dismiss(animated: true)
            })

        closeButton.accessibilityIdentifier = "settings.mail.close"
        navigationItem.leftBarButtonItem = closeButton
        navigationItem.rightBarButtonItem = sendButton
    }
}

// MARK: - UITableViewDataSource

extension MailController {

    public override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }

    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        NSLocalizedString("Message", bundle: .module, comment: "Section heading for the editable support message.")
    }

    public override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        NSLocalizedString(
            "After tapping Send, a draft opens in your mail app. Review it and send it there.", bundle: .module,
            comment: "Mail form footer explaining that the external mail app opens a draft and the user sends it there.")
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withClass: MailCell.self, for: indexPath)

        cell.delegate = self
        cell.configure(type: type, text: currentText)

        return cell
    }
}

// MARK: - MailCellDelegate

extension MailController: MailCellDelegate {

    func mailCell(_ cell: MailCell, didChangeText text: String, needsHeightUpdate: Bool) {

        if currentText != text { pendingMailFallback = nil }
        // A later edit revokes the pending snapshot instead of opening stale text.
        if isPreparingMail && currentText != text { cancelMailPreparation() }
        currentText = text

        sendButton.isEnabled = !isPreparingMail && text.prefix(type.minCharactersCount).count >= type.minCharactersCount

        if needsHeightUpdate {
            UIView.performWithoutAnimation {
                tableView.beginUpdates()
                tableView.endUpdates()
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
        sendButton.isEnabled = !preparing && currentText.prefix(type.minCharactersCount).count >= type.minCharactersCount
        navigationItem.rightBarButtonItem = sendButton
    }

    func prepareMail() {
        guard !isPreparingMail, currentText.prefix(type.minCharactersCount).count >= type.minCharactersCount else { return }
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
            if !opened {
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
