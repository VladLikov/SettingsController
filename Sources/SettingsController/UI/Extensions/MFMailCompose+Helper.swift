//
//  File.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import MessageUI
import AlertKit

public extension MFMailComposeViewController {
    
    static func canSendEmail() -> Bool {
        
        let canSendMail = canSendMail()
        
        if !canSendMail {
            AlertKitAPI.present(
                title: NSLocalizedString("Mail is not installed.", bundle: .module, comment: ""),
                icon: .error,
                style: .iOS17AppleMusic,
                haptic: .error
            )
        }
        
        return canSendMail
    }
    
//    static func getDefault(for email: String, needLanguage: Bool = false) -> MFMailComposeViewController {
//        
//        let mail = MFMailComposeViewController()
//        
//        let deviceModel = UIDevice.current.model
//        let systemVersion = UIDevice.current.systemVersion
//        
//        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? ""
//        let appName = (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String) ?? ""
//        
//        let message = "\(needLanguage ? NSLocalizedString("Language needed: ", bundle: .module, comment: "") : "")\n\n\n\n\n\nDevice: \(deviceModel)\niOS: \(systemVersion)\nApp Version: \(appVersion)"
//        
//        mail.setMessageBody(message, isHTML: false)
//        mail.setSubject(appName)
//        mail.setToRecipients([email])
//        
//        return mail
//    }
}
