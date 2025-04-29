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
        
        public typealias PremiumAction = (_ fromVC: UIViewController) -> Void
        
        case user(String, UIImage?, UIViewController.Type)

        case premium(Bool, UIColor, UIViewController.Type?, PremiumAction?)

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
                             color: .systemOrange)
            case .rateApp(_):
                SettingsIcon(image: UIImage(.heart.fill),
                             color: .systemRed)
            case .moreApps(_):
                SettingsIcon(image: UIImage(.square.stack_3dUpFill),
                             color: .systemIndigo)
            case .premium(_, let color, _, _):
                SettingsIcon(image: UIImage(.star.fill),
                             color: color)
            case .contactDeveloper(_):
                SettingsIcon(image: UIImage(.envelope.fill),
                             color: .systemBlue)
            case .language(_):
                SettingsIcon(image: UIImage(.globe),
                             color: .gray)
            case .telegram(_):
                SettingsIcon(image: UIImage(resource: .telegram),
                             color: .init(hex: "0091FF"),
                             inset: .init(top: 1, left: 1, bottom: 1, right: 1))
            case .vkGroup(_):
                SettingsIcon(image: UIImage(resource: .vk),
                             color: .systemBlue,
                             inset: .init(top: 20, left: 20, bottom: 20, right: 20))
            default: nil
                
            }
        }
    }
}
