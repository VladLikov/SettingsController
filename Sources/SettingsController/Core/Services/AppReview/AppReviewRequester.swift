//
//  AppReviewRequester.swift
//  SettingsController
//
//  Created by Влад Лыков on 17.05.2025.
//

import StoreKit
import UIKit

enum AppReviewRequester {

    @MainActor
    static func requestReview() {

#if os(iOS)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
#else
        SKStoreReviewController.requestReview()
#endif
    }
}
