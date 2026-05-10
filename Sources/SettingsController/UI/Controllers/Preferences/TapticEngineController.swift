//
//  TapticEngineController.swift
//  SettingsController
//
//  Created by Влад Лыков on 06.10.2024.
//

import UIKit

// MARK: - TapticEngineController

class TapticEngineController: UITableViewController {
    
    // MARK: Properties [Private]
    
    private let tapticArray: [TapticEngineStyle] = TapticEngineStyle.allCases
        
    private var taptic: TapticStorage
    private weak var eventHandler: (any SettingsControllerEventHandler)?

    // MARK: Life Cycle
    
    init(
        tapticStorage: TapticStorage,
        eventHandler: (any SettingsControllerEventHandler)?
    ) {
        self.taptic = tapticStorage
        self.eventHandler = eventHandler
        super.init(style: .insetGrouped)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        normalizeTapticStyleIfNeeded()

        tableView.register(SwitchCell.self)
        tableView.register(UITableViewCell.self)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = defaultRowEstimatedHeight
        
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
            return tapticArray.count
            
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
            
            let cell = tableView.dequeueReusableCell(withClass: SwitchCell.self, for: indexPath)

            cell.configure(
                title: NSLocalizedString("Taptic Engine", bundle: .module, comment: ""),
                isOn: taptic.tapticEngine,
                onTintColor: view.tintColor
            ) { [weak self] isOn in
                self?.tapticEngineAction(isOn: isOn)
            }

            return cell
            
        } else if section == 1 {
            
            let cell = tableView.dequeueReusableCell(withClass: UITableViewCell.self, for: indexPath)
            cell.selectionStyle = .none

            let tapticStyle = tapticArray[row]
            let isSelected = row == taptic.tapticStyle

            var configuration = cell.defaultContentConfiguration()
            configuration.text = tapticStyle.title
            configuration.textProperties.numberOfLines = 0
            configuration.textProperties.lineBreakMode = .byWordWrapping
            configuration.directionalLayoutMargins.top = 6
            configuration.directionalLayoutMargins.bottom = 6
            cell.contentConfiguration = configuration

            cell.accessoryType = isSelected ? .checkmark : .none

            return cell
        }
        
        preconditionFailure("Unexpected taptic settings indexPath: \(indexPath)")
        
    }
    
}

// MARK: - UITableViewDelegate

extension TapticEngineController {
        
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 1 {
            
            let oldIndexPath = IndexPath(row: selectedTapticStyleIndex, section: indexPath.section)

            tableView.cellForRow(at: oldIndexPath)?.accessoryType = .none
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
            
            taptic.tapticStyle = indexPath.row
            eventHandler?.settingsDidUpdateTaptic(taptic)
            
#if !os(visionOS)
            UISelectionFeedbackGenerator().selectionChanged()
#endif
        }
        
    }
    
}

// MARK: - Actions

extension TapticEngineController {
        
    private var selectedTapticStyleIndex: Int {
        guard tapticArray.indices.contains(taptic.tapticStyle) else {
            return TapticEngineStyle.medium.rawValue
        }

        return taptic.tapticStyle
    }

    private var defaultRowEstimatedHeight: CGFloat {
        if #available(iOS 26, *) {
            53
        } else {
            45
        }
    }

    private func normalizeTapticStyleIfNeeded() {
        guard tapticArray.indices.contains(taptic.tapticStyle) else {
            taptic.tapticStyle = TapticEngineStyle.medium.rawValue
            return
        }
    }

    private func tapticEngineAction(isOn: Bool) {

        taptic.tapticEngine = isOn
        eventHandler?.settingsDidUpdateTaptic(taptic)

        let indexSet = IndexSet(integer: 1)

        if isOn {
            tableView.insertSections(indexSet, with: .fade)
        } else {
            tableView.deleteSections(indexSet, with: .fade)
        }
        
    }
    
}
