import Foundation

public struct SettingsInsets {
    public let top: CGFloat?
    public let bottom: CGFloat?

    public init(top: CGFloat? = nil, bottom: CGFloat? = nil) {
        self.top = top
        self.bottom = bottom
    }
}
