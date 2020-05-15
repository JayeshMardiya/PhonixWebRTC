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
    
    struct Proxy : Codable {
        let offer: String
        let src: String
    }
    
    init(dictionary: [String: Any]) throws {
        let decoder = JSONDecoder()
        let proxy = try decoder.decode(Proxy.self, from: JSONSerialization.data(withJSONObject: dictionary))
        
        let data = try proxy.offer.data(using: .utf8) ?? throw_(Errors.parsingError)
        let offer = try decoder.decode(SDP.self, from: data)
        
        self.offer = offer
        self.src = proxy.src
    }
}

struct CandidateMessage : Codable {
    let candidate: Candidate
    let src: String
    
    struct Proxy : Codable {
        let candidate: String
        let src: String
    }
    
    init(dictionary: [String: Any]) throws {
        let decoder = JSONDecoder()
        let proxy = try decoder.decode(Proxy.self, from: JSONSerialization.data(withJSONObject: dictionary))
        
        let data = try proxy.candidate.data(using: .utf8) ?? throw_(Errors.parsingError)
        let candidate = try decoder.decode(Candidate.self, from: data)
        
        self.candidate = candidate
        self.src = proxy.src
    }
}

enum Errors : Error {
    case parsingError
}

func throw_<T> (_ error: Error) throws -> T {
    throw error
}
