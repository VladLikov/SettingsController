//
//  CustomRow.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import Foundation
import UIKit
import SafeSFSymbols

public enum SettingsRowData {
    
    case row(SettingsRow)
    case defaultRow(DefaultRow)
    
    public enum DefaultRow {
        
        case user(String, UIImage, UIViewController.Type)

        case premium(Bool, UIColor, UIViewController.Type)

        case shareApp(String)
        case rateApp(String)
        case moreApps(String)
        
        case contactDeveloper(String)
        case language(String)

        case telegram(String)
        case vkGroup(String)

        var title: String? {
            switch self {
            case .shareApp:
                NSLocalizedString("Share app", bundle: .module, comment: "")
            case .rateApp:
                NSLocalizedString("Write a review", bundle: .module, comment: "")
            case .moreApps:
                NSLocalizedString("More apps", bundle: .module, comment: "")
            case .premium:
                NSLocalizedString("Premium", bundle: .module, comment: "")
            case .contactDeveloper:
                NSLocalizedString("Contact developer", bundle: .module, comment: "")
            case .language:
                NSLocalizedString("Language", bundle: .module, comment: "")
            case .telegram:
                NSLocalizedString("Telegram channel", bundle: .module, comment: "")
            case .vkGroup:
                NSLocalizedString("VK group", bundle: .module, comment: "")
            case .user:
                nil
            }
        }
        
        var icon: SettingsIcon? {
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
            case .premium(_, let color, _):
                SettingsIcon(image: UIImage(.star.fill),
                             color: color,
                             inset: .init())
            case .contactDeveloper(_):
                SettingsIcon(image: UIImage(.envelope.fill),
                             color: .systemBlue,
                             inset: .init())
            case .language(_):
                SettingsIcon(image: UIImage(.globe),
                             color: .gray,
                             inset: .init())
            case .telegram(_):
                SettingsIcon(image: UIImage(resource: .telegram),
                             color: .init(hex: "0091FF"),
                             inset: .init(1))
            case .vkGroup(_):
                SettingsIcon(image: UIImage(resource: .vk),
                             color: .systemBlue,
                             inset: .init(5))
            default: nil
                
            }
        }
    }
}
