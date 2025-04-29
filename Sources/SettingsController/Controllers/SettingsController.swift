// The Swift Programming Language
// https://docs.swift.org/swift-book

import UIKit
import MessageUI
import AlertKit
import SafeSFSymbols
import StoreKit

// MARK: - SettingsControllerDelegate

public protocol SettingsControllerDelegate: AnyObject {
    func settingsDidDismiss(_ initialValues: [AnyKeyPath: Any]?)
    
    func settingsUserInfoRequested(_ request: (UserInfo) -> Void)
    func settingsPremiumStatusRequested(_ request: (Bool) -> Void)
}

// MARK: - SettingsController

public final class SettingsController: UITableViewController {
    
    // MARK: Properties [Public]

    public weak var delegate: SettingsControllerDelegate?
        
    // MARK: Present Settings
    
    @discardableResult
    public static func present(configuration: SettingsConfiguration,
                               from fromVC: UIViewController) -> SettingsController {
        
        DispatchQueue.anywayOnMain {
            
            let settingsController = SettingsController(configuration: configuration)
            let settingsNavController = UINavigationController(rootViewController: settingsController)
            
            let splitViewController = SplitController.getDefault(for: settingsNavController)
            
            splitViewController.modalPresentationStyle = .fullScreen
            
            fromVC.present(splitViewController, animated: true)
            
            return settingsController
        }
    }
    
    // MARK: Properties [Private]
    
    private var configuration: SettingsConfiguration
    
    private lazy var sections = configuration.sections
    
    private lazy var closeButton: UIBarButtonItem = {
        UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(self.closeAction(_:)))
    }()
    
    private var overlayAppViewDidShown: Bool = false
        
    private var indexPathToRefresh: IndexPath?
    
    // MARK: Life Cycle
    
    init(configuration: SettingsConfiguration) {
        self.configuration = configuration
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        title = configuration.title
        
        tableView?.register(SettingsCell.self)
        tableView?.register(UserCell.self)

        tableView?.rowHeight = 45
        tableView?.separatorInset.left = 60
         
        if let topInset = configuration.topInset {
            tableView?.contentInset.top = topInset
        }
                
        navigationItem.largeTitleDisplayMode = .automatic
        navigationItem.rightBarButtonItem = closeButton

        navigationController?.navigationBar.prefersLargeTitles = true
        
        clearsSelectionOnViewWillAppear = true
    }
       
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        reloadRowsIfNeeded()
        
        if #available(iOS 14.0, *) {
            displayAppOverlayIfNeeded()
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if #available(iOS 14.0, *) {
            dismissAppOverlayIfNeeded()
        }
    }
    
}

// MARK: - Status Bar

extension SettingsController {
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
}

// MARK: - UITableViewDataSource

extension SettingsController {
    
    public override func numberOfSections(in tableView: UITableView) -> Int {
       return sections.count
   }
   
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
   }
   
    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
       return sections[section].title
   }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                              
       let section = indexPath.section, row = indexPath.row
       let item = sections[section].rows[row]
       
       switch item {
       case .row(let row):
           
           let cell = tableView.dequeueReusableCell(ofType: SettingsCell.self, for: indexPath)
           cell.configure(title: row.title, icon: row.icon, detail: row.detail)
           return cell
           
       case .defaultRow(let defaultRow):
           
           if case .user(let name, let image, _) = defaultRow {
               let cell = tableView.dequeueReusableCell(ofType: UserCell.self, for: indexPath)
               cell.configure(title: name, avatar: image)
               return cell
           }
           
           let cell = tableView.dequeueReusableCell(ofType: SettingsCell.self, for: indexPath)
           
           var detail: String?
           
           if case .premium(let hasPremium, _, _, _) = defaultRow {
               detail = hasPremium ?
               NSLocalizedString("Active", bundle: .module, comment: "") :
               NSLocalizedString("Not active", bundle: .module, comment: "")
           }
           
           cell.configure(title: defaultRow.title, icon: defaultRow.icon, detail: detail)

           return cell
       }
              
   }
    
    //    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    //
    //       let cell = tableView.dequeueReusableCell(ofType: SettingsCell.self, for: indexPath)
    //
    //       let section = indexPath.section, row = indexPath.row
    //       let item = sections[section].rows[row]
    //
    //       switch item {
    //       case .row(let row):
    //           cell.configure(title: row.title, icon: row.icon, detail: row.detail)
    //
    //       case .defaultRow(let action):
    //           var detail: String?
    //
    //           if case .premium(let hasPremium, _, _) = action {
    //               detail = hasPremium ?
    //               NSLocalizedString("Active", bundle: .module, comment: "") :
    //               NSLocalizedString("Not active", bundle: .module, comment: "")
    //           }
    //
    //           cell.configure(title: action.title, icon: action.icon, detail: detail)
    //
    //       }
    //
    //       return cell
    //
    //   }
    
}

