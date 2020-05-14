//
//  UIView+Extensions.swift
//  popguide
//
//  Created by Sumit Anantwar on 22/12/2018.
//  Copyright © 2019 Populi Ltd. All rights reserved.
//

import UIKit

extension UIView {

    private func constraintsFor(attribute: NSLayoutConstraint.Attribute) -> [NSLayoutConstraint] {

        let filteredArray = self.constraints.filter { $0.firstAttribute == attribute }
        var constraints: [NSLayoutConstraint] = []
        for const in filteredArray where const.isActive {
            constraints.append(const)
        }

        return constraints
    }

    func constraint(attribute: NSLayoutConstraint.Attribute) -> NSLayoutConstraint? {
        let constraints = self.constraintsFor(attribute: attribute)
        if constraints.count > 0 {
            return constraints.first
        }

        return nil
    }

    func parentViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.parentViewController()
        } else {
            return nil
        }
    }

    func localWiFiIPAddress() -> String? {

        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        if getifaddrs(&ifaddr) == 0 {

            var ptr = ifaddr

            while ptr != nil {

                defer { ptr = ptr?.pointee.ifa_next }

                if let interface = ptr?.pointee {

                    let addrFamily = interface.ifa_addr.pointee.sa_family

                    if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {

                        let name: String = String(cString: interface.ifa_name)

                        if name == "en0" {

                            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                            getnameinfo(interface.ifa_addr,
                                        socklen_t(interface.ifa_addr.pointee.sa_len),
                                        &hostname,
                                        socklen_t(hostname.count),
                                        nil,
                                        socklen_t(0),
                                        NI_NUMERICHOST)
                            address = String(cString: hostname)
                        }
                    }
                }
            }

            freeifaddrs(ifaddr)
        }

        return address
    }
}
