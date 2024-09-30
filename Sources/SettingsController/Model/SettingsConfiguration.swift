//
//  SettingsConfiguration.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import UIKit

public struct SettingsConfiguration {
    public var settingsTitle: String?
//    public var initialAppColor: UIColor?
    public var topInset: CGFloat?
    public var sections: [SettingsSection]
    
    public var initialValues: [AnyKeyPath: Any]?
    
    public init(settingsTitle: String? = nil,
                initialValues: [AnyKeyPath: Any]? = nil,
                /*initialAppColor: UIColor? = nil,*/
                topInset: CGFloat? = nil,
                sections: [SettingsSection]) {
        self.settingsTitle = settingsTitle
//        self.initialAppColor = initialAppColor
        self.initialValues = initialValues
        self.sections = sections
        self.topInset = topInset
    }
}
