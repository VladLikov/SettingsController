import Foundation

/// User and purchase details supplied by the host app for support diagnostics.
public struct SettingsMailInfo: Sendable, Equatable {
    public let userID: String?
    public let productID: String?
    public let isPremium: Bool?

    public init(userID: String? = nil, productID: String? = nil, isPremium: Bool? = nil) {
        self.userID = userID
        self.productID = productID
        self.isPremium = isPremium
    }
}
