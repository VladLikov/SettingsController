//
//  SettingsSection.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import Foundation

public enum SettingsSectionKind {
    /// Статический набор строк (старое поведение)
    case rows([SettingsRowData])

    /// Автоматическая витрина App Store-приложений вашего dev-аккаунта
    /// - Parameters:
    ///   - developerID: id разработчика в App Store
    ///   - limit:  cколько приложений показать
    case ourApps(developerID: String, limit: Int, appID: String)
}

public struct SettingsSection {
      
    var title: String? = nil
    var kind: SettingsSectionKind
    
    public init(title: String? = nil, kind: SettingsSectionKind) {
        self.title = title
        self.kind = kind
    }
}
