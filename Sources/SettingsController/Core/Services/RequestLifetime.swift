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

/// One replaceable asynchronous request: starting a new one cancels and supersedes the previous one.
///
/// The body receives a token. A superseded or cancelled body may keep running, but `token.isCurrent`
/// turns false, so it must not apply its result. The task reference is cleared when the current body
/// finishes, or earlier when it calls `token.finish()`.
@MainActor
final class CancellableRequest {
    struct Token {
        fileprivate let id: UUID
        fileprivate weak var owner: CancellableRequest?

        /// False once the request was cancelled or superseded, even if the task keeps running.
        @MainActor var isCurrent: Bool { !Task.isCancelled && owner?.lifetime.isCurrent(id) == true }

        /// Ends the current request early. Returns false for a superseded or cancelled request.
        @MainActor @discardableResult
        func finish() -> Bool { owner?.finish(id) ?? false }
    }

    private let lifetime = RequestLifetime()
    private(set) var task: Task<Void, Never>?
    var isRunning: Bool { task != nil }

    deinit { task?.cancel() }

    @discardableResult
    func start(_ body: @escaping @MainActor (Token) async -> Void) -> Task<Void, Never> {
        let token = Token(id: lifetime.begin(), owner: self)
        task?.cancel()
        let task = Task { @MainActor in
            await body(token)
            token.finish()
        }
        self.task = task
        return task
    }

    func cancel() {
        lifetime.invalidate()
        task?.cancel()
        task = nil
    }

    fileprivate func finish(_ id: UUID) -> Bool {
        guard lifetime.finish(id) else { return false }
        task = nil
        return true
    }
}
