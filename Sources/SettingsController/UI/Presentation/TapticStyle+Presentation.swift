import UIKit

extension TapticStyle {
    var title: String {
        switch self {
        case .light: NSLocalizedString("Light", bundle: .module, comment: "Light haptic feedback intensity option.")
        case .medium: NSLocalizedString("Medium", bundle: .module, comment: "Medium haptic feedback intensity option.")
        case .heavy: NSLocalizedString("Hard", bundle: .module, comment: "Strong haptic feedback intensity option.")
        }
    }

    var impactStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .light: .light
        case .medium: .medium
        case .heavy: .heavy
        }
    }
}

extension InterfaceStyle {
    var title: String {
        switch self {
        case .light: NSLocalizedString("Light Theme", bundle: .module, comment: "Option selecting light interface appearance.")
        case .dark: NSLocalizedString("Dark Theme", bundle: .module, comment: "Option selecting dark interface appearance.")
        }
    }
}
