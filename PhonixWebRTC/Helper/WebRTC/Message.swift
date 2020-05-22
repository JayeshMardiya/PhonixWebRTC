//
//  Message.swift
//  VoW
//
//  Created by Jayesh Mardiya on 04/09/19.
//  Copyright © 2019 Jayesh Mardiya. All rights reserved.
//

import UIKit
import WebRTC

enum SdpType: String, Codable {
    case offer, prAnswer, answer
    
    var rtcSdpType: RTCSdpType {
        switch self {
            case .offer:    return .offer
            case .answer:   return .answer
            case .prAnswer: return .prAnswer
        }
    }
}

struct MessageData: Codable {
    
    var name: String?
    var message: String?
    
    init() {
        
    }
}

extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data,
                                                                options: .allowFragments) as? [String: Any] else {
                                                                    throw NSError()
        }
        return dictionary
    }
}

struct SDP : Codable {
    let sdp: String
    let sdpType: SdpType
}

extension SDP {
    
    init(rtcSDP: RTCSessionDescription) {
        
        self.sdp = rtcSDP.sdp
        
        switch rtcSDP.type {
            case .answer: self.sdpType = .answer
            case .offer: self.sdpType = .offer
            case .prAnswer: self.sdpType = .prAnswer
            @unknown default:
                fatalError("Invalid RTCSDPType")
        }
    }
    
    func toDictionary() -> [String : String] {
        return [
            "sdp": self.sdp,
            "sdpType": self.sdpType.rawValue
        ]
    }
    
    func rtcSDP() -> RTCSessionDescription {
        return RTCSessionDescription(type: self.sdpType.rtcSdpType, sdp: self.sdp)
    }
    
    init(dictionary: [String: Any]) throws {
        self = try JSONDecoder().decode(
            SDP.self, from: JSONSerialization.data(withJSONObject: dictionary)
        )
    }
}

struct Candidate : Codable {
    let sdp: String
    let sdpMLineIndex: Int32
    let sdpMid: String?
}

extension Candidate {
    
    init(dictionary: [String: Any]) throws {
        self = try JSONDecoder().decode(
            Candidate.self, from: JSONSerialization.data(withJSONObject: dictionary)
        )
    }
    
    init(rtcICE: RTCIceCandidate) {
        self.sdp = rtcICE.sdp
        self.sdpMLineIndex = rtcICE.sdpMLineIndex
        self.sdpMid = rtcICE.sdpMid
    }
    
    func toDictionary() -> [String : Any] {
        return [
            "sdp": self.sdp,
            "sdpMLineIndex": self.sdpMLineIndex,
            "sdpMid": self.sdpMid ?? ""
        ]
    }
    
    func rtcCandidate() -> RTCIceCandidate {
        return RTCIceCandidate(sdp: self.sdp, sdpMLineIndex: self.sdpMLineIndex, sdpMid: sdpMid)
    }
}

enum RemoteMessage {
    case sdp(SDP)
    case candidate(Candidate)
}

extension RemoteMessage {
    
    func toDictionary() -> [String : Any] {
        
        switch self {
        case .sdp(let sdp):
            return [
                "type": "sdp",
                "payload": sdp.toDictionary()
            ]
        case .candidate(let candidate):
            return [
                "type": "candidate",
                "payload": candidate.toDictionary()
            ]
        }
    }
}

struct SdpResponse : Codable {
    let src: String?
    let payload: SDP
    
    init(dictionary: [String: Any]) throws {
        self = try JSONDecoder().decode(
            SdpResponse.self, from: JSONSerialization.data(withJSONObject: dictionary)
        )
    }
}

struct CandidateResponse : Codable {
    let src: String?
    let payload: Candidate
    
    init(dictionary: [String: Any]) throws {
        self = try JSONDecoder().decode(
            CandidateResponse.self, from: JSONSerialization.data(withJSONObject: dictionary)
        )
    }
}

