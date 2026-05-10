//
//  AppItem.swift
//  SettingsController
//
//  Created by Влад Лыков on 02.05.2025.
//

import Foundation

public struct AppItem: Sendable {
    public let id: Int
    public let name: String
    public let iconURL: URL
    public let storeURL: URL
}
