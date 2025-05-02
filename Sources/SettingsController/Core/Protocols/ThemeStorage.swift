//
//  ThemeStorage.swift
//  SettingsController
//
//  Created by Влад Лыков on 02.05.2025.
//

import UIKit

public protocol ThemeStorage {
    var appColor: UIColor { get set }
    var appColorIndex: Int { get set }
    var autoTheme: Bool { get set }
    var interfaceStyle: Int { get set }
}
