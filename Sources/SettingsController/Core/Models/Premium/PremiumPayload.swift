//
//  PremiumPayload.swift
//  SettingsController
//
//  Created by Влад Лыков on 20.05.2025.
//

import Foundation
import UIKit

public struct PremiumPayload {
    public let isPremium: Bool
    public let color: UIColor
    public let destinationControllerType: UIViewController.Type?
    public let action: PremiumAction?

    public typealias PremiumAction = (_ fromVC: UIViewController) -> Void

    public init(
        isPremium: Bool,
        color: UIColor,
        destinationControllerType: UIViewController.Type?,
        action: PremiumAction?
    ) {
        self.isPremium = isPremium
        self.color = color
        self.destinationControllerType = destinationControllerType
        self.action = action
    }

}
