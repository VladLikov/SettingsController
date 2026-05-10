//
//  MailAvailability.swift
//  SettingsController
//
//  Created by Влад Лыков on 06.05.2026.
//

import AlertKit
import Foundation
import MessageUI

enum MailAvailability {

    @MainActor
    static func canSendEmail(presentingAlert: Bool = true) -> Bool {
        let canSendMail = MFMailComposeViewController.canSendMail()

        if !canSendMail, presentingAlert {
            AlertKitAPI.present(
                title: NSLocalizedString("Mail is not installed.", bundle: .module, comment: ""),
                icon: .error,
                style: .iOS17AppleMusic,
                haptic: .error
            )
        }

        return canSendMail
    }
}
