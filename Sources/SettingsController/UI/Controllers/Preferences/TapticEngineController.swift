import UIKit

/// Turns haptic feedback on or off and chooses its strength; selecting a strength plays a sample.
final class TapticEngineController: UITableViewController {

    private let taptic: TapticStorage
    private weak var eventHandler: (any SettingsControllerEventHandler)?

    // The table renders this local copy, so a storage that ignores a write cannot desynchronize sections.
    private var isEnabled: Bool
    private var style: TapticStyle

    private enum Section: Int {
        case toggle, styles
    }

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
    }
}

// MARK: - UITableViewDataSource

extension TapticEngineController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        isEnabled ? 2 : 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .toggle: 1
        case .styles: TapticStyle.allCases.count
        case nil: 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard Section(rawValue: section) == .styles else { return nil }
        return NSLocalizedString("Taptic Force", bundle: .module, comment: "Section heading for haptic feedback intensity.")
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard Section(rawValue: section) == .toggle else { return nil }
        return NSLocalizedString(
            "Adds taptic feedback to various actions in the app.", bundle: .module, comment: "Footer explaining the haptic feedback switch."
        )
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section) {
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

        case .styles:
            let cell = tableView.dequeueReusableCell(withClass: UITableViewCell.self, for: indexPath)
            let rowStyle = TapticStyle.allCases[indexPath.row]
            var configuration = cell.defaultContentConfiguration()
            configuration.text = rowStyle.title
            configuration.applySettingsRowLayout()
            cell.contentConfiguration = configuration
            cell.selectionStyle = .none
            cell.accessoryType = rowStyle == style ? .checkmark : .none
            return cell

        case nil:
            preconditionFailure("Unexpected taptic settings indexPath: \(indexPath)")
        }
    }
}

// MARK: - UITableViewDelegate

extension TapticEngineController {

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard Section(rawValue: indexPath.section) == .styles else { return }
        let selected = TapticStyle.allCases[indexPath.row]
        if selected != style, let old = TapticStyle.allCases.firstIndex(of: style) {
            tableView.cellForRow(at: IndexPath(row: old, section: indexPath.section))?.accessoryType = .none
        }
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        style = selected
        taptic.tapticStyle = selected
        eventHandler?.settingsDidUpdateTaptic(taptic)
        // Let the user feel the chosen strength, even when it was already selected.
        SettingsHaptics(storage: taptic).preview(selected)
    }

    private func setEnabled(_ isOn: Bool) {
        guard isOn != isEnabled else { return }
        isEnabled = isOn
        taptic.isTapticEngineEnabled = isOn
        eventHandler?.settingsDidUpdateTaptic(taptic)
        let sections = IndexSet(integer: Section.styles.rawValue)
        if isOn {
            tableView.insertSections(sections, with: .fade)
        } else {
            tableView.deleteSections(sections, with: .fade)
        }
    }
}
