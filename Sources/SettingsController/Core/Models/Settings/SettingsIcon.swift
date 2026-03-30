//
//  Icon.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import UIKit

public struct SettingsIcon {
        
    let base: UIImage?
    let color: UIColor
    let inset: Inset?
        
    @MainActor
    public func generateImage() async -> UIImage? {
        if let inset {
            return await base?.inset(inset.edgeInsets)
        } else {
            return base
        }
    }
    
    public init(image: UIImage?, color: UIColor, inset: Inset? = nil) {
        self.base  = image
        self.color = color
        self.inset = inset
    }
}
