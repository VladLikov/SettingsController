from pathlib import Path
R=Path.cwd(); S=R/'Sources/SettingsController'
def write(p,t):
    p=R/p;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(t)
def replace(p,a,b):
    p=R/p;t=p.read_text();assert a in t,(p,a[:80]);p.write_text(t.replace(a,b))
write('Sources/SettingsController/Core/Models/Settings/SettingsDestinationFactory.swift','''import UIKit

/// Invoked lazily, once for each accepted navigation action. Return a fresh controller.
public typealias SettingsDestinationFactory = @MainActor () -> UIViewController
''')
p=S/'Core/Models/Settings/SettingsRow.swift';t=p.read_text().replace('    public let action: SettingsAction?','    public let action: SettingsAction?\n    public let destinationFactory: SettingsDestinationFactory?')
t=t.replace('        self.action = action','        self.action = action\n        self.destinationFactory = nil')
t=t[:-2]+'''
    public init(title: String, detail: String? = nil, icon: SettingsIcon,
                destinationFactory: @escaping SettingsDestinationFactory) {
        self.title = title
        self.detail = detail
        self.icon = icon
        self.destinationControllerType = nil
        self.action = nil
        self.destinationFactory = destinationFactory
    }
}
''';p.write_text(t)
p=S/'Core/Models/Premium/PremiumPayload.swift';t=p.read_text().replace('public let isPremium: Bool','public private(set) var isPremium: Bool').replace('    public let action: PremiumAction?','    public let action: PremiumAction?\n    public let destinationFactory: SettingsDestinationFactory?').replace('        self.action = action','        self.action = action\n        self.destinationFactory = nil')
t=t.rstrip()[:-1]+'''
    public init(isPremium: Bool, color: UIColor,
                destinationFactory: @escaping SettingsDestinationFactory) {
        self.isPremium = isPremium
        self.color = color
        self.destinationControllerType = nil
        self.action = nil
        self.destinationFactory = destinationFactory
    }

    func withPremiumStatus(_ value: Bool) -> Self {
        var result = self
        result.isPremium = value
        return result
    }
}
''';p.write_text(t)
p=S/'Core/Models/Settings/SettingsRowItem.swift';t=p.read_text().replace('        case user(String, UIImage?, UIViewController.Type)','''        case user(String, UIImage?, UIViewController.Type)
        case userFactory(String, UIImage?, SettingsDestinationFactory)

        public static func user(_ name: String, _ avatar: UIImage? = nil,
                                destinationFactory: @escaping SettingsDestinationFactory) -> Self {
            .userFactory(name, avatar, destinationFactory)
        }''');p.write_text(t)
write('Sources/SettingsController/Core/Models/AppStore/AppItem.swift','''import Foundation

public struct AppItem: Sendable, Equatable {
    public let id: Int
    public let name: String
    public let iconURL: URL
    public let storeURL: URL

    public init(id: Int, name: String, iconURL: URL, storeURL: URL) {
        self.id = id
        self.name = name
        self.iconURL = iconURL
        self.storeURL = storeURL
    }
}
''')
write('Sources/SettingsController/Core/Services/AppStore/AppCatalogState.swift','''import Foundation

/// Keyed by the immutable configuration section ID, never by a visible IndexPath.
enum AppCatalogState: Equatable {
    case loading
    case loaded([AppItem])
    case empty
    case failed
}
''')
p=S/'Core/Services/AppStore/AppStoreAppsLoader.swift';t=p.read_text().replace('''        guard limit > 0 else { return [] }''','''        try await fetch(developerId: developerId, limit: limit, excludeAppID: excludeAppID, session: .shared)
    }

    static func fetch(developerId: String, limit: Int, excludeAppID: String? = nil,
                      session: URLSession) async throws -> [AppItem] {
        guard limit > 0 else { return [] }
        try Task.checkCancellation()''').replace('.returnCacheDataElseLoad','.useProtocolCachePolicy').replace('try await URLSession.shared.data(for: request)','try await session.data(for: request)\n        try Task.checkCancellation()')
t=t.replace('let storeURL = URL(string: link)','''let storeURL = URL(string: link),
                      id > 0, !name.isEmpty,
                      ["https", "http"].contains(iconURL.scheme?.lowercased() ?? ""),
                      ["https", "http"].contains(storeURL.scheme?.lowercased() ?? ""),
                      iconURL.host != nil, storeURL.host != nil''');p.write_text(t)
