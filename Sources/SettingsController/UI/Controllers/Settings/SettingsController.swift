//
//  SettingsController.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import UIKit

// MARK: - SettingsController

public final class SettingsController: UITableViewController {
            
    // MARK: Present Settings
    
    @discardableResult
    @MainActor
    public static func present(configuration: SettingsConfiguration,
                               from fromVC: UIViewController) -> SettingsController {

        let settingsController = SettingsController(configuration: configuration)
        let settingsNavController = UINavigationController(rootViewController: settingsController)

        let splitViewController = SplitController.makeDefault(for: settingsNavController)

        splitViewController.modalPresentationStyle = .fullScreen

        fromVC.present(splitViewController, animated: true)

        return settingsController
    }
    
    @MainActor
    public static func getSplitPresentationSettingsController(configuration: SettingsConfiguration) -> UIViewController {

        let settingsController = SettingsController(configuration: configuration)
        let settingsNavController = UINavigationController(rootViewController: settingsController)

        return SplitController.makeDefault(for: settingsNavController)
    }
    
    // MARK: Properties
    
    let configuration: SettingsConfiguration

    var sections: [SettingsSection]
    
    private lazy var closeButton: UIBarButtonItem = {
        UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(self.closeAction(_:)))
    }()
    
    var overlayAppViewDidShown: Bool = false
        
    enum PendingRefresh {
        case premium(IndexPath)
        case user(IndexPath)
    }

    var pendingRefresh: PendingRefresh?

    var isPremium: Bool = false

    var appLoadTasks: [Int: Task<Void, Never>] = [:]
    var storeProductTask: Task<Void, Never>?
    var pendingRefreshTask: Task<Void, Never>?
    var aboutStatusTask: Task<Void, Never>?
    var mailPresentationTask: Task<Void, Never>?
    
    // MARK: Life Cycle
    
    public init(configuration: SettingsConfiguration) {
        self.configuration = configuration
        self.sections = configuration.sections
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        appLoadTasks.values.forEach { $0.cancel() }
        storeProductTask?.cancel()
        pendingRefreshTask?.cancel()
        aboutStatusTask?.cancel()
        mailPresentationTask?.cancel()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        title = configuration.title
        isPremium = cachedPremiumStatus
        
        tableView?.register(SettingsCell.self)
        tableView?.register(UserCell.self)
        tableView?.register(AppCell.self)
        tableView?.register(PremiumCell.self)

        tableView?.rowHeight = UITableView.automaticDimension
        tableView?.estimatedRowHeight = defaultRowEstimatedHeight
        tableView?.separatorInset.left = 63
        
        if let topInset = configuration.insets?.top {
            tableView?.contentInset.top = topInset
        }
        
        if let bottomInset = configuration.insets?.bottom {
            tableView?.contentInset.bottom = bottomInset
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
        
        for (idx, section) in sections.enumerated() {
            if case .ourApps = section.kind {
                loadOurApps(for: idx)
            }
        }
    }
       
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        refreshPendingRowIfNeeded()
        
        displayAppOverlayIfNeeded()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        dismissAppOverlayIfNeeded()
    }
    
    private func loadOurApps(for sectionIndex: Int) {

        let section = sections[sectionIndex]

        guard case let .ourApps(developerID, limit, appID) = section.kind else {
            return
        }

        appLoadTasks[sectionIndex]?.cancel()

        appLoadTasks[sectionIndex] = Task { [weak self] in
            do {
                let apps = try await AppStoreAppsLoader.fetch(
                    developerId: developerID,
                    limit: limit,
                    excludeAppID: appID
                )

                let rows = apps.map { SettingsRowItem.app(.loaded($0)) }

                await MainActor.run { [weak self] in
                    guard let self,
                          !Task.isCancelled,
                          sections.indices.contains(sectionIndex) else { return }

                    sections[sectionIndex].kind = rows.isEmpty ? .rows([.app(.failed)]) : .rows(rows)
                    tableView.reloadSections(IndexSet(integer: sectionIndex), with: .automatic)
                    appLoadTasks[sectionIndex] = nil
                }

            } catch is CancellationError {
                return
            } catch {
                await MainActor.run { [weak self] in
                    guard let self,
                          !Task.isCancelled,
                          sections.indices.contains(sectionIndex) else { return }

                    sections[sectionIndex].kind = .rows([.app(.failed)])
                    tableView.reloadSections(IndexSet(integer: sectionIndex), with: .automatic)
                    appLoadTasks[sectionIndex] = nil
                }
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
