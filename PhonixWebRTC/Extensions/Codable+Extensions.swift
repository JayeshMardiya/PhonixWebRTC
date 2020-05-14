//
//  Codable+Extensions.swift
//  popguide
//
//  Created by Sumit Anantwar on 22/12/2018.
//  Copyright © 2018 Populi Ltd. All rights reserved.
//

import Foundation

extension Encodable {
    func toJSONData() -> Data? {
        return try? JSONEncoder().encode(self)
    }
}
