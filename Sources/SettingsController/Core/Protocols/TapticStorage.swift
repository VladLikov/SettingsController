import Foundation

/// The strength of haptic feedback. Raw values match the integers stored by SettingsController 4.x.
public enum TapticStyle: Int, CaseIterable, Sendable {
    case light = 0
    case medium = 1
    case heavy = 2
}

/// Persists the haptic feedback settings. The library also honors `isTapticEngineEnabled` for its own feedback.
public protocol TapticStorage: AnyObject {
    var isTapticEngineEnabled: Bool { get set }
    var tapticStyle: TapticStyle { get set }
}
