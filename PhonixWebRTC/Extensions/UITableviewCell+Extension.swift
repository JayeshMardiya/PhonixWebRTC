//
//  UITableviewCell+Extension.swift
//  VoW
//
//  Created by Sumit on 28/06/2019.
//  Copyright © 2019 Vox. All rights reserved.
//

import UIKit

protocol NibInstantiable {
    static var nibInstance: UINib { get }
}

extension NibInstantiable where Self: UITableViewCell {

    static var cellId: String {
        return String(describing: self)
    }

    static var bundle: Bundle {
        return Bundle(for: self)
    }

    static var nibInstance: UINib {
        return UINib(nibName: cellId, bundle: bundle)
    }

    static func register(with tableView: UITableView) {
        tableView.register(nibInstance, forCellReuseIdentifier: cellId)
    }
}

extension UITableViewCell: NibInstantiable {}
