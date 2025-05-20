//
//  PremiumCell.swift
//  SettingsController
//
//  Created by Влад Лыков on 20.05.2025.
//

import UIKit
import SwiftUI

final class PremiumCell: UITableViewCell {
    // MARK: - Инициализация SwiftUI view через HostingController
    private var host: UIHostingController<PremiumCard>?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupHost()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupHost()
    }

    private func setupHost() {
        
        backgroundColor = .clear
        selectionStyle = .none
        
        let swiftUIView = PremiumCard(
            image: Image(uiImage: UIImage(systemName: "bolt.circle.fill")!),
            title: "Checker+",
            subtitle: "One-time purchase",
            color: .systemBlue,
            onUpgrade: { print("Upgrade tapped") }
        )
        let host = UIHostingController(rootView: swiftUIView)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.backgroundColor = .clear
        contentView.addSubview(host.view)
        self.host = host

        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    // MARK: - Поддержка переиспользования (если нужно динамически менять данные)
    func configure(payload: PremiumCardPayload, onUpgrade: @escaping () -> Void) {
        // Пересоздавать rootView — единственный нормальный способ для HostingController
        host?.rootView = PremiumCard(
            image: Image(uiImage: payload.image),
            title: payload.title,
            subtitle: payload.subtitle,
            color: payload.base.color,
            onUpgrade: onUpgrade
        )
    }
}
