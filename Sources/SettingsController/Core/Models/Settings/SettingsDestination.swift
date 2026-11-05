import UIKit

/// Invoked lazily, once for each accepted navigation action. Return a fresh controller.
public typealias SettingsDestinationFactory = @MainActor () -> UIViewController

/// Where an action row or a premium action runs.
@MainActor
public struct SettingsActionContext {
    /// The controller to present from.
    public let viewController: UIViewController
    /// The settings table and the selected row, when the action comes from a row.
    public let tableView: UITableView?
    public let indexPath: IndexPath?

    public init(viewController: UIViewController, tableView: UITableView? = nil, indexPath: IndexPath? = nil) {
        self.viewController = viewController
        self.tableView = tableView
        self.indexPath = indexPath
    }
}

public typealias SettingsActionHandler = @MainActor (SettingsActionContext) -> Void

/// What selecting a row or a premium action does. Exactly one behavior per row.
public enum SettingsDestination {
    /// Shows a controller created with `init()`.
    case controller(UIViewController.Type)
    /// Shows a controller from a factory, invoked once for each selection.
    case factory(SettingsDestinationFactory)
    /// Runs an action without showing a screen of the library's choosing.
    case action(SettingsActionHandler)

    /// True when the library shows a screen for this destination.
    var opensScreen: Bool {
        if case .action = self { return false }
        return true
    }

    @MainActor
    func makeViewController() -> UIViewController? {
        switch self {
        case .controller(let type): type.init()
        case .factory(let factory): factory()
        case .action: nil
        }
    }
}
