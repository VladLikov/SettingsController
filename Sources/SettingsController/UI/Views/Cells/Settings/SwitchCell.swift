import UIKit

public class SwitchCell: SettingsCell {
    public let switchControl = UISwitch()
    private var onChange: ((Bool) -> Void)?

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        accessoryView = switchControl
        selectionStyle = .none
        onChange = nil
        switchControl.accessibilityLabel = nil
        switchControl.isOn = false
        switchControl.onTintColor = nil
    }

    public func configure(title: String?, icon: SettingsIcon? = nil, isOn: Bool,
                          onTintColor: UIColor?, onChange: ((Bool) -> Void)?) {
        super.configure(title: title, icon: icon, accessory: .none, selectionStyle: .none)
        accessoryView = switchControl
        switchControl.accessibilityLabel = title
        switchControl.isOn = isOn
        switchControl.onTintColor = onTintColor
        self.onChange = onChange
    }

    private func setupView() {
        selectionStyle = .none
        isAccessibilityElement = false
        accessibilityElements = [switchControl]
        accessoryView = switchControl
        switchControl.addTarget(self, action: #selector(handleSwitchChanged), for: .valueChanged)
    }

    @objc private func handleSwitchChanged() { onChange?(switchControl.isOn) }
}
