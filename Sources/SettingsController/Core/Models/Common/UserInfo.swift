//
//  UserInfo.swift
//  SettingsController
//
//  Created by Влад Лыков on 01.12.2024.
//

import Foundation
import UIKit

public struct UserInfo {
    
    public let name: String
    public let avatar: UIImage?
    /// Stable identity plus revision of the avatar content. Change this value whenever
    /// its pixels change. Leave nil to retain UIImage reference-based comparison.
    public let avatarRevision: String?
    
    public init(name: String, avatar: UIImage? = nil, avatarRevision: String? = nil) {
        self.name = name
        self.avatar = avatar
        self.avatarRevision = avatarRevision
    }
    func hasSameAvatar(as other: UserInfo?) -> Bool {
        guard let other else { return false }
        guard (avatar == nil) == (other.avatar == nil) else { return false }
        if let avatarRevision, let previous = other.avatarRevision { return avatarRevision == previous }
        return avatar === other.avatar
    }
}
