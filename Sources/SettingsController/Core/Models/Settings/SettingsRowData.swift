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
    case app(AppRow)
    
    public enum DefaultRow {
                
        case user(String, UIImage?, UIViewController.Type)

        case premium(PremiumPayload)

        case shareApp(appID: String)
        case rateApp(appID: String)
        case moreApps(developerID: String)
        
        @available(iOS 14.0, *)
        case redeemCode
        
        case contactDeveloper(email: String)
        case language(email: String)

        case telegram(id: String)
        case vkGroup(id: String)

        case appearance(theme: ThemeStorage, colors: [any AppColorType])
        case tapticEngine(taptic: TapticStorage)
        
        var title: String? {
            switch self {
            case .appearance:
                NSLocalizedString("Appearance", bundle: .module, comment: "")
            case .tapticEngine:
                NSLocalizedString("Taptic Engine", bundle: .module, comment: "")
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
            case .redeemCode:
                NSLocalizedString("Redeem code", bundle: .module, comment: "")
            default: nil
            }
        }
        
        var icon: SettingsIcon? {
            switch self {
            case .appearance:
                SettingsIcon(image: .init(.lightbulb.fill),
                             color: .systemIndigo,
                             inset: .init())
                
            case .tapticEngine:
                SettingsIcon(image: .init(.sun.minFill),
                             color: .systemOrange,
                             inset: .init())
                
            case .shareApp(_):
                SettingsIcon(image: .init(.square.andArrowUpFill),
                             color: .systemOrange,
                             inset: .init())

            case .rateApp(_):
                SettingsIcon(image: .init(.heart.fill),
                             color: .systemRed,
                             inset: .init())

            case .moreApps(_):
                SettingsIcon(image: .init(.square.stack_3dUpFill),
                             color: .systemIndigo,
                             inset: .init())

            case .premium(let payload):
                SettingsIcon(image: .init(.star.fill),
                             color: payload.color,
                             inset: .init())
                
            case .contactDeveloper(_):
                SettingsIcon(image: .init(.envelope.fill),
                             color: .systemBlue,
                             inset: .init())
                
            case .language(_):
                SettingsIcon(image: .init(.globe),
                             color: .gray,
                             inset: .init())
                
            case .telegram(_):
                SettingsIcon(image: .init(resource: .telegram),
                             color: .init(hex: "0091FF"),
                             inset: .init(1))
                
            case .vkGroup(_):
                SettingsIcon(image: .init(resource: .vk),
                             color: .systemBlue,
                             inset: .init(5))
                
            case .redeemCode:
                SettingsIcon(image: .init(.number),
                             color: .systemOrange,
                             inset: .init(5))
                
            default: nil
                
            }
        }
    }
}
