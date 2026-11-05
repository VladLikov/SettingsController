import UIKit

/// Accent color and light or dark appearance. The host applies the stored values in its event handler.
final class AppearanceController: UITableViewController {

    var onColorChange: ((UIColor) -> Void)?
    var haptics = SettingsHaptics(storage: nil)

    private let colors: [any AppColorType]
    private let theme: ThemeStorage
    private weak var eventHandler: (any SettingsControllerEventHandler)?

    // The table renders this local copy, so a storage that ignores a write cannot desynchronize sections.
    private var selectedColorID: String
    private var followsSystemAppearance: Bool
    private var interfaceStyle: InterfaceStyle

    private enum Section: Int {
        case colors, automatic, style
    }

    init(themeStorage: ThemeStorage, colors: [any AppColorType], eventHandler: (any SettingsControllerEventHandler)?) {
        theme = themeStorage
        self.colors = colors
        self.eventHandler = eventHandler
        selectedColorID = themeStorage.appColorID
        followsSystemAppearance = themeStorage.followsSystemAppearance
        interfaceStyle = themeStorage.interfaceStyle
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = SettingsMetrics.estimatedRowHeight
        tableView.register(SwitchCell.self)
        tableView.register(ColorCell.self)
        tableView.register(UITableViewCell.self)
        navigationItem.largeTitleDisplayMode = .never
    }

    private var selectedColor: UIColor? {
        colors.first { $0.rawValue == selectedColorID }?.color
    }
}

// MARK: - UITableViewDataSource

extension AppearanceController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        followsSystemAppearance ? 2 : 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .colors: colors.count
        case .automatic: 1
        case .style: InterfaceStyle.allCases.count
        case nil: 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section) {
        case .colors:
            NSLocalizedString("App color", bundle: .module, comment: "Appearance section heading for selecting the app accent color.")
        case .automatic:
            NSLocalizedString(
                "Light & Dark theme", bundle: .module, comment: "Appearance section heading for light and dark interface mode.")
        case .style, nil:
            nil
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard Section(rawValue: section) == .automatic else { return nil }
        return NSLocalizedString(
            "When the switch is on, the system appearance is used.", bundle: .module,
            comment: "Footer explaining the automatic system appearance switch.")
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section) {
        case .colors:
            let cell = tableView.dequeueReusableCell(withClass: ColorCell.self, for: indexPath)
            let appColor = colors[indexPath.row]
            cell.configure(appColor: appColor)
            cell.accessoryType = selectedColorID == appColor.rawValue ? .checkmark : .none
            return cell

        case .automatic:
            let cell = tableView.dequeueReusableCell(withClass: SwitchCell.self, for: indexPath)
            cell.configure(
                title: NSLocalizedString(
                    "Automatically", bundle: .module, comment: "Switch label for following the system light or dark appearance."),
                isOn: followsSystemAppearance,
                onTintColor: selectedColor
            ) { [weak self] isOn in
                self?.setFollowsSystemAppearance(isOn)
            }
            return cell

        case .style:
            let cell = tableView.dequeueReusableCell(withClass: UITableViewCell.self, for: indexPath)
            let style = InterfaceStyle.allCases[indexPath.row]
            var configuration = cell.defaultContentConfiguration()
            configuration.text = style.title
            configuration.applySettingsRowLayout()
            cell.contentConfiguration = configuration
            cell.selectionStyle = .none
            cell.accessoryType = style == interfaceStyle ? .checkmark : .none
            cell.tintColor = view.tintColor
            return cell

        case nil:
            preconditionFailure("Unexpected appearance settings indexPath: \(indexPath)")
        }
    }
}

// MARK: - UITableViewDelegate

extension AppearanceController {

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch Section(rawValue: indexPath.section) {
        case .colors:
            selectColor(at: indexPath)
        case .style:
            selectInterfaceStyle(InterfaceStyle.allCases[indexPath.row], at: indexPath)
        case .automatic, nil:
            break
        }
    }

    private func selectColor(at indexPath: IndexPath) {
        guard colors.indices.contains(indexPath.row) else { return }
        let appColor = colors[indexPath.row]
        if let old = colors.firstIndex(where: { $0.rawValue == selectedColorID }) {
            tableView.cellForRow(at: IndexPath(row: old, section: Section.colors.rawValue))?.accessoryType = .none
        }
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        selectedColorID = appColor.rawValue
        theme.appColorID = appColor.rawValue
        eventHandler?.settingsDidSelectAppColor(appColor)
        eventHandler?.settingsDidUpdateTheme(theme)
        onColorChange?(appColor.color)
        applyTint(appColor.color)
        haptics.selectionChanged()
    }

    private func selectInterfaceStyle(_ style: InterfaceStyle, at indexPath: IndexPath) {
        guard style != interfaceStyle else { return }
        if let old = InterfaceStyle.allCases.firstIndex(of: interfaceStyle) {
            tableView.cellForRow(at: IndexPath(row: old, section: Section.style.rawValue))?.accessoryType = .none
        }
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        interfaceStyle = style
        theme.interfaceStyle = style
        eventHandler?.settingsDidUpdateTheme(theme)
        haptics.selectionChanged()
    }

    private func setFollowsSystemAppearance(_ isOn: Bool) {
        guard isOn != followsSystemAppearance else { return }
        followsSystemAppearance = isOn
        theme.followsSystemAppearance = isOn
        eventHandler?.settingsDidUpdateTheme(theme)
        let sections = IndexSet(integer: Section.style.rawValue)
        if isOn {
            tableView.deleteSections(sections, with: .fade)
        } else {
            tableView.insertSections(sections, with: .fade)
        }
    }

    /// Cross-fades the navigation bar, switch and checkmarks to the new accent color.
    private func applyTint(_ color: UIColor) {
        let switchCell = tableView.cellForRow(at: IndexPath(row: 0, section: Section.automatic.rawValue)) as? SwitchCell
        let styleCells =
            followsSystemAppearance
            ? []
            : InterfaceStyle.allCases.indices.compactMap { tableView.cellForRow(at: IndexPath(row: $0, section: Section.style.rawValue)) }
        let changes = { [navigationController] in
            navigationController?.navigationBar.tintColor = color
            switchCell?.switchControl.onTintColor = color
            for cell in styleCells { cell.tintColor = color }
        }
        if UIAccessibility.isReduceMotionEnabled {
            changes()
        } else {
            UIView.animate(withDuration: 0.25, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction], animations: changes)
        }
    }
}
