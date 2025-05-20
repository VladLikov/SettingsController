// The Swift Programming Language
// https://docs.swift.org/swift-book

import UIKit
import AlertKit
import SafeSFSymbols
import StoreKit
import MessageUI

// MARK: - SettingsController

public final class SettingsController: UITableViewController {
            
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
    
    public static func getSplitPresentationSettingsController(configuration: SettingsConfiguration) -> UIViewController {
        
        DispatchQueue.anywayOnMain {
            
            let settingsController = SettingsController(configuration: configuration)
            let settingsNavController = UINavigationController(rootViewController: settingsController)
                                                
            return SplitController.getDefault(for: settingsNavController)
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
    
    public init(configuration: SettingsConfiguration) {
        self.configuration = configuration
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        title = configuration.title
        
        tableView?.register(SettingsCell.self)
        tableView?.register(UserCell.self)
        tableView?.register(AppCell.self)
        tableView?.register(PremiumCell.self)

        tableView?.separatorInset.left = 60
         
        if let topInset = configuration.insets?.top {
            tableView?.contentInset.top = topInset
        }
        
        if let bottomInset = configuration.insets?.bottom {
            tableView?.contentInset.top = bottomInset
        }
                
        navigationItem.largeTitleDisplayMode = .automatic
        
        if let nav = navigationController,
           nav.presentingViewController != nil,
           nav.viewControllers.first === self
        {
            navigationItem.rightBarButtonItem = closeButton
        }
        
        navigationController?.navigationBar.prefersLargeTitles = true
        
        clearsSelectionOnViewWillAppear = true
        
        setNotifications()
        
        for (idx, section) in sections.enumerated() {
            if case .ourApps = section.kind {
                loadOurApps(for: idx)
            }
        }
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
    
    private func loadOurApps(for sectionIndex: Int) {
        
        let section = sections[sectionIndex]

        guard case let .ourApps(developerID, limit, appID) = section.kind else {
            return
        }

        Task { @MainActor in
            do {
                let apps = try await AppsLoader.fetch(developerId: developerID, limit: limit)

                let filteredApps = apps.filter { String($0.id) != appID }
                
                let rows = filteredApps.map { SettingsRowData.app(.loaded($0)) }

                sections[sectionIndex].kind = .rows(rows)
                tableView.reloadSections(IndexSet(integer: sectionIndex), with: .automatic)

            } catch {
                sections[sectionIndex].kind = .rows([.app(.failed)])
                tableView.reloadSections(IndexSet(integer: sectionIndex), with: .automatic)
            }
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
        switch sections[section].kind {
        case .rows(let rows):
            return rows.count
        case .ourApps(_, let limit, _):
            return limit
        case .premiumCard(_):
            return 1
        }
   }
   
    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
       return sections[section].title
   }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                              
       let section = indexPath.section
        
        switch sections[section].kind {
            
        case .rows(let rows):
            switch rows[indexPath.row] {
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
                 
                if case .premium(let payload) = defaultRow {
                    detail = payload.isPremium ?
                    NSLocalizedString("Active", bundle: .module, comment: "") :
                    NSLocalizedString("Not active", bundle: .module, comment: "")
                }
                
                cell.configure(title: defaultRow.title, icon: defaultRow.icon, detail: detail)
                
                return cell

            case .app(let appRow):
                return makeAppCell(for: tableView, at: indexPath, appRow: appRow)
                
            }
            
        case .ourApps:
            return makeAppCell(for: tableView, at: indexPath, appRow: .placeholder)
            
        case .premiumCard(let payload):
            let cell = tableView.dequeueReusableCell(ofType: PremiumCell.self, for: indexPath)
            cell.configure(payload: payload) { [weak self] in
                self?.indexPathToRefresh = indexPath
                self?.presentPremium(payload.base)
            }
            return cell
        }
   }
    
    private func makeAppCell(for tableView: UITableView,
                             at indexPath: IndexPath,
                             appRow: AppRow) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(ofType: AppCell.self, for: indexPath)
        cell.configure(with: appRow)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension SettingsController {
        
    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let section = indexPath.section, row = indexPath.row
        
        switch sections[section].kind {
        case .rows(let rows):
            if case .defaultRow(let row) = rows[row], case .user = row {
                return 65
            }
        case .premiumCard:
            return 100
            
        default:
            break
        }
        
        return 45
    }
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let section = indexPath.section, row = indexPath.row
                    
        switch sections[section].kind {
        case .rows(let rows):
            let item = rows[row]
            
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

                case .premium(let payload):
                    indexPathToRefresh = indexPath
                    presentPremium(payload)
                    
                case .contactDeveloper(let email):
                    sendMail(email)
                    
                case .language(let email):
                    pushVC(LanguageController(email: email),
                           navigationTitle: NSLocalizedString("Language", bundle: .module, comment: ""))
                    
                case .appearance(let theme):
                    pushVC(AppearanceController(themeStorage: theme),
                           navigationTitle: NSLocalizedString("Appearance", bundle: .module, comment: ""))
                    
                case .telegram(let channelURL):
                    openTelegramChannel(channelURL)
                    
                case .vkGroup(let groupID):
                    openVKGroup(groupID)
                    
                case .user(_, _, let vcType):
                    indexPathToRefresh = indexPath
                    pushVC(vcType.init(),
                           navigationTitle: NSLocalizedString("User", bundle: .module, comment: ""))

                case .tapticEngine(let taptic):
                    pushVC(TapticEngineController(tapticStorage: taptic),
                           navigationTitle: NSLocalizedString("Taptic Engine", bundle: .module, comment: ""))
                }
     
            case .app(.loaded(let app)):
                openApp(app.id, url: app.storeURL)
                
            default:
                break
                
            }
            
        default:
            break
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
    
    private func openApp(_ id: Int, url: URL) {
        
#if !os(visionOS)
        let vc = SKStoreProductViewController()
        Task { @MainActor in
            let loaded = try await vc.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: id])
            guard loaded else { return }
            present(vc, animated: true)
        }
#else
        UIApplication.shared.open(url)
#endif
    }
}

