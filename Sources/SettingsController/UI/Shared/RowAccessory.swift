import UIKit

/// The trailing accessory of a settings row. Follows the HIG: a chevron only for rows that show a screen.
enum RowAccessory: Equatable {
    /// Shows a screen in the navigation stack or the detail column.
    case disclosure
    /// Leaves the app, for example to the App Store, a social app or system Settings.
    case external
    /// Presents a sheet or performs an action in place.
    case none

    func apply(to cell: UITableViewCell) {
        switch self {
        case .disclosure:
            cell.accessoryView = nil
            cell.accessoryType = .disclosureIndicator
        case .none:
            cell.accessoryView = nil
            cell.accessoryType = .none
        case .external:
            cell.accessoryType = .none
            let configuration = UIImage.SymbolConfiguration(textStyle: .footnote, scale: .medium)
                .applying(UIImage.SymbolConfiguration(weight: .semibold))
            let view = UIImageView(image: UIImage(systemName: "arrow.up.forward", withConfiguration: configuration))
            view.tintColor = .tertiaryLabel
            view.adjustsImageSizeForAccessibilityContentSizeCategory = true
            // Decorative: the row's own traits and title describe the action.
            view.isAccessibilityElement = false
            cell.accessoryView = view
        }
    }
}

extension DisplayRow {
    var accessory: RowAccessory {
        switch self {
        case .item(.row(let row)):
            return row.destination?.opensScreen == true ? .disclosure : .none
        case .item(.defaultRow(let row)):
            switch row {
            case .appearance, .tapticEngine, .about: return .disclosure
            case .user(_, _, let destination): return destination.opensScreen ? .disclosure : .none
            case .rateApp, .moreApps, .telegram, .vkGroup, .language: return .external
            case .shareApp, .redeemCode, .contactDeveloper, .premium: return .none
            }
        case .app(.loaded):
            return .external
        case .app(.placeholder), .app(.failed):
            return .none
        }
    }
}
