//
//  AppColor.swift
//  Speech To Text
//
//  Created by Влад Лыков on 07.10.2024.
//

import UIKit

public enum AppColor: String, CaseIterable, AppColorType {
    case purple, blue, pink, green, red, orange, yellow
    
    public var title: String {
        switch self {
        case .red:    NSLocalizedString("Red", bundle: .module, comment: "")
        case .green:  NSLocalizedString("Green", bundle: .module, comment: "")
        case .blue:   NSLocalizedString("Blue", bundle: .module, comment: "")
        case .pink:   NSLocalizedString("Pink", bundle: .module, comment: "")
        case .purple: NSLocalizedString("Purple", bundle: .module, comment: "")
        case .orange: NSLocalizedString("Orange", bundle: .module, comment: "")
        case .yellow: NSLocalizedString("Yellow", bundle: .module, comment: "")
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
