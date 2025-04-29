//
//  Icon.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import UIKit

public struct SettingsIcon {

    public let color: UIColor
    private let base: UIImage
    private let inset: UIEdgeInsets

    public func generateImage() async -> UIImage {
        if inset == .zero {
            return base
        } else {
            return await base.inset(inset)
        }
    }

    public init(image: UIImage,
                color: UIColor,
                inset: UIEdgeInsets = .zero) {
        self.base  = image
        self.color = color
        self.inset = inset
    }
}

//
//public struct SettingsIcon {
//    
//    var image: UIImage?
//    var color: UIColor
//    
//    public init(image: UIImage?, color: UIColor, inset: Inset? = nil) {
//        if let inset {
//            self.image = image?.inset(inset.value)
//        } else {
//            self.image = image
//        }
//        self.color = color
//    }
//}
