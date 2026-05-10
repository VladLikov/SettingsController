//
//  SettingsIcon.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import UIKit
import SafeSFSymbols

public struct SettingsIcon {

    public let image: UIImage?
    public let color: UIColor
    public let inset: Inset?

    @MainActor
    fileprivate static let tileCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 200
        return cache
    }()

    private let symbol: SafeSFSymbol?
    private let cacheIdentifier: String?

    public func generateImage() -> UIImage? {
        guard let image else { return nil }
        guard let inset else { return image }

        return image.padded(by: inset.edgeInsets, renderingMode: .alwaysTemplate)
    }

    @MainActor
    func makeSettingsTileImage(
        size: CGSize = CGSize(width: 30, height: 30),
        cornerRadius: CGFloat = 7.5,
        traitCollection: UITraitCollection = .current
    ) -> UIImage? {
        guard size.width > 0, size.height > 0, cornerRadius >= 0 else {
            return nil
        }

        guard let cacheKey = tileCacheKey(
            size: size,
            cornerRadius: cornerRadius,
            traitCollection: traitCollection
        ) else {
            return renderSettingsTileImage(size: size, cornerRadius: cornerRadius, traitCollection: traitCollection)
        }

        if let cached = Self.tileCache.object(forKey: cacheKey) {
            return cached
        }

        guard let rendered = renderSettingsTileImage(
            size: size,
            cornerRadius: cornerRadius,
            traitCollection: traitCollection
        ) else {
            return nil
        }

        Self.tileCache.setObject(rendered, forKey: cacheKey)
        return rendered
    }

    public init(image: UIImage?, color: UIColor, inset: Inset? = nil, cacheIdentifier: String? = nil) {
        self.image = image
        self.color = color
        self.inset = inset
        self.symbol = nil
        self.cacheIdentifier = cacheIdentifier
    }

    public init(symbol: SafeSFSymbol, color: UIColor, inset: Inset? = Inset()) {
        self.image = UIImage(symbol)
        self.color = color
        self.inset = inset
        self.symbol = symbol
        self.cacheIdentifier = "sf:\(symbol.name)"
    }

    @MainActor
    public func generateSettingsImage(
        size: CGSize = SettingsIconGenerator.defaultSize,
        cornerRadius: CGFloat = SettingsIconGenerator.defaultCornerRadius,
        traitCollection: UITraitCollection = .current
    ) -> UIImage? {
        SettingsIconGenerator.generate(
            self,
            size: size,
            cornerRadius: cornerRadius,
            traitCollection: traitCollection
        )
    }
}

public enum SettingsIconGenerator {

    public static let defaultSize = CGSize(width: 30, height: 30)
    public static let defaultCornerRadius: CGFloat = 7.5

    @MainActor
    public static func generate(
        _ icon: SettingsIcon,
        size: CGSize = defaultSize,
        cornerRadius: CGFloat = defaultCornerRadius,
        traitCollection: UITraitCollection = .current
    ) -> UIImage? {
        icon.makeSettingsTileImage(
            size: size,
            cornerRadius: cornerRadius,
            traitCollection: traitCollection
        )
    }

    @MainActor
    public static func generate(
        systemName: String,
        backgroundColor: UIColor,
        inset: Inset? = Inset(),
        size: CGSize = defaultSize,
        cornerRadius: CGFloat = defaultCornerRadius,
        traitCollection: UITraitCollection = .current
    ) -> UIImage? {
        generate(
            image: UIImage(systemName: systemName),
            backgroundColor: backgroundColor,
            inset: inset,
            cacheIdentifier: "sf:\(systemName)",
            size: size,
            cornerRadius: cornerRadius,
            traitCollection: traitCollection
        )
    }

    @MainActor
    public static func generate(
        symbol: SafeSFSymbol,
        backgroundColor: UIColor,
        inset: Inset? = Inset(),
        size: CGSize = defaultSize,
        cornerRadius: CGFloat = defaultCornerRadius,
        traitCollection: UITraitCollection = .current
    ) -> UIImage? {
        generate(
            SettingsIcon(symbol: symbol, color: backgroundColor, inset: inset),
            size: size,
            cornerRadius: cornerRadius,
            traitCollection: traitCollection
        )
    }

