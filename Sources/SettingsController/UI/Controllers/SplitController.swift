//
//  Untitled.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import UIKit

// MARK: - SplitController

final class SplitController: UISplitViewController {
        
    // MARK: Life Cycle
    
    init() {
        
        if UIDevice.isPad {
            if #available(iOS 26, *) {
                super.init(style: .doubleColumn)
            } else {
                super.init(nibName: nil, bundle: nil)
            }
        } else {
            super.init(nibName: nil, bundle: nil)
        }

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
        
        if UIDevice.isPad {
            if #available(iOS 26, *) {
                displayModeButtonVisibility = .never
            }
        }
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
    
    static func getDefault(for vc: UIViewController) -> UIViewController {
                
        let detailController = UIViewController()
        detailController.setEmptyView(.init(title:    NSLocalizedString("Select an item", bundle: .module, comment: ""),
                                            subtitle: NSLocalizedString("Additional information will appear here.", bundle: .module, comment: "")))
        
        
        let splitViewController = SplitController()
        splitViewController.viewControllers = [vc, detailController]
                
        return splitViewController
        
    }
    
}
