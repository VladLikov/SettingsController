//
//  SettingsRowItem.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import Foundation
import UIKit
import SafeSFSymbols

public enum SettingsRowItem {
     
    case row(SettingsRow)
    case defaultRow(DefaultRow)
    case app(AppStoreAppRowState)
    
    public enum DefaultRow {
                
        case user(String, UIImage?, UIViewController.Type)

        case premium(PremiumPayload)

        case shareApp(appID: String)
        case rateApp(appID: String)
        case moreApps(developerID: String)
        
        case redeemCode
        
        case contactDeveloper(email: String)
        case language(email: String)

        case telegram(id: String)
        case vkGroup(id: String)

        case appearance(theme: ThemeStorage, colors: [any AppColorType] = AppColor.allCases)
        case tapticEngine(taptic: TapticStorage)
        
        case about(userID: String?, appID: String, privacyURL: URL, termsURL: URL)
        
        var title: String? {
            switch self {
            case .appearance:
                NSLocalizedString("Appearance", bundle: .module, comment: "")
            case .tapticEngine:
                NSLocalizedString("Taptic Engine", bundle: .module, comment: "")
            case .shareApp:
                NSLocalizedString("Share App", bundle: .module, comment: "")
            case .rateApp:
                NSLocalizedString("Write a Review", bundle: .module, comment: "")
            case .moreApps:
                NSLocalizedString("More Apps", bundle: .module, comment: "")
            case .premium:
                NSLocalizedString("Premium", bundle: .module, comment: "")
            case .contactDeveloper:
                NSLocalizedString("Contact Developer", bundle: .module, comment: "")
            case .language:
                NSLocalizedString("Language", bundle: .module, comment: "")
            case .telegram:
                NSLocalizedString("Telegram Channel", bundle: .module, comment: "")
            case .vkGroup:
                NSLocalizedString("VK Group", bundle: .module, comment: "")
            case .redeemCode:
                NSLocalizedString("Redeem Code", bundle: .module, comment: "")
            case .about:
                NSLocalizedString("About App", bundle: .module, comment: "")
            default: nil
            }
        }
        
        var icon: SettingsIcon? {
            switch self {
            case .appearance:
                SettingsIcon(symbol: .lightbulb.fill,
                             color: .systemIndigo,
                             inset: .init())

            case .tapticEngine:
                SettingsIcon(symbol: .hand.tapFill,
                             color: .systemOrange,
                             inset: .init())

            case .shareApp(_):
                SettingsIcon(symbol: .square.andArrowUpFill,
                             color: .systemOrange,
                             inset: .init())

            case .rateApp(_):
                SettingsIcon(symbol: .heart.fill,
                             color: .systemRed,
                             inset: .init())

            case .moreApps(_):
                SettingsIcon(symbol: .square.stack_3dUpFill,
                             color: .systemIndigo,
                             inset: .init())

            case .premium(let payload):
                SettingsIcon(symbol: .star.fill,
                             color: payload.color,
                             inset: .init())

            case .contactDeveloper(_):
                SettingsIcon(symbol: .envelope.fill,
                             color: .systemBlue,
                             inset: .init())

            case .language(_):
                SettingsIcon(symbol: .globe,
                             color: .gray,
                             inset: .init())

            case .about:
                SettingsIcon(symbol: .house.fill,
                             color: UIColor(red: 50 / 255, green: 173 / 255, blue: 230 / 255, alpha: 1),
                             inset: .init())

            case .telegram(_):
                SettingsIcon(image: .init(resource: .telegram),
                             color: UIColor(red: 0, green: 145 / 255, blue: 1, alpha: 1),
                             inset: .init(1),
                             cacheIdentifier: "asset:telegram")

            case .vkGroup(_):
                SettingsIcon(image: .init(resource: .vk),
                             color: .systemBlue,
                             inset: .init(5),
                             cacheIdentifier: "asset:vk")

            case .redeemCode:
                SettingsIcon(symbol: .number,
                             color: .systemOrange,
                             inset: .init(5))
                
            default: nil
                
            }
        }
    }
}
