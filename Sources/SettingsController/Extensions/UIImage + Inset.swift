//
//  UIImage + Inset.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import UIKit

import UIKit

actor InsetCache {
    
    private let cache = NSCache<NSString, UIImage>()

    func image(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}

extension UIImage {

    private static let insetCache = InsetCache()

    func inset(_ inset: UIEdgeInsets) async -> UIImage {
        
        guard inset != .zero else { return self }

        let cacheKey = "\(hash)_\(inset.top)_\(inset.left)_\(inset.bottom)_\(inset.right)"

        if let cached = await UIImage.insetCache.image(forKey: cacheKey) {
            print("return cached image")
            return cached
        }

        let newSize = CGSize(width: size.width + inset.left + inset.right,
                             height: size.height + inset.top + inset.bottom)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)

        let rendered = renderer.image { _ in
            draw(at: CGPoint(x: inset.left, y: inset.top))
        }.withRenderingMode(renderingMode)

        await UIImage.insetCache.setImage(rendered, forKey: cacheKey)
        
        return rendered
    }
}

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

