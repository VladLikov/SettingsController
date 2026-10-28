import Foundation

/// Keyed by the immutable configuration section ID, never by a visible IndexPath.
enum AppCatalogState: Equatable {
    case loading
    case loaded([AppItem])
    case empty
    case failed
}
