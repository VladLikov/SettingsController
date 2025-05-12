//
//  AppColor.swift
//  Speech To Text
//
//  Created by Влад Лыков on 07.10.2024.
//

import UIKit

public enum AppColor: String, CaseIterable {
    case purple, blue, pink, green, red, orange, yellow
    
    public var title: String {
        switch self {
        case .red:    NSLocalizedString("Red", comment: "")
        case .green:  NSLocalizedString("Green", comment: "")
        case .blue:   NSLocalizedString("Blue", comment: "")
        case .pink:   NSLocalizedString("Pink", comment: "")
        case .purple: NSLocalizedString("Purple", comment: "")
        case .orange: NSLocalizedString("Orange", comment: "")
        case .yellow: NSLocalizedString("Yellow", comment: "")
        }
    }
    
    public var color: UIColor {
        switch self {
        case .red:    .systemRed
        case .green:  .systemGreen
        case .blue:   .systemBlue
        case .pink:   .systemPink
        case .purple: .systemIndigo
        case .orange: .systemOrange
        case .yellow: .systemYellow
        }
    }
    
    public var iconName: String {
        String(describing: self).capitalized + "Icon"
    }
}
