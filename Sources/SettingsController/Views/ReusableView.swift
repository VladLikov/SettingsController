//
//  ReusableView.swift
//  SettingsController
//
//  Created by Влад Лыков on 12.09.2024.
//

import UIKit

protocol ReusableView: AnyObject {
    static var reuseIdentifier: String { get }
}

extension ReusableView where Self: UIView {
    static var reuseIdentifier: String {
        return String(describing: Self.self)
    }
}

extension UITableViewCell: ReusableView {}

extension UITableView {
        
    func register<T: UITableViewCell>(_: T.Type) {
        register(T.self, forCellReuseIdentifier: T.reuseIdentifier)
    }
        
    func dequeueReusableCell<T: UITableViewCell>(ofType cellType: T.Type,
                                                 for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withIdentifier: cellType.reuseIdentifier,
                                             for: indexPath) as? T else {
            return .init()
        }
        return cell
    }
    
}