    @MainActor
    public static func generate(
        image: UIImage?,
        backgroundColor: UIColor,
        inset: Inset? = nil,
        cacheIdentifier: String? = nil,
        size: CGSize = defaultSize,
        cornerRadius: CGFloat = defaultCornerRadius,
        traitCollection: UITraitCollection = .current
    ) -> UIImage? {
        generate(
            SettingsIcon(
                image: image,
                color: backgroundColor,
                inset: inset,
                cacheIdentifier: cacheIdentifier
            ),
            size: size,
            cornerRadius: cornerRadius,
            traitCollection: traitCollection
        )
    }

    @MainActor
    public static func removeAllCachedImages() {
        SettingsIcon.tileCache.removeAllObjects()
    }
}

private extension SettingsIcon {

    @MainActor
    func renderSettingsTileImage(
        size: CGSize,
        cornerRadius: CGFloat,
        traitCollection: UITraitCollection
    ) -> UIImage? {
        guard let glyph = generateImage() else { return nil }

        let resolvedColor = color.resolvedColor(with: traitCollection)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = max(traitCollection.displayScale, 1)
        format.opaque = false

        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            let rect = CGRect(origin: .zero, size: size)
            resolvedColor.setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).fill()

            glyph
                .withRenderingMode(.alwaysTemplate)
                .withTintColor(.white, renderingMode: .alwaysOriginal)
                .draw(in: glyphRect(for: glyph, in: rect))
        }
    }

    func glyphRect(for glyph: UIImage, in bounds: CGRect) -> CGRect {
        let maxGlyphSize = inset == nil
            ? bounds.size.applyingScale(0.7)
            : bounds.size
        let fittedSize = glyph.size.aspectFit(in: maxGlyphSize)
        let origin = CGPoint(
            x: bounds.midX - fittedSize.width / 2,
            y: bounds.midY - fittedSize.height / 2
        )

        return CGRect(origin: origin, size: fittedSize)
    }

    @MainActor
    func tileCacheKey(
        size: CGSize,
        cornerRadius: CGFloat,
        traitCollection: UITraitCollection
    ) -> NSString? {
        guard let image else { return nil }

        let glyphKey = cacheIdentifier ?? "image:\(ObjectIdentifier(image))"
        let colorKey = color.resolvedColor(with: traitCollection).rgbaCacheKey
        let scale = max(traitCollection.displayScale, 1)
        let insetValue = inset?.value ?? 0

        return [
            glyphKey,
            colorKey,
            size.width.cacheKeyComponent,
            size.height.cacheKeyComponent,
            cornerRadius.cacheKeyComponent,
            scale.cacheKeyComponent,
            insetValue.cacheKeyComponent,
            "\(traitCollection.userInterfaceStyle.rawValue)"
        ].joined(separator: "|") as NSString
    }
}

private extension CGSize {

    func applyingScale(_ scale: CGFloat) -> CGSize {
        CGSize(width: width * scale, height: height * scale)
    }

    func aspectFit(in boundingSize: CGSize) -> CGSize {
        guard width > 0,
              height > 0,
              boundingSize.width > 0,
              boundingSize.height > 0 else {
            return .zero
        }

        let scale = min(boundingSize.width / width, boundingSize.height / height)
        return CGSize(width: width * scale, height: height * scale)
    }
}

private extension UIImage {

    func padded(by insets: UIEdgeInsets, renderingMode: UIImage.RenderingMode? = nil) -> UIImage? {
        guard insets.top >= 0,
              insets.left >= 0,
              insets.bottom >= 0,
              insets.right >= 0 else {
            return nil
        }

        guard insets != .zero else {
            return renderingMode.map { withRenderingMode($0) } ?? self
        }

        let newSize = CGSize(
            width: size.width + insets.left + insets.right,
            height: size.height + insets.top + insets.bottom
        )

        guard newSize.width > 0, newSize.height > 0 else {
            return nil
        }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        format.opaque = false

        let paddedImage = UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(at: CGPoint(x: insets.left, y: insets.top))
        }

        return renderingMode.map { paddedImage.withRenderingMode($0) } ?? paddedImage
    }
}

private extension UIColor {

    var rgbaCacheKey: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return "\(hash)"
        }

        return [
            red.cacheKeyComponent,
            green.cacheKeyComponent,
            blue.cacheKeyComponent,
            alpha.cacheKeyComponent
        ].joined(separator: ",")
    }
}

private extension CGFloat {

    var cacheKeyComponent: String {
        String(format: "%.4f", Double(self))
    }
}
