//
//  DataEmpty.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import UIKit

public protocol DataEmpty {
    func setEmptyView(_ emptyView: EmptyView) async
    func resetEmptyView() async
}

public class EmptyView: UIView {
    
    private var headerText: String?
    private var footerText: String?

    private lazy var headerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = headerText
        label.textColor = .gray
        label.font = .systemFont(ofSize: 30, weight: .black)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var footerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = footerText
        label.textColor = .gray
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 3
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        return label
    }()
    
    public init(title: String?, subtitle: String?) {
        super.init(frame: .zero)
        
        self.headerText = title
        self.footerText = subtitle
        
        setupView()
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
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

extension UITableView: DataEmpty {
    public func setEmptyView(_ emptyView: EmptyView) {
        self.backgroundView = emptyView
    }
    
    public func resetEmptyView() {
        self.backgroundView = nil
    }
}

extension UICollectionView: DataEmpty {
    public func setEmptyView(_ emptyView: EmptyView) {
        self.backgroundView = emptyView
    }
    
    public func resetEmptyView() {
        self.backgroundView = nil
    }
}

extension UIViewController: DataEmpty {
    public func setEmptyView(_ emptyView: EmptyView) {
        self.view = emptyView
    }
    
    public func resetEmptyView() {}
}
