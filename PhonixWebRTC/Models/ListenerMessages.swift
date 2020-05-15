//
//  ListenerMessages.swift
//  PhonixWebRTC
//
//  Created by Sumit Anantwar on 15/05/2020.
//  Copyright © 2020 Jayesh Mardiya. All rights reserved.
//

import Foundation

struct OfferMessage : Codable {
    let offer: SDP
    let src: String
    
    init(dictionary: [String: Any]) throws {
        self = try JSONDecoder().decode(OfferMessage.self, from: JSONSerialization.data(withJSONObject: dictionary))
    }
}

struct CandidateMessage : Codable {
    let candidate: Candidate
    let src: String
    
    init(dictionary: [String: Any]) throws {
        self = try JSONDecoder().decode(CandidateMessage.self, from: JSONSerialization.data(withJSONObject: dictionary))
    }
}
