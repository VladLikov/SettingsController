import UIKit

class SwitchCell: UITableViewCell {

    private var valueChanged: ((Bool) -> Void)?

    lazy var switchControl: UISwitch = {
        let control = UISwitch()
        control.onTintColor = tintColor
        return control
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentConfiguration = nil
        valueChanged = nil
        switchControl.accessibilityLabel = nil
        switchControl.isOn = false
        switchControl.onTintColor = tintColor
    }

    func configure(
        title: String?, isOn: Bool, onTintColor: UIColor?,
        valueChanged: @escaping (Bool) -> Void
    ) {
        var configuration = defaultContentConfiguration()
        configuration.text = title
        configuration.applySettingsRowLayout()
        contentConfiguration = configuration
        switchControl.accessibilityLabel = title
        switchControl.isOn = isOn
        switchControl.onTintColor = onTintColor
        self.valueChanged = valueChanged
    }

    private func setupView() {
        selectionStyle = .none
        isAccessibilityElement = false
        accessibilityElements = [switchControl]
        accessoryView = switchControl
        switchControl.addTarget(self, action: #selector(switchValueChanged(_:)), for: .valueChanged)
    }

    @objc private func switchValueChanged(_ sender: UISwitch) { valueChanged?(sender.isOn) }
}
