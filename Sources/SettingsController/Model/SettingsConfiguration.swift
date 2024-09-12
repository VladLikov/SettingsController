//
//  SettingsConfiguration.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import UIKit

public struct SettingsConfiguration {
    public var settingsTitle: String?
    public var initialAppColor: UIColor
    public var sections: [SettingsSection]
    
    public init(settingsTitle: String? = nil, initialAppColor: UIColor, sections: [SettingsSection]) {
        self.settingsTitle = settingsTitle
        self.initialAppColor = initialAppColor
        self.sections = sections
    }
}
