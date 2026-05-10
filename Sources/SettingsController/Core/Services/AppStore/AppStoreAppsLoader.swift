//
//  AppStoreAppsLoader.swift
//  SettingsController
//
//  Created by Влад Лыков on 29.04.2025.
//

import Foundation

public enum AppStoreAppsLoader {

    public static func fetch(developerId: String, limit: Int, excludeAppID: String? = nil) async throws -> [AppItem] {
        guard limit > 0 else { return [] }

        var components = URLComponents(string: "https://itunes.apple.com/lookup")
        components?.queryItems = [
            URLQueryItem(name: "id", value: developerId),
            URLQueryItem(name: "entity", value: "software")
        ]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw URLError(.badServerResponse)
        }

        let raw = try JSONDecoder().decode(LookupResponse.self, from: data)

        return raw.results
            .filter { $0.kind == "software" }
            .compactMap {
                guard let id = $0.trackId,
                      let name = $0.trackName,
                      let icon = $0.artworkUrl100,
                      let link = $0.trackViewUrl,
                      let iconURL = URL(string: icon),
                      let storeURL = URL(string: link)
                else { return nil }
                return AppItem(id: id, name: name, iconURL: iconURL, storeURL: storeURL)
            }
            .filter { excludeAppID == nil || String($0.id) != excludeAppID }
            .prefix(limit)
            .map { $0 }
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
