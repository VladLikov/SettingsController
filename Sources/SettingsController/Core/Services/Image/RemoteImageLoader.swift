//
//  RemoteImageLoader.swift
//  SettingsController
//
//  Created by Влад Лыков on 05.05.2026.
//

import Foundation
import ImageIO
import UIKit

actor RemoteImageLoader {

    static let shared = RemoteImageLoader()

    private let cache = NSCache<NSString, UIImage>()
    private let session: URLSession
    private let flights = InFlightDeduplicator<String, UIImage>()
    var activeRequestCount: Int { get async { await flights.activeRequestCount } }
    var activeConsumerCount: Int { get async { await flights.activeConsumerCount } }

    init(session: URLSession = .shared) {
        self.session = session
        cache.countLimit = 200
        cache.totalCostLimit = 16 * 1024 * 1024
    }

    func image(from url: URL, maxPixelSize: CGFloat, scale: CGFloat) async throws -> UIImage {
        try Task.checkCancellation()
        let scale = scale.isFinite && scale > 0 ? scale : 1
        let pixelSize = Self.pixelSize(maxPixelSize: maxPixelSize, scale: scale)
        let cacheKey = "\(url.absoluteString)#\(pixelSize)@\(scale)" as NSString

        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }

        let result = try await flights.value(for: cacheKey as String) { [session] in
            try await Self.loadImage(from: url, session: session, pixelSize: pixelSize, scale: scale)
        }
        // Only the caller that completed the current flight publishes it; a cancelled old flight never does.
        if result.completedFlight {
            let image = result.value
            cache.setObject(image, forKey: cacheKey, cost: (image.cgImage?.bytesPerRow ?? 0) * (image.cgImage?.height ?? 0))
        }
        return result.value
    }

    private static func loadImage(
        from url: URL,
        session: URLSession,
        pixelSize: Int,
        scale: CGFloat
    ) async throws -> UIImage {
        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        request.timeoutInterval = 15

        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()

        if let httpResponse = response as? HTTPURLResponse,
            !(200...299).contains(httpResponse.statusCode)
        {
            throw URLError(.badServerResponse)
        }

        guard let image = Self.downsample(data: data, pixelSize: pixelSize, scale: scale) else {
            throw URLError(.cannotDecodeContentData)
        }

        return image
    }

    private static func downsample(data: Data, pixelSize: Int, scale: CGFloat) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else {
            return nil
        }

        let thumbnailOptions =
            [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: pixelSize,
            ] as CFDictionary

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else {
            return nil
        }

        return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
    }

    private static func pixelSize(maxPixelSize: CGFloat, scale: CGFloat) -> Int {
        guard maxPixelSize.isFinite, scale.isFinite else { return 1 }
        let product = maxPixelSize * scale
        guard product.isFinite else { return 1 }
        return Int(min(8192, max(1, product.rounded(.up))))
    }
}
