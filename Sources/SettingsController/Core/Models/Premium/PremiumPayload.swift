//
//  PremiumPayload.swift
//  SettingsController
//
//  Created by Влад Лыков on 20.05.2025.
//

import Foundation
import UIKit

public struct PremiumPayload {
    public private(set) var isPremium: Bool
    public let color: UIColor
    public let destinationControllerType: UIViewController.Type?
    public let action: PremiumAction?
    public let destinationFactory: SettingsDestinationFactory?

    public typealias PremiumAction = (_ fromVC: UIViewController) -> Void

    public init(
        isPremium: Bool,
        color: UIColor,
        destinationControllerType: UIViewController.Type? = nil,
        action: PremiumAction? = nil
    ) {
        self.isPremium = isPremium
        self.color = color
        self.destinationControllerType = destinationControllerType
        self.action = action
        self.destinationFactory = nil
    }


    public init(isPremium: Bool, color: UIColor,
                destinationFactory: @escaping SettingsDestinationFactory) {
        self.isPremium = isPremium
        self.color = color
        self.destinationControllerType = nil
        self.action = nil
        self.destinationFactory = destinationFactory
    }

    func withPremiumStatus(_ value: Bool) -> Self {
        var result = self
        result.isPremium = value
        return result
    }
}