write('Sources/SettingsController/UI/Controllers/Settings/SettingsController.swift','''import UIKit

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
            do {
                let apps = try await fetch(developer, limit, excluded)
                guard !Task.isCancelled, lifetime.isCurrent(request) else { return }
                self?.finishCatalogLoad(apps.isEmpty ? .empty : .loaded(apps), id: id, request: request)
            } catch {
                guard !Task.isCancelled, lifetime.isCurrent(request) else { return }
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
''')
write('Sources/SettingsController/UI/Controllers/Settings/SettingsController+PremiumRefresh.swift','''import UIKit

extension SettingsController {
    var cachedPremiumStatus: Bool { isPremium }

    /// Call after purchases, restores, account changes and profile edits, including on iPad.
    /// Cancelling the caller also cancels its request. The latest refresh wins.
    @MainActor
    public func refreshState() async {
        guard let task = startStateRefresh() else { return }
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
        let lifetime = stateLifetime
        let request = lifetime.begin()
        stateRefreshTask?.cancel()
        let fallback = isPremium
        let task = Task { @MainActor [weak self] in
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
            if lifetime.finish(request) { self?.stateRefreshTask = nil }
        }
        stateRefreshTask = task
        return task
    }

    func applyResolvedState(info: SettingsMailInfo?, premium: Bool?, user: UserInfo?, includesAccount: Bool) {
        var changed = false
        if includesAccount {
            currentMailInfo = info // nil must clear a previous account ID.
            if let premium, premium != isPremium { isPremium = premium; changed = true }
            activeAboutController?.applyAccountInfo(info, premium: isPremium)
        }
        // nil means "no new snapshot". A guest UserInfo explicitly represents logout.
        if let user, currentUser?.name != user.name || currentUser?.avatar !== user.avatar {
            currentUser = user
            changed = true
        }
        if changed { rebuildSections() }
    }

    func pushAboutController(appID: String, privacyURL: URL, termsURL: URL, navigationTitle: String?) {
        let controller = AboutAppController(isPremium: isPremium, userID: currentMailInfo?.userID,
                                            appID: appID, privacyURL: privacyURL, termsURL: termsURL)
        controller.dataProvider = configuration.dataProvider
        controller.openURL = openURL
        activeAboutController = controller
        // Navigate first; the destination owns its cancellable account request.
        pushViewController(controller, navigationTitle: navigationTitle)
    }
}
''')
p=S/'UI/Controllers/Settings/SettingsController+DataSource.swift';t=p.read_text()
t=t.replace('            return limit','            return max(0, limit)')
t=t.replace('''                if case .user(let name, let image, _) = defaultRow {
                    let cell = tableView.dequeueReusableCell(withClass: UserCell.self, for: indexPath)
                    cell.configure(title: name, avatar: image)
                    return cell
                }''','''                switch defaultRow {
                case .user(let name, let image, _), .userFactory(let name, let image, _):
                    let cell = tableView.dequeueReusableCell(withClass: UserCell.self, for: indexPath)
                    cell.configure(title: name, avatar: image)
                    return cell
                default: break
                }''')
t=t.replace('cell.configure(payload: payload)', 'cell.configure(payload: payload, parent: self)')
t=t.replace('                pendingRefresh = .premium(indexPath)','                needsStateRefresh = true')
p.write_text(t)
p=S/'UI/Controllers/Settings/SettingsController+TableDelegate.swift';t=p.read_text();a=t.index('    public override func tableView(_ tableView: UITableView, heightForRowAt');b=t.index('    public override func tableView(_ tableView: UITableView, estimatedHeightForRowAt',a)
t=t[:a]+'''    public override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

'''+t[b:]
t=t.replace('''            if case .defaultRow(let row) = rows[indexPath.row], case .user = row {
                return userRowHeight
            }''','''            switch rows[indexPath.row] {
            case .defaultRow(.user), .defaultRow(.userFactory): return userRowHeight
            default: break
            }''')
t=t.replace('''            if let destinationControllerType = row.destinationControllerType {''','''            if let factory = row.destinationFactory {
                guard navigationController?.transitionCoordinator == nil else { return }
                pushViewController(factory(), navigationTitle: row.title)
            } else if let destinationControllerType = row.destinationControllerType {''')
