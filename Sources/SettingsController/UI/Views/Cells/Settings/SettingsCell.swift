//
//  SettingsCell.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import UIKit

// MARK: - SettingsCell

public final class SettingsCell: UITableViewCell {

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
            registerForTraitChanges([UITraitUserInterfaceStyle.self, UITraitAccessibilityContrast.self, UITraitDisplayScale.self]) {
                (cell: SettingsCell, _: UITraitCollection) in
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
        accessoryType = .disclosureIndicator
        accessoryView = nil
        selectionStyle = .default
        currentTitle = title
        currentDetail = detail
        iconDescription = icon
        currentIcon = icon?.generateSettingsImage(traitCollection: traitCollection)
        updateContentConfiguration()
    }

    private func updateContentConfiguration() {
        var configuration =
            currentDetail == nil
            ? defaultContentConfiguration()
            : UIListContentConfiguration.valueCell()

        configuration.text = currentTitle
        configuration.textProperties.color = .label
        configuration.secondaryText = currentDetail
        configuration.secondaryTextProperties.color = .secondaryLabel
        configuration.applySettingsRowLayout()
        configuration.applySettingsIcon(currentIcon)
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

    }
}
