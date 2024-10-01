//
//  SettingsCell.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import UIKit

// MARK: - SettingsCell

public final class SettingsCell: UITableViewCell {
    
    // MARK: Properties [Public]
    
    public var title: String? {
        titleLabel.text
    }
    
    // MARK: Properties [Private]
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = .systemFont(ofSize: 17)
        label.textColor = .label
        label.textAlignment = .left
        return label
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .white
        imageView.backgroundColor = .gray
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = round(CGFloat(30 / 4))
        return imageView
    }()
    
    private let detailLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = .systemFont(ofSize: 17)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        return label
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 4
        return stackView
    }()
    
    // MARK: Life Cycle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: Self.reuseIdentifier)
        
        self.accessoryType  = .disclosureIndicator
        self.selectionStyle = .default
        
        setupView()
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
}

// MARK: - Configure

extension SettingsCell {
    
    public func configure(title: String, icon: SettingsIcon, detail: String? = nil) {
        self.titleLabel.text = title
        self.iconImageView.image = icon.image
        self.iconImageView.backgroundColor = icon.color
        self.detailLabel.text = detail
        
        self.detailLabel.isHidden = detail == nil
    }
    
}

// MARK: - Setup View

extension SettingsCell {
    
    private func setupView() {
        contentView.addSubview(iconImageView)
        contentView.addSubview(stackView)
    }
    
}

// MARK: - Set Constraints

extension SettingsCell {
    
    private func setConstraints() {
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 30),
            iconImageView.heightAnchor.constraint(equalToConstant: 30),

            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 15),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8)
        ])
        
    }
    
}
