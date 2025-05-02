//
//  UIImage + Inset.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

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
        }.withRenderingMode(.alwaysTemplate)

        await UIImage.insetCache.setImage(rendered, forKey: cacheKey)
        
        return rendered
    }
}

