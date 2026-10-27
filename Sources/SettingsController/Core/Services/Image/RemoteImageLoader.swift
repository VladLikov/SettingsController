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
    private struct Flight {
        let id: UUID
        let task: Task<UIImage, Error>
        var consumers: Set<UUID>
    }
    private var inFlightTasks: [String: Flight] = [:]
    var activeRequestCount: Int { inFlightTasks.count }
    var activeConsumerCount: Int { inFlightTasks.values.reduce(0) { $0 + $1.consumers.count } }

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

        let key = cacheKey as String
        let consumer = UUID()
        let flight: Flight
        if var existing = inFlightTasks[key] {
            existing.consumers.insert(consumer)
            inFlightTasks[key] = existing
            flight = existing
        } else {
            let task = Task<UIImage, Error> { [session] in
                try await Self.loadImage(from: url, session: session, pixelSize: pixelSize, scale: scale)
            }
            flight = Flight(id: UUID(), task: task, consumers: [consumer])
            inFlightTasks[key] = flight
        }
        return try await withTaskCancellationHandler {
            do {
                let image = try await flight.task.value
                // A cancelled old flight must never remove/cache over a newer one.
                if inFlightTasks[key]?.id == flight.id {
                    cache.setObject(image, forKey: cacheKey,
                                    cost: (image.cgImage?.bytesPerRow ?? 0) * (image.cgImage?.height ?? 0))
                    inFlightTasks[key] = nil
                }
                try Task.checkCancellation()
                return image
            } catch {
                if inFlightTasks[key]?.id == flight.id { inFlightTasks[key] = nil }
                if Task.isCancelled { throw CancellationError() }
                throw error
            }
        } onCancel: {
            Task { await self.release(key: key, flightID: flight.id, consumer: consumer) }
        }
    }

    private func release(key: String, flightID: UUID, consumer: UUID) {
        guard var flight = inFlightTasks[key], flight.id == flightID else { return }
        flight.consumers.remove(consumer)
        if flight.consumers.isEmpty {
            inFlightTasks[key] = nil
            flight.task.cancel()
        } else {
            inFlightTasks[key] = flight
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
        let product = maxPixelSize * scale
        guard product.isFinite else { return 1 }
        return Int(min(8192, max(1, product.rounded(.up))))
    }
}
