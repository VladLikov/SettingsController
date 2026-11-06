import UIKit

/// The trailing accessory of a settings row.
enum RowAccessory: Equatable {
    /// The standard chevron of an actionable row.
    case disclosure
    /// Leaves the app for an external page.
    case external
    /// Not actionable.
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
    /// Every actionable row shows a chevron, as in system Settings; More Apps, which leaves for the
    /// developer's App Store page, shows an arrow. Catalog placeholders and the retry row show none.
    var accessory: RowAccessory {
        switch self {
        case .item(.defaultRow(.moreApps)):
            return .external
        case .item(.row(let row)):
            return row.destination == nil ? .none : .disclosure
        case .item:
            return .disclosure
        case .app(.loaded):
            return .disclosure
        case .app(.placeholder), .app(.failed):
            return .none
        }
    }
}
