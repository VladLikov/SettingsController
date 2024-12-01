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
        label.numberOfLines = 1
        label.font = .boldSystemFont(ofSize: 18)
        label.textColor = .label
        label.textAlignment = .left
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
        userLabel.text = title
        userImageView.image = avatar
    }

    // MARK: Setup View

    private func setupView() {
        
        accessoryType  = .disclosureIndicator
        selectionStyle = .default
        
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
            
            userLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            userLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            userLabel.leadingAnchor.constraint(equalTo: userImageView.trailingAnchor, constant: 15),
            userLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
        ])
        
    }
    
}
