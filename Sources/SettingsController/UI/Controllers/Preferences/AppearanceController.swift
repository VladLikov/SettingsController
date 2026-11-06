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

    enum Section: Hashable, Sendable {
        case colors, automatic, style
    }

    enum Item: Hashable, Sendable {
        case color(String)
        case automatic
        case style(InterfaceStyle)
    }

    private(set) var dataSource: TitledDataSource<Section, Item>?

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
        installDataSource()
    }

    private var selectedColor: UIColor? {
        colors.first { $0.rawValue == selectedColorID }?.color
    }
}

// MARK: - Data source

extension AppearanceController {

    private func installDataSource() {
        let dataSource = TitledDataSource<Section, Item>(tableView: tableView) { [unowned self] tableView, indexPath, item in
            cell(for: item, in: tableView, at: indexPath)
        }
        dataSource.defaultRowAnimation = .automatic
        dataSource.header = { section in
            switch section {
            case .colors:
                NSLocalizedString("App color", bundle: .module, comment: "Appearance section heading for selecting the app accent color.")
            case .automatic:
                NSLocalizedString(
                    "Light & Dark theme", bundle: .module, comment: "Appearance section heading for light and dark interface mode.")
            case .style:
                nil
            }
        }
        dataSource.footer = { section in
            guard section == .automatic else { return nil }
            return NSLocalizedString(
                "When the switch is on, the system appearance is used.", bundle: .module,
                comment: "Footer explaining the automatic system appearance switch.")
        }
        self.dataSource = dataSource
        tableView.dataSource = dataSource
        UIView.performWithoutAnimation { dataSource.apply(makeSnapshot(), animatingDifferences: false) }
    }

    private func makeSnapshot() -> NSDiffableDataSourceSnapshot<Section, Item> {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.colors, .automatic])
        snapshot.appendItems(colors.map { .color($0.rawValue) }, toSection: .colors)
        snapshot.appendItems([.automatic], toSection: .automatic)
        if !followsSystemAppearance {
            snapshot.appendSections([.style])
            snapshot.appendItems(InterfaceStyle.allCases.map { .style($0) }, toSection: .style)
        }
        return snapshot
    }

    private func cell(for item: Item, in tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        switch item {
        case .color(let id):
            let cell = tableView.dequeueReusableCell(withClass: ColorCell.self, for: indexPath)
            if let appColor = colors.first(where: { $0.rawValue == id }) { cell.configure(appColor: appColor) }
            cell.accessoryType = selectedColorID == id ? .checkmark : .none
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

        case .style(let style):
            let cell = tableView.dequeueReusableCell(withClass: UITableViewCell.self, for: indexPath)
            var configuration = cell.defaultContentConfiguration()
            configuration.text = style.title
            configuration.applySettingsRowLayout()
            cell.contentConfiguration = configuration
            cell.selectionStyle = .none
            cell.accessoryType = style == interfaceStyle ? .checkmark : .none
            cell.tintColor = selectedColor ?? view.tintColor
            return cell
        }
    }
}

// MARK: - UITableViewDelegate

extension AppearanceController {

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch dataSource?.itemIdentifier(for: indexPath) {
        case .color(let id):
            selectColor(id)
        case .style(let style):
            selectInterfaceStyle(style)
        case .automatic, nil:
            break
        }
    }

    private func selectColor(_ id: String) {
        guard let appColor = colors.first(where: { $0.rawValue == id }) else { return }
        let previous = selectedColorID
        selectedColorID = id
        theme.appColorID = id
        eventHandler?.settingsDidSelectAppColor(appColor)
        eventHandler?.settingsDidUpdateTheme(theme)
        onColorChange?(appColor.color)
        navigationController?.navigationBar.tintColor = appColor.color
        // Checkmarks, the switch tint and the style checkmarks follow the new accent.
        dataSource?.reconfigure([.color(previous), .color(id), .automatic] + InterfaceStyle.allCases.map { .style($0) })
        haptics.selectionChanged()
    }

    private func selectInterfaceStyle(_ style: InterfaceStyle) {
        guard style != interfaceStyle else { return }
        let previous = interfaceStyle
        interfaceStyle = style
        theme.interfaceStyle = style
        eventHandler?.settingsDidUpdateTheme(theme)
        dataSource?.reconfigure([.style(previous), .style(style)])
        haptics.selectionChanged()
    }

    private func setFollowsSystemAppearance(_ isOn: Bool) {
        guard isOn != followsSystemAppearance else { return }
        followsSystemAppearance = isOn
        theme.followsSystemAppearance = isOn
        eventHandler?.settingsDidUpdateTheme(theme)
        dataSource?.apply(makeSnapshot(), animatingDifferences: tableView.window != nil)
    }
}
