//
//  SplitController.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import UIKit

// MARK: - SplitController

final class SplitController: UISplitViewController {
        
    // MARK: Life Cycle
    
    init() {
        super.init(nibName: nil, bundle: nil)

        setupController()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: Status Bar
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        viewControllers.first?.preferredStatusBarStyle ?? .lightContent
    }
    
    // MARK: Private Methods
    
    private func setupController() {
        
        delegate = self
        preferredDisplayMode = .oneBesideSecondary
    }
}

// MARK: - UISplitViewControllerDelegate

extension SplitController: UISplitViewControllerDelegate {
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
    }
}

// MARK: - Get Default

extension SplitController {
    
    static func makeDefault(for primaryViewController: UIViewController) -> UIViewController {
        let detailController = UIViewController()
        detailController.view = EmptyStateView(
            title: NSLocalizedString("Select an item", bundle: .module, comment: ""),
            subtitle: NSLocalizedString("Additional information will appear here.", bundle: .module, comment: "")
        )

        let splitViewController = SplitController()
        splitViewController.viewControllers = [
            primaryViewController,
            UINavigationController(rootViewController: detailController)
        ]
                
        return splitViewController
        
    }
}
