import StoreKit
import UIKit

@MainActor
enum StoreProductLoader {
    static func load(_ id: Int) async throws -> UIViewController? {
#if !os(visionOS)
        let controller = SKStoreProductViewController()
        let loaded = try await controller.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: id])
        try Task.checkCancellation()
        return loaded ? controller : nil
#else
        return nil
#endif
    }
}

extension SettingsController {
    func openApp(_ id: Int, url: URL) {
        let lifetime = storeLifetime
        let request = lifetime.begin()
        storeProductTask?.cancel()
        let load = loadStoreProduct
        let open = openURL
        storeProductTask = Task { @MainActor [weak self] in
            defer { if lifetime.finish(request) { self?.storeProductTask = nil } }
            let destination: UIViewController?
            do {
                destination = try await load(id)
            } catch {
                guard !Task.isCancelled, !(error is CancellationError),
                      (error as? URLError)?.code != .cancelled,
                      lifetime.isCurrent(request) else { return }
                destination = nil
            }
            guard !Task.isCancelled, lifetime.isCurrent(request), self?.settingsCanPresent == true else {
                return
            }
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
        SKPaymentQueue.default().presentCodeRedemptionSheet()
    }

    func displayAppOverlayIfNeeded() {
        guard !overlayAppViewDidShown, let appID = configuration.overlayAppID,
              let scene = view.window?.windowScene else { return }
        let position: SKOverlay.Position = tabBarController == nil ? .bottom : .bottomRaised
        let overlay = SKOverlay(configuration: SKOverlay.AppConfiguration(appIdentifier: appID, position: position))
        overlay.delegate = self
        overlay.present(in: scene)
        overlayAppViewDidShown = true
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
