import Foundation

public struct SettingsMailInfo: Sendable, Equatable {
    /// Kept for source compatibility only. Never included in support emails.
    @available(*, deprecated, message: "Adapty Profile ID is not used in emails. Pass User ID separately.")
    public let adaptyProfileID: String?
    public let productID: String?
    public let isPremium: Bool?

    /// Preferred initializer for new integrations.
    public init(productID: String? = nil, isPremium: Bool? = nil) {
        self.adaptyProfileID = nil
        self.productID = productID
        self.isPremium = isPremium
    }

    /// Preserves existing integrations; the profile ID is ignored by email diagnostics.
    @available(*, deprecated, message: "Use init(productID:isPremium:) and supply User ID separately.")
    public init(adaptyProfileID: String?, productID: String? = nil, isPremium: Bool? = nil) {
        self.adaptyProfileID = adaptyProfileID
        self.productID = productID
        self.isPremium = isPremium
    }
}
