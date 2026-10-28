import UIKit

typealias OpenURLOperation = @MainActor (URL) async -> Bool

@MainActor
enum SystemActions {
    static func openURL(_ url: URL) async -> Bool {
        await UIApplication.shared.open(url, options: [:])
    }
}
