//
//  UIImage + Inset.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import Foundation
import UIKit.UIImage

//public extension UIImage {
//    func inset(_ inset: CGFloat = 4.0) -> UIImage {
//        return self.with(UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset))
//    }
//    
//    func with(_ insets: UIEdgeInsets) -> UIImage {
//        let targetWidth  = size.width  + insets.left + insets.right
//        let targetHeight = size.height + insets.top  + insets.bottom
//        let targetSize = CGSize(width: targetWidth, height: targetHeight)
//        let targetOrigin = CGPoint(x: insets.left, y: insets.top)
//        let format = UIGraphicsImageRendererFormat()
////        format.scale = self.scale * self.scale // maybe need to delete
//        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
//        return renderer.image { _ in
//            draw(in: CGRect(origin: targetOrigin, size: size))
//        }.withRenderingMode(.alwaysTemplate)
//    }
//}

