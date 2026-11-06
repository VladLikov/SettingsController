import QuartzCore
import os

/// Points of Interest intervals for Instruments. Signposts are free when no trace is recording.
enum SettingsSignposts {
    static let signposter = OSSignposter(subsystem: "SettingsController", category: .pointsOfInterest)
}

/// Counts premium card sizing work. Tests use it to verify that self-sizing reuses cached measurements.
@MainActor
enum PremiumCardSizingStatistics {
    /// Calls of `PremiumCell.systemLayoutSizeFitting`.
    private(set) static var cellSizingCount = 0
    /// SwiftUI layouts run to size the card, that is, height cache misses.
    private(set) static var measurementCount = 0
    private(set) static var measurementDuration: Double = 0

    static func recordCellSizing() { cellSizingCount += 1 }

    static func recordMeasurement(duration: Double) {
        measurementCount += 1
        measurementDuration += duration
    }

    static func reset() {
        cellSizingCount = 0
        measurementCount = 0
        measurementDuration = 0
    }
}
