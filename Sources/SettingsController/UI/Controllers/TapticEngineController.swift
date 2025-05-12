//
//  TapticController.swift
//  Speech To Text
//
//  Created by Влад Лыков on 06.10.2024.
//

import UIKit

// MARK: - TapticEngineController

class TapticEngineController: UITableViewController {
    
    // MARK: Properties [Private]
    
    private let tapticArray: [TapticEngineStyle] = TapticEngineStyle.allCases
        
    private var taptic: TapticStorage

    // MARK: Life Cycle
    
    init(tapticStorage: TapticStorage) {
        self.taptic = tapticStorage
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(SwitchCell.self)
        tableView.register(UITableViewCell.self)
        
        navigationItem.largeTitleDisplayMode = .never
    }
    
}

// MARK: - UITableViewDataSource

extension TapticEngineController {
        
    override func numberOfSections(in tableView: UITableView) -> Int {
        return taptic.tapticEngine ? 2 : 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch section {
        case 0:
            return 1
            
        case 1:
            return 3
            
        default:
            return 0
        }

    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if section == 1 {
            return NSLocalizedString("Taptic Force", bundle: .module, comment: "")
        }
        
        return nil
        
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        
        if section == 0 {
            return NSLocalizedString("Adds taptic feedback to various actions in the app.", bundle: .module, comment: "")
        }
        
        return nil
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                
        let section = indexPath.section, row = indexPath.row
        
        if section == 0 && row == 0 {
            
            let cell = tableView.dequeueReusableCell(ofType: SwitchCell.self, for: indexPath)
            
            cell.textLabel?.text = "Taptic Engine"
            cell.switchControl.onTintColor = view.tintColor //settings.appColor
            cell.switchControl.isOn = taptic.tapticEngine
            cell.switchControl.addTarget(self,
                                         action: #selector(self.tapticEngineAction(_:)),
                                         for: .valueChanged)
            
            return cell
            
        } else if section == 1 {
            
            let cell = tableView.dequeueReusableCell(ofType: UITableViewCell.self, for: indexPath)
            cell.selectionStyle = .none

            let tapticStyle = tapticArray[row]
            let isSelected = row == taptic.tapticStyle

            cell.textLabel?.text = tapticStyle.title
            cell.accessoryType = isSelected ? .checkmark : .none
            
            return cell
        }
        
        return .init()
        
    }
    
}

// MARK: - UITableViewDelegate

extension TapticEngineController {
        
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 1 {
            
            guard let tapticStyle = TapticEngineStyle(rawValue: taptic.tapticStyle) else {
                return
            }
            
            let oldIndexPath = IndexPath(row: tapticStyle.rawValue, section: indexPath.section)

            tableView.cellForRow(at: oldIndexPath)?.accessoryType = .none
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
            
            taptic.tapticStyle = indexPath.row
            SettingsNotifier.didChangeTaptic(taptic)
            
#if !os(visionOS)
            UISelectionFeedbackGenerator().selectionChanged()
#endif
        }
        
    }
    
}

// MARK: - Actions

extension TapticEngineController {
        
    @objc
    private func tapticEngineAction(_ sender: UISwitch) {
        
        taptic.tapticEngine = sender.isOn
                
        let indexSet = IndexSet(integer: 1)

        if sender.isOn {
            tableView.insertSections(indexSet, with: .fade)
        } else {
            tableView.deleteSections(indexSet, with: .fade)
        }
        
    }
    
}
