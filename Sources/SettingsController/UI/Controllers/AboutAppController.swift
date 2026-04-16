//
//  AboutAppController.swift
//  SettingsController
//
//  Created by Влад Лыков on 16.04.2026.
//

import UIKit
import SwiftBoost
import SafariServices
import AlertKit
import SafeSFSymbols
import CheckUpdate

// MARK: - Section

enum Section: Int, CaseIterable {
    case version
    case links
    case parameters
}

// MARK: - Item

enum Item {
    case currentVersion(String)
    case checkForUpdate
    case privacyPolicy
    case terms
    case userID(String)
    case appVersion(String)
    case instance(String)
    case appRegion(String)
    case appLanguage(String)
    case systemLanguage(String)
    case proStatus(Bool)
    
    var title: String {
        switch self {
        case .currentVersion:
            return NSLocalizedString("Current", bundle: .module, comment: "")
            
        case .checkForUpdate:
            return NSLocalizedString("Check for Update", bundle: .module, comment: "")

        case .privacyPolicy:
            return NSLocalizedString("Privacy Policy", bundle: .module, comment: "")

        case .terms:
            return NSLocalizedString("Terms of Use", bundle: .module, comment: "")

        case .userID:
            return NSLocalizedString("User ID", bundle: .module, comment: "")

        case .appVersion:
            return NSLocalizedString("App Version", bundle: .module, comment: "")

        case .instance:
            return NSLocalizedString("Instance", bundle: .module, comment: "")

        case .appRegion:
            return NSLocalizedString("App Region", bundle: .module, comment: "")

        case .appLanguage:
            return NSLocalizedString("App Language", bundle: .module, comment: "")

        case .systemLanguage:
            return NSLocalizedString("System Language", bundle: .module, comment: "")

        case .proStatus:
            return NSLocalizedString("Pro Status", bundle: .module, comment: "")
        }
    }
    
    var value: String? {
        switch self {
        case .currentVersion(let v),
             .userID(let v),
             .appVersion(let v),
             .instance(let v),
             .appRegion(let v),
             .appLanguage(let v),
             .systemLanguage(let v):
            return v
            
        case .proStatus(let isPro):
            return isPro ? "true" : "false"
            
        case .privacyPolicy, .terms, .checkForUpdate:
            return nil
        }
    }
}

// MARK: - AboutAppController

final class AboutAppController: UITableViewController {
    
    private var data: [(section: Section, items: [Item])] = []
    
    private let isPremium: Bool
    private let userID: String?
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self)

        setupData()
    }
}

// MARK: - Data

private extension AboutAppController {
    
    func setupData() {
        
        let bundle = Bundle.main
        
        let appVersion = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let build = bundle.infoDictionary?["CFBundleVersion"] as? String ?? "-"
        
        let fullVersion = "\(appVersion) (\(build))"
                
        let systemLanguage = Locale.current.languageCode ?? "-"
        let appLanguage = Bundle.main.preferredLocalizations.first ?? "-"
        
        let region = Locale.current.regionCode ?? "-"
        
        data = [
            (
                .version,
                [
                    .currentVersion(appVersion),
                    .checkForUpdate
                ]
            ),
            (
                .links,
                [
                    .privacyPolicy,
                    .terms
                ]
            ),
            (
                .parameters,
                [
                    .userID(userID ?? "-"),
                    .appVersion(fullVersion),
                    .instance(region.lowercased()),
                    .appRegion(region.lowercased()),
                    .appLanguage(appLanguage),
                    .systemLanguage(systemLanguage),
                    .proStatus(isPremium) 
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
        switch data[section].section {
        case .version: return NSLocalizedString("Version", bundle: .module, comment: "")
        case .links: return nil
        case .parameters: return NSLocalizedString("Parameters", bundle: .module, comment: "")
        }
    }
    
    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        
        let item = data[indexPath.section].items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withClass: UITableViewCell.self, for: indexPath)
        
        var config = UIListContentConfiguration.valueCell()
        config.secondaryTextProperties.color = .secondaryLabel
        
        switch item {
        case .privacyPolicy, .terms:
            config.text = item.title
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
                        
        case .checkForUpdate:
            config.text = item.title
            config.textProperties.color = view.tintColor
            
        case .userID:
            config.text = item.title
            config.secondaryText = item.value
            cell.selectionStyle = .default
            cell.accessoryType = .none
            
        default:
            config.text = item.title
            config.secondaryText = item.value
            cell.selectionStyle = .none
            cell.accessoryType = .none
            
        }
        
        cell.contentConfiguration = config
        return cell
    }
}

// MARK: - UITableViewDelegate

extension AboutAppController {

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = data[indexPath.section].items[indexPath.row]

        switch item {
        case .privacyPolicy:
            pushSafari(with: privacyURL)
            
        case .terms:
            pushSafari(with: termsURL)

        case .userID:
            if let userID {
                UIPasteboard.general.string = userID
                AlertKitAPI.present(
                    title: NSLocalizedString("Сopied", bundle: .module, comment: ""),
                    icon: .custom(UIImage(.doc.onClipboard)),
                    style: .iOS17AppleMusic,
                    haptic: .success
                )
            }
            
        case .checkForUpdate:
            Task {
                do {
                    try await CheckUpdate().showUpdate(for: appID, withConfirmation: true, fromVC: self)
                } catch let error as CheckUpdateError {
                    if  error == .noUpdateAvailable {
                        AlertKitAPI.present(
                            title: NSLocalizedString("Latest version is installed", bundle: .module, comment: ""),
                            icon: .custom(UIImage(.checkmark.sealFill)),
                            style: .iOS17AppleMusic,
                            haptic: .success
                        )
                    }
                }
            }
            
        default:
            break
        }

    }
    
    private func pushSafari(with url: URL) {
        
        let safari = SFSafariViewController(url: url)
        present(safari, animated: true)
    }
}
