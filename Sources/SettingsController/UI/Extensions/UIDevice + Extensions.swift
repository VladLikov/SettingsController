//
//  UIDevice + Extensions.swift
//  AppLock
//
//  Created by Влад Лыков on 27.06.2025.
//

import UIKit

extension UIDevice {
    
    static var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
}
