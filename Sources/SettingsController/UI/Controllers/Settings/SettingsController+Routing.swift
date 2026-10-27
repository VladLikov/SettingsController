//
//  SettingsController+Routing.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import UIKit
import AlertKit
import SafeSFSymbols

// MARK: - Routing

extension SettingsController {

    @objc
    func closeAction(_ sender: UIBarButtonItem) {
        cancelOperations()
        let root = presentationRoot ?? navigationController ?? self
        root.dismiss(animated: true) { [weak self] in self?.reportDismissal() }
    }

    func pushViewController(_ viewController: UIViewController, navigationTitle: String?) {
        viewController.navigationItem.title = navigationTitle
        viewController.navigationItem.largeTitleDisplayMode = .never

        if let split = splitViewController, !split.isCollapsed {
            let destination = (viewController as? UINavigationController)
                ?? UINavigationController(rootViewController: viewController)
            split.showDetailViewController(destination, sender: self)
        } else if viewController is UINavigationController {
            present(viewController, animated: true)
        } else if let navigationController {
            navigationController.pushViewController(viewController, animated: true)
        } else {
            present(UINavigationController(rootViewController: viewController), animated: true)
        }
    }

    func presentPremium(_ payload: PremiumPayload) {
        if isPremium {
            let style: AlertViewStyle

#if os(visionOS)
            style = .iOS17AppleMusic
#else
            style = .iOS16AppleMusic
#endif

            AlertKitAPI.present(
                title: NSLocalizedString("Premium is active", bundle: .module, comment: "Confirmation shown when an already-premium user taps the premium action."),
                icon: .custom(UIImage(.star.fill)),
                style: style,
                haptic: .success
            )

        } else if payload.destinationFactory != nil || payload.destinationControllerType != nil {
            guard presentedViewController == nil else { return }
            let destination = payload.destinationFactory?() ?? payload.destinationControllerType?.init()
            guard let viewController = destination else { return }
            if traitCollection.horizontalSizeClass == .compact {
                viewController.modalPresentationStyle = .fullScreen
            }
            present(viewController, animated: true)
            if viewController.presentationController?.delegate == nil {
                viewController.presentationController?.delegate = self
            }

        } else if let action = payload.action {
            action(self)
        }
    }

    func openLanguageSettings() {
        guard languageSettingsTask == nil,
              let url = URL(string: UIApplication.openSettingsURLString) else { return }
        let open = openURL
        languageSettingsTask = Task { @MainActor [weak self] in
            let success = await open(url)
            guard !Task.isCancelled else { return }
            self?.languageSettingsTask = nil
            guard !success, let self, settingsCanPresent else { return }
            let alert = UIAlertController(
                title: NSLocalizedString("Unable to open Settings", bundle: .module, comment: "Opening system settings failed"),
                message: nil, preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", bundle: .module, comment: ""), style: .default))
            present(alert, animated: true)
        }
    }

    func sendMail(_ email: String) {
        let mailController = MailController(
            type: .supportRequest,
            email: email,
            isPremium: cachedPremiumStatus,
            productID: configuration.productID,
            dataProvider: configuration.dataProvider
        )
        mailController.openURL = openURL
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

extension SettingsController: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        if presentationController.presentedViewController === presentationRoot {
            reportDismissal()
        } else {
            needsStateRefresh = false
            _ = startStateRefresh()
        }
    }
}
