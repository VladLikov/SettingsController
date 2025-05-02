//
//  AppCell.swift
//  SettingsController
//
//  Created by Влад Лыков on 29.04.2025.
//

import UIKit

final class AppCell: UITableViewCell {

    // MARK: UI Elements [Private]

    private lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 7.5 // 30 / 4
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemBackground
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .label
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
}

// MARK: - Configure

extension AppCell {
    
    public func configure(with row: AppRow) {
        
        switch row {
        case .placeholder:
            titleLabel.text = "Loading…"

        case .failed:
            titleLabel.text = "Failed to load"

        case .loaded(let item):
            titleLabel.text = item.name
            load(icon: item.iconURL)
        }
    }
    
    private func load(icon url: URL) {
        
        Task { @MainActor in
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let img = UIImage(data: data)
                iconView.image = img
            } catch {
                print(error)
            }
        }
    }
}

// MARK: - Setup View

extension AppCell {
    
    private func setupView() {
        
        accessoryType = .disclosureIndicator
        
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
    }
}

// MARK: - Set Constraints

extension AppCell {
    
    private func setConstraints() {
        
        NSLayoutConstraint.activate([
            
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint (equalToConstant: 30),
            iconView.heightAnchor.constraint(equalToConstant: 30),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 15),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
}
