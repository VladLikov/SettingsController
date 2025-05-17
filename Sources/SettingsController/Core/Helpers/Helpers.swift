//
//  Helpers.swift
//  SettingsController
//
//  Created by Влад Лыков on 17.05.2025.
//

import Foundation
import StoreKit

enum Helpers {

    static func requestReview() {
        
        DispatchQueue.main.async {
            #if os(iOS)
            if #available(iOS 14.0, *) {
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    SKStoreReviewController.requestReview(in: scene)
                }
            } else {
                SKStoreReviewController.requestReview()
            }
            #else
            SKStoreReviewController.requestReview()
            #endif
        }
    }
}
