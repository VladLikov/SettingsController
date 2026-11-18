import UIKit

final class EmptyStateView: UIView {
    static var settingsImage: UIImage? { UIImage(systemName: "gearshape") }

    init(title: String, subtitle: String) {
        super.init(frame: .zero)
        backgroundColor = .systemGroupedBackground
        let icon = UIImageView(image: Self.settingsImage)
        icon.contentMode = .scaleAspectFit
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .largeTitle)
        icon.tintColor = .secondaryLabel
        icon.adjustsImageSizeForAccessibilityContentSizeCategory = true
        icon.isAccessibilityElement = false
        let header = UILabel()
        header.text = title
        header.font = .preferredFont(forTextStyle: .headline)
        header.textColor = .label
        header.accessibilityTraits.insert(.header)
        header.numberOfLines = 0
        header.adjustsFontForContentSizeCategory = true
        header.textAlignment = .center
        let footer = UILabel()
        footer.text = subtitle
        footer.font = .preferredFont(forTextStyle: .subheadline)
        footer.textColor = .secondaryLabel
        footer.numberOfLines = 0
        footer.adjustsFontForContentSizeCategory = true
        footer.textAlignment = .center
        let scroll = UIScrollView()
        scroll.alwaysBounceVertical = true
        // The viewport extends behind bars; native safe-area/column insets still
        // place its readable content, including on a non-scrolling horizontal axis.
        scroll.contentInsetAdjustmentBehavior = .always
        let content = UIView()
        let stack = UIStackView(arrangedSubviews: [icon, header, footer])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = UIStackView.spacingUseSystem
        for view in [scroll, content, stack] { view.translatesAutoresizingMaskIntoConstraints = false }
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
            icon.widthAnchor.constraint(lessThanOrEqualTo: stack.widthAnchor),
            header.widthAnchor.constraint(equalTo: stack.widthAnchor),
            footer.widthAnchor.constraint(equalTo: stack.widthAnchor),
            stack.topAnchor.constraint(greaterThanOrEqualTo: content.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: content.bottomAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: content.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
