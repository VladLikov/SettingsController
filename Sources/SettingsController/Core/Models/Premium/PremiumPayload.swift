import UIKit

public struct PremiumPayload {
    public private(set) var isPremium: Bool
    public private(set) var color: UIColor
    /// Shown modally (full screen in compact width) or run when the user is not premium.
    public let destination: SettingsDestination?

    public typealias PremiumAction = @MainActor (_ fromVC: UIViewController) -> Void

    public init(isPremium: Bool, color: UIColor, destination: SettingsDestination? = nil) {
        self.isPremium = isPremium
        self.color = color
        self.destination = destination
    }

    @available(*, deprecated, message: "Use init(isPremium:color:destination:) with .controller or .action.")
    public init(
        isPremium: Bool, color: UIColor,
        destinationControllerType: UIViewController.Type? = nil, action: PremiumAction? = nil
    ) {
        let destination: SettingsDestination? =
            if let destinationControllerType {
                .controller(destinationControllerType)
            } else if let action {
                .action { action($0.viewController) }
            } else {
                nil
            }
        self.init(isPremium: isPremium, color: color, destination: destination)
    }

    @available(*, deprecated, message: "Use init(isPremium:color:destination:) with .factory(...).")
    public init(isPremium: Bool, color: UIColor, destinationFactory: @escaping SettingsDestinationFactory) {
        self.init(isPremium: isPremium, color: color, destination: .factory(destinationFactory))
    }

    func withColor(_ color: UIColor) -> Self {
        var result = self
        result.color = color
        return result
    }

    func withPremiumStatus(_ value: Bool) -> Self {
        var result = self
        result.isPremium = value
        return result
    }
}
