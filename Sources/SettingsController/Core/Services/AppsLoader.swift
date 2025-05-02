//
//  AppItem.swift
//  SettingsController
//
//  Created by Влад Лыков on 29.04.2025.
//

import Foundation

public enum AppsLoader {
    
    public static func fetch(developerId: String, limit: Int) async throws -> [AppItem] {
        
        let url = URL(string:"https://itunes.apple.com/lookup?id=\(developerId)&entity=software")!
        let (data, _) = try await URLSession.shared.data(from: url)
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
