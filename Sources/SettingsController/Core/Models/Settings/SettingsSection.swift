//
//  SettingsSection.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import Foundation

public enum SettingsSectionKind {
    /// Статический набор строк (старое поведение)
    case rows([SettingsRowItem])

    /// Автоматическая витрина App Store-приложений вашего dev-аккаунта
    /// - Parameters:
    ///   - developerID: id разработчика в App Store
    ///   - limit:  cколько приложений показать
    case ourApps(developerID: String, limit: Int, excludeAppID: String)
    
    case premiumCard(_ payload: PremiumCardPayload)
}

public struct SettingsSection {
      
    public let title: String?
    public internal(set) var kind: SettingsSectionKind
    
    public init(title: String? = nil, kind: SettingsSectionKind) {
        self.title = title
        self.kind = kind
    }
}