// MARK: - UITableViewDelegate

extension SettingsController {
        
    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let section = indexPath.section, row = indexPath.row
        let item = sections[section].rows[row]
        
        if case .defaultRow(let row) = item, case .user = row {
            return 65
        }
        
        return 45
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let section = indexPath.section, row = indexPath.row
                        
        let item = sections[section].rows[row]
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            tableView.deselectRow(at: indexPath, animated: true)
        } else {
            if case .defaultRow(let row) = item, case .premium = row {
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }

        switch item {
        case .row(let row):
            
            if let vcType = row.vc {
                
                let title = (tableView.cellForRow(at: indexPath) as? SettingsCell)?.title
                
                let vc = vcType.init()
                pushVC(vc, navigationTitle: title)

            } else if let action = row.action {
                tableView.deselectRow(at: indexPath, animated: true)
                action(indexPath, tableView, self)
            }

        case .defaultRow(let row):
            
            switch row {
            case .shareApp(let appID):
                shareApp(appID, at: indexPath)
                
            case .rateApp(let appID):
                rateApp(appID)
                
            case .moreApps(let developerID):
                moreApps(developerID)

            case .premium(let hasPremium, _, let vc, let action):
                indexPathToRefresh = indexPath
                presentPremium(hasPremium, premiumVC: vc, action: action)
                
            case .contactDeveloper(let email):
                sendMail(email)
                
            case .language(let email):
                pushVC(LanguageController(email: email),
                       navigationTitle: NSLocalizedString("Language", bundle: .module, comment: ""))
                
            case .telegram(let channelURL):
                openTelegramChannel(channelURL)
                
            case .vkGroup(let groupID):
                openVKGroup(groupID)
                
            case .user(_, _, let vcType):
                indexPathToRefresh = indexPath
                pushVC(vcType.init(),
                       navigationTitle: NSLocalizedString("User", bundle: .module, comment: ""))

            }

        }

                        
    }
    
    private func pushVC(_ vc: UIViewController, navigationTitle: String?) {
        
        vc.navigationItem.title = navigationTitle
        
        if UIDevice.current.userInterfaceIdiom != .phone {
            showDetailViewController(UINavigationController(rootViewController: vc), sender: nil)
        } else {
            showDetailViewController(vc, sender: nil)
        }
                
    }
    
}

// MARK: - Actions

extension SettingsController {
    
    @objc
    private func closeAction(_ sender: UIBarButtonItem) {
        
        navigationController?.dismiss(animated: true, completion: { [weak self] in
            guard let self else { return }
            delegate?.settingsDidDismiss(configuration.initialValues)
        })
                
    }
    
}

// MARK: - Private Methods

extension SettingsController {
    
    private func reloadRowsIfNeeded() {
        
        guard let indexPathToRefresh else { return }
        
        let row = sections[indexPathToRefresh.section].rows[indexPathToRefresh.row]
        
        if case .defaultRow(let defaultRow) = row, case .premium(_, let color, let vc, let action) = defaultRow {
            delegate?.settingsPremiumStatusRequested { [weak self]  isPremium in
                self?.sections[indexPathToRefresh.section].rows[indexPathToRefresh.row] = .defaultRow(.premium(isPremium, color, vc, action))
            }
        } else if case .defaultRow(let defaultRow) = row, case .user(_, _, let vc) = defaultRow {
            delegate?.settingsUserInfoRequested { [weak self] user in
                self?.sections[indexPathToRefresh.section].rows[indexPathToRefresh.row] = .defaultRow(.user(user.name, user.avatar, vc))
            }
        }
        
        tableView?.reloadRows(at: [indexPathToRefresh], with: .fade)
        
        self.indexPathToRefresh = nil
        
    }
    
