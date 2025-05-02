//
//  AppRow.swift
//  SettingsController
//
//  Created by Влад Лыков on 29.04.2025.
//

import Foundation

public enum AppRow {
    case placeholder                     // «скелетон» пока идёт загрузка
    case loaded(AppItem)                 // когда всё скачалось
    case failed                          // если запрос упал
}
