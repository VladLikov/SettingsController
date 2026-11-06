import UIKit

/// Turns haptic feedback on or off and chooses its strength; selecting a strength plays a sample.
final class TapticEngineController: UITableViewController {

    private let taptic: TapticStorage
    private weak var eventHandler: (any SettingsControllerEventHandler)?

    // The table renders this local copy, so a storage that ignores a write cannot desynchronize sections.
    private var isEnabled: Bool
    private var style: TapticStyle

    enum Section: Hashable, Sendable {
        case toggle, styles
    }

    enum Item: Hashable, Sendable {
        case toggle
        case style(TapticStyle)
    }

    private(set) var dataSource: TitledDataSource<Section, Item>?

    init(tapticStorage: TapticStorage, eventHandler: (any SettingsControllerEventHandler)?) {
        taptic = tapticStorage
        self.eventHandler = eventHandler
        isEnabled = tapticStorage.isTapticEngineEnabled
        style = tapticStorage.tapticStyle
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(SwitchCell.self)
        tableView.register(UITableViewCell.self)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = SettingsMetrics.estimatedRowHeight
        navigationItem.largeTitleDisplayMode = .never
        installDataSource()
    }
}

// MARK: - Data source

extension TapticEngineController {

    private func installDataSource() {
        let dataSource = TitledDataSource<Section, Item>(tableView: tableView) { [unowned self] tableView, indexPath, item in
            cell(for: item, in: tableView, at: indexPath)
        }
        dataSource.defaultRowAnimation = .automatic
        dataSource.header = { section in
            guard section == .styles else { return nil }
            return NSLocalizedString("Taptic Force", bundle: .module, comment: "Section heading for haptic feedback intensity.")
        }
        dataSource.footer = { section in
            guard section == .toggle else { return nil }
            return NSLocalizedString(
                "Adds taptic feedback to various actions in the app.", bundle: .module,
                comment: "Footer explaining the haptic feedback switch.")
        }
        self.dataSource = dataSource
        tableView.dataSource = dataSource
        UIView.performWithoutAnimation { dataSource.apply(makeSnapshot(), animatingDifferences: false) }
    }

    private func makeSnapshot() -> NSDiffableDataSourceSnapshot<Section, Item> {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.toggle])
        snapshot.appendItems([.toggle], toSection: .toggle)
        if isEnabled {
            snapshot.appendSections([.styles])
            snapshot.appendItems(TapticStyle.allCases.map { .style($0) }, toSection: .styles)
        }
        return snapshot
    }

    private func cell(for item: Item, in tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        switch item {
        case .toggle:
            let cell = tableView.dequeueReusableCell(withClass: SwitchCell.self, for: indexPath)
            cell.configure(
                title: NSLocalizedString("Taptic Engine", bundle: .module, comment: "Settings row and switch label for haptic feedback."),
                isOn: isEnabled,
                onTintColor: view.tintColor
            ) { [weak self] isOn in
                self?.setEnabled(isOn)
            }
            return cell

        case .style(let rowStyle):
            let cell = tableView.dequeueReusableCell(withClass: UITableViewCell.self, for: indexPath)
            var configuration = cell.defaultContentConfiguration()
            configuration.text = rowStyle.title
            configuration.applySettingsRowLayout()
            cell.contentConfiguration = configuration
            cell.selectionStyle = .none
            cell.accessoryType = rowStyle == style ? .checkmark : .none
            return cell
        }
    }
}

// MARK: - UITableViewDelegate

extension TapticEngineController {

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard case .style(let selected) = dataSource?.itemIdentifier(for: indexPath) else { return }
        let previous = style
        style = selected
        taptic.tapticStyle = selected
        eventHandler?.settingsDidUpdateTaptic(taptic)
        dataSource?.reconfigure([.style(previous), .style(selected)])
        // Let the user feel the chosen strength, even when it was already selected.
        SettingsHaptics(storage: taptic).preview(selected)
    }

    private func setEnabled(_ isOn: Bool) {
        guard isOn != isEnabled else { return }
        isEnabled = isOn
        taptic.isTapticEngineEnabled = isOn
        eventHandler?.settingsDidUpdateTaptic(taptic)
        dataSource?.apply(makeSnapshot(), animatingDifferences: tableView.window != nil)
    }
}
