//
//  SettingsConfiguration.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import UIKit

// MARK: - SettingsControllerDelegate

public protocol SettingsControllerDelegate: AnyObject {
    func settingsDidDismiss(_ initialValues: [AnyKeyPath: Any]?)
    
    func settingsDidUpdateTheme(_ theme: ThemeStorage)
    func settingsDidUpdateTaptic(_ taptic: TapticStorage)

    func settingsUserInfoRequested(_ request: (UserInfo) -> Void)
    func settingsPremiumStatusRequested(_ request: (Bool) -> Void)
}

// MARK: - SettingsConfiguration

public final class SettingsConfiguration {
    
    public var title: String?
    public var topInset: CGFloat?
    public var sections: [SettingsSection]
    public var overlayAppID: String?
        
    public var initialValues: [AnyKeyPath: Any]?
    
    public weak var delegate: SettingsControllerDelegate?
    
    public init(title: String? = nil,
                initialValues: [AnyKeyPath: Any]? = nil,
                topInset: CGFloat? = nil,
                overlayAppID: String? = nil,
                sections: [SettingsSection],
                delegate: SettingsControllerDelegate? = nil) {
        
        self.title = title
        self.initialValues = initialValues
        self.sections = sections
        self.topInset = topInset
        self.overlayAppID = overlayAppID
        self.delegate = delegate
    }
}
