//
//  Row.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import Foundation
import UIKit.UIViewController

public struct SettingsRow {
    var title: String
    var detail: String?
    var icon: SettingsIcon
    var vc: UIViewController.Type?
    var function: ((_ indexPath: IndexPath, _ tableView: UITableView) -> Void)?
    
    public init(title: String,
                detail: String? = nil,
                icon: SettingsIcon,
                vc: UIViewController.Type? = nil,
                function: ((_ indexPath: IndexPath, _ tableView: UITableView) -> Void)? = nil) {
        
        self.title = title
        self.detail = detail
        self.icon = icon
        self.vc = vc
        self.function = function
    }
}
