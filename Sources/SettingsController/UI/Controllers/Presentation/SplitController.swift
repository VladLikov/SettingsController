import UIKit

final class SplitPlaceholderController: UIViewController {
    override func loadView() {
        view = EmptyStateView(
            title: NSLocalizedString("Select an item", bundle: .module, comment: "Empty iPad detail column prompt."),
            subtitle: NSLocalizedString("Additional information will appear here.", bundle: .module, comment: "Explanation in the empty iPad detail column before a settings item is selected.")
        )
    }
}

final class SplitController: UISplitViewController, UISplitViewControllerDelegate {
    var onWillPresent: (@MainActor () -> Void)?
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isBeingPresented { onWillPresent?() }
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
