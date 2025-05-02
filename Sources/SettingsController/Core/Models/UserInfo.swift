//
//  User.swift
//  SettingsController
//
//  Created by Влад Лыков on 01.12.2024.
//

import Foundation
import UIKit

public struct UserInfo {
    
    public var name: String
    public var avatar: UIImage?
    
    public init(name: String, avatar: UIImage? = nil) {
        self.name = name
        self.avatar = avatar
    }
}
