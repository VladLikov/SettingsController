//
//  SettingsController+Routing.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import UIKit
import AlertKit
import MessageUI
import SafeSFSymbols

// MARK: - Routing

extension SettingsController {

    @objc
    func closeAction(_ sender: UIBarButtonItem) {
        navigationController?.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            configuration.eventHandler?.settingsDidDismiss()
        }
    }

    func pushViewController(_ viewController: UIViewController, navigationTitle: String?) {
        viewController.navigationItem.title = navigationTitle
        SettingsNavigationTitleStyle.applyCompactTitles(to: viewController)

        if UIDevice.current.userInterfaceIdiom != .phone {
            showDetailViewController(UINavigationController(rootViewController: viewController), sender: nil)
        } else {
            showDetailViewController(viewController, sender: nil)
        }
    }

    func presentPremium(_ payload: PremiumPayload) {
        if payload.isPremium {
            let style: AlertViewStyle

#if os(visionOS)
            style = .iOS17AppleMusic
#else
            style = .iOS16AppleMusic
#endif

            AlertKitAPI.present(
                title: NSLocalizedString("Premium is active", bundle: .module, comment: ""),
                icon: .custom(UIImage(.star.fill)),
                style: style,
                haptic: .success
            )

        } else if let premiumControllerType = payload.destinationControllerType {
            let viewController = premiumControllerType.init()
            SettingsNavigationTitleStyle.applyCompactTitles(to: viewController)
            if UIDevice.current.userInterfaceIdiom == .phone {
                viewController.modalPresentationStyle = .fullScreen
            }
            present(viewController, animated: true)

        } else if let action = payload.action {
            action(self)
        }
    }

    func sendMail(_ email: String) {
        guard MailAvailability.canSendEmail() else { return }

        let mailController = MailController(
            type: .supportRequest,
            email: email,
            userID: mailUserID,
            isPremium: cachedPremiumStatus,
            productID: configuration.productID,
            dataProvider: configuration.dataProvider
        )
        present(UINavigationController(rootViewController: mailController), animated: true)
    }

    func shareApp(_ appID: String, at indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? SettingsCell else { return }
        guard let url = URL(string: "https://apps.apple.com/app/id\(appID)") else { return }

        let activityController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityController.popoverPresentationController?.sourceView = tableView
        activityController.popoverPresentationController?.sourceRect = cell.frame
        present(activityController, animated: true)
    }

    func rateApp(_ appID: String) {
        if let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appID)?action=write-review") {
            UIApplication.shared.open(url)
        }
    }

    func moreApps(_ developerID: String) {
        if let url = URL(string: "itms-apps://itunes.apple.com/developer/id\(developerID)") {
            UIApplication.shared.open(url)
        }
    }

    func openTelegramChannel(_ channelUsername: String) {
        guard let appURL = URL(string: "tg://resolve?domain=\(channelUsername)"),
              let webURL = URL(string: "https://t.me/\(channelUsername)") else {
            return
        }

        if UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else {
            UIApplication.shared.open(webURL)
        }
    }

    func openVKGroup(_ groupID: String) {
        guard let appURL = URL(string: "vk://vk.com/club\(groupID)"),
              let webURL = URL(string: "https://vk.com/club\(groupID)") else {
            return
        }

        if UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else {
            UIApplication.shared.open(webURL)
        }
    }
}

extension SettingsController {

    var mailUserID: String? {
        for section in sections {
            guard case .rows(let rows) = section.kind else { continue }

            for row in rows {
                guard case .defaultRow(.about(let userID, _, _, _)) = row else {
                    continue
                }

                return userID
            }
        }

        return nil
    }
}

// MARK: - Navigation Titles

/// Only affects controllers opened by SettingsController itself.
/// The SettingsController root keeps its large title.
@MainActor
enum SettingsNavigationTitleStyle {

    static func applyCompactTitles(to viewController: UIViewController) {
        viewController.navigationItem.largeTitleDisplayMode = .never

        // A custom destination may itself be a navigation controller.
        guard let navigationController = viewController as? UINavigationController else {
            return
        }

        navigationController.navigationBar.prefersLargeTitles = false
        for controller in navigationController.viewControllers {
            controller.navigationItem.largeTitleDisplayMode = .never
        }
    }
}
