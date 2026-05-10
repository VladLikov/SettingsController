//
//  MailController.swift
//  SettingsController
//
//  Created by Влад Лыков on 11.04.2026.
//

import UIKit
import SafeSFSymbols
import MessageUI

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
    private let userID: String?
    private let isPremium: Bool?

    private var currentText: String = ""
        
    // MARK: UI Elements [Private]

    private lazy var sendButton: UIBarButtonItem = {
        
        let button = UIBarButtonItem(image: UIImage(.arrow.up),
                                         primaryAction: .init { [weak self] _ in
            
            guard let self else { return }
            guard MailAvailability.canSendEmail() else { return }
            
            let text = currentText
        
            let urlString = MailBuilder.buildMail(
                with: text,
                recipient: email,
                type: type,
                userID: userID,
                isPremium: isPremium
            )
            
            if let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        })
        
        if #available(iOS 26.0, *) {
            button.style = .prominent
        }
        
        button.isEnabled = false
        
        return button
    }()
    
    // MARK: Life Cycle

    public init(type: MailType, email: String, userID: String? = nil, isPremium: Bool? = nil) {
        self.type = type
        self.email = email
        self.userID = userID
        self.isPremium = isPremium
        
        super.init(style: .insetGrouped)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
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
        NSLocalizedString("After tapping Send, you'll be redirected to the Mail app and the message will be sent from your mailbox.", bundle: .module, comment: "")
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withClass: MailCell.self, for: indexPath)
        
        cell.delegate = self
        cell.configure(type: type)
        
        return cell
    }
}

// MARK: - MailCellDelegate

extension MailController: MailCellDelegate {

    func mailCell(_ cell: MailCell, didChangeText text: String, needsHeightUpdate: Bool) {

        currentText = text

        sendButton.isEnabled = text.count >= type.minCharactersCount

        if needsHeightUpdate {
            UIView.performWithoutAnimation {
                tableView.beginUpdates()
                tableView.endUpdates()
            }
        }
    }
}
