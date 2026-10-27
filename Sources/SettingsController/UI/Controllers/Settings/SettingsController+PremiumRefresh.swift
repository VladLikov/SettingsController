import UIKit

extension SettingsController {
    var cachedPremiumStatus: Bool { isPremium }

    /// Call after purchases, restores, account changes and profile edits, including on iPad.
    /// Cancelling the caller also cancels its request. The latest refresh wins.
    @MainActor
    public func refreshState() async {
        guard !Task.isCancelled, let task = startStateRefresh() else { return }
        await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
    }

    @discardableResult
    func startStateRefresh() -> Task<Void, Never>? {
        let wantsUser = configuration.sections.contains { section in
            guard case .rows(let rows) = section.kind else { return false }
            return rows.contains { row in
                switch row {
                case .defaultRow(.user), .defaultRow(.userFactory): return true
                default: return false
                }
            }
        }
        let wantsAccount = activeAboutController != nil || configuration.sections.contains { section in
            switch section.kind {
            case .premiumCard: return true
            case .rows(let rows):
                return rows.contains { if case .defaultRow(.premium) = $0 { return true }; return false }
            case .ourApps: return false
            }
        }
        guard let provider = configuration.dataProvider, wantsUser || wantsAccount else { return nil }
        if wantsAccount { activeAboutController?.cancelAccountRequest() }
        let lifetime = stateLifetime
        let request = lifetime.begin()
        stateRefreshTask?.cancel()
        let fallback = isPremium
        let task = Task { @MainActor [weak self] in
            defer { if lifetime.finish(request) { self?.stateRefreshTask = nil } }
            let context: (info: SettingsMailInfo?, isPremium: Bool?)
            if wantsAccount {
                context = await MailInfoResolver.resolve(provider: provider, fallbackPremium: fallback)
            } else {
                context = (nil, nil)
            }
            guard !Task.isCancelled, lifetime.isCurrent(request) else { return }
            let user = wantsUser ? await provider.settingsCurrentUserInfo() : nil
            guard !Task.isCancelled, lifetime.isCurrent(request) else { return }
            self?.applyResolvedState(info: context.info, premium: context.isPremium, user: user, includesAccount: wantsAccount)
        }
        stateRefreshTask = task
        return task
    }

    func applyResolvedState(info: SettingsMailInfo?, premium: Bool?, user: UserInfo?, includesAccount: Bool) {
        var changed = false
        if includesAccount {
            currentMailInfo = info // nil must clear a previous account ID.
            if let premium, premium != isPremium { isPremium = premium; changed = true }
            activeAboutController?.acceptAccountInfo(info, premium: isPremium)
        }
        // nil means "no new snapshot". A guest UserInfo explicitly represents logout.
        if let user, currentUser?.name != user.name || currentUser?.avatar !== user.avatar {
            currentUser = user
            changed = true
        }
        if changed { rebuildSections() }
    }

    func pushAboutController(appID: String, privacyURL: URL, termsURL: URL, navigationTitle: String?) {
        // The destination starts the newer account request; an older root refresh
        // must not overwrite it when it completes out of order.
        stateLifetime.invalidate()
        stateRefreshTask?.cancel()
        stateRefreshTask = nil
        needsStateRefresh = true
        let controller = AboutAppController(isPremium: isPremium, userID: currentMailInfo?.userID,
                                            appID: appID, privacyURL: privacyURL, termsURL: termsURL)
        controller.dataProvider = configuration.dataProvider
        controller.openURL = openURL
        controller.onAccountUpdate = { [weak self] info, premium in
            self?.applyResolvedState(info: info, premium: premium, user: nil, includesAccount: true)
        }
        activeAboutController = controller
        // Navigate first; the destination owns its cancellable account request.
        pushViewController(controller, navigationTitle: navigationTitle)
    }
}
