//
//  AppItem.swift
//  SettingsController
//
//  Created by Влад Лыков on 02.05.2025.
//

import Foundation

public struct AppItem: Sendable {
    let id: Int
    let name: String
    let iconURL: URL
    let storeURL: URL
}
