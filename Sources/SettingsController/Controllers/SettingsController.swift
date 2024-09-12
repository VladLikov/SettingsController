// The Swift Programming Language
// https://docs.swift.org/swift-book

import UIKit
import MessageUI
import AlertKit

// MARK: - SettingsControllerDelegate

protocol SettingsControllerDelegate: AnyObject {
    func settingsDidDissmised(_ initialAppColor: UIColor)
}

public struct SettingsConfiguration {
    public var settingsTitle: String?
    public var initialAppColor: UIColor
    public var sections: [Section]
}

// MARK: Section

public struct Section {
    var title: String? = nil
    var rows: [CustomRow]
}

// MARK: CustomRow

public enum CustomRow {
    case row(Row)
    case action(Action)
    
    public enum Action {
        case shareApp(String)
        case rateApp(String)
        case moreApps(String)
        case contactDeveloper(String)
        case premium(Bool, UIViewController)
        
        var title: String {
            switch self {
            case .shareApp(_):
                NSLocalizedString("Share app", comment: "")
            case .rateApp(_):
                NSLocalizedString("Write a review", comment: "")
            case .moreApps(_):
                NSLocalizedString("More apps", comment: "")
            case .premium(_, _):
                NSLocalizedString("Premium", comment: "")
            case .contactDeveloper(_):
                NSLocalizedString("Contact Developer", comment: "")
            }
        }
        
        var icon: Icon {
            switch self {
            case .shareApp(_):
                Icon(image: UIImage(systemName: "square.and.arrow.up.fill"), color: .systemYellow)
            case .rateApp(_):
                Icon(image: UIImage(systemName: "heart.fill"), color: .systemRed)
            case .moreApps(_):
                Icon(image: UIImage(systemName: "square.stack.3d.up.fill"), color: .systemIndigo)
            case .premium(_, _):
                Icon(image: UIImage(systemName: "star.fill"), color: .systemBlue)
            case .contactDeveloper(_):
                Icon(image: UIImage(systemName: "envelope.fill"), color: .systemBlue)
            }
        }
    }
}

// MARK: Row

public struct Row {
    var title: String
    var icon: Icon
    var vc: UIViewController.Type? = nil
    var function: ((_ indexPath: IndexPath) -> Void)? = nil
}

// MARK: Icon

public struct Icon {
    var image: UIImage?
    var color: UIColor
    
    init(image: UIImage?, color: UIColor) {
        self.image = image
        self.color = color
    }
}

// MARK: - SettingsController

final class SettingsController: UITableViewController {
    
    private var configuration: SettingsConfiguration
    
    private lazy var sections = configuration.sections
    
    weak var delegate: SettingsControllerDelegate?
        
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
        
    // MARK: Properties [Private]
    
    private lazy var closeButton: UIBarButtonItem = {
        UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(self.closeAction(_:)))
    }()
    
    // MARK: Life Cycle
    
    private init(configuration: SettingsConfiguration) {
        self.configuration = configuration
        if #available(iOS 13.0, *) {
            super.init(style: .insetGrouped)
        } else {
            super.init(style: .grouped)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    required public init?(coder: NSCoder) {
//        super.init(coder: coder)
//    }
    
     override func viewDidLoad() {
        super.viewDidLoad()
        
         title = configuration.settingsTitle
        
        tableView?.register(SettingsCell.self)
        tableView?.rowHeight = 45
        tableView?.contentInset.top = 25
        
        navigationItem.largeTitleDisplayMode = .automatic
        navigationItem.rightBarButtonItem = closeButton

        navigationController?.navigationBar.prefersLargeTitles = true
        
        clearsSelectionOnViewWillAppear = true
        
    }
    
     override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
                
        DispatchQueue.main.async { [weak self] in
            self?.navigationController?.navigationBar.sizeToFit()
        }
        
    }
    
    // MARK: Status Bar
    
     override var preferredStatusBarStyle: UIStatusBarStyle {
        .default
    }
              
    // MARK: UITableViewDataSource
    
     override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
     override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }
    
     override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
    
     override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(ofType: SettingsCell.self, for: indexPath)
                        
        let section = indexPath.section, row = indexPath.row
        
        let item = sections[section].rows[row]
        
        switch item {
        case .row(let row):
            cell.configure(title: row.title, icon: row.icon, detail: nil)

        case .action(let action):
            var detail: String?
            
            if case .premium(let hasPremium, _) = action {
                detail = hasPremium ? NSLocalizedString("Active", comment: "") : NSLocalizedString("Not active", comment: "")
            }
            
            cell.configure(title: action.title, icon: action.icon, detail: detail)

        }
        
        return cell
        
    }
    
    // MARK: UITableViewDelegate
    
     override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let cell = tableView.cellForRow(at: indexPath) as? SettingsCell else { return }
                
        let section = indexPath.section, row = indexPath.row
                        
        let item = sections[section].rows[row]

        switch item {
        case .row(let row):
            if let vcType = row.vc {
                
                let vc = vcType.init()
                vc.navigationItem.title = cell.titleLabel.text
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
    
    // MARK: Actions

    @objc func closeAction(_ sender: UIBarButtonItem) {
        
        navigationController?.dismiss(animated: true, completion: { [weak self] in
            guard let self else { return }
            delegate?.settingsDidDissmised(configuration.initialAppColor)
        })
                
    }
    
    // MARK: Private Methods
    
    private func presentPremium(_ hasPremium: Bool, premiumVC: UIViewController) {
        
        if hasPremium {
            
            AlertKitAPI.present(
                title: NSLocalizedString("Premium is active", comment: ""),
                icon: .custom(UIImage(systemName: "star.fill") ?? .init()),
                style: .iOS16AppleMusic,
                haptic: .success
            )
            
        } else {
            
            premiumVC.modalPresentationStyle = .overFullScreen
            present(premiumVC, animated: true)
            
        }
        
    }

    private func sendMail(_ email: String) {
        
        guard MFMailComposeViewController.canSendMail() else { return }

        let mail = MFMailComposeViewController()
        
        let deviceModel = UIDevice.current.model
        let systemVersion = UIDevice.current.systemVersion
        
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? ""
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        
        let message = "\n\n\n\n\n\nDevice: \(deviceModel)\niOS: \(systemVersion)\nApp Version: \(appVersion)"
        
        mail.setMessageBody(message, isHTML: false)
        mail.setSubject(appName ?? "")
        mail.setToRecipients([email])
        
        present(mail, animated: true, completion: nil)
        
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
    
    public func isTapticEngineSupported() -> Bool {
        return (UIDevice.current.value(forKey: "_feedbackSupportLevel") as? NSNumber)?.boolValue ?? false
    }
    
}
