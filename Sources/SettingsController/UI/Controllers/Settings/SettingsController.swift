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
    var catalogLifetimes: [Int: RequestLifetime] = [:]
    var appLoadTasks: [Int: Task<Void, Never>] = [:]
    var isPremium: Bool
    var currentUser: UserInfo?
    var currentMailInfo: SettingsMailInfo?
    var needsStateRefresh = true
    var stateRefreshTask: Task<Void, Never>?
    let stateLifetime = RequestLifetime()
    var storeProductTask: Task<Void, Never>?
    let storeLifetime = RequestLifetime()
    var languageSettingsTask: Task<Void, Never>?
    var openURL: OpenURLOperation = SystemActions.openURL
    var loadStoreProduct: @MainActor (Int) async throws -> UIViewController? = StoreProductLoader.load
    var fetchApps: @Sendable (String, Int, String?) async throws -> [AppItem] = {
        try await AppStoreAppsLoader.fetch(developerId: $0, limit: $1, excludeAppID: $2)
    }
    weak var activeAboutController: AboutAppController?
    weak var presentationRoot: UIViewController?
    private var didReportDismissal = false
    private var finishingModal = false
    var overlayAppViewDidShown = false
    var overlayFrame: CGRect?
    var baseBottomInset: CGFloat { configuration.insets?.bottom ?? 0 }

    private lazy var closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeAction(_:)))

    public init(configuration: SettingsConfiguration) {
        self.configuration = configuration
        self.isPremium = Self.initialPremium(in: configuration.sections)
        super.init(style: .insetGrouped)
        for (id, section) in configuration.sections.enumerated() {
            if case .ourApps(_, let limit, _) = section.kind {
                catalogStates[id] = limit > 0 ? .loading : .empty
            }
        }
        rebuildSections(reload: false)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit {
        appLoadTasks.values.forEach { $0.cancel() }
        stateRefreshTask?.cancel()
        storeProductTask?.cancel()
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
        tableView.estimatedRowHeight = defaultRowEstimatedHeight
        tableView.separatorInset.left = 63
        tableView.contentInset.top = configuration.insets?.top ?? 0
        tableView.contentInset.bottom = baseBottomInset
        navigationItem.largeTitleDisplayMode = .automatic
        navigationController?.navigationBar.prefersLargeTitles = true
        clearsSelectionOnViewWillAppear = true
        resumeCatalogLoads()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if presentationRoot == nil && (isBeingPresented || navigationController?.isBeingPresented == true) {
            beginPresentation()
        }
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        finishingModal = false
        if presentationRoot?.presentingViewController != nil || navigationController?.presentingViewController != nil {
            navigationItem.rightBarButtonItem = closeButton
        }
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
        updateOverlayInset()
    }

    func cancelOperations() {
        stateLifetime.invalidate()
        storeLifetime.invalidate()
        catalogLifetimes.values.forEach { $0.invalidate() }
        stateRefreshTask?.cancel()
        stateRefreshTask = nil
        storeProductTask?.cancel()
        storeProductTask = nil
        languageSettingsTask?.cancel()
        languageSettingsTask = nil
        appLoadTasks.values.forEach { $0.cancel() }
        appLoadTasks.removeAll()
        needsStateRefresh = true
        activeAboutController?.cancelRequests()
    }

    func beginPresentation() {
        didReportDismissal = false
        needsStateRefresh = true
        overlayAppViewDidShown = false
    }

    func reportDismissal() {
        guard !didReportDismissal else { return }
        didReportDismissal = true
        cancelOperations()
        configuration.eventHandler?.settingsDidDismiss()
    }

    func rebuildSections(reload: Bool = true) {
        var result: [SettingsSection] = []
        var ids: [Int] = []
        for (id, definition) in configuration.sections.enumerated() {
            var section = definition
            switch definition.kind {
            case .ourApps(_, let limit, _):
                switch catalogStates[id] ?? (limit > 0 ? .loading : .empty) {
                case .empty: continue
                case .loading:
                    guard limit > 0 else { continue }
                    section.kind = .rows(Array(repeating: .app(.placeholder), count: limit))
                case .loaded(let apps):
                    guard !apps.isEmpty else { continue }
                    section.kind = .rows(apps.map { .app(.loaded($0)) })
                case .failed: section.kind = .rows([.app(.failed)])
                }
            case .premiumCard(let card):
                if isPremium {
                    section.kind = .rows([.defaultRow(.premium(card.premium.withPremiumStatus(true)))])
                }
            case .rows(let rows):
                section.kind = .rows(rows.map { row in
                    switch row {
                    case .defaultRow(.premium(let payload)):
                        return .defaultRow(.premium(payload.withPremiumStatus(isPremium)))
                    case .defaultRow(.user(_, _, let type)):
                        guard let user = currentUser else { return row }
                        return .defaultRow(.user(user.name, user.avatar, type))
                    case .defaultRow(.userFactory(_, _, let factory)):
                        guard let user = currentUser else { return row }
                        return .defaultRow(.userFactory(user.name, user.avatar, factory))
                    default: return row
                    }
                })
            }
            result.append(section)
            ids.append(id)
        }
        sections = result
        visibleSectionIDs = ids
        if reload, isViewLoaded { tableView.reloadData() }
    }

    private func resumeCatalogLoads() {
        for (id, state) in catalogStates where state == .loading && appLoadTasks[id] == nil {
            loadOurApps(for: id)
        }
    }

    func loadOurApps(for id: Int) {
        guard configuration.sections.indices.contains(id),
              case let .ourApps(developer, limit, excluded) = configuration.sections[id].kind,
              limit > 0 else { return }
        let lifetime = catalogLifetimes[id] ?? RequestLifetime()
        catalogLifetimes[id] = lifetime
        let request = lifetime.begin()
        appLoadTasks[id]?.cancel()
        catalogStates[id] = .loading
        rebuildSections()
        let fetch = fetchApps
        appLoadTasks[id] = Task { @MainActor [weak self] in
            defer { if lifetime.finish(request) { self?.appLoadTasks[id] = nil } }
            do {
                let apps = try await fetch(developer, limit, excluded)
                guard !Task.isCancelled, lifetime.isCurrent(request) else { return }
                self?.finishCatalogLoad(apps.isEmpty ? .empty : .loaded(apps), id: id, request: request)
            } catch {
                guard !Task.isCancelled, !(error is CancellationError), (error as? URLError)?.code != .cancelled,
                      lifetime.isCurrent(request) else { return }
                self?.finishCatalogLoad(.failed, id: id, request: request)
            }
        }
    }

    private func finishCatalogLoad(_ state: AppCatalogState, id: Int, request: UUID) {
        guard catalogLifetimes[id]?.finish(request) == true else { return }
        appLoadTasks[id] = nil
        catalogStates[id] = state
        rebuildSections()
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
