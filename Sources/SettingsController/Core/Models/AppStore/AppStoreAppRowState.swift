//
//  AppStoreAppRowState.swift
//  SettingsController
//
//  Created by Влад Лыков on 29.04.2025.
//

public enum AppStoreAppRowState {
    case placeholder
    case loaded(AppItem)
    case failed
}
