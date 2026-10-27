//
//  SettingsCell.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import UIKit

// MARK: - SettingsCell

public final class SettingsCell: UITableViewCell {

    private enum Metrics {
        static let iconSize = CGSize(width: 30, height: 30)
        static let iconCornerRadius: CGFloat = 7.5
        static let imageToTextPadding: CGFloat = 15
        static let verticalPadding: CGFloat = 6
    }

    private var currentTitle: String?
    private var currentDetail: String?
    private var currentIcon: UIImage?
    private var iconDescription: SettingsIcon?

    // MARK: Properties [Public]

    public var title: String? {
        currentTitle
    }

    // MARK: Life Cycle

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        accessoryType = .disclosureIndicator
        selectionStyle = .default
        observeAppearance()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        observeAppearance()
    }

    public override func prepareForReuse() {
        super.prepareForReuse()

        resetContent()
    }
    private func observeAppearance() {
        if #available(iOS 17, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self, UITraitAccessibilityContrast.self, UITraitDisplayScale.self]) { (cell: SettingsCell, _: UITraitCollection) in
                cell.refreshIconForTraits()
            }
        }
    }

    @available(iOS, introduced: 8, deprecated: 17)
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #unavailable(iOS 17) { refreshIconForTraits() }
    }

    func refreshIconForTraits() {
        currentIcon = iconDescription?.generateSettingsImage(traitCollection: traitCollection)
        updateContentConfiguration()
    }

}

// MARK: - Configure

extension SettingsCell {

    public func configure(title: String?, icon: SettingsIcon?, detail: String? = nil) {
        resetContent()

        currentTitle = title
        currentDetail = detail
        iconDescription = icon
        currentIcon = icon?.generateSettingsImage(traitCollection: traitCollection)
        updateContentConfiguration()
    }

    private func updateContentConfiguration() {
        var configuration = currentDetail == nil
            ? defaultContentConfiguration()
            : UIListContentConfiguration.valueCell()

        configuration.text = currentTitle
        configuration.textProperties.color = .label
        configuration.textProperties.numberOfLines = 0
        configuration.textProperties.lineBreakMode = .byWordWrapping
        configuration.secondaryText = currentDetail
        configuration.secondaryTextProperties.color = .secondaryLabel
        configuration.secondaryTextProperties.numberOfLines = 0
        configuration.secondaryTextProperties.lineBreakMode = .byWordWrapping
        configuration.directionalLayoutMargins.top = Metrics.verticalPadding
        configuration.directionalLayoutMargins.bottom = Metrics.verticalPadding
        configuration.image = currentIcon
        configuration.imageProperties.maximumSize = Metrics.iconSize
        configuration.imageProperties.reservedLayoutSize = Metrics.iconSize
        configuration.imageProperties.cornerRadius = Metrics.iconCornerRadius
        configuration.imageToTextPadding = Metrics.imageToTextPadding
        contentConfiguration = configuration
    }

    private func resetContent() {
        currentTitle = nil
        currentDetail = nil
        currentIcon = nil
        iconDescription = nil

        accessoryType = .disclosureIndicator
        accessoryView = nil
        selectionStyle = .default
        backgroundConfiguration = nil
        contentConfiguration = nil

        imageView?.image = nil
        textLabel?.text = nil
        detailTextLabel?.text = nil
    }
}
