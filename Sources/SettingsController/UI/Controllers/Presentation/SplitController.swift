import UIKit

final class SplitPlaceholderController: UIViewController {
    override func loadView() {
        view = EmptyStateView(
            title: NSLocalizedString("Select an item", bundle: .module, comment: "Prompt in an empty split detail column before a settings item is selected."),
            subtitle: NSLocalizedString("Additional information will appear here.", bundle: .module, comment: "Explanation in the empty split detail column on iPad or an expanded phone before a settings item is selected.")
        )
    }
}

final class SplitController: UISplitViewController, UISplitViewControllerDelegate {
    var onWillPresent: (@MainActor () -> Void)?
    var onWillDismiss: (@MainActor () -> Void)?
    var onDidDismiss: (@MainActor () -> Void)?
    private var dismissingModal = false
    private var unfoldedColumnWidths: ColumnWidths?

    private struct ColumnWidths {
        let primaryFraction: CGFloat
        let primaryWidth: CGFloat
        let primaryMaximum: CGFloat
        let secondaryFraction: CGFloat
        let secondaryWidth: CGFloat
    }

    init() {
#if compiler(>=6.4)
        if #available(iOS 27.1, *) {
            super.init(style: .doubleColumn)
        } else {
            super.init(nibName: nil, bundle: nil)
        }
#else
        super.init(nibName: nil, bundle: nil)
#endif
        delegate = self
        preferredDisplayMode = .oneBesideSecondary
        if style != .unspecified { preferredSplitBehavior = .tile }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func updateViewConstraints() {
#if compiler(>=6.4)
        if #available(iOS 27.1, *) {
            // UIKit tracks reserved-region reads during constraint updates. An active
            // division, rather than a model name or hinge angle, defines this layout.
            applyDivisionLayout(hasActiveDivision: view.reservedRegions(kind: .division).contains { $0.isActive })
        }
#endif
        super.updateViewConstraints()
    }

#if compiler(>=6.4)
    @available(iOS 27.1, *)
    func applyDivisionLayout(hasActiveDivision: Bool) {
        guard style != .unspecified else { return }
        if hasActiveDivision {
            guard unfoldedColumnWidths == nil else { return }
            unfoldedColumnWidths = ColumnWidths(
                primaryFraction: preferredPrimaryColumnWidthFraction,
                primaryWidth: preferredPrimaryColumnWidth,
                primaryMaximum: maximumPrimaryColumnWidth,
                secondaryFraction: preferredSecondaryColumnWidthFraction,
                secondaryWidth: preferredSecondaryColumnWidth
            )
            preferredPrimaryColumnWidth = UISplitViewController.automaticDimension
            preferredSecondaryColumnWidth = UISplitViewController.automaticDimension
            maximumPrimaryColumnWidth = .greatestFiniteMagnitude
            preferredPrimaryColumnWidthFraction = 0.5
            preferredSecondaryColumnWidthFraction = 0.5
            preferredDisplayMode = .oneBesideSecondary
        } else if let widths = unfoldedColumnWidths {
            unfoldedColumnWidths = nil
            preferredPrimaryColumnWidthFraction = widths.primaryFraction
            preferredPrimaryColumnWidth = widths.primaryWidth
            maximumPrimaryColumnWidth = widths.primaryMaximum
            preferredSecondaryColumnWidthFraction = widths.secondaryFraction
            preferredSecondaryColumnWidth = widths.secondaryWidth
        }
    }

#endif

    func showSettingsDetail(_ controller: UIViewController) {
        let navigation = (controller as? UINavigationController)
            ?? UINavigationController(rootViewController: controller)
        if style == .unspecified {
            showDetailViewController(navigation, sender: self)
        } else {
            setViewController(navigation, for: .secondary)
            show(.secondary)
        }
    }

    private var secondaryIsPlaceholder: Bool {
        let secondary = viewController(for: .secondary)
        if let navigation = secondary as? UINavigationController {
            return navigation.viewControllers.count == 1 && navigation.viewControllers.first is SplitPlaceholderController
        }
        return secondary is SplitPlaceholderController
    }

    func splitViewController(_ svc: UISplitViewController,
                             topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column {
        secondaryIsPlaceholder ? .primary : .secondary
    }

    func splitViewController(_ svc: UISplitViewController,
                             displayModeForExpandingToProposedDisplayMode proposedDisplayMode: UISplitViewController.DisplayMode) -> UISplitViewController.DisplayMode {
        .oneBesideSecondary
    }

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
        let secondary = UINavigationController(rootViewController: SplitPlaceholderController())
        if split.style == .unspecified {
            split.viewControllers = [primaryViewController, secondary]
        } else {
            split.setViewController(primaryViewController, for: .primary)
            split.setViewController(secondary, for: .secondary)
        }
        return split
    }
}
