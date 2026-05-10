//
//  SettingsRow.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import Foundation
import UIKit.UIViewController

public struct SettingsRow {
    
    public typealias SettingsAction = ((_ indexPath: IndexPath,
                                        _ tableView: UITableView,
                                        _ viewController: UIViewController) -> Void)

    public let title: String
    public let detail: String?
    public let icon: SettingsIcon
    public let destinationControllerType: UIViewController.Type?
    public let action: SettingsAction?

    public init(title: String,
                detail: String? = nil,
                icon: SettingsIcon,
                destinationControllerType: UIViewController.Type? = nil,
                action: SettingsAction? = nil) {

        self.title = title
        self.detail = detail
        self.icon = icon
        self.destinationControllerType = destinationControllerType
        self.action = action
    }
}
