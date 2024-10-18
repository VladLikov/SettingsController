//
//  DispatchQueue + Extensions.swift
//  SettingsController
//
//  Created by Влад Лыков on 15.10.2024.
//

import Foundation

extension DispatchQueue {
    
    static func anywayOnMain<T>(_ clousure: () throws -> T) rethrows -> T {
        guard Thread.isMainThread else {
            return try main.sync(execute: clousure)
        }
        
        return try clousure()
    }
}
