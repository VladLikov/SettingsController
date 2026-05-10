//
//  SettingsInsets.swift
//  SettingsController
//
//  Created by Влад Лыков on 20.05.2025.
//

import Foundation

public struct SettingsInsets {
    public let top: CGFloat?
    public let bottom: CGFloat?
    
    public init(top: CGFloat? = nil, bottom: CGFloat? = nil) {
        self.top = top
        self.bottom = bottom
    }
}
