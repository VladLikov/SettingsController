import UIKit
import SwiftUI

final class PremiumCell: UITableViewCell {
    private var host: UIHostingController<PremiumCard>?
    private weak var hostingParent: UIViewController?
    private var hostConstraints: [NSLayoutConstraint] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func prepareForReuse() {
        super.prepareForReuse()
        detachHost(discard: true)
        hostingParent = nil
        contentConfiguration = nil
        backgroundConfiguration = nil
        accessoryType = .none
        accessoryView = nil
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil { detachHost(discard: false) }
        else if let parent = hostingParent { attachHost(to: parent) }
    }

    func configure(payload: PremiumCardPayload, parent: UIViewController,
                   forceLegacyHosting: Bool = false, onTap: @escaping () -> Void) {
        let card = PremiumCard(image: payload.image, title: payload.title, subtitle: payload.subtitle,
                               buttonTitle: payload.buttonTitle, color: payload.premium.color, onTap: onTap)
        if #available(iOS 16, *), !forceLegacyHosting {
            detachHost(discard: true)
            hostingParent = nil
            contentConfiguration = UIHostingConfiguration { card }.margins(.all, 0)
        } else {
            contentConfiguration = nil
            hostingParent = parent
            if let host { host.rootView = card }
            else { host = UIHostingController(rootView: card) }
            attachHost(to: parent)
            host?.view.invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    override func systemLayoutSizeFitting(_ targetSize: CGSize,
                                          withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
                                          verticalFittingPriority: UILayoutPriority) -> CGSize {
        guard let host else {
            return super.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority,
                                                  verticalFittingPriority: verticalFittingPriority)
        }
        let width = max(targetSize.width, 1)
        let fitted = host.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: ceil(fitted.height))
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
            host.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
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
