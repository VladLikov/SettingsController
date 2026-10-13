import Foundation

public struct SettingsMailInfo: Sendable, Equatable {
    public let adaptyProfileID: String?
    public let productID: String?
    public let isPremium: Bool?

    public init(adaptyProfileID: String? = nil, productID: String? = nil, isPremium: Bool? = nil) {
        self.adaptyProfileID = adaptyProfileID
        self.productID = productID
        self.isPremium = isPremium
    }
}
