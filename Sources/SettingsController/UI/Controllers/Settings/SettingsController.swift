import UIKit

public final class SettingsController: UITableViewController {
    @discardableResult
    @MainActor
    public static func present(configuration: SettingsConfiguration, from fromVC: UIViewController) -> SettingsController {
        let settings = SettingsController(configuration: configuration)
        let root = makePresentation(for: settings)
        root.modalPresentationStyle = .fullScreen
        fromVC.present(root, animated: true)
        return settings
    }

    @MainActor
    public static func getSplitPresentationSettingsController(configuration: SettingsConfiguration) -> UIViewController {
        makePresentation(for: SettingsController(configuration: configuration))
    }

    private static func makePresentation(for settings: SettingsController) -> SplitController {
        let root = SplitController.makeDefault(for: UINavigationController(rootViewController: settings))
        settings.presentationRoot = root
        root.onWillPresent = { [weak settings] in settings?.beginPresentation() }
        root.onWillDismiss = { [weak settings] in settings?.cancelOperations() }
        root.onDidDismiss = { [weak settings] in settings?.reportDismissal() }
        return root
    }

    let configuration: SettingsConfiguration
    // Original definitions remain in configuration. These arrays are a rendered projection.
    var sections: [SettingsSection] = []
    var visibleSectionIDs: [Int] = []
    var catalogStates: [Int: AppCatalogState] = [:]
    var catalogRequests: [Int: CancellableRequest] = [:]
    var appLoadTasks: [Int: Task<Void, Never>] { catalogRequests.compactMapValues(\.task) }
    var premiumColorOverride: UIColor?
    var isPremium: Bool
    var currentUser: UserInfo?
    var currentMailInfo: SettingsMailInfo?
    var needsStateRefresh = true
    let stateRefresh = CancellableRequest()
    var stateRefreshTask: Task<Void, Never>? { stateRefresh.task }
    let storeProduct = CancellableRequest()
    var storeProductTask: Task<Void, Never>? { storeProduct.task }
    var languageSettingsTask: Task<Void, Never>?
    var openURL: OpenURLOperation = SystemActions.openURL
    var loadStoreProduct: @MainActor (Int) async throws -> UIViewController? = StoreProductLoader.load
    var fetchApps: @Sendable (String, Int, String?) async throws -> [AppItem] = {
        try await AppStoreAppsLoader.fetch(developerId: $0, limit: $1, excludeAppID: $2)
    }
    /// Synchronous lookups of the default loader's memory cache. Tests that inject `fetchApps` never fill it.
    var cachedCatalog: (String, Int, String?) -> [AppItem]? = {
        AppStoreAppsLoader.cachedApps(developerId: $0, limit: $1, excludeAppID: $2)
    }
    var lastKnownCatalogCount: (String, Int, String?) -> Int? = {
        AppStoreAppsLoader.lastKnownCount(developerId: $0, limit: $1, excludeAppID: $2)
    }
    weak var activeAboutController: AboutAppController?
    weak var presentationRoot: UIViewController?
    private var didReportDismissal = false
    private var finishingModal = false
    var didShowAppOverlay = false
    var overlayFrame: CGRect?
    var selectionBeforeTap: IndexPath?
    private var lastOverlayGeometry: OverlayGeometry?
    var baseBottomInset: CGFloat { configuration.insets?.bottom ?? 0 }

