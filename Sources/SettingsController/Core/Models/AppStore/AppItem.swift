import Foundation

struct AppItem: Sendable, Equatable {
    let id: Int
    let name: String
    let iconURL: URL
    let storeURL: URL
}
