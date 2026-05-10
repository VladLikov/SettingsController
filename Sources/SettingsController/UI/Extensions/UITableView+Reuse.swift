//
//  UITableView+Reuse.swift
//  SettingsController
//
//  Created by Влад Лыков on 05.05.2026.
//

import UIKit

extension UITableView {

    func register<Cell: UITableViewCell>(_ cellClass: Cell.Type) {
        register(cellClass, forCellReuseIdentifier: Cell.reuseIdentifier)
    }

    func dequeueReusableCell<Cell: UITableViewCell>(
        withClass cellClass: Cell.Type,
        for indexPath: IndexPath
    ) -> Cell {
        guard let cell = dequeueReusableCell(
            withIdentifier: cellClass.reuseIdentifier,
            for: indexPath
        ) as? Cell else {
            preconditionFailure("Unable to dequeue \(cellClass) with identifier \(Cell.reuseIdentifier)")
        }

        return cell
    }
}

private extension UITableViewCell {

    static var reuseIdentifier: String {
        String(describing: Self.self)
    }
}

