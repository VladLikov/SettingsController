//
//  SettingsNotifier.swift
//  SettingsController
//
//  Created by Влад Лыков on 02.05.2025.
//

import Foundation

enum SettingsNotifier {
    
    static func didChangeTheme(_ theme: ThemeStorage) {
        NotificationCenter.default.post(name: .themeDidChange, object: theme)
    }
    
    static func didChangeTaptic(_ taptic: TapticStorage) {
        NotificationCenter.default.post(name: .tapticDidChange, object: taptic)
    }
}

extension Notification.Name {
    static let themeDidChange = Notification.Name("themeDidChange")
    static let tapticDidChange = Notification.Name("tapticDidChange")
}
