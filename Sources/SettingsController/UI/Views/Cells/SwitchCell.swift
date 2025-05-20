//
//  SwitchTableViewCell.swift
//  Speech To Text
//
//  Created by Влад Лыков on 06.10.2024.
//

import UIKit

public class SwitchCell: UITableViewCell {
    
    public lazy var switchControl: UISwitch = {
        let switchControl = UISwitch()
        switchControl.onTintColor = tintColor
        return switchControl
    }()
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupView() {
        selectionStyle = .none
        accessoryView = switchControl
    }
}
