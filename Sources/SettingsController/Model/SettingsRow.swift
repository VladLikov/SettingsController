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
    var icon: SettingsIcon
    var vc: UIViewController.Type? = nil
    var function: ((_ indexPath: IndexPath) -> Void)? = nil
}
