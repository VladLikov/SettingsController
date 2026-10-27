import Foundation
import UIKit

/// A snapshot keeps formatting deterministic and avoids reading system preferences.
struct MailEnvironment: Sendable {
    let appName: String
    let version: String
    let build: String
    let deviceModel: String
    let deviceType: String
    let systemName: String
    let systemVersion: String
    let battery: String
    let locale: String
    let preferredLanguage: String
    let appLanguage: String
    let region: String
    let timeZone: String
    let timestamp: String

    @MainActor
    static func current() -> Self {
        let device = UIDevice.current
        let wasEnabled = device.isBatteryMonitoringEnabled
        device.isBatteryMonitoringEnabled = true
        defer { device.isBatteryMonitoringEnabled = wasEnabled }
        let bundle = Bundle.main
        let locale = Locale.current
        let region: String
        if #available(iOS 16, *) {
            region = locale.region?.identifier ?? "Unknown"
        } else {
            region = locale.regionCode ?? "Unknown"
        }
        return Self(
            appName: bundle.infoDictionary?["CFBundleDisplayName"] as? String
                ?? bundle.infoDictionary?["CFBundleName"] as? String ?? "App",
            version: bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            build: bundle.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown",
            deviceModel: DeviceModel.supportDescription,
            deviceType: device.model,
            systemName: device.systemName,
            systemVersion: device.systemVersion,
            battery: device.batteryLevel >= 0 ? "\(Int(device.batteryLevel * 100))%" : "Unknown",
            locale: locale.identifier,
            preferredLanguage: Locale.preferredLanguages.first ?? "Unknown",
            appLanguage: bundle.preferredLocalizations.first ?? bundle.developmentLocalization ?? "Unknown",
            region: region.lowercased(),
            timeZone: TimeZone.current.identifier,
            timestamp: ISO8601DateFormatter().string(from: Date())
        )
    }
}
