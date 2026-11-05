import UIKit

public struct SettingsRow {
    public typealias SettingsAction =
        @MainActor (_ indexPath: IndexPath, _ tableView: UITableView, _ viewController: UIViewController) -> Void

    public let title: String
    public let detail: String?
    public let icon: SettingsIcon
    /// Nil makes the row inert, for example a purely informational row.
    public let destination: SettingsDestination?

    public init(title: String, detail: String? = nil, icon: SettingsIcon, destination: SettingsDestination?) {
        self.title = title
        self.detail = detail
        self.icon = icon
        self.destination = destination
    }

    @available(*, deprecated, message: "Use init(title:detail:icon:destination:) with .controller or .action.")
    public init(
        title: String, detail: String? = nil, icon: SettingsIcon,
        destinationControllerType: UIViewController.Type? = nil, action: SettingsAction? = nil
    ) {
        let destination: SettingsDestination? =
            if let destinationControllerType {
                .controller(destinationControllerType)
            } else if let action {
                .action { context in
                    action(context.indexPath ?? IndexPath(row: 0, section: 0), context.tableView ?? UITableView(), context.viewController)
                }
            } else {
                nil
            }
        self.init(title: title, detail: detail, icon: icon, destination: destination)
    }

    @available(*, deprecated, renamed: "init(title:detail:icon:destination:)", message: "Pass .factory(...) as the destination.")
    public init(title: String, detail: String? = nil, icon: SettingsIcon, destinationFactory: @escaping SettingsDestinationFactory) {
        self.init(title: title, detail: detail, icon: icon, destination: .factory(destinationFactory))
    }
}
