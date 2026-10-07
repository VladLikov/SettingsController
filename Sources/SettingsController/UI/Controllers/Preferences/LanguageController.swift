//
//  LanguageController.swift
//  SettingsController
//
//  Created by Влад Лыков on 25.09.2024.
//

import UIKit
import MessageUI

// MARK: - LanguageController

class LanguageController: UITableViewController {
        
    private let languages: [String] = Bundle.main.localizations.filter { $0 != "Base" }
    
    private let email: String
    private let userID: String?
    private let isPremium: Bool?
    private let subscriptionID: String?
    
    // MARK: Life Cycle
    
    init(email: String, userID: String? = nil, isPremium: Bool? = nil, subscriptionID: String? = nil) {
        self.email = email
        self.userID = userID
        self.isPremium = isPremium
        self.subscriptionID = subscriptionID
        super.init(style: .insetGrouped)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self)

        navigationItem.largeTitleDisplayMode = .never
    }
    
}

// MARK: - UITableViewDataSource

extension LanguageController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return languages.count
        }
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 1 {
            return NSLocalizedString("If you want you can help me translate the app to another language.", bundle: .module, comment: "")
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let section = indexPath.section, row = indexPath.row
                    
        if section == 0 {
            
            let cell = tableView.dequeueReusableCell(withClass: UITableViewCell.self, for: indexPath)

            let languageCode = languages[row]

            var configuration = UIListContentConfiguration.subtitleCell()
            configuration.text = Locale(identifier: languageCode).localizedString(forLanguageCode: languageCode)?.capitalized
            configuration.secondaryText = Locale.current.localizedString(forLanguageCode: languageCode)?.capitalized
            configuration.secondaryTextProperties.color = .secondaryLabel
            cell.contentConfiguration = configuration

            let isCurrent = languageCode == Locale.current.languageCode
            
            cell.accessoryType = isCurrent ? .checkmark : .none
            
            return cell
            
        } else if section == 1 && row == 0 {
            
            let cell = tableView.dequeueReusableCell(withClass: UITableViewCell.self, for: indexPath)

            var configuration = cell.defaultContentConfiguration()
            configuration.text = NSLocalizedString("Need Other Language", bundle: .module, comment: "")
            configuration.textProperties.alignment = .center
            configuration.textProperties.color = view.tintColor
            cell.contentConfiguration = configuration

            return cell
        }
        
        preconditionFailure("Unexpected language settings indexPath: \(indexPath)")
        
    }
    
}

// MARK: - UITableViewDelegate

extension LanguageController {
        
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let section = indexPath.section
        
        if section == 0 {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        } else if section == 1 {
            sendMail()
        }
                
    }
    
}

// MARK: - Mail

extension LanguageController {

    private func sendMail() {
        
        guard MailAvailability.canSendEmail() else { return }
        
        let mailVC = MailController(
            type: .languageRequest,
            email: email,
            userID: userID,
            isPremium: isPremium,
            subscriptionID: subscriptionID
        )
        
        present(UINavigationController(rootViewController: mailVC), animated: true)
                
    }
}
