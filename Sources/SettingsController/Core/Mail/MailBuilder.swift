//
//  MailBuilder.swift
//  SettingsController
//
//  Created by Влад Лыков on 11.04.2026.
//

import Foundation
import UIKit

@MainActor
enum MailBuilder {
    
    static func buildMail(
        with text: String,
        recipient: String,
        type: MailType,
        userID: String?,
        isPremium: Bool?,
        productID: String? = nil,
        mailInfo: SettingsMailInfo? = nil
    ) -> String {
        
        // MARK: Device
        
        let device = UIDevice.current
        
        let modelIdentifier = DeviceModel.supportDescription
        
        let wasBatteryMonitoringEnabled = device.isBatteryMonitoringEnabled
        device.isBatteryMonitoringEnabled = true
        defer {
            device.isBatteryMonitoringEnabled = wasBatteryMonitoringEnabled
        }

        let batteryLevel = device.batteryLevel >= 0
            ? "\(Int(device.batteryLevel * 100))%"
            : "Unknown"
        
        // MARK: App
        
        let bundle = Bundle.main
        let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = bundle.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        let appName = bundle.infoDictionary?["CFBundleDisplayName"] as? String ?? "App"
        let proStatus = (mailInfo?.isPremium ?? isPremium).map { $0 ? "true" : "false" } ?? "-"
        let effectiveProductID = mailInfo?.productID ?? productID
        
        // MARK: System
        
        let systemVersion = device.systemVersion
        let systemName = device.systemName
        
        let currentLocale = Locale.current
        let locale = currentLocale.identifier

        // Read the system language without the per-app language override.
        let globalPreferredLanguages = UserDefaults.standard
            .persistentDomain(forName: UserDefaults.globalDomain)?["AppleLanguages"] as? [String]
        let systemLanguageIdentifier = globalPreferredLanguages?.first
            ?? Locale.preferredLanguages.first
            ?? "Unknown"
        let systemLanguage = Locale(identifier: systemLanguageIdentifier).languageCode
            ?? systemLanguageIdentifier

        let appLanguage = bundle.preferredLocalizations.first
            ?? bundle.developmentLocalization
            ?? "Unknown"

        let appRegion: String
        if #available(iOS 16.0, *) {
            appRegion = currentLocale.region?.identifier.lowercased() ?? "Unknown"
        } else {
            appRegion = currentLocale.regionCode?.lowercased() ?? "Unknown"
        }

        let timeZone = TimeZone.current.identifier
        
        
        let message = """
        \(type == .languageRequest ? "Language needed: " : "")\(text)
        
        
        
        ===== DEVICE INFO =====
        
        Device Model: \(modelIdentifier)
        Device Type: \(device.model)
        
        OS: \(systemName) \(systemVersion)
        
        Battery: \(batteryLevel)
        
        ===== APP INFO =====
        
        App: \(appName)
        Version: \(version)
        Build: \(build)

        ===== USER INFO =====

        User ID: \(userID ?? "-")
        Product ID: \(effectiveProductID ?? "-")
        Pro Status: \(proStatus)
        
        ===== ENVIRONMENT =====
        
        Locale: \(locale)
        System Language: \(systemLanguage)
        App Language: \(appLanguage)
        App Region: \(appRegion)
        Time Zone: \(timeZone)
        
        Timestamp: \(Date())
        
        """
        
        let subject = "\(appName) \(type.subject)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let body = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        return "mailto:\(recipient)?subject=\(subject)&body=\(body)"
    }
}
