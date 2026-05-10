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
    private var inFlightTasks: [NSString: Task<UIImage, Error>] = [:]

    init(session: URLSession = .shared) {
        self.session = session
        cache.countLimit = 200
    }

    func image(from url: URL, maxPixelSize: CGFloat, scale: CGFloat) async throws -> UIImage {
        let pixelSize = Self.pixelSize(maxPixelSize: maxPixelSize, scale: scale)
        let cacheKey = "\(url.absoluteString)#\(pixelSize)" as NSString

        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }

        if let task = inFlightTasks[cacheKey] {
            return try await task.value
        }

        let task = Task<UIImage, Error> { [session] in
            let image = try await Self.loadImage(
                from: url,
                session: session,
                pixelSize: pixelSize,
                scale: scale
            )
            try Task.checkCancellation()
            return image
        }

        inFlightTasks[cacheKey] = task

        do {
            let image = try await task.value
            cache.setObject(image, forKey: cacheKey)
            inFlightTasks[cacheKey] = nil
            return image
        } catch {
            inFlightTasks[cacheKey] = nil
            throw error
        }
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
           !(200...299).contains(httpResponse.statusCode) {
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

        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: pixelSize
        ] as CFDictionary

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else {
            return nil
        }

        return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
    }

    private static func pixelSize(maxPixelSize: CGFloat, scale: CGFloat) -> Int {
        guard maxPixelSize.isFinite, scale.isFinite else { return 1 }
        return max(1, Int((maxPixelSize * scale).rounded(.up)))
    }
}
