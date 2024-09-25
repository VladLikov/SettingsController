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
    
    private var email: String = ""
    
    // MARK: Life Cycle
    
    init(email: String) {
        super.init(style: .insetGrouped)
        
        self.email = email
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
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
            return NSLocalizedString("Help me translate the app to another language and get premium forever for free.", comment: "")
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let section = indexPath.section, row = indexPath.row

        let cell = tableView.dequeueReusableCell(ofType: UITableViewCell.self, for: indexPath)
                    
        if section == 0 {
            
            let languageCode = languages[row]
            
            cell.textLabel?.text = Locale(identifier: languageCode).localizedString(forLanguageCode: languageCode)?.capitalized
            cell.detailTextLabel?.text = Locale.current.localizedString(forLanguageCode: languageCode)?.capitalized
            
            cell.detailTextLabel?.textColor = .gray
            
            let isCurrent = languageCode == Locale.current.languageCode
            
            cell.accessoryType = isCurrent ? .checkmark : .none
            
        } else if section == 1 && row == 0 {
            cell.textLabel?.text = NSLocalizedString("Need other language", comment: "")
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.textColor = view.tintColor
        }
        
        return cell
        
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
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
}

// MARK: - Mail

extension LanguageController: @preconcurrency MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true, completion: nil)
    }
    
    private func sendMail() {
        
        guard MFMailComposeViewController.canSendMail() else { return }

        let mail = MFMailComposeViewController.getDefault(for: email)
        
        mail.mailComposeDelegate = self
        
        present(mail, animated: true)
                
    }
}
