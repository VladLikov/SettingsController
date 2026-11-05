//
//  SettingsRowItem.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import Foundation
import UIKit

public enum SettingsRowItem {

    case row(SettingsRow)
    case defaultRow(DefaultRow)
    case app(AppStoreAppRowState)

    public enum DefaultRow {

        case user(String, UIImage?, UIViewController.Type)
        case userFactory(String, UIImage?, SettingsDestinationFactory)

        public static func user(
            _ name: String, _ avatar: UIImage? = nil,
            destinationFactory: @escaping SettingsDestinationFactory
        ) -> Self {
            .userFactory(name, avatar, destinationFactory)
        }

        case premium(PremiumPayload)

        case shareApp(appID: String)
        case rateApp(appID: String)
        case moreApps(developerID: String)

        case redeemCode

        case contactDeveloper(email: String)
        case language

        case telegram(id: String)
        case vkGroup(id: String)

        case appearance(theme: ThemeStorage, colors: [any AppColorType] = AppColor.allCases)
        case tapticEngine(taptic: TapticStorage)

        case about(appID: String, privacyURL: URL, termsURL: URL)
    }
}
