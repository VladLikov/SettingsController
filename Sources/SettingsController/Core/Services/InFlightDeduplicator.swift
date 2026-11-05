import Foundation

/// Shares one in-flight operation between concurrent callers that ask for the same key.
///
/// Only requests currently in flight are shared; nothing is cached. When every caller of a flight
/// is cancelled, the shared operation is cancelled too. A cancelled flight never removes a newer one.
actor InFlightDeduplicator<Key: Hashable & Sendable, Value: Sendable> {
    struct Result {
        let value: Value
        /// True for exactly one caller: the first to observe completion of the current flight.
        /// That caller may publish the value, for example to a cache.
        let completedFlight: Bool
    }

    private struct Flight {
        let id: UUID
        let task: Task<Value, Error>
        var consumers: Set<UUID>
    }

    private var flights: [Key: Flight] = [:]

    var activeRequestCount: Int { flights.count }
    var activeConsumerCount: Int { flights.values.reduce(0) { $0 + $1.consumers.count } }

    func value(for key: Key, operation: @escaping @Sendable () async throws -> Value) async throws -> Result {
        try Task.checkCancellation()
        let consumer = UUID()
        let flight: Flight
        if var existing = flights[key] {
            existing.consumers.insert(consumer)
            flights[key] = existing
            flight = existing
        } else {
            flight = Flight(id: UUID(), task: Task { try await operation() }, consumers: [consumer])
            flights[key] = flight
        }
        return try await withTaskCancellationHandler {
            do {
                let value = try await flight.task.value
                let completed = flights[key]?.id == flight.id
                if completed { flights[key] = nil }
                try Task.checkCancellation()
                return Result(value: value, completedFlight: completed)
            } catch {
                if flights[key]?.id == flight.id { flights[key] = nil }
                if Task.isCancelled { throw CancellationError() }
                throw error
            }
        } onCancel: {
            Task { await self.release(key, flightID: flight.id, consumer: consumer) }
        }
    }

    private func release(_ key: Key, flightID: UUID, consumer: UUID) {
        guard var flight = flights[key], flight.id == flightID else { return }
        flight.consumers.remove(consumer)
        if flight.consumers.isEmpty {
            flights[key] = nil
            flight.task.cancel()
        } else {
            flights[key] = flight
        }
    }
}
