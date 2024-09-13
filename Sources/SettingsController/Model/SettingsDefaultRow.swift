//
//  CustomRow.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import Foundation
import UIKit
import SafeSFSymbols

public enum SettingsDefaultRow {
    case row(SettingsRow)
    case action(Action)
    
    public enum Action {
        case shareApp(String)
        case rateApp(String)
        case moreApps(String)
        case contactDeveloper(String)
        case premium(Bool, UIViewController.Type)
        
        var title: String {
            switch self {
            case .shareApp(_):
                NSLocalizedString("Share app", comment: "")
            case .rateApp(_):
                NSLocalizedString("Write a review", comment: "")
            case .moreApps(_):
                NSLocalizedString("More apps", comment: "")
            case .premium(_, _):
                NSLocalizedString("Premium", comment: "")
            case .contactDeveloper(_):
                NSLocalizedString("Contact Developer", comment: "")
            }
        }
        
        var icon: SettingsIcon {
            switch self {
            case .shareApp(_):
                SettingsIcon(image: UIImage(.square.andArrowUpFill),
                             color: .systemOrange,
                             inset: .init())
            case .rateApp(_):
                SettingsIcon(image: UIImage(.heart.fill),
                             color: .systemRed,
                             inset: .init())
            case .moreApps(_):
                SettingsIcon(image: UIImage(.square.stack_3dUpFill),
                             color: .systemIndigo,
                             inset: .init())
            case .premium(_, _):
                SettingsIcon(image: UIImage(.star.fill),
                             color: .systemBlue,
                             inset: .init())
            case .contactDeveloper(_):
                SettingsIcon(image: UIImage(.envelope.fill),
                             color: .systemBlue,
                             inset: .init())
            }
        }
    }
}
