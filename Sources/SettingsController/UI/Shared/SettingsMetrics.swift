import UIKit

/// Shared geometry of settings rows, so every screen lines up with the main list.
enum SettingsMetrics {
    static let iconSize = CGSize(width: 30, height: 30)
    static let iconCornerRadius: CGFloat = 7.5
    static let imageToTextPadding: CGFloat = 15
    static let verticalPadding: CGFloat = 6
    /// Aligns separators with the row text after a 30 pt icon.
    static let separatorInset: CGFloat = 63

    static var estimatedRowHeight: CGFloat {
        if #available(iOS 26, *) { 53 } else { 45 }
    }

    static var estimatedUserRowHeight: CGFloat {
        if #available(iOS 26, *) { 73 } else { 65 }
    }
}

extension UIListContentConfiguration {
    /// Wrapping text and the shared vertical margins of a settings row.
    mutating func applySettingsRowLayout() {
        textProperties.numberOfLines = 0
        textProperties.lineBreakMode = .byWordWrapping
        secondaryTextProperties.numberOfLines = 0
        secondaryTextProperties.lineBreakMode = .byWordWrapping
        directionalLayoutMargins.top = SettingsMetrics.verticalPadding
        directionalLayoutMargins.bottom = SettingsMetrics.verticalPadding
    }

    /// A 30 pt leading image. Pass a nil corner radius for images that are already shaped, such as swatches.
    mutating func applySettingsIcon(_ icon: UIImage?, cornerRadius: CGFloat? = SettingsMetrics.iconCornerRadius) {
        image = icon
        imageProperties.maximumSize = SettingsMetrics.iconSize
        imageProperties.reservedLayoutSize = SettingsMetrics.iconSize
        if let cornerRadius { imageProperties.cornerRadius = cornerRadius }
        imageToTextPadding = SettingsMetrics.imageToTextPadding
    }
}
