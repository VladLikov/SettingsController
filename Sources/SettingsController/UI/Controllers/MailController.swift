//
//  MailController 2.swift
//  SettingsController
//
//  Created by Влад Лыков on 11.04.2026.
//

import UIKit
import SafeSFSymbols
import SwiftBoost
import MessageUI

public enum MailType {
    case supportRequest, languageRequest
    
    public var placeholder: String {
        switch self {
        case .supportRequest: NSLocalizedString("What went wrong? Add at least 10 characters. The more detail, the faster we can help.", bundle: .module, comment: "")
        case .languageRequest: NSLocalizedString("Which language would you like to see in the app?", bundle: .module, comment: "")
        }
    }
    
    public var minCharactersCount: Int {
        switch self {
        case .supportRequest: 10
        case .languageRequest: 2
        }
    }
}

// MARK: - MailController

@MainActor
public class MailController: UITableViewController {
    
    // MARK: Properties [Private]

    private let type: MailType
    private let email: String

    private var currentText: String = ""
        
    // MARK: UI Elements [Private]

    private lazy var sendButton: UIBarButtonItem = {
        
        let button = UIBarButtonItem(image: UIImage(.arrow.up),
                                         primaryAction: .init { [weak self] _ in
            
            guard let self else { return }
            guard MFMailComposeViewController.canSendEmail() else { return }
            
            let text = currentText
        
            let urlString = MailBuilder.buildMail(with: text, recipient: email, type: type)
            
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

    public init(type: MailType, email: String) {
        self.type = type
        self.email = email
        
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
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
        
        title = NSLocalizedString("Ask Support a Question", bundle: .module, comment: "")

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
    
    func mailCell(_ cell: MailCell, didChangeText text: String) {
        
        currentText = text
        
        sendButton.isEnabled = text.count >= type.minCharactersCount
        
        UIView.performWithoutAnimation {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
}
