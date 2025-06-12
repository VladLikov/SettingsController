//
//  AppColorType.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.06.2025.
//

import Foundation
import UIKit

/// 1) Протокол, которому должен соответствовать любой enum “цветов”.
public protocol AppColorType: RawRepresentable, CaseIterable where RawValue == String {
    /// Локализованное название
    var title: String { get }
    /// Собственно цвет
    var color: UIColor { get }
    /// Имя иконки
    var iconName: String { get }
}

public extension SettingsRowData.DefaultRow {
    static func appearance(theme: ThemeStorage) -> Self {
        .appearance(theme: theme, colors: AppColor.allCases)
    }
}
