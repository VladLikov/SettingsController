import Foundation

/// The light or dark appearance chosen when the app does not follow the system.
/// Raw values match the integers stored by SettingsController 4.x.
public enum InterfaceStyle: Int, CaseIterable, Sendable {
    case light = 1
    case dark = 2
}

/// Persists the appearance settings. The library writes these values; the host applies them.
public protocol ThemeStorage: AnyObject {
    /// The `rawValue` of the selected `AppColorType`.
    var appColorID: String { get set }
    /// When true, the system light or dark appearance is used and `interfaceStyle` is ignored.
    var followsSystemAppearance: Bool { get set }
    var interfaceStyle: InterfaceStyle { get set }
}
