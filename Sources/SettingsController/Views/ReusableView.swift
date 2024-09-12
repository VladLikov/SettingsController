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
extension UICollectionReusableView: ReusableView {}

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

extension UICollectionView {
    
    // MARK: - Register cells & views

    func register<T: UICollectionViewCell>(_ cellClass: T.Type) {
        register(cellClass, forCellWithReuseIdentifier: cellClass.reuseIdentifier)
    }
    
    func register<T: UICollectionViewCell>(_ cellClasses: [T.Type]) {
        cellClasses.forEach { register($0) }
    }
    
    func register<T: UICollectionReusableView>(_ viewClass: T.Type, forSupplementaryViewOfKind elementKind: String) {
        register(viewClass, forSupplementaryViewOfKind: elementKind,
                 withReuseIdentifier: viewClass.reuseIdentifier)
    }
    
    func registerHeaderView<T: UICollectionReusableView>(_ viewClass: T.Type) {
        register(viewClass, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                 withReuseIdentifier: viewClass.reuseIdentifier)
    }
    
    func registerHeaderViews<T: UICollectionReusableView>(_ viewClasses: [T.Type]) {
        viewClasses.forEach { registerHeaderView($0) }
    }
    
    func registerFooterView<T: UICollectionReusableView>(_ viewClass: T.Type) {
        register(viewClass, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                 withReuseIdentifier: viewClass.reuseIdentifier)
    }
    
    func registerFooterViews<T: UICollectionReusableView>(_ viewClasses: [T.Type]) {
        viewClasses.forEach { registerFooterView($0) }
    }
    
    // MARK: - Dequeue cells & views

    func dequeueReusableCell<T: UICollectionViewCell>(ofType cellType: T.Type, for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withReuseIdentifier: cellType.reuseIdentifier,
                                             for: indexPath) as? T else {
            return .init()
        }
        return cell
    }
    
    func dequeueReusableSupplementaryView<T: UICollectionReusableView>(ofKind elementKind: String,
                                                                       viewType: T.Type,
                                                                       for indexPath: IndexPath) -> T {
        guard let view = dequeueReusableSupplementaryView(ofKind: elementKind,
                                                          withReuseIdentifier: viewType.reuseIdentifier,
                                                          for: indexPath) as? T else {
            return .init()
        }
        return view
    }
    
    func dequeueReusableHeaderView<T: UICollectionReusableView>(ofType viewType: T.Type,
                                                                for indexPath: IndexPath) -> T {
        return dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                viewType: viewType,
                                                for: indexPath)
    }
    
    func dequeueReusableFooterView<T: UICollectionReusableView>(ofType viewType: T.Type,
                                                                for indexPath: IndexPath) -> T {
        return dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter,
                                                viewType: viewType,
                                                for: indexPath)
    }
    
}