    private func presentPremium(_ hasPremium: Bool,
                                premiumVC: UIViewController.Type?,
                                action: SettingsRowData.DefaultRow.PremiumAction?) {
        
        if hasPremium {
            
            AlertKitAPI.present(
                title: NSLocalizedString("Premium is active", bundle: .module, comment: ""),
                icon: .custom(UIImage(.star.fill)),
                style: .iOS16AppleMusic,
                haptic: .success
            )
            
        } else if let premiumVC {
            
            let vc = premiumVC.init()
            if UIDevice.current.userInterfaceIdiom == .phone {
                vc.modalPresentationStyle = .fullScreen
            }
            present(vc, animated: true)
                        
        } else if let action {
            action(self)
        }
        
    }

    private func sendMail(_ email: String) {
        
        guard MFMailComposeViewController.canSendEmail() else { return }
        
        let mail = MFMailComposeViewController.getDefault(for: email)
        
        mail.mailComposeDelegate = self
        
        present(mail, animated: true)
        
    }
    
    private func shareApp(_ appID: String, at indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? SettingsCell else { return }
        guard let url = URL(string: "https://apps.apple.com/app/id\(appID)") else { return }
        let items = [url]
        let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        ac.popoverPresentationController?.sourceView = tableView
        ac.popoverPresentationController?.sourceRect = cell.frame
        present(ac, animated: true)
    }
    
    private func rateApp(_ appID: String) {
        if let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appID)?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
    
    private func moreApps(_ developerID: String) {
        if let url = URL(string: "itms-apps://itunes.apple.com/developer/id\(developerID)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openTelegramChannel(_ channelURL: String) {
        
        guard let appURL = URL(string: "tg://resolve?domain=\(channelURL)"),
              let webURL = URL(string: "https://t.me/\(channelURL)") else {
            return
        }
        
        if UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else {
            UIApplication.shared.open(webURL)
        }
        
    }
    
    private func openVKGroup(_ groupID: String) {
        
        guard let appURL = URL(string: "vk://vk.com/club\(groupID)"),
              let webURL = URL(string: "https://vk.com/club\(groupID)") else {
            return
        }
        
        if UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else {
            UIApplication.shared.open(webURL)
        }
        
    }
    
    @available(iOS 14.0, *)
    private func displayAppOverlayIfNeeded() {
        
        guard !overlayAppViewDidShown else { return }
        
        if let overlayAppID = configuration.overlayAppID {
            guard let scene = view.window?.windowScene else { return }
            
            let config = SKOverlay.AppConfiguration(appIdentifier: overlayAppID, position: .bottom)
            let overlay = SKOverlay(configuration: config)
            overlay.delegate = self
            overlay.present(in: scene)
            
            overlayAppViewDidShown = true
        }
    }
    
    @available(iOS 14.0, *)
    private func dismissAppOverlayIfNeeded() {
        
        guard let scene = view.window?.windowScene else { return }
        SKOverlay.dismiss(in: scene)
    }
    
}

// MARK: - MFMailComposeViewControllerDelegate

extension SettingsController: @preconcurrency MFMailComposeViewControllerDelegate {
    
    public func mailComposeController(_ controller: MFMailComposeViewController,
                                      didFinishWith result: MFMailComposeResult,
                                      error: (any Error)?) {
        
        controller.dismiss(animated: true)
    }
}

// MARK: - SKOverlayDelegate

@available(iOS 14.0, *)
extension SettingsController: @preconcurrency SKOverlayDelegate {
  
    public func storeOverlayDidFinishPresentation(_ overlay: SKOverlay,
                                                  transitionContext: SKOverlay.TransitionContext) {
        
        tableView.contentInset.bottom = transitionContext.endFrame.size.height
    }
    
    public func storeOverlayDidFinishDismissal(_ overlay: SKOverlay,
                                               transitionContext: SKOverlay.TransitionContext) {
        
        tableView.contentInset.bottom = 0
    }
    
}

