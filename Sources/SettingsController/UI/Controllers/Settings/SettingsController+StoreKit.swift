import StoreKit
import UIKit

extension SettingsController {
    /// Only navigation intent is revoked; catalog/image/state requests are independent.
    func cancelPendingStoreProduct() {
        storeProduct.cancel()
        setOpeningStoreApp(nil)
    }

    func openApp(_ id: Int, url: URL) {
        // A second tap on the app whose page is loading must not restart the request.
        guard !(storeProduct.isRunning && openingStoreAppID == id) else { return }
        let load = loadStoreProduct
        let open = openURL
        setOpeningStoreApp(id)
        storeProduct.start { [weak self] token in
            defer { if token.finish() { self?.setOpeningStoreApp(nil) } }
            let destination: UIViewController?
            do {
                destination = try await load(id)
            } catch {
                guard token.isCurrent, !(error is CancellationError), (error as? URLError)?.code != .cancelled else { return }
                destination = nil
            }
            guard token.isCurrent, self?.settingsCanPresent == true else { return }
            if let destination {
                #if !os(visionOS)
                (destination as? SKStoreProductViewController)?.delegate = self
                #endif
                self?.present(destination, animated: true)
            } else {
                _ = await open(url)
            }
        }
    }

    func redeemCode() {
        cancelPendingStoreProduct()
        if #available(iOS 16.0, *), let scene = view.window?.windowScene {
            Task { try? await AppStore.presentOfferCodeRedeemSheet(in: scene) }
        } else {
            SKPaymentQueue.default().presentCodeRedemptionSheet()
        }
    }

    /// Shows progress on the row of the app whose App Store page is loading.
    private func setOpeningStoreApp(_ id: Int?) {
        guard openingStoreAppID != id else { return }
        let changed = [openingStoreAppID, id].compactMap { $0 }
        openingStoreAppID = id
        guard isViewLoaded else { return }
        let rows = visibleSectionIDs.flatMap { section in changed.map { SettingsRowID(section: section, kind: .app($0)) } }
        reconfigure(Set(rows))
    }

    func displayAppOverlayIfNeeded() {
        guard !didShowAppOverlay, let appID = configuration.overlayAppID,
            let scene = view.window?.windowScene
        else { return }
        let position: SKOverlay.Position = tabBarController == nil ? .bottom : .bottomRaised
        let overlay = SKOverlay(configuration: SKOverlay.AppConfiguration(appIdentifier: appID, position: position))
        overlay.delegate = self
        overlay.present(in: scene)
        didShowAppOverlay = true
    }

    func dismissAppOverlayIfNeeded() {
        if let scene = view.window?.windowScene { SKOverlay.dismiss(in: scene) }
        overlayFrame = nil
        updateOverlayInset()
    }

    func updateOverlayInset() {
        guard isViewLoaded else { return }
        var extra: CGFloat = 0
        if let frame = overlayFrame, let window = view.window, let scene = window.windowScene {
            let frameInWindow = window.convert(frame, from: scene.coordinateSpace)
            let intersection = tableView.bounds.intersection(tableView.convert(frameInWindow, from: window))
            if !intersection.isNull, !intersection.isEmpty {
                let automaticInset = max(0, tableView.adjustedContentInset.bottom - tableView.contentInset.bottom)
                extra = max(0, tableView.bounds.maxY - intersection.minY - automaticInset)
            }
        }
        let bottom = baseBottomInset + extra
        if abs(tableView.contentInset.bottom - bottom) > 0.5 {
            tableView.contentInset.bottom = bottom
            tableView.verticalScrollIndicatorInsets.bottom = bottom
        }
    }
}

extension SettingsController: @preconcurrency SKOverlayDelegate {
    public func storeOverlayDidFinishPresentation(_ overlay: SKOverlay, transitionContext: SKOverlay.TransitionContext) {
        #if !os(visionOS)
        overlayFrame = transitionContext.endFrame
        updateOverlayInset()
        #endif
    }

    public func storeOverlayDidFinishDismissal(_ overlay: SKOverlay, transitionContext: SKOverlay.TransitionContext) {
        overlayFrame = nil
        updateOverlayInset()
    }
}

#if !os(visionOS)
extension SettingsController: @preconcurrency SKStoreProductViewControllerDelegate {
    public func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.dismiss(animated: true)
    }
}
#endif
