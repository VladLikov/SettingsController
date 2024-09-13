// The Swift Programming Language
// https://docs.swift.org/swift-book

import UIKit
import MessageUI
import AlertKit
import SafeSFSymbols

// MARK: - SettingsControllerDelegate

public protocol SettingsControllerDelegate: AnyObject {
    func settingsDidDissmised(_ initialAppColor: UIColor)
}

// MARK: - SettingsController

public final class SettingsController: UITableViewController {
    
    // MARK: Properties [Public]

    public weak var delegate: SettingsControllerDelegate?
        
    // MARK: Present Settings

    
    // need to change
    @discardableResult
    public static func presentSettings(configuration: SettingsConfiguration,
                                       from fromVC: UIViewController) -> SettingsController {
        
        let settingsController = SettingsController(configuration: configuration)
        let settingsNavController = UINavigationController(rootViewController: settingsController)
                
        let splitViewController = SplitController.getDefault(for: settingsNavController)

        splitViewController.modalPresentationStyle = .overFullScreen
        
        fromVC.present(splitViewController, animated: true)
        
        return settingsController
    }
    
    // MARK: Is Taptic Engine Supported
    
    public func isTapticEngineSupported() -> Bool {
        return (UIDevice.current.value(forKey: "_feedbackSupportLevel") as? NSNumber)?.boolValue ?? false
    }
    
    // MARK: Properties [Private]
    
    private var configuration: SettingsConfiguration
    
    private lazy var sections = configuration.sections
    
    private lazy var closeButton: UIBarButtonItem = {
        UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(self.closeAction(_:)))
    }()
    
    // MARK: Life Cycle
    
    public init(configuration: SettingsConfiguration) {
        self.configuration = configuration
        super.init(style: .insetGrouped)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        title = configuration.settingsTitle
        
        tableView?.register(SettingsCell.self)
        tableView?.rowHeight = 45
         
        if let topInset = configuration.topInset {
            tableView?.contentInset.top = topInset
        }
                
        navigationItem.largeTitleDisplayMode = .automatic
        navigationItem.rightBarButtonItem = closeButton

        navigationController?.navigationBar.prefersLargeTitles = true
        
        clearsSelectionOnViewWillAppear = true
        
    }
    
}

// MARK: - Status Bar

extension SettingsController {
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        .default
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
       
       let cell = tableView.dequeueReusableCell(ofType: SettingsCell.self, for: indexPath)
                       
       let section = indexPath.section, row = indexPath.row
       
       let item = sections[section].rows[row]
       
       switch item {
       case .row(let row):
           cell.configure(title: row.title, icon: row.icon, detail: row.detail)

       case .action(let action):
           var detail: String?
           
           if case .premium(let hasPremium, _) = action {
               detail = hasPremium ? NSLocalizedString("Active", comment: "") : NSLocalizedString("Not active", comment: "")
           }
           
           cell.configure(title: action.title, icon: action.icon, detail: detail)

       }
       
       return cell
       
   }
    
}

// MARK: - UITableViewDelegate

extension SettingsController {
        
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let cell = tableView.cellForRow(at: indexPath) as? SettingsCell else { return }
                
        let section = indexPath.section, row = indexPath.row
                        
        let item = sections[section].rows[row]

        switch item {
        case .row(let row):
            
            if let vcType = row.vc {
                
                let vc = vcType.init()
                vc.navigationItem.title = cell.title
                navigationController?.pushViewController(vc, animated: true)
                
            } else if let function = row.function {
                tableView.deselectRow(at: indexPath, animated: true)
                function(indexPath)
            }

        case .action(let action):
            
            switch action {
            case .shareApp(let appID):
                shareApp(appID, at: indexPath)
                
            case .rateApp(let appID):
                rateApp(appID)
                
            case .moreApps(let developerID):
                moreApps(developerID)

            case .premium(let hasPremium, let premiumVC):
                presentPremium(hasPremium, premiumVC: premiumVC)
                
            case .contactDeveloper(let email):
                sendMail(email)
                
            }

        }

                        
    }
    
}

// MARK: - Actions

extension SettingsController {
    
    @objc
    private func closeAction(_ sender: UIBarButtonItem) {
        
        navigationController?.dismiss(animated: true, completion: { [weak self] in
            guard let self, let initialAppColor = configuration.initialAppColor else { return }
            delegate?.settingsDidDissmised(initialAppColor)
        })
                
    }
    
}

// MARK: - Private Methods

extension SettingsController {
        
    private func presentPremium(_ hasPremium: Bool, premiumVC: UIViewController.Type) {
        
        if hasPremium {
            
            AlertKitAPI.present(
                title: NSLocalizedString("Premium is active", comment: ""),
                icon: .custom(UIImage(.star.fill)),
                style: .iOS16AppleMusic,
                haptic: .success
            )
            
        } else {
            
            let vc = premiumVC.init()
            vc.modalPresentationStyle = .overFullScreen
            present(vc, animated: true)
            
        }
        
    }

    private func sendMail(_ email: String) {
        
        guard MFMailComposeViewController.canSendMail() else { return }
        
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
    
}

// MARK: - MFMailComposeViewControllerDelegate

extension SettingsController: @preconcurrency MFMailComposeViewControllerDelegate {
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: (any Error)?) {
        controller.dismiss(animated: true)
    }
}
