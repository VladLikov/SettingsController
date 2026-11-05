import QuartzCore
import os

/// Points of Interest intervals for Instruments. Signposts are free when no trace is recording.
enum SettingsSignposts {
    static let signposter = OSSignposter(subsystem: "SettingsController", category: .pointsOfInterest)
}

/// Counts real SwiftUI measurement passes of the premium card. Tests use it to verify sizing work.
@MainActor
enum PremiumCardSizingStatistics {
    private(set) static var measurementCount = 0
    private(set) static var measurementDuration: Double = 0

    static func recordMeasurement(duration: Double) {
        measurementCount += 1
        measurementDuration += duration
    }

    static func reset() {
        measurementCount = 0
        measurementDuration = 0
    }
}
