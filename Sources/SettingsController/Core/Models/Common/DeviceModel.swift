//
//  DeviceModel.swift
//  SettingsController
//
//  Created by Влад Лыков on 07.05.2026.
//

import Foundation

enum DeviceModel {

    static var supportDescription: String {
        guard let name = readableNames[identifier] else {
            return identifier
        }

        return "\(identifier) (\(name))"
    }

    static var identifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)

        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
    }

    private static let readableNames: [String: String] = [
        "iPhone17,1": "iPhone 16 Pro",
        "iPhone17,2": "iPhone 16 Pro Max",
        "iPhone17,3": "iPhone 16",
        "iPhone17,4": "iPhone 16 Plus",
        "iPhone17,5": "iPhone 16e",
        "iPhone18,1": "iPhone 17 Pro",
        "iPhone18,2": "iPhone 17 Pro Max",
        "iPhone18,3": "iPhone 17",
        "iPhone18,4": "iPhone Air"
    ]
}
