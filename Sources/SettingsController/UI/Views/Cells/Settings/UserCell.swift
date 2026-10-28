//
//  UserCell.swift
//  SettingsController
//
//  Created by Влад Лыков on 01.12.2024.
//

import UIKit

// MARK: - UserCell

class UserCell: UITableViewCell {
    
    // MARK: Properties

    private static let userImageViewSize: CGFloat = 45
    
    private lazy var userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .white
        imageView.backgroundColor = .gray
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = round(Self.userImageViewSize / 2.0)
        imageView.layer.masksToBounds = true
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private lazy var userLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
        label.textAlignment = .natural
        return label
    }()
    
    // MARK: Life Cycle
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupView()
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
 
    // MARK: Configure

    public func configure(title: String, avatar: UIImage?) {
        accessibilityLabel = title
        userLabel.text = title
        userImageView.image = avatar
    }

    // MARK: Setup View

    private func setupView() {
        
        accessoryType  = .disclosureIndicator
        selectionStyle = .default
        
        isAccessibilityElement = true
        accessibilityTraits = .button
        userImageView.isAccessibilityElement = false
        contentView.addSubview(userImageView)
        contentView.addSubview(userLabel)

    }
    
    // MARK: Set Constraints

    private func setConstraints() {
        
        NSLayoutConstraint.activate([
            userImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            userImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            userImageView.widthAnchor.constraint(equalToConstant:  Self.userImageViewSize),
            userImageView.heightAnchor.constraint(equalToConstant: Self.userImageViewSize),
            
            userImageView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 10),
            userImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),
            userLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            userLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            userLabel.leadingAnchor.constraint(equalTo: userImageView.trailingAnchor, constant: 15),
            userLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])
        
    }
    
}
