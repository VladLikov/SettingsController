import UIKit
import SwiftUI
import SettingsController

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Example", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: scene)
        window.rootViewController = DashboardController()
        if ProcessInfo.processInfo.arguments.contains("-demo-dark") { window.overrideUserInterfaceStyle = .dark }
        if ProcessInfo.processInfo.arguments.contains("-demo-rtl") { window.semanticContentAttribute = .forceRightToLeft }
        self.window = window
        window.makeKeyAndVisible()
    }
}

/// Stored strongly by the dashboard and explicit configuration; never retains settings.
@MainActor
final class DemoStore: SettingsControllerDelegate {
    weak var settings: SettingsController?
    var premium = false
    var name = "Demo User"
    var userID: String? = "demo-user-123"
    let theme = DemoTheme()

    func settingsCurrentUserInfo() async -> UserInfo? { UserInfo(name: name, avatar: nil) }
    func settingsIsPremiumActive() async -> Bool { premium }
    func settingsMailInfo() async -> SettingsMailInfo? {
        SettingsMailInfo(userID: userID, productID: premium ? "demo.annual" : nil, isPremium: premium)
    }
    func settingsDidDismiss() { settings = nil }
    func settingsDidUpdateTheme(_ theme: ThemeStorage) { settings?.view.window?.tintColor = theme.appColor }
    func settingsDidUpdateTaptic(_ taptic: TapticStorage) {}

    func logout() async {
        name = "Guest"
        userID = nil
        premium = false
        await settings?.refreshState()
    }

    func configuration() -> SettingsConfiguration {
        let premium = PremiumPayload(isPremium: premium, color: .systemIndigo, destinationFactory: { [self] in
            UINavigationController(rootViewController: PaywallController(store: self))
        })
        return SettingsConfiguration(title: "Settings", sections: [
            SettingsSection(kind: .rows([.defaultRow(.user(name, destinationFactory: { [self] in ProfileController(store: self) }))])),
            SettingsSection(kind: .premiumCard(PremiumCardPayload(image: Image(systemName: "star.fill"), title: "Premium",
                subtitle: "All example features", buttonTitle: "Continue", premium: premium))),
            SettingsSection(title: "Preferences", kind: .rows([
                .defaultRow(.language),
                .defaultRow(.appearance(theme: theme)),
                .row(SettingsRow(title: "Injected destination", icon: SettingsIcon(image: UIImage(systemName: "shippingbox"), color: .systemGreen),
                    destinationFactory: { [self] in ProfileController(store: self) }))
            ])),
            SettingsSection(title: "Support", kind: .rows([
                .defaultRow(.contactDeveloper(email: "support@example.com")),
                .defaultRow(.about(appID: "6746766591", privacyURL: URL(string: "https://example.com/privacy")!, termsURL: URL(string: "https://example.com/terms")!)),
                .row(SettingsRow(title: "Standalone mail", icon: SettingsIcon(image: UIImage(systemName: "envelope"), color: .systemBlue), action: { [self] _, _, presenter in
                    // Standalone MailController holds its provider weakly; the dashboard retains DemoStore.
                    let mail = MailController(type: .custom(placeholder: "Message", minCharactersCount: 1, navigationTitle: "Contact", subject: "Example"), email: "support@example.com", dataProvider: self)
                    presenter.present(UINavigationController(rootViewController: mail), animated: true)
                }))
            ]))
        ], eventHandler: self, dataProvider: self)
    }
}

final class DemoTheme: ThemeStorage {
    var appColor: UIColor = .systemIndigo
    var appColorRawValue = AppColor.allCases.first!.rawValue
    var autoTheme = true
    var interfaceStyle = UIUserInterfaceStyle.light.rawValue
}

@MainActor
final class DashboardController: UIViewController {
    private let store = DemoStore()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let stack = makeStack(in: view)
        stack.addArrangedSubview(makeButton("Open full screen", id: "open-fullscreen") { [weak self] in self?.open(sheet: false) })
        stack.addArrangedSubview(makeButton("Open sheet", id: "open-sheet") { [weak self] in self?.open(sheet: true) })
        // Compile public models and cells through an ordinary import, not @testable.
        _ = AppItem(id: 1, name: "Example", iconURL: URL(string: "https://example.com/icon.png")!, storeURL: URL(string: "https://apps.apple.com/app/id1")!)
        _ = SettingsCell(style: .default, reuseIdentifier: nil)
        _ = SwitchCell(style: .default, reuseIdentifier: nil)
        _ = MailCell(style: .default, reuseIdentifier: nil)
    }

    private func open(sheet: Bool) {
        if sheet {
            let root = SettingsController.getSplitPresentationSettingsController(configuration: store.configuration())
            store.settings = findSettings(in: root)
            root.modalPresentationStyle = .pageSheet
            present(root, animated: true)
        } else {
            store.settings = SettingsController.present(configuration: store.configuration(), from: self)
        }
    }

    private func findSettings(in controller: UIViewController) -> SettingsController? {
        if let settings = controller as? SettingsController { return settings }
        for child in controller.children {
            if let settings = findSettings(in: child) { return settings }
        }
        return nil
    }
}

@MainActor
final class ProfileController: UIViewController {
    let store: DemoStore
    init(store: DemoStore) { self.store = store; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("Unused") }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Profile"
        view.backgroundColor = .systemBackground
        let stack = makeStack(in: view)
        stack.addArrangedSubview(makeButton("Rename to Updated User", id: "rename") { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                store.name = "Updated User"
                await store.settings?.refreshState()
                returnToSettingsIfCompact()
            }
        })
        stack.addArrangedSubview(makeButton("Log out", id: "logout") { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                await store.logout()
                returnToSettingsIfCompact()
            }
        })
    }
    private func returnToSettingsIfCompact() {
        if splitViewController?.isCollapsed != false { navigationController?.popViewController(animated: true) }
    }
}

@MainActor
final class PaywallController: UIViewController {
    let store: DemoStore
    init(store: DemoStore) { self.store = store; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("Unused") }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Demo purchase"
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(close))
        let stack = makeStack(in: view)
        stack.addArrangedSubview(makeButton("Simulate purchase", id: "buy") { [weak self] in self?.activate() })
        stack.addArrangedSubview(makeButton("Simulate restore", id: "restore") { [weak self] in self?.activate() })
    }
    private func activate() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            store.premium = true
            await store.settings?.refreshState()
            dismiss(animated: true)
        }
    }
    @objc private func close() { dismiss(animated: true) }
}

@MainActor
private func makeButton(_ title: String, id: String, action: @escaping @MainActor () -> Void) -> UIButton {
    let button = UIButton(type: .system)
    button.setTitle(title, for: .normal)
    button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
    button.titleLabel?.adjustsFontForContentSizeCategory = true
    button.titleLabel?.numberOfLines = 0
    button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
    button.accessibilityIdentifier = id
    button.addAction(UIAction { _ in action() }, for: .touchUpInside)
    return button
}

@MainActor
private func makeStack(in view: UIView) -> UIStackView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 20
    stack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stack)
    NSLayoutConstraint.activate([
        stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
        stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
        stack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
    ])
    return stack
}
