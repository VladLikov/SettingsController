//
//  SettingsSectionData.swift
//  SettingsController
//
//  Created by Влад Лыков on 28.04.2025.
//

import Foundation

public enum SettingsSectionData {
    
    case section(SettingsSection)
    case defaultSection(DefaultSection)
    
    public enum DefaultSection {
        
        case ourApps(String)
        
        var title: String? {
            switch self {
            case .ourApps:
                NSLocalizedString("Our apps", bundle: .module, comment: "")
            }
        }
    }
}