    private lazy var closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeAction(_:)))

    public init(configuration: SettingsConfiguration) {
        self.configuration = configuration
        self.isPremium = Self.initialPremium(in: configuration.sections)
        super.init(style: .insetGrouped)
        for (id, section) in configuration.sections.enumerated() {
            if case .ourApps(_, let limit, _) = section.kind {
                if limit <= 0 {
                    catalogStates[id] = .empty
                } else if let apps = cachedApps(section.kind) {
                    catalogStates[id] = apps.isEmpty ? .empty : .loaded(apps)
                } else {
                    catalogStates[id] = .loading
                }
            }
        }
        rebuildSections(reload: false)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        languageSettingsTask?.cancel()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = configuration.title
        tableView.register(SettingsCell.self)
        tableView.register(UserCell.self)
        tableView.register(AppCell.self)
        tableView.register(PremiumCell.self)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = SettingsMetrics.estimatedRowHeight
        tableView.separatorInset.left = SettingsMetrics.separatorInset
        tableView.contentInset.top = configuration.insets?.top ?? 0
        tableView.contentInset.bottom = baseBottomInset
        navigationItem.largeTitleDisplayMode = .automatic
        navigationController?.navigationBar.prefersLargeTitles = true
        clearsSelectionOnViewWillAppear = true
        observeTextSizeChanges()
        resumeCatalogLoads()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if presentationRoot?.presentingViewController != nil || navigationController?.presentingViewController != nil {
            navigationItem.rightBarButtonItem = closeButton
        }
        if presentationRoot == nil && (isBeingPresented || navigationController?.isBeingPresented == true) {
            beginPresentation()
        }
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        finishingModal = false
        if needsStateRefresh {
            needsStateRefresh = false
            _ = startStateRefresh()
        }
        resumeCatalogLoads()
        displayAppOverlayIfNeeded()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismissAppOverlayIfNeeded()
        if settingsIsLeavingHierarchy {
            finishingModal = isBeingDismissed || navigationController?.isBeingDismissed == true
            cancelOperations()
        }
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if finishingModal { reportDismissal() }
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // The table is this controller's view, so this runs on every scroll frame.
        // The overlay inset only depends on geometry, not on the scroll offset.
        let geometry = overlayGeometry
        guard geometry != lastOverlayGeometry else { return }
        lastOverlayGeometry = geometry
        updateOverlayInset()
    }

    private var overlayGeometry: OverlayGeometry {
        OverlayGeometry(
            overlayFrame: overlayFrame, tableSize: tableView.bounds.size,
            tableOrigin: view.window.flatMap { window in tableView.superview?.convert(tableView.frame.origin, to: window) },
            adjustedBottom: tableView.adjustedContentInset.bottom - tableView.contentInset.bottom)
    }

    func cancelOperations() {
        stateRefresh.cancel()
        cancelPendingStoreProduct()
        languageSettingsTask?.cancel()
        languageSettingsTask = nil
        for request in catalogRequests.values { request.cancel() }
        needsStateRefresh = true
        activeAboutController?.cancelRequests()
    }

    func beginPresentation() {
        didReportDismissal = false
        needsStateRefresh = true
        didShowAppOverlay = false
    }

    func reportDismissal() {
        guard !didReportDismissal else { return }
        didReportDismissal = true
        cancelOperations()
        configuration.eventHandler?.settingsDidDismiss()
    }

    func rebuildSections(reload: Bool = true, changedSectionIDs: Set<Int>? = nil, reconfiguredRows: [IndexPath] = []) {
        let oldIDs = visibleSectionIDs
        let rendered = SettingsSectionRenderer.render(
            configuration.sections,
            state: SettingsRenderState(
                catalogStates: catalogStates, isPremium: isPremium, premiumColorOverride: premiumColorOverride,
                currentUser: currentUser, placeholderCount: { [self] in placeholderCount($0) }))
        let result = rendered.sections
        let ids = rendered.ids
        guard reload, isViewLoaded, tableView.window != nil, let changedSectionIDs else {
            sections = result
            visibleSectionIDs = ids
            // An offscreen table may not have acquired its initial row counts yet.
            // Synchronize it without issuing batch operations against unknown counts.
            if reload, isViewLoaded { tableView.reloadData() }
            return
        }
        let deleted = IndexSet(oldIDs.indices.filter { !ids.contains(oldIDs[$0]) })
        let inserted = IndexSet(ids.indices.filter { !oldIDs.contains(ids[$0]) })
        let replaced = IndexSet(oldIDs.indices.filter { ids.contains(oldIDs[$0]) && changedSectionIDs.contains(oldIDs[$0]) })
        UIView.performWithoutAnimation {
            if !deleted.isEmpty || !inserted.isEmpty || !replaced.isEmpty {
                tableView.performBatchUpdates {
                    sections = result
                    visibleSectionIDs = ids
                    tableView.deleteSections(deleted, with: .none)
                    tableView.insertSections(inserted, with: .none)
                    tableView.reloadSections(replaced, with: .none)
                }
            } else {
                sections = result
                visibleSectionIDs = ids
            }
            if !reconfiguredRows.isEmpty { tableView.reconfigureRows(at: reconfiguredRows) }
        }
    }

    /// Updates premium gradients and CTA tint after a host-owned appearance change.
    /// Reconfigures visible cards only and keeps the color for later state refreshes.
    public func updatePremiumColor(_ color: UIColor) {
        guard premiumColorOverride?.isEqual(color) != true else { return }
        premiumColorOverride = color
        rebuildSections(reload: false)
        guard isViewLoaded else { return }
        // An active entitlement renders the card as a premium row whose icon uses the same color.
        reconfigureVisiblePremiumRows(includingActiveRows: true)
    }

    func reconfigureVisiblePremiumRows(includingActiveRows: Bool) {
        let rows = (tableView.indexPathsForVisibleRows ?? []).filter { path in
            switch sections[path.section].kind {
            case .premiumCard: return true
            case .rows(let items):
                guard includingActiveRows, items.indices.contains(path.row), case .defaultRow(.premium) = items[path.row] else {
                    return false
                }
                return true
            case .ourApps: return false
            }
        }
        if !rows.isEmpty {
            UIView.performWithoutAnimation { tableView.reconfigureRows(at: rows) }
        }
    }

    /// Text size and Bold Text change the card's measured size; re-measure the visible card.
    private func observeTextSizeChanges() {
        if #available(iOS 17, *) {
            registerForTraitChanges([UITraitPreferredContentSizeCategory.self, UITraitLegibilityWeight.self]) {
                (controller: SettingsController, _: UITraitCollection) in
                controller.reconfigureVisiblePremiumRows(includingActiveRows: false)
            }
        }
    }

    @available(iOS, introduced: 8, deprecated: 17)
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #unavailable(iOS 17), isViewLoaded,
            previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory
                || previousTraitCollection?.legibilityWeight != traitCollection.legibilityWeight
        {
            reconfigureVisiblePremiumRows(includingActiveRows: false)
        }
    }

    private func resumeCatalogLoads() {
        for (id, state) in catalogStates where state == .loading && appLoadTasks[id] == nil {
            loadOurApps(for: id)
        }
    }

    func loadOurApps(for id: Int) {
        guard configuration.sections.indices.contains(id),
            case .ourApps(let developer, let limit, let excluded) = configuration.sections[id].kind,
            limit > 0
        else { return }
        let request = catalogRequests[id] ?? CancellableRequest()
        catalogRequests[id] = request
        let wasLoading = catalogStates[id] == .loading
        catalogStates[id] = .loading
        if !wasLoading { rebuildSections(changedSectionIDs: [id]) }
        let fetch = fetchApps
        request.start { [weak self] token in
            do {
                let apps = try await fetch(developer, limit, excluded)
                guard token.isCurrent else { return }
                self?.finishCatalogLoad(apps.isEmpty ? .empty : .loaded(apps), id: id, token: token)
            } catch {
                guard token.isCurrent, !(error is CancellationError), (error as? URLError)?.code != .cancelled else { return }
                self?.finishCatalogLoad(.failed, id: id, token: token)
            }
        }
    }

    private func finishCatalogLoad(_ state: AppCatalogState, id: Int, token: CancellableRequest.Token) {
        guard token.finish() else { return }
        catalogStates[id] = state
        rebuildSections(changedSectionIDs: [id])
    }

    private func cachedApps(_ kind: SettingsSectionKind) -> [AppItem]? {
        guard case .ourApps(let developer, let limit, let excluded) = kind else { return nil }
        return cachedCatalog(developer, limit, excluded)
    }

    private func placeholderCount(_ kind: SettingsSectionKind) -> Int? {
        guard case .ourApps(let developer, let limit, let excluded) = kind else { return nil }
        return lastKnownCatalogCount(developer, limit, excluded)
    }

    private static func initialPremium(in sections: [SettingsSection]) -> Bool {
        for section in sections {
            switch section.kind {
            case .premiumCard(let card): return card.premium.isPremium
            case .rows(let rows):
                for row in rows {
                    if case .defaultRow(.premium(let payload)) = row { return payload.isPremium }
                }
            case .ourApps: break
            }
        }
        return false
    }

    public override var preferredStatusBarStyle: UIStatusBarStyle { .default }
}

struct OverlayGeometry: Equatable {
    let overlayFrame: CGRect?
    let tableSize: CGSize
    let tableOrigin: CGPoint?
    let adjustedBottom: CGFloat
}
