//
//  JoinResponse.swift
//  PhonixWebRTC
//
//  Created by Sumit Anantwar on 14/05/2020.
//  Copyright © 2020 Jayesh Mardiya. All rights reserved.
//

import Foundation

struct SpeakerStatus : Codable {
    let status: String
    let uuId: String?
}

struct TwilioIceServer : Codable {
    let url: String
}

struct TwilioCreds : Codable {
    let ice_servers: [TwilioIceServer]
    let username: String
    let password: String
}

struct JoinResponse : Codable {
    let speaker_status: SpeakerStatus
    let twilio_creds: TwilioCreds
    
    init(dictionary: [String: Any]) throws {
        self = try JSONDecoder().decode(JoinResponse.self, from: JSONSerialization.data(withJSONObject: dictionary))
    }
}
