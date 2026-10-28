//
//  AppStoreAppsLoader.swift
//  SettingsController
//
//  Created by Влад Лыков on 29.04.2025.
//

import Foundation

public enum AppStoreAppsLoader {

    public static func fetch(developerId: String, limit: Int, excludeAppID: String? = nil) async throws -> [AppItem] {
        try await fetch(developerId: developerId, limit: limit, excludeAppID: excludeAppID, session: .shared)
    }

    static func fetch(developerId: String, limit: Int, excludeAppID: String? = nil,
                      session: URLSession) async throws -> [AppItem] {
        guard limit > 0 else { return [] }
        try Task.checkCancellation()

        var components = URLComponents(string: "https://itunes.apple.com/lookup")
        components?.queryItems = [
            URLQueryItem(name: "id", value: developerId),
            URLQueryItem(name: "entity", value: "software")
        ]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .useProtocolCachePolicy
        request.timeoutInterval = 15

        let data = try await CatalogRequestLoader.shared.data(for: request, session: session)
        try Task.checkCancellation()

        let raw = try JSONDecoder().decode(LookupResponse.self, from: data)

        var apps: [AppItem] = []
        apps.reserveCapacity(min(limit, raw.results.count))
        for row in raw.results {
            guard row.kind == "software", let id = row.trackId, id > 0,
                  excludeAppID == nil || String(id) != excludeAppID,
                  let name = row.trackName, !name.isEmpty,
                  let icon = row.artworkUrl100, let link = row.trackViewUrl,
                  let iconURL = URL(string: icon), let storeURL = URL(string: link),
                  ["https", "http"].contains(iconURL.scheme?.lowercased() ?? ""),
                  ["https", "http"].contains(storeURL.scheme?.lowercased() ?? ""),
                  iconURL.host != nil, storeURL.host != nil else { continue }
            apps.append(AppItem(id: id, name: name, iconURL: iconURL, storeURL: storeURL))
            if apps.count == limit { break }
        }
        return apps
    }
}

private struct LookupResponse: Decodable {
    let results: [Raw]
    struct Raw: Decodable {
        let kind: String?
        let trackId: Int?
        let trackName: String?
        let artworkUrl100: String?
        let trackViewUrl: String?
    }
}

// Shares only requests currently in flight. No TTL or stale response cache is added.
actor CatalogRequestLoader {
    static let shared = CatalogRequestLoader()
    private struct Key: Hashable { let session: ObjectIdentifier; let url: URL }
    private struct Flight {
        let id: UUID
        let task: Task<Data, Error>
        var consumers: Set<UUID>
    }
    private var flights: [Key: Flight] = [:]
    var activeConsumerCount: Int { flights.values.reduce(0) { $0 + $1.consumers.count } }

    func data(for request: URLRequest, session: URLSession) async throws -> Data {
        try Task.checkCancellation()
        guard let url = request.url else { throw URLError(.badURL) }
        let key = Key(session: ObjectIdentifier(session), url: url)
        let consumer = UUID()
        let flight: Flight
        if var existing = flights[key] {
            existing.consumers.insert(consumer)
            flights[key] = existing
            flight = existing
        } else {
            let task = Task {
                let (data, response) = try await session.data(for: request)
                try Task.checkCancellation()
                if let response = response as? HTTPURLResponse, !(200...299).contains(response.statusCode) {
                    throw URLError(.badServerResponse)
                }
                return data
            }
            flight = Flight(id: UUID(), task: task, consumers: [consumer])
            flights[key] = flight
        }
        return try await withTaskCancellationHandler {
            do {
                let data = try await flight.task.value
                if flights[key]?.id == flight.id { flights[key] = nil }
                try Task.checkCancellation()
                return data
            } catch {
                if flights[key]?.id == flight.id { flights[key] = nil }
                if Task.isCancelled { throw CancellationError() }
                throw error
            }
        } onCancel: {
            Task { await self.release(key, flightID: flight.id, consumer: consumer) }
        }
    }

    private func release(_ key: Key, flightID: UUID, consumer: UUID) {
        guard var flight = flights[key], flight.id == flightID else { return }
        flight.consumers.remove(consumer)
        if flight.consumers.isEmpty {
            flights[key] = nil
            flight.task.cancel()
        } else { flights[key] = flight }
    }
}
