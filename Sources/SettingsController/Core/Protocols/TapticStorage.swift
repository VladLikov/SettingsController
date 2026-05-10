//
//  TapticStorage.swift
//  SettingsController
//
//  Created by Влад Лыков on 02.05.2025.
//

import Foundation

public protocol TapticStorage: AnyObject {
    var tapticStyle: Int { get set }
    var tapticEngine: Bool { get set }
}
