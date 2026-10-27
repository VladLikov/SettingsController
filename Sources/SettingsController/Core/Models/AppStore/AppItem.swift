import Foundation

public struct AppItem: Sendable, Equatable {
    public let id: Int
    public let name: String
    public let iconURL: URL
    public let storeURL: URL

    public init(id: Int, name: String, iconURL: URL, storeURL: URL) {
        self.id = id
        self.name = name
        self.iconURL = iconURL
        self.storeURL = storeURL
    }
}
