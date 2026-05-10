//
//  SettingsController+StoreKit.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import StoreKit
import UIKit

// MARK: - StoreKit

extension SettingsController {

    func openApp(_ id: Int, url: URL) {
#if !os(visionOS)
        let storeProductViewController = SKStoreProductViewController()
        storeProductTask?.cancel()
        storeProductTask = Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                let loaded = try await storeProductViewController.loadProduct(
                    withParameters: [SKStoreProductParameterITunesItemIdentifier: id]
                )
                guard loaded, !Task.isCancelled else {
                    await UIApplication.shared.open(url)
                    return
                }
                present(storeProductViewController, animated: true)
            } catch is CancellationError {
                return
            } catch {
                await UIApplication.shared.open(url)
            }
        }
#else
        UIApplication.shared.open(url)
#endif
    }

    func redeemCode() {
        SKPaymentQueue.default().presentCodeRedemptionSheet()
    }

    func displayAppOverlayIfNeeded() {
        guard !overlayAppViewDidShown else { return }

        if let overlayAppID = configuration.overlayAppID {

            guard let scene = view.window?.windowScene else { return }

            let hasTabBar = self.tabBarController != nil
            let position: SKOverlay.Position = hasTabBar ? .bottomRaised : .bottom
            
            let config = SKOverlay.AppConfiguration(appIdentifier: overlayAppID, position: position)
            let overlay = SKOverlay(configuration: config)
            overlay.delegate = self
            overlay.present(in: scene)

            overlayAppViewDidShown = true
        }
    }

    func dismissAppOverlayIfNeeded() {
        guard let scene = view.window?.windowScene else { return }
        SKOverlay.dismiss(in: scene)
    }
}

// MARK: - SKOverlayDelegate

extension SettingsController: @preconcurrency SKOverlayDelegate {

    public func storeOverlayDidFinishPresentation(
        _ overlay: SKOverlay,
        transitionContext: SKOverlay.TransitionContext
    ) {
#if !os(visionOS)
        tableView.contentInset.bottom = transitionContext.endFrame.size.height
#endif
    }

    public func storeOverlayDidFinishDismissal(
        _ overlay: SKOverlay,
        transitionContext: SKOverlay.TransitionContext
    ) {
        tableView.contentInset.bottom = 0
    }
}
