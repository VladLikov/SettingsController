import UIKit

extension UIViewController {
    /// A push or a presented child is not the end of this controller's lifetime.
    var settingsIsLeavingHierarchy: Bool {
        var controller: UIViewController? = self
        while let current = controller {
            if current.isBeingDismissed || current.isMovingFromParent { return true }
            controller = current.parent
        }
        return false
    }

    var settingsCanPresent: Bool {
        isViewLoaded && view.window != nil && !settingsIsLeavingHierarchy
            && presentedViewController == nil
    }
}
