//
//  SettingsSection.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import Foundation

public struct SettingsSection {
    var title: String? = nil
    var rows: [SettingsDefaultRow]
    
    public init(title: String? = nil, rows: [SettingsDefaultRow]) {
        self.title = title
        self.rows = rows
    }
}
