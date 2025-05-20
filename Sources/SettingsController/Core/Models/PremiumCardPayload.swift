//
//  PremiumCardPayload.swift
//  SettingsController
//
//  Created by Влад Лыков on 20.05.2025.
//

import UIKit

public struct PremiumCardPayload {
    let isPremium: Bool
    let color: UIColor
    let image: UIImage
    let title: String
    let subtitle: String
    let vc: UIViewController.Type?
    let action: SettingsRowData.DefaultRow.PremiumAction?
    
    public init(isPremium: Bool, color: UIColor, image: UIImage, title: String, subtitle: String, vc: UIViewController.Type?, action: SettingsRowData.DefaultRow.PremiumAction?) {
        self.isPremium = isPremium
        self.color = color
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.vc = vc
        self.action = action
    }
}
