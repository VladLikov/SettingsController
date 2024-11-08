//
//  File.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import MessageUI

extension MFMailComposeViewController {
    static func getDefault(for email: String, needLanguage: Bool = false) -> MFMailComposeViewController {
        let mail = MFMailComposeViewController()
        
        let deviceModel = UIDevice.current.model
        let systemVersion = UIDevice.current.systemVersion
        
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? ""
        let appName = (Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String) ?? ""
        
        let message = "\(needLanguage ? NSLocalizedString("Needed language: ", bundle: .module, comment: "") : "")\n\n\n\n\n\nDevice: \(deviceModel)\niOS: \(systemVersion)\nApp Version: \(appVersion)"
        
        mail.setMessageBody(message, isHTML: false)
        mail.setSubject(appName)
        mail.setToRecipients([email])
        
        return mail
    }
}
