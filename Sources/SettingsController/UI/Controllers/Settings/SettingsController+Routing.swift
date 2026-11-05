//
//  SettingsController+Routing.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import AlertKit
import SafeSFSymbols
import UIKit

// MARK: - Routing

extension SettingsController {

    @objc
    func closeAction(_ sender: UIBarButtonItem) {
        cancelOperations()
        let root = presentationRoot ?? navigationController ?? self
        root.dismiss(animated: true) { [weak self] in self?.reportDismissal() }
    }

    func pushViewController(_ viewController: UIViewController, navigationTitle: String?) {
        cancelPendingStoreProduct()
        viewController.navigationItem.title = navigationTitle
        viewController.navigationItem.largeTitleDisplayMode = .never

        if let split = splitViewController as? SplitController, split.style != .unspecified {
            split.showSettingsDetail(viewController)
        } else if let split = splitViewController, !split.isCollapsed {
            let destination =
                (viewController as? UINavigationController)
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
            AlertKitAPI.present(
                title: NSLocalizedString(
                    "Premium is active", bundle: .module,
                    comment: "Confirmation shown when an already-premium user taps the premium action."),
                icon: .custom(UIImage(.star.fill)),
                style: .settingsConfirmation,
                haptic: haptics.alertHaptic
            )

        } else if case .action(let action) = payload.destination {
            cancelPendingStoreProduct()
            action(SettingsActionContext(viewController: self))
        } else if let destination = payload.destination {
            guard presentedViewController == nil, let viewController = destination.makeViewController() else { return }
            cancelPendingStoreProduct()
            if traitCollection.horizontalSizeClass == .compact {
                viewController.modalPresentationStyle = .fullScreen
            }
            present(viewController, animated: true)
            if viewController.presentationController?.delegate == nil {
                viewController.presentationController?.delegate = self
            }

        }
    }

    func openLanguageSettings() {
        guard languageSettingsTask == nil,
            let url = URL(string: UIApplication.openSettingsURLString)
        else { return }
        cancelPendingStoreProduct()
        let open = openURL
        languageSettingsTask = Task { @MainActor [weak self] in
            let success = await open(url)
            guard !Task.isCancelled else { return }
            self?.languageSettingsTask = nil
            guard !success, let self, settingsCanPresent else { return }
            let alert = UIAlertController(
                title: NSLocalizedString(
                    "Unable to open Settings", bundle: .module,
                    comment: "Alert title when opening the host app page in system Settings fails."),
                message: nil, preferredStyle: .alert
            )
            alert.addAction(
                UIAlertAction(
                    title: NSLocalizedString(
                        "OK", bundle: .module, comment: "Confirmation button dismissing an informational or recoverable error alert."),
                    style: .default))
            present(alert, animated: true)
        }
    }

    func sendMail(_ email: String) {
        guard presentedViewController == nil else { return }
        cancelPendingStoreProduct()
        let mailController = MailController(
            type: .supportRequest,
            email: email,
            isPremium: isPremium,
            productID: configuration.productID,
            dataProvider: configuration.dataProvider
        )
        mailController.openURL = openURL
        present(UINavigationController(rootViewController: mailController), animated: true)
    }

    func shareApp(_ appID: String, at indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? SettingsCell else { return }
        guard let url = URL(string: "https://apps.apple.com/app/id\(appID)") else { return }

        guard presentedViewController == nil else { return }
        cancelPendingStoreProduct()
        let activityController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityController.popoverPresentationController?.sourceView = tableView
        activityController.popoverPresentationController?.sourceRect = cell.frame
        present(activityController, animated: true)
    }

    func rateApp(_ appID: String) {
        openExternal(
            Self.storeURL(scheme: "itms-apps", path: "/app/id\(appID)", query: [URLQueryItem(name: "action", value: "write-review")]),
            fallback: Self.storeURL(scheme: "https", path: "/app/id\(appID)", query: [URLQueryItem(name: "action", value: "write-review")]))
    }

    func moreApps(_ developerID: String) {
        openExternal(
            Self.storeURL(scheme: "itms-apps", path: "/developer/id\(developerID)"),
            fallback: Self.storeURL(scheme: "https", path: "/developer/id\(developerID)"))
    }

    func openTelegramChannel(_ channel: String) {
        var app = URLComponents()
        app.scheme = "tg"
        app.host = "resolve"
        app.queryItems = [URLQueryItem(name: "domain", value: channel)]
        openExternal(app.url, fallback: Self.webURL(host: "t.me", path: "/\(channel)"))
    }

    func openVKGroup(_ groupID: String) {
        openExternal(
            Self.webURL(scheme: "vk", host: "vk.com", path: "/club\(groupID)"),
            fallback: Self.webURL(host: "vk.com", path: "/club\(groupID)"))
    }

    /// Opens the app link, or the web link when the app is not installed. No Info.plist query schemes are needed.
    func openExternal(_ primary: URL?, fallback: URL?) {
        guard let target = primary ?? fallback else { return }
        cancelPendingStoreProduct()
        let open = openURL
        Task { @MainActor in
            if await open(target) { return }
            if let fallback, fallback != target { _ = await open(fallback) }
        }
    }

    private static func storeURL(scheme: String, path: String, query: [URLQueryItem]? = nil) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = scheme == "https" ? "apps.apple.com" : "itunes.apple.com"
        components.path = path
        components.queryItems = query
        return components.url
    }

    /// Builds a URL from an unescaped path, so configured IDs with spaces or slashes cannot break it.
    private static func webURL(scheme: String = "https", host: String, path: String) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = path
        return components.url
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