t=t.replace('''        case .app(.loaded(let app)):
            openApp(app.id, url: app.storeURL)''','''        case .app(.loaded(let app)):
            openApp(app.id, url: app.storeURL)

        case .app(.failed):
            tableView.deselectRow(at: indexPath, animated: true)
            guard visibleSectionIDs.indices.contains(indexPath.section) else { return }
            loadOurApps(for: visibleSectionIDs[indexPath.section])''')
t=t.replace('pendingRefresh = .premium(indexPath)', 'needsStateRefresh = true').replace('pendingRefresh = .user(indexPath)', 'needsStateRefresh = true')
t=t.replace('''        case .tapticEngine(let taptic):''','''        case .userFactory(_, _, let factory):
            guard navigationController?.transitionCoordinator == nil else { return }
            needsStateRefresh = true
            pushViewController(factory(), navigationTitle: row.title)

        case .tapticEngine(let taptic):''')
p.write_text(t)
p=S/'UI/Controllers/Settings/SettingsController+Routing.swift';t=p.read_text()
a=t.index('        navigationController?.dismiss(animated: true)');b=t.index('\n    func pushViewController',a)
t=t[:a]+'''        cancelOperations()
        let root = presentationRoot ?? navigationController ?? self
        root.dismiss(animated: true) { [weak self] in self?.reportDismissal() }
    }
'''+t[b:]
a=t.index('        if UIDevice.current.userInterfaceIdiom != .phone');b=t.index('\n    func presentPremium',a)
t=t[:a]+'''        if let split = splitViewController, !split.isCollapsed {
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
'''+t[b:]
t=t.replace('        if payload.isPremium {','        if isPremium {')
a=t.index('        } else if let premiumControllerType');b=t.index('\n        } else if let action',a)
t=t[:a]+'''        } else if payload.destinationFactory != nil || payload.destinationControllerType != nil {
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
'''+t[b:]
t=t.replace('        present(UINavigationController(rootViewController: mailController), animated: true)','        mailController.openURL = openURL\n        present(UINavigationController(rootViewController: mailController), animated: true)')
t+='''
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
''';p.write_text(t)
write('Sources/SettingsController/UI/Controllers/Presentation/SplitController.swift','''import UIKit

final class SplitPlaceholderController: UIViewController {
    override func loadView() {
        view = EmptyStateView(
            title: NSLocalizedString("Select an item", bundle: .module, comment: ""),
            subtitle: NSLocalizedString("Additional information will appear here.", bundle: .module, comment: "")
        )
    }
}

final class SplitController: UISplitViewController, UISplitViewControllerDelegate {
    var onWillDismiss: (@MainActor () -> Void)?
    var onDidDismiss: (@MainActor () -> Void)?
    private var dismissingModal = false

    init() {
        super.init(nibName: nil, bundle: nil)
        delegate = self
        preferredDisplayMode = .oneBesideSecondary
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        viewControllers.first?.preferredStatusBarStyle ?? .default
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismissingModal = settingsIsLeavingHierarchy && presentingViewController != nil
        if dismissingModal { onWillDismiss?() }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if dismissingModal { onDidDismiss?() }
        dismissingModal = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        dismissingModal = false // An interactive dismissal can be cancelled.
    }

    func splitViewController(_ splitViewController: UISplitViewController,
                             collapseSecondary secondaryViewController: UIViewController,
                             onto primaryViewController: UIViewController) -> Bool {
        if let navigation = secondaryViewController as? UINavigationController {
            return navigation.viewControllers.count == 1 && navigation.viewControllers.first is SplitPlaceholderController
        }
        return secondaryViewController is SplitPlaceholderController
    }

    static func makeDefault(for primaryViewController: UIViewController) -> SplitController {
        let split = SplitController()
        split.viewControllers = [primaryViewController, UINavigationController(rootViewController: SplitPlaceholderController())]
        return split
    }
}
''')
write('Sources/SettingsController/UI/Controllers/Settings/SettingsController+StoreKit.swift','''import StoreKit
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
                if lifetime.finish(request) { self?.storeProductTask = nil }
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
            if lifetime.finish(request) { self?.storeProductTask = nil }
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
''')
