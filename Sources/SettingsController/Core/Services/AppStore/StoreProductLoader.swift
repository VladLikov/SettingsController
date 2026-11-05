import StoreKit
import UIKit

@MainActor
enum StoreProductLoader {
    static func load(_ id: Int) async throws -> UIViewController? {
        #if !os(visionOS)
        let controller = SKStoreProductViewController()
        let loaded = try await controller.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: id])
        try Task.checkCancellation()
        return loaded ? controller : nil
        #else
        return nil
        #endif
    }
}
