//
//  AppColorType.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.06.2025.
//

import UIKit

public protocol AppColorType: RawRepresentable, CaseIterable where RawValue == String {
    var title: String { get }
    var color: UIColor { get }
}
