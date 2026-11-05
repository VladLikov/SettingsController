import AlertKit
import UIKit

/// The library's own haptic feedback. It is silent when the user turned the Taptic Engine setting off.
@MainActor
struct SettingsHaptics {
    /// The storage behind a `.tapticEngine` row, if the configuration has one.
    weak var storage: TapticStorage?

    var isEnabled: Bool { storage?.isTapticEngineEnabled ?? true }

    var alertHaptic: AlertHaptic { isEnabled ? .success : .none }

    func selectionChanged() {
        #if !os(visionOS)
        guard isEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }

    /// Plays a sample of the given strength, regardless of the stored style.
    func preview(_ style: TapticStyle) {
        #if !os(visionOS)
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: style.impactStyle).impactOccurred()
        #endif
    }

    static func from(_ sections: [SettingsSection]) -> SettingsHaptics {
        for section in sections {
            guard case .rows(let rows) = section.kind else { continue }
            for row in rows {
                if case .defaultRow(.tapticEngine(let storage)) = row { return SettingsHaptics(storage: storage) }
            }
        }
        return SettingsHaptics(storage: nil)
    }
}

extension AlertViewStyle {
    /// The one confirmation style used by the library's transient alerts.
    static var settingsConfirmation: AlertViewStyle { .iOS17AppleMusic }
}
