//
//  PremiumCell.swift
//  SettingsController
//
//  Created by Влад Лыков on 20.05.2025.
//

import UIKit
import SwiftUI

final class PremiumCell: UITableViewCell {
    private var host: UIHostingController<PremiumCard>?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        selectionStyle = .none
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        backgroundConfiguration = nil
        accessoryType = .none
        accessoryView = nil

        if #available(iOS 16.0, *) {
            contentConfiguration = nil
        }
    }

    func configure(payload: PremiumCardPayload, onTap: @escaping () -> Void) {

        let premiumCard = PremiumCard(
            image: payload.image,
            title: payload.title,
            subtitle: payload.subtitle,
            buttonTitle: payload.buttonTitle,
            color: payload.premium.color,
            onTap: onTap
        )

        if #available(iOS 16.0, *) {
            host?.view.removeFromSuperview()
            host = nil
            contentConfiguration = UIHostingConfiguration {
                premiumCard
            }
            .margins(.all, 0)
        } else {
            if let host = host {
                host.rootView = premiumCard
            } else {
                let host = UIHostingController(rootView: premiumCard)
                host.view.translatesAutoresizingMaskIntoConstraints = false
                host.view.backgroundColor = .clear
                contentView.addSubview(host.view)
                NSLayoutConstraint.activate([
                    host.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                    host.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                    host.view.topAnchor.constraint(equalTo: contentView.topAnchor),
                    host.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
                ])
                self.host = host
            }
        }
    }
}
