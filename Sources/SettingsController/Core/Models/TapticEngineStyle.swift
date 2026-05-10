//
//  TapticEngineStyle.swift
//  SettingsController
//
//  Created by Влад Лыков on 06.10.2024.
//

import Foundation

enum TapticEngineStyle: Int, CaseIterable {
    case light  = 0
    case medium = 1
    case hard   = 2
    
    var title: String {
        switch self {
        case .light:  NSLocalizedString("Light", bundle: .module, comment: "")
        case .medium: NSLocalizedString("Medium", bundle: .module, comment: "")
        case .hard:   NSLocalizedString("Hard", bundle: .module, comment: "")
        }
    }
}
