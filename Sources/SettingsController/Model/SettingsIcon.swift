//
//  Icon.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import UIKit

public struct SettingsIcon {
    
    var image: UIImage?
    var color: UIColor
    
    public init(image: UIImage?, color: UIColor, inset: Inset? = nil) {
        if let inset {
            self.image = image?.inset(inset.value)
        } else {
            self.image = image
        }
        self.color = color
    }
}
