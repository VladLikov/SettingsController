//
//  SettingsConfiguration.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import UIKit

public struct SettingsConfiguration {
    
    public var title: String?
    public var topInset: CGFloat?
    public var sections: [SettingsSection]
    public var overlayAppID: String?
    
    public var initialValues: [AnyKeyPath: Any]?
    
    public init(title: String? = nil,
                initialValues: [AnyKeyPath: Any]? = nil,
                topInset: CGFloat? = nil,
                overlayAppID: String? = nil,
                sections: [SettingsSection]) {
        
        self.title = title
        self.initialValues = initialValues
        self.sections = sections
        self.topInset = topInset
        self.overlayAppID = overlayAppID
    }
}
