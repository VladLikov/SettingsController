import Foundation
import CheckUpdate

struct AppUpdate: Sendable, Equatable {
    let version: String
    let minimumOSVersion: String
    let url: URL
}

enum AppUpdateLookup {
    static func fetch(_ appID: String) async throws -> AppUpdate? {
        guard let result = try await CheckUpdate().getLatestAvailableVersion(for: appID) else { return nil }
        return AppUpdate(version: result.version, minimumOSVersion: result.minimumOsVersion, url: result.upgradeURL)
    }

    static func compare(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let left = lhs.split(separator: ".", omittingEmptySubsequences: false)
        let right = rhs.split(separator: ".", omittingEmptySubsequences: false)
        let a = left.compactMap { Int($0) }, b = right.compactMap { Int($0) }
        guard a.count == left.count, b.count == right.count, !a.isEmpty, !b.isEmpty else {
            return lhs.compare(rhs, options: .numeric)
        }
        for index in 0..<max(a.count, b.count) {
            let x = index < a.count ? a[index] : 0, y = index < b.count ? b[index] : 0
            if x != y { return x < y ? .orderedAscending : .orderedDescending }
        }
        return .orderedSame
    }
}
