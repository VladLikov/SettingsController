import Foundation

/// A cancelled or superseded request may finish, but must never apply its result.
/// Task cancellation is cooperative; this identity check is deliberately separate.
@MainActor
final class RequestLifetime {
    private var currentID: UUID?

    func begin() -> UUID {
        let id = UUID()
        currentID = id
        return id
    }

    func isCurrent(_ id: UUID) -> Bool { currentID == id }

    @discardableResult
    func finish(_ id: UUID) -> Bool {
        guard isCurrent(id) else { return false }
        currentID = nil
        return true
    }

    func invalidate() { currentID = nil }
}
