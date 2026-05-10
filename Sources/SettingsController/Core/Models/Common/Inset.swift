//
//  Inset.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import UIKit

public struct Inset {
    
    public let value: CGFloat
    
    public var edgeInsets: UIEdgeInsets {
        .init(top: value, left: value, bottom: value, right: value)
    }
    
    public init(_ value: CGFloat = 4) {
        self.value = value
    }
}
