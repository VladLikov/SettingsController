import UIKit

final class EmptyStateView: UIView {
    init(title: String?, subtitle: String?) {
        super.init(frame: .zero)
        backgroundColor = .systemGroupedBackground
        let header = UILabel()
        header.text = title
        header.font = .preferredFont(forTextStyle: .largeTitle)
        header.accessibilityTraits.insert(.header)
        let footer = UILabel()
        footer.text = subtitle
        footer.font = .preferredFont(forTextStyle: .body)
        for label in [header, footer] {
            label.numberOfLines = 0
            label.adjustsFontForContentSizeCategory = true
            label.textAlignment = .center
            label.textColor = .secondaryLabel
        }
        let scroll = UIScrollView()
        // The viewport extends behind bars; native safe-area/column insets still
        // place its readable content, including on a non-scrolling horizontal axis.
        scroll.contentInsetAdjustmentBehavior = .always
        let content = UIView()
        let stack = UIStackView(arrangedSubviews: [header, footer])
        stack.axis = .vertical
        stack.spacing = 12
        [scroll, content, stack].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        addSubview(scroll)
        scroll.addSubview(content)
        content.addSubview(stack)
        let preferredHeight = content.heightAnchor.constraint(equalTo: safeAreaLayoutGuide.heightAnchor)
        preferredHeight.priority = .defaultLow
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: trailingAnchor),
            scroll.topAnchor.constraint(equalTo: topAnchor),
            scroll.bottomAnchor.constraint(equalTo: bottomAnchor),
            content.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            content.widthAnchor.constraint(equalTo: safeAreaLayoutGuide.widthAnchor),
            content.heightAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.heightAnchor),
            preferredHeight,
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(greaterThanOrEqualTo: content.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: content.bottomAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: content.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
