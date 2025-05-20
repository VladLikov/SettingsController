//
//  PremiumPayload.swift
//  SettingsController
//
//  Created by Влад Лыков on 20.05.2025.
//

import Foundation
import UIKit

public struct PremiumPayload {
    let isPremium: Bool
    let color: UIColor
    let vc: UIViewController.Type?
    let action: PremiumAction?
    
    public typealias PremiumAction = (_ fromVC: UIViewController) -> Void
    
    public init(isPremium: Bool, color: UIColor, vc: UIViewController.Type?, action: PremiumAction?) {
        self.isPremium = isPremium
        self.color = color
        self.vc = vc
        self.action = action
    }
}
