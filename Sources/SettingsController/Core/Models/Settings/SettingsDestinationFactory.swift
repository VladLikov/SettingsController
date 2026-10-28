import UIKit

/// Invoked lazily, once for each accepted navigation action. Return a fresh controller.
public typealias SettingsDestinationFactory = @MainActor () -> UIViewController
