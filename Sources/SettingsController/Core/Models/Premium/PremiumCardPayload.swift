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
    /// Host-localized tier label, such as PRO or Plus; rendered in bold after the title.
    public let tierTitle: String?
    public let subtitle: String
    public let buttonTitle: String

    public let premium: PremiumPayload

    public init(image: Image, title: String, subtitle: String, buttonTitle: String, premium: PremiumPayload) {
        self.init(image: image, title: title, tierTitle: nil, subtitle: subtitle,
                  buttonTitle: buttonTitle, premium: premium)
    }

    public init(image: Image = Image(systemName: "sparkle"), title: String, tierTitle: String?,
                subtitle: String = "", buttonTitle: String, premium: PremiumPayload) {
        self.image = image
        self.title = title
        let tier = tierTitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.tierTitle = tier?.isEmpty == false ? tier : nil
        self.subtitle = subtitle
        self.buttonTitle = buttonTitle
        self.premium = premium
    }
}
