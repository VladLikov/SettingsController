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
            cell.accessoryView = (cell.accessoryView as? ExternalArrowView) ?? ExternalArrowView()
        }
    }
}

/// The external arrow accessory.
///
/// UIKit insets a bare `UIImageView` accessory about 5 pt further from the trailing edge than the
/// disclosure chevron, so the arrow sits inside a plain view, which UIKit places at the chevron's
/// trailing edge and vertical center.
final class ExternalArrowView: UIView {
    private let imageView: UIImageView = {
        let configuration = UIImage.SymbolConfiguration(textStyle: .footnote, scale: .medium)
            .applying(UIImage.SymbolConfiguration(weight: .semibold))
        let view = UIImageView(image: UIImage(systemName: "arrow.up.forward", withConfiguration: configuration))
        view.tintColor = .tertiaryLabel
        view.adjustsImageSizeForAccessibilityContentSizeCategory = true
        // The intrinsic size includes the symbol's baseline padding, so it is taller than the glyph;
        // drawing at the glyph's own size keeps the arrow from being stretched.
        view.contentMode = .center
        return view
    }()

    init() {
        super.init(frame: .zero)
        addSubview(imageView)
        // Decorative: the row's own traits and title describe the action.
        isAccessibilityElement = false
        resizeToImage()
        if #available(iOS 17, *) {
            registerForTraitChanges([UITraitPreferredContentSizeCategory.self, UITraitLegibilityWeight.self]) {
                (view: ExternalArrowView, _: UITraitCollection) in
                view.resizeToImage()
            }
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var intrinsicContentSize: CGSize { imageView.intrinsicContentSize }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
    }

    @available(iOS, introduced: 8, deprecated: 17)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #unavailable(iOS 17),
            previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory
                || previousTraitCollection?.legibilityWeight != traitCollection.legibilityWeight
        {
            resizeToImage()
        }
    }

    /// Text size changes the symbol's size; the cell lays the accessory out again at the new size.
    private func resizeToImage() {
        let size = imageView.intrinsicContentSize
        guard bounds.size != size else { return }
        bounds.size = size
        superview?.setNeedsLayout()
    }
}

extension DisplayRow {
    /// Settings actions show standard chevrons. Loaded Our Apps catalog entries show an external
    /// arrow; catalog placeholders and the retry row show none.
    var accessory: RowAccessory {
        switch self {
        case .item(.row(let row)):
            return row.destination == nil ? .none : .disclosure
        case .item:
            return .disclosure
        case .app(.loaded):
            return .external
        case .app(.placeholder), .app(.failed):
            return .none
        }
    }
}
