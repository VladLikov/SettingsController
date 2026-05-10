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
        isPremium: Bool?
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
        let proStatus = isPremium.map { $0 ? "true" : "false" } ?? "-"
        
        // MARK: System
        
        let systemVersion = device.systemVersion
        let systemName = device.systemName
        
        let locale = Locale.current.identifier
        let timeZone = TimeZone.current.identifier
        
        
        let message = """
        \(type == .languageRequest ? "Language needed: " : "")\(text)
        
        
        
        ===== DEVICE INFO =====
        
        Device Model: \(modelIdentifier)
        Device Name: \(device.name)
        Device Type: \(device.model)
        
        OS: \(systemName) \(systemVersion)
        
        Battery: \(batteryLevel)
        
        ===== APP INFO =====
        
        App: \(appName)
        Version: \(version)
        Build: \(build)

        ===== USER INFO =====

        User ID: \(userID ?? "-")
        Pro Status: \(proStatus)
        
        ===== ENVIRONMENT =====
        
        Locale: \(locale)
        Time Zone: \(timeZone)
        
        Timestamp: \(Date())
        
        """
        
        let subject = "\(appName) \(type.subject)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let body = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        return "mailto:\(recipient)?subject=\(subject)&body=\(body)"
    }
}
