//
//  PremiumCardPayload.swift
//  SettingsController
//
//  Created by Влад Лыков on 20.05.2025.
//

import UIKit

public struct PremiumCardPayload {
    
    let image: UIImage
    let title: String
    let subtitle: String
    
    let base: PremiumPayload
    
    public init(image: UIImage, title: String, subtitle: String, base: PremiumPayload) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.base = base
    }
}
