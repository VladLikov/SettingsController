//
//  AppearanceController.swift
//  SettingsController
//
//  Created by Влад Лыков on 06.10.2024.
//

import UIKit

// MARK: - AppearanceController

class AppearanceController: UITableViewController {
    
    // MARK: Properties [Private]

    private let colors: [any AppColorType]
    
    private var theme: ThemeStorage
    private weak var eventHandler: (any SettingsControllerEventHandler)?
    
    private var reviewRequested: Bool = false
    
    // MARK: Life Cycle
    
    init(
        themeStorage: ThemeStorage,
        colors: [any AppColorType],
        eventHandler: (any SettingsControllerEventHandler)?
    ) {
        self.theme = themeStorage
        self.colors = colors
        self.eventHandler = eventHandler
        super.init(style: .insetGrouped)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        normalizeInterfaceStyleIfNeeded()

        tableView?.rowHeight = UITableView.automaticDimension
        tableView?.estimatedRowHeight = defaultRowEstimatedHeight
                
        tableView?.register(SwitchCell.self)
        tableView?.register(ColorCell.self)
        tableView?.register(UITableViewCell.self)

        navigationItem.largeTitleDisplayMode = .never
    }
}

// MARK: - UITableViewDataSource

extension AppearanceController {
        
    override func numberOfSections(in tableView: UITableView) -> Int {
        return theme.autoTheme ? 2 : 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return colors.count
        } else if section == 2 {
            return 2
        }
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return NSLocalizedString("App color", bundle: .module, comment: "")
        } else if section == 1 {
            return NSLocalizedString("Light & Dark theme", bundle: .module, comment: "")
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 2 {
            return NSLocalizedString("When the switch is on, the system appearance is used.", bundle: .module, comment: "")
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
           
        let section = indexPath.section, row = indexPath.row
        
        if section == 0 {
            
            let cell = tableView.dequeueReusableCell(withClass: ColorCell.self, for: indexPath)
                        
            let appColor = colors[row]
            
            cell.configure(appColor: appColor)
            
            let isSelected = theme.appColor == appColor.color
            
            cell.accessoryType = isSelected ? .checkmark : .none
                        
            return cell
            
        } else if section == 1 && row == 0 {
            
            let cell = tableView.dequeueReusableCell(withClass: SwitchCell.self, for: indexPath)

            cell.configure(
                title: NSLocalizedString("Automatically", bundle: .module, comment: ""),
                isOn: theme.autoTheme,
                onTintColor: theme.appColor
            ) { [weak self] isOn in
                self?.autoThemeSwitchAction(isOn: isOn)
            }

            return cell
            
        } else if section == 2 {
            
            let cell = tableView.dequeueReusableCell(withClass: UITableViewCell.self, for: indexPath)

            cell.selectionStyle = .none

            var configuration = cell.defaultContentConfiguration()
            configuration.text = [
                NSLocalizedString("Light Theme", bundle: .module, comment: ""),
                NSLocalizedString("Dark Theme", bundle: .module, comment: "")
            ][row]
            configuration.textProperties.numberOfLines = 0
            configuration.textProperties.lineBreakMode = .byWordWrapping
            configuration.directionalLayoutMargins.top = 6
            configuration.directionalLayoutMargins.bottom = 6
            cell.contentConfiguration = configuration

            let isSelected = row == selectedInterfaceStyleIndex
            
            cell.accessoryType = isSelected ? .checkmark : .none
            
            cell.tintColor = view.tintColor
            
            return cell
            
        }
        
        preconditionFailure("Unexpected appearance settings indexPath: \(indexPath)")
        
    }
    
}

// MARK: - UITableViewDelegate

extension AppearanceController {
        
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            let currentRaw = theme.appColorRawValue
            guard let oldIndex = colors.firstIndex(where: { $0.rawValue == currentRaw }) else {
                return
            }
            
            let oldIndexPath = IndexPath(row: oldIndex, section: indexPath.section)

            tableView.cellForRow(at: oldIndexPath)?.accessoryType = .none
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark

            let newAppColor = colors[indexPath.row]
            
            let newColor = newAppColor.color
            
            theme.appColor = newColor
            eventHandler?.settingsDidUpdateTheme(theme)
            
            navigationController?.navigationBar.tintColor = newColor
                                                
            updateVisibleThemeControlsTint(newColor)
            
            if !reviewRequested {
                reviewRequested = true
                AppReviewRequester.requestReview()
            }
                        
#if !os(visionOS)
            UISelectionFeedbackGenerator().selectionChanged()
#endif
                        
        } else if indexPath.section == 2 {
            
            let oldIndexPath = IndexPath(row: selectedInterfaceStyleIndex, section: indexPath.section)

            tableView.cellForRow(at: oldIndexPath)?.accessoryType = .none
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
            
            theme.interfaceStyle = indexPath.row + 1
            eventHandler?.settingsDidUpdateTheme(theme)
            
#if !os(visionOS)
            UISelectionFeedbackGenerator().selectionChanged()
#endif

        }
                
    }
    
}

// MARK: - Actions

extension AppearanceController {

    private var selectedInterfaceStyleIndex: Int {
        min(max(theme.interfaceStyle - 1, 0), 1)
    }

    private var defaultRowEstimatedHeight: CGFloat {
        if #available(iOS 26, *) {
            53
        } else {
            45
        }
    }

    private func normalizeInterfaceStyleIfNeeded() {
        guard (1...2).contains(theme.interfaceStyle) else {
            theme.interfaceStyle = 1
            return
        }
    }

    private func autoThemeSwitchAction(isOn: Bool) {

        theme.autoTheme = isOn
        eventHandler?.settingsDidUpdateTheme(theme)

        let indexSet = IndexSet(integer: 2)

        if !isOn {
            tableView.insertSections(indexSet, with: .fade)
        } else {
            tableView.deleteSections(indexSet, with: .fade)
        }
    }

    private func updateVisibleThemeControlsTint(_ color: UIColor) {
        if let switchCell = tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? SwitchCell {
            switchCell.switchControl.onTintColor = color
        }

        guard !theme.autoTheme else { return }

        for row in 0..<2 {
            tableView.cellForRow(at: IndexPath(row: row, section: 2))?.tintColor = color
        }
    }
}
