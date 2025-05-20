//
//  SettingsInsets.swift
//  SettingsController
//
//  Created by Влад Лыков on 20.05.2025.
//

import Foundation

public struct SettingsInsets {
    let top: CGFloat?
    let bottom: CGFloat?
    
    public init(top: CGFloat? = nil, bottom: CGFloat? = nil) {
        self.top = top
        self.bottom = bottom
    }
}
