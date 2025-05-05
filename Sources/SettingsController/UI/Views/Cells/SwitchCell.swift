//
//  SwitchTableViewCell.swift
//  Speech To Text
//
//  Created by Влад Лыков on 06.10.2024.
//

import UIKit

class SwitchCell: UITableViewCell {
    
//    public lazy var switchControl: UISwitch = {
//        let switchControl = UISwitch()
//        switchControl.onTintColor = tintColor
//        return switchControl
//    }()
    
#if targetEnvironment(tvOS)
    public lazy var switchControl: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("OFF", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemRed
        button.layer.cornerRadius = 8
        button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
        button.addTarget(self, action: #selector(toggle), for: .primaryActionTriggered)
        return button
    }()
    
    private var isOn = false {
        didSet {
            switchControl.setTitle(isOn ? "ON" : "OFF", for: .normal)
            switchControl.backgroundColor = isOn ? .systemGreen : .systemRed
        }
    }

    @objc private func toggle() {
        isOn.toggle()
    }

#else
    public lazy var switchControl: UISwitch = {
        let switchControl = UISwitch()
        switchControl.onTintColor = tintColor
        return switchControl
    }()
#endif
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
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
