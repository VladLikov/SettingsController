//
//  MailController.swift
//  SettingsController
//
//  Created by Влад Лыков on 11.04.2026.
//

import UIKit
import SafeSFSymbols

public enum MailType: Equatable {
    case supportRequest,
         languageRequest,
         custom(placeholder: String, minCharactersCount: Int, navigationTitle: String, subject: String)
    
    public var navigationTitle: String {
        switch self {
        case .supportRequest:
            return NSLocalizedString("Ask Support a Question", bundle: .module, comment: "")
            
        case .languageRequest:
            return NSLocalizedString("Request a Language", bundle: .module, comment: "")
            
        case .custom(_, _, let navigationTitle, _):
            return navigationTitle
        }
    }
    
    public var placeholder: String {
        switch self {
        case .supportRequest:
            return NSLocalizedString("What went wrong? Add at least 10 characters. The more detail, the faster we can help.", bundle: .module, comment: "")
            
        case .languageRequest:
            return NSLocalizedString("Which language would you like to see in the app?", bundle: .module, comment: "")
            
        case .custom(let placeholder, _, _, _):
            return placeholder
        }
    }
    
    public var minCharactersCount: Int {
        switch self {
        case .supportRequest:
            return 10
        case .languageRequest:
            return 2
        case .custom(_, let minCharactersCount, _, _):
            return minCharactersCount
        }
    }
    
    public var subject: String {
        switch self {
        case .supportRequest:
            return NSLocalizedString("Support Request", bundle: .module, comment: "")

        case .languageRequest:
            return NSLocalizedString("Language Request", bundle: .module, comment: "")
            
        case .custom(_, _, _, let subject):
            return subject
        }
    }
}

// MARK: - MailController

@MainActor
public class MailController: UITableViewController {
    
    // MARK: Properties [Private]

    private let type: MailType
    private let email: String
    private let isPremium: Bool?
    private let productID: String?
    private weak var dataProvider: (any SettingsControllerDataProvider)?
    private var mailTask: Task<Void, Never>?
    private var isPreparingMail = false
    private let mailLifetime = RequestLifetime()
    var openURL: OpenURLOperation = SystemActions.openURL
    private lazy var progress = UIActivityIndicatorView(style: .medium)

    private var currentText: String = ""
        
    // MARK: UI Elements [Private]

    private lazy var sendButton: UIBarButtonItem = {
        
        let button = UIBarButtonItem(image: UIImage(.arrow.up),
                                         primaryAction: .init { [weak self] _ in
            
            self?.prepareMail()
        })
        
        if #available(iOS 26.0, *) {
            button.style = .prominent
        }
        
        button.accessibilityLabel = NSLocalizedString("Send", bundle: .module, comment: "Prepare a draft in the mail app")
        button.isEnabled = false
        
        return button
    }()
    
    // MARK: Life Cycle

    public init(type: MailType, email: String, isPremium: Bool? = nil, productID: String? = nil, dataProvider: (any SettingsControllerDataProvider)? = nil) {
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
    
    deinit { mailTask?.cancel() }

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if settingsIsLeavingHierarchy { cancelMailPreparation() }
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
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
        
        let closeButton = UIBarButtonItem(systemItem: .close,
                                          primaryAction: .init { [weak self] _ in
            self?.cancelMailPreparation()
            self?.dismiss(animated: true)
        })
        
        navigationItem.leftBarButtonItem = closeButton
        navigationItem.rightBarButtonItem = sendButton
    }
}

// MARK: - UITableViewDataSource

extension MailController {
        
    public override func numberOfSections(in tableView: UITableView) -> Int { 1 }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }
    
    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        NSLocalizedString("Message", bundle: .module, comment: "")
    }
    
    public override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        NSLocalizedString("After tapping Send, a draft opens in your mail app. Review it and send it there.", bundle: .module, comment: "")
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

        currentText = text

        sendButton.isEnabled = !isPreparingMail && text.count >= type.minCharactersCount

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
        mailLifetime.invalidate()
        mailTask?.cancel()
        mailTask = nil
        setPreparingMail(false)
    }

    private func setPreparingMail(_ preparing: Bool) {
        isPreparingMail = preparing
        if preparing {
            progress.startAnimating()
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: progress)
        } else {
            progress.stopAnimating()
            sendButton.isEnabled = currentText.count >= type.minCharactersCount
            navigationItem.rightBarButtonItem = sendButton
        }
    }

    func prepareMail() {
        guard !isPreparingMail, currentText.count >= type.minCharactersCount else { return }
        setPreparingMail(true)
        let request = mailLifetime.begin()
        let lifetime = mailLifetime
        let text = currentText
        let provider = dataProvider
        let fallback = isPremium
        let recipient = email
        let type = type
        let product = productID
        let open = openURL

        mailTask = Task { @MainActor [weak self] in
            let diagnostics = await MailInfoResolver.resolve(provider: provider, fallbackPremium: fallback)
            guard !Task.isCancelled, lifetime.isCurrent(request), self?.settingsCanPresent == true else {
                self?.finishMailPreparation(request)
                return
            }
            let draft = MailBuilder.makeDraft(
                with: text, recipient: recipient, type: type,
                isPremium: diagnostics.isPremium, productID: product,
                mailInfo: diagnostics.info, environment: .current()
            )
            let opened: Bool
            if let url = draft.url { opened = await open(url) } else { opened = false }
            guard !Task.isCancelled, lifetime.isCurrent(request) else { return }
            self?.finishMailPreparation(request)
            if !opened, self?.settingsCanPresent == true { self?.showMailFallback(draft) }
        }
    }

    private func finishMailPreparation(_ request: UUID) {
        guard mailLifetime.finish(request) else { return }
        mailTask = nil
        setPreparingMail(false)
    }

    private func showMailFallback(_ draft: MailDraft) {
        let alert = UIAlertController(
            title: NSLocalizedString("Unable to open a mail app", bundle: .module, comment: "Mail URL failed"),
            message: NSLocalizedString("Your message is still here. You can copy the support address or message.", bundle: .module, comment: "Mail fallback"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("Copy Address", bundle: .module, comment: "Mail fallback"), style: .default) { _ in
            UIPasteboard.general.string = draft.recipient
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("Copy Message", bundle: .module, comment: "Mail fallback"), style: .default) { _ in
            UIPasteboard.general.string = draft.subject + "\n\n" + draft.body
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", bundle: .module, comment: ""), style: .cancel))
        present(alert, animated: true)
    }
}
