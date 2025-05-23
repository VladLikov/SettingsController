//
//  PremiumCardPayload.swift
//  SettingsController
//
//  Created by Влад Лыков on 20.05.2025.
//

import UIKit
import SwiftUI

public struct PremiumCardPayload {
    
    let image: Image
    let title: String
    let subtitle: String
    let buttonTitle: String

    let base: PremiumPayload
    
    public init(image: Image, title: String, subtitle: String, buttonTitle: String, base: PremiumPayload) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.buttonTitle = buttonTitle
        self.base = base
    }
}
