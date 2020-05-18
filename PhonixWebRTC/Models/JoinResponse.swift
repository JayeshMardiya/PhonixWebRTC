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
    
    init(dictionary: [String: Any]) throws {
        self = try JSONDecoder().decode(SpeakerStatus.self, from: JSONSerialization.data(withJSONObject: dictionary))
    }
}

struct TwilioIceServer : Codable {
    let url: String
}

struct TwilioCreds : Codable {
    let ice_servers: [TwilioIceServer]
    let username: String
    let password: String
    
    func servers() -> [String] {
        return ice_servers.map { $0.url }
    }
}

struct ListenerJoinResponse : Codable {
    let speaker_status: SpeakerStatus
    let twilio_creds: TwilioCreds
    
    init(dictionary: [String: Any]) throws {
        let response = try dictionary["response"] as? [String : Any] ?? throw_(Errors.parsingError)
        self = try JSONDecoder().decode(ListenerJoinResponse.self, from: JSONSerialization.data(withJSONObject: response))
    }
}

struct SpeakerJoinResponse : Codable {
    let twilio_creds: TwilioCreds
    
    init(dictionary: [String: Any]) throws {
        let response = try dictionary["response"] as? [String : Any] ?? throw_(Errors.parsingError)
        self = try JSONDecoder().decode(SpeakerJoinResponse.self, from: JSONSerialization.data(withJSONObject: response))
    }
}
