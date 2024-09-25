//
//  SubtitleTableViewCell.swift
//  SettingsController
//
//  Created by Влад Лыков on 25.09.2024.
//

import UIKit

class SubtitleTableViewCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
