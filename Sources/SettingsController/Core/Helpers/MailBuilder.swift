//
//  MailBuilder.swift
//  TestMail
//
//  Created by Влад Лыков on 11.04.2026.
//

import Foundation
import UIKit

@MainActor
enum MailBuilder {
    
    static func buildMail(with text: String, recipient: String, type: MailType) -> String {
        
        // MARK: Device
        
        let device = UIDevice.current
        
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelIdentifier = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
        
        device.isBatteryMonitoringEnabled = true
        
        let batteryLevel = device.batteryLevel >= 0
            ? "\(Int(device.batteryLevel * 100))%"
            : "Unknown"
        
        // MARK: App
        
        let bundle = Bundle.main
        let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = bundle.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        let appName = bundle.infoDictionary?["CFBundleDisplayName"] as? String ?? "App"
        
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
        
        ===== ENVIRONMENT =====
        
        Locale: \(locale)
        Time Zone: \(timeZone)
        
        Timestamp: \(Date())
        
        """
        
        let subject = appName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let body = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        return "mailto:\(recipient)?subject=\(subject)&body=\(body)"
    }
}
