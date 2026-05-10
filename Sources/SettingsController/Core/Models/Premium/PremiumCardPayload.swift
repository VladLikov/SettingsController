//
//  PremiumCardPayload.swift
//  SettingsController
//
//  Created by Влад Лыков on 20.05.2025.
//

import UIKit
import SwiftUI

public struct PremiumCardPayload {
    
    public let image: Image
    public let title: String
    public let subtitle: String
    public let buttonTitle: String

    public let premium: PremiumPayload

    public init(image: Image, title: String, subtitle: String, buttonTitle: String, premium: PremiumPayload) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.buttonTitle = buttonTitle
        self.premium = premium
    }
}
