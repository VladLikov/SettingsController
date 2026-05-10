//
//  SwitchCell.swift
//  SettingsController
//
//  Created by Влад Лыков on 06.10.2024.
//

import UIKit

public class SwitchCell: UITableViewCell {

    private enum Metrics {
        static let verticalPadding: CGFloat = 6
    }

    private var valueChanged: ((Bool) -> Void)?

    public lazy var switchControl: UISwitch = {
        let switchControl = UISwitch()
        switchControl.onTintColor = tintColor
        return switchControl
    }()
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public override func prepareForReuse() {
        super.prepareForReuse()

        contentConfiguration = nil
        valueChanged = nil
        switchControl.isOn = false
        switchControl.onTintColor = tintColor
    }

    public func configure(
        title: String?,
        isOn: Bool,
        onTintColor: UIColor?,
        valueChanged: @escaping (Bool) -> Void
    ) {
        var configuration = defaultContentConfiguration()
        configuration.text = title
        configuration.textProperties.numberOfLines = 0
        configuration.textProperties.lineBreakMode = .byWordWrapping
        configuration.directionalLayoutMargins.top = Metrics.verticalPadding
        configuration.directionalLayoutMargins.bottom = Metrics.verticalPadding
        contentConfiguration = configuration

        switchControl.isOn = isOn
        switchControl.onTintColor = onTintColor
        self.valueChanged = valueChanged
    }

    private func setupView() {
        selectionStyle = .none
        accessoryView = switchControl
        switchControl.addTarget(self, action: #selector(switchValueChanged(_:)), for: .valueChanged)
    }

    @objc
    private func switchValueChanged(_ sender: UISwitch) {
        valueChanged?(sender.isOn)
    }
}
