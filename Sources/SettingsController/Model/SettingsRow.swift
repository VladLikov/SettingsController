//
//  Row.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import Foundation
import UIKit.UIViewController

public struct SettingsRow {
    
    public typealias SettingsAction = ((_ indexPath: IndexPath,
                                        _ tableView: UITableView,
                                        _ vc: UIViewController) -> Void)
    
    var title: String
    var detail: String?
    var icon: SettingsIcon
    var vc: UIViewController.Type?
    var action: SettingsAction?
    
    public init(title: String,
                detail: String? = nil,
                icon: SettingsIcon,
                vc: UIViewController.Type? = nil,
                action: SettingsAction? = nil) {
        
        self.title = title
        self.detail = detail
        self.icon = icon
        self.vc = vc
        self.action = action
    }
}