// MARK: - Actions

extension SettingsController {
    
    @objc
    private func closeAction(_ sender: UIBarButtonItem) {
        
        navigationController?.dismiss(animated: true, completion: { [weak self] in
            guard let self else { return }
            configuration.delegate?.settingsDidDismiss(configuration.initialValues)
        })
    }
}

// MARK: - Private Methods

extension SettingsController {
    
    private func reloadRowsIfNeeded() {
        guard let indexPath = indexPathToRefresh else { return }

        // Получаем секцию
        let section = sections[indexPath.section]
        
        // Проверяем, что она содержит .rows
        guard case var .rows(rows) = section.kind else { return }

        let row = rows[indexPath.row]

        if case .premiumCard(let payloadCard) = section.kind {
            configuration.delegate?.settingsPremiumStatusRequested { [weak self] isPremium in
                guard let self else { return }
                let payload = payloadCard.base
                rows[indexPath.row] = .defaultRow(.premium(.init(isPremium: isPremium, color: payload.color, vc: payload.vc, action: payload.action)))
                self.sections[indexPath.section].kind = .rows(rows)
                self.tableView?.reloadRows(at: [indexPath], with: .fade)
                self.indexPathToRefresh = nil
            }
            return
        }
        
        switch row {

        case .defaultRow(let defaultRow):
            switch defaultRow {

            case .premium(let payload):
                configuration.delegate?.settingsPremiumStatusRequested { [weak self] isPremium in
                    guard let self else { return }
//                    rows[indexPath.row] = .defaultRow(.premium(isPremium: isPremium, tintColor: color, vc: vc, action: action))
                    rows[indexPath.row] = .defaultRow(.premium(.init(isPremium: isPremium, color: payload.color, vc: payload.vc, action: payload.action)))
                    self.sections[indexPath.section].kind = .rows(rows)
                    self.tableView?.reloadRows(at: [indexPath], with: .fade)
                    self.indexPathToRefresh = nil
                }
                
            case .user(_, _, let vc):
                configuration.delegate?.settingsUserInfoRequested { [weak self] user in
                    guard let self else { return }
                    rows[indexPath.row] = .defaultRow(.user(user.name, user.avatar, vc))
                    self.sections[indexPath.section].kind = .rows(rows)
                    self.tableView?.reloadRows(at: [indexPath], with: .fade)
                    self.indexPathToRefresh = nil
                }

            default:
                break
            }

        default:
            break
        }
    }
    
    private func presentPremium(_ payload: PremiumPayload) {
        
        if payload.isPremium {
            
            AlertKitAPI.present(
                title: NSLocalizedString("Premium is active", bundle: .module, comment: ""),
                icon: .custom(UIImage(.star.fill)),
                style: .iOS17AppleMusic,
                haptic: .success
            )
            
        } else if let premiumVC = payload.vc {
            
            let vc = premiumVC.init()
            if UIDevice.current.userInterfaceIdiom == .phone {
                vc.modalPresentationStyle = .fullScreen
            }
            present(vc, animated: true)
                        
        } else if let action = payload.action {
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
#if !os(visionOS)
        tableView.contentInset.bottom = transitionContext.endFrame.size.height
#endif
    }
    
    public func storeOverlayDidFinishDismissal(_ overlay: SKOverlay,
                                               transitionContext: SKOverlay.TransitionContext) {
        
        tableView.contentInset.bottom = 0
    }
    
}

// MARK: - Set Notifications

extension SettingsController {
    
    private func setNotifications() {
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleThemeChange(_:)),
            name: .themeDidChange,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTapticChange(_:)),
            name: .tapticDidChange,
            object: nil
        )
    }
}

// MARK: - Handle Notifications

extension SettingsController {
    
    @objc
    private func handleThemeChange(_ notification: Notification) {
        guard let theme = notification.object as? ThemeStorage else { return }
        configuration.delegate?.settingsDidUpdateTheme(theme)
    }
    
    @objc
    private func handleTapticChange(_ notification: Notification) {
        guard let taptic = notification.object as? TapticStorage else { return }
        configuration.delegate?.settingsDidUpdateTaptic(taptic)
    }
}

