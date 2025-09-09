//
//  InterfaceController.swift
//  Speech To Text
//
//  Created by Влад Лыков on 06.10.2024.
//

import UIKit
import SwiftBoost

// MARK: - AppearanceController

class AppearanceController: UITableViewController {
    
    // MARK: Properties [Private]

    private let colors: [any AppColorType]
    
    private var theme: ThemeStorage
    
    private var reviewRequested: Bool = false
    
    // MARK: Life Cycle
    
    init(themeStorage: ThemeStorage, colors: [any AppColorType]) {
        self.theme = themeStorage
        self.colors = colors
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 26, *) {
            tableView?.rowHeight = 50
        } else {
            tableView?.rowHeight = 45
        }
                
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
            
            cell.textLabel?.text = NSLocalizedString("Automatically", bundle: .module, comment: "")
            
            cell.switchControl.isOn = theme.autoTheme
            cell.switchControl.onTintColor = theme.appColor

            cell.switchControl.addTarget(self,
                                         action: #selector(self.autoThemeSwitchAction(_:)),
                                         for: .valueChanged)
            
            return cell
            
        } else if section == 2 {
            
            let cell = tableView.dequeueReusableCell(withClass: UITableViewCell.self, for: indexPath)
            
            cell.selectionStyle = .none
            
            cell.textLabel?.text =
            [NSLocalizedString("Light Theme", bundle: .module, comment: ""),
             NSLocalizedString("Dark Theme", bundle: .module, comment: "")
            ][row]
            
            let isSelected = row == theme.interfaceStyle - 1
            
            cell.accessoryType = isSelected ? .checkmark : .none
            
            cell.tintColor = view.tintColor
            
            return cell
            
        }
        
        return .init()
        
    }
    
}

// MARK: - UITableViewDelegate

extension AppearanceController {
        
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
                        
//            guard let oldAppColor = AppColor(rawValue: theme.appColorRawValue),
//                  let oldIndex = colors.firstIndex(where: { $0 == oldAppColor }) else {
//                return
//            }
            
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
            SettingsNotifier.didChangeTheme(theme)
            
            navigationController?.navigationBar.tintColor = newColor
                                                
            tableView.reloadSections(IndexSet(integer: 1), with: .fade)
            
            if !theme.autoTheme {
                tableView.reloadSections(IndexSet(integer: 2), with: .fade)
            }
            
            if !reviewRequested {
                reviewRequested = true
                Helpers.requestReview()
            }
                        
#if !os(visionOS)
            UISelectionFeedbackGenerator().selectionChanged()
#endif
                        
        } else if indexPath.section == 2 {
            
            let oldIndexPath = IndexPath(row: theme.interfaceStyle - 1, section: indexPath.section)

            tableView.cellForRow(at: oldIndexPath)?.accessoryType = .none
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
            
            theme.interfaceStyle = indexPath.row + 1
            SettingsNotifier.didChangeTheme(theme)
            
#if !os(visionOS)
            UISelectionFeedbackGenerator().selectionChanged()
#endif

        }
                
    }
    
}

// MARK: - Actions

extension AppearanceController {

    @objc
    private func autoThemeSwitchAction(_ sender: UISwitch) {
        
        theme.autoTheme = sender.isOn
        SettingsNotifier.didChangeTheme(theme)

        let indexSet = IndexSet(integer: 2)

        if !sender.isOn {
            tableView.insertSections(indexSet, with: .fade)
        } else {
            tableView.deleteSections(indexSet, with: .fade)
        }
    }
}


