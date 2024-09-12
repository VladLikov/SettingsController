//
//  Untitled.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import UIKit

// MARK: - SplitController

class SplitController: UISplitViewController {

    static func getDefault(for vc: UIViewController) -> UIViewController {
                
        let detailController = UIViewController()
        detailController.setEmptyView(.init(title:    NSLocalizedString("Select an item", comment: ""),
                                            subtitle: NSLocalizedString("Additional information will appear here.", comment: "")))
        
        
        let splitViewController = SplitController()
        splitViewController.viewControllers = [vc, detailController]
                
        return splitViewController
        
    }
    
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
        preferredDisplayMode = .allVisible
    }
    
}

// MARK: - UISplitViewControllerDelegate

extension SplitController: UISplitViewControllerDelegate {
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
    }
    
}
