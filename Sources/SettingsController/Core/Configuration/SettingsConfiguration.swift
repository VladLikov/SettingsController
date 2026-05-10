//
//  SettingsConfiguration.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import UIKit

// MARK: - SettingsControllerEventHandler

@MainActor
public protocol SettingsControllerEventHandler: AnyObject {
    func settingsDidDismiss()

    func settingsDidUpdateTheme(_ theme: ThemeStorage)
    func settingsDidUpdateTaptic(_ taptic: TapticStorage)
}

// MARK: - SettingsControllerDataProvider

@MainActor
public protocol SettingsControllerDataProvider: AnyObject {
    func settingsCurrentUserInfo() async -> UserInfo?
    func settingsIsPremiumActive() async -> Bool
}

// MARK: - SettingsControllerDelegate

@MainActor
public protocol SettingsControllerDelegate: SettingsControllerEventHandler, SettingsControllerDataProvider {}

// MARK: - SettingsConfiguration

public final class SettingsConfiguration {

    public let title: String?
    public let insets: SettingsInsets?
    public let sections: [SettingsSection]
    public let overlayAppID: String?

    public private(set) weak var eventHandler: (any SettingsControllerEventHandler)?
    public private(set) weak var dataProvider: (any SettingsControllerDataProvider)?

    private let retainedEventHandler: (any SettingsControllerEventHandler)?
    private let retainedDataProvider: (any SettingsControllerDataProvider)?

    public init(title: String? = nil,
                insets: SettingsInsets? = nil,
                overlayAppID: String? = nil,
                sections: [SettingsSection],
                eventHandler: (any SettingsControllerEventHandler)? = nil,
                dataProvider: (any SettingsControllerDataProvider)? = nil,
                delegate: (any SettingsControllerDelegate)? = nil) {

        self.title = title
        self.sections = sections
        self.insets = insets
        self.overlayAppID = overlayAppID
        self.retainedEventHandler = eventHandler
        self.retainedDataProvider = dataProvider
        self.eventHandler = eventHandler ?? delegate
        self.dataProvider = dataProvider ?? delegate
    }
}
