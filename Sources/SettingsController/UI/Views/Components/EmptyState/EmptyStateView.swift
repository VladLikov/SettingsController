//
//  EmptyStateView.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import UIKit

final class EmptyStateView: UIView {

    private let title: String?
    private let subtitle: String?

    private lazy var headerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = title
        label.textColor = .gray
        label.font = .systemFont(ofSize: 30, weight: .black)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var footerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = subtitle
        label.textColor = .gray
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 3
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        return label
    }()
    
    init(title: String?, subtitle: String?) {
        self.title = title
        self.subtitle = subtitle
        super.init(frame: .zero)

        setupView()
        setConstraints()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .systemGroupedBackground
        
        addSubview(headerLabel)
        addSubview(footerLabel)
    }
    
    private func setConstraints() {
        NSLayoutConstraint.activate([
            headerLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            headerLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            footerLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 8),
            footerLabel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.9),
            footerLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }
}
