import SwiftUI
import UIKit

final class PremiumCell: UITableViewCell {
    private var host: UIHostingController<PremiumCard>?
    private weak var hostingParent: UIViewController?
    private var hostConstraints: [NSLayoutConstraint] = []

    private var payload: PremiumCardPayload?
    private var onTap: (() -> Void)?
    private var layout: PremiumCardLayout = .automatic
    private var usesLegacyHosting = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        if #available(iOS 17, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self, UITraitAccessibilityContrast.self]) {
                (cell: PremiumCell, _: UITraitCollection) in cell.applyCard()
            }
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @available(iOS, introduced: 8, deprecated: 17)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #unavailable(iOS 17),
            previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle
                || previousTraitCollection?.accessibilityContrast != traitCollection.accessibilityContrast
        {
            applyCard()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        detachHost(discard: true)
        hostingParent = nil
        payload = nil
        onTap = nil
        layout = .automatic
        contentConfiguration = nil
        backgroundConfiguration = nil
        accessoryType = .none
        accessoryView = nil
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil { detachHost(discard: false) } else if let parent = hostingParent { attachHost(to: parent) }
    }

    func configure(
        payload: PremiumCardPayload, parent: UIViewController,
        forceLegacyHosting: Bool = false, onTap: @escaping () -> Void
    ) {
        self.payload = payload
        self.onTap = onTap
        if #available(iOS 16, *), !forceLegacyHosting {
            usesLegacyHosting = false
            detachHost(discard: true)
            hostingParent = nil
            // Reuse the last measured arrangement; sizing corrects it if the width changed.
            layout = PremiumCardMeasurer.lastLayout(for: payload, traits: traitCollection) ?? .automatic
        } else {
            usesLegacyHosting = true
            hostingParent = parent
            layout = .automatic
        }
        applyCard()
    }

    /// Renders the card with the measured layout and a palette resolved from the cell's own traits.
    private func applyCard() {
        guard let payload, let onTap else { return }
        let palette = PremiumCardPalette.cached(color: payload.premium.color, traits: traitCollection)
        let card = PremiumCard(payload: payload, layout: layout, palette: palette, onTap: onTap)
        if #available(iOS 16, *), !usesLegacyHosting {
            contentConfiguration = UIHostingConfiguration { card }.margins(.all, 0)
        } else {
            contentConfiguration = nil
            guard let parent = hostingParent else { return }
            if let host { host.rootView = card } else { host = UIHostingController(rootView: card) }
            attachHost(to: parent)
            host?.view.invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        guard let payload else {
            return super.systemLayoutSizeFitting(
                targetSize, withHorizontalFittingPriority: horizontalFittingPriority,
                verticalFittingPriority: verticalFittingPriority)
        }
        let signpost = SettingsSignposts.signposter.beginInterval("PremiumCell sizing")
        defer { SettingsSignposts.signposter.endInterval("PremiumCell sizing", signpost) }
        PremiumCardSizingStatistics.recordCellSizing()
        let width = max(targetSize.width, 1)
        let resolution = PremiumCardMeasurer.resolve(payload, width: width, traits: traitCollection)
        if resolution.layout != layout {
            layout = resolution.layout
            applyCard()
        }
        return CGSize(width: width, height: resolution.height)
    }

    private func attachHost(to parent: UIViewController) {
        guard let host, host.parent !== parent else { return }
        detachHost(discard: false)
        parent.addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.backgroundColor = .clear
        contentView.addSubview(host.view)
        hostConstraints = [
            host.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ]
        NSLayoutConstraint.activate(hostConstraints)
        host.didMove(toParent: parent)
    }

    private func detachHost(discard: Bool) {
        guard let host else { return }
        if host.parent != nil { host.willMove(toParent: nil) }
        NSLayoutConstraint.deactivate(hostConstraints)
        hostConstraints.removeAll()
        host.view.removeFromSuperview()
        if host.parent != nil { host.removeFromParent() }
        if discard { self.host = nil }
    }
}
