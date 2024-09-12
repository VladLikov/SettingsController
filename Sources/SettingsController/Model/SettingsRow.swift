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
    var vc: UIViewController.Type? = nil
    var function: ((_ indexPath: IndexPath) -> Void)? = nil
    
    public init(title: String,
                detail: String?,
                icon: SettingsIcon,
                vc: UIViewController.Type?,
                function: ((_ indexPath: IndexPath) -> Void)? = nil) {
        
        self.title = title
        self.detail = detail
        self.icon = icon
        self.vc = vc
        self.function = function
    }
}
