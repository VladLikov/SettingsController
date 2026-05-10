//
//  ThemeStorage.swift
//  SettingsController
//
//  Created by Влад Лыков on 02.05.2025.
//

import UIKit

public protocol ThemeStorage: AnyObject {
    var appColor: UIColor { get set }
    var appColorRawValue: String { get set }
    var autoTheme: Bool { get set }
    var interfaceStyle: Int { get set }
}
