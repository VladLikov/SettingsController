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
    private var divisionUpdateTask: Task<Void, Never>?
    private var divisionUpdateGeneration = 0

    deinit { divisionUpdateTask?.cancel() }

    private struct ColumnWidths {
        let primaryFraction: CGFloat
        let primaryWidth: CGFloat
        let primaryMaximum: CGFloat
        let primaryMinimum: CGFloat
        let secondaryMinimum: CGFloat
        let secondaryFraction: CGFloat
        let secondaryWidth: CGFloat
    }

    init() {
        // iOS 27 accessibility separators query column-only width APIs.
        // A classic split can raise an exception during native accessibility auditing.
        if #available(iOS 27.0, *) {
            super.init(style: .doubleColumn)
        } else {
            super.init(nibName: nil, bundle: nil)
        }
        delegate = self
        preferredDisplayMode = .oneBesideSecondary
        if style != .unspecified { preferredSplitBehavior = .tile }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 27.1, *) {
            // UIKit tracks reserved-region reads in UIView.updateConstraints().
            // Preserve UISplitViewController's own root view and layout machinery.
            let tracker = DivisionTrackingView()
            tracker.translatesAutoresizingMaskIntoConstraints = false
            tracker.isUserInteractionEnabled = false
            tracker.accessibilityElementsHidden = true
            tracker.onDivisionChange = { [weak self] active in
                guard let self else { return }
                self.divisionUpdateTask?.cancel()
                self.divisionUpdateGeneration &+= 1
                let generation = self.divisionUpdateGeneration
                self.divisionUpdateTask = Task { @MainActor [weak self] in
                    guard let self, !Task.isCancelled else { return }
                    self.applyDivisionLayout(hasActiveDivision: active)
                    if self.divisionUpdateGeneration == generation {
                        self.divisionUpdateTask = nil
                    }
                }
            }
            view.addSubview(tracker)
            NSLayoutConstraint.activate([
                tracker.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                tracker.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                tracker.topAnchor.constraint(equalTo: view.topAnchor),
                tracker.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
    }

    @available(iOS 27.1, *)
    func applyDivisionLayout(hasActiveDivision: Bool) {
        guard style != .unspecified else { return }
        if hasActiveDivision {
            guard unfoldedColumnWidths == nil else { return }
            unfoldedColumnWidths = ColumnWidths(
                primaryFraction: preferredPrimaryColumnWidthFraction,
                primaryWidth: preferredPrimaryColumnWidth,
                primaryMaximum: maximumPrimaryColumnWidth,
                primaryMinimum: minimumPrimaryColumnWidth,
                secondaryMinimum: minimumSecondaryColumnWidth,
                secondaryFraction: preferredSecondaryColumnWidthFraction,
                secondaryWidth: preferredSecondaryColumnWidth
            )
            preferredPrimaryColumnWidth = UISplitViewController.automaticDimension
            preferredSecondaryColumnWidth = UISplitViewController.automaticDimension
            maximumPrimaryColumnWidth = .greatestFiniteMagnitude
            minimumPrimaryColumnWidth = 0
            minimumSecondaryColumnWidth = 0
            preferredPrimaryColumnWidthFraction = 0.5
            preferredSecondaryColumnWidthFraction = 0.5
            preferredDisplayMode = .oneBesideSecondary
        } else if let widths = unfoldedColumnWidths {
            unfoldedColumnWidths = nil
            preferredPrimaryColumnWidthFraction = widths.primaryFraction
            preferredPrimaryColumnWidth = widths.primaryWidth
            maximumPrimaryColumnWidth = widths.primaryMaximum
            minimumPrimaryColumnWidth = widths.primaryMinimum
            minimumSecondaryColumnWidth = widths.secondaryMinimum
            preferredSecondaryColumnWidthFraction = widths.secondaryFraction
            preferredSecondaryColumnWidth = widths.secondaryWidth
        }
    }


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

@available(iOS 27.1, *)
final class DivisionTrackingView: UIView {
    var onDivisionChange: ((Bool) -> Void)?
    private var lastActiveDivision: Bool?
    private var lastHorizontalSizeClass: UIUserInterfaceSizeClass?

    override func updateConstraints() {
        let active = reservedRegions(kind: .division).contains { $0.isActive }
        let horizontalSizeClass = traitCollection.horizontalSizeClass
        if lastActiveDivision != active || lastHorizontalSizeClass != horizontalSizeClass {
            lastActiveDivision = active
            lastHorizontalSizeClass = horizontalSizeClass
            onDivisionChange?(active)
        }
        super.updateConstraints()
    }
}
