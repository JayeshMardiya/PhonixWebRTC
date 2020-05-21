//
//  Message.swift
//  VoW
//
//  Created by Jayesh Mardiya on 04/09/19.
//  Copyright © 2019 Jayesh Mardiya. All rights reserved.
//

import UIKit
import WebRTC

enum MessageType: String, Codable {
    case message
    case votingAnswer
    case votingData
    case finishedVotingResult
    case setup
}

struct SessionData: Codable {
    
    var streamName: String?
    var localRecording: Bool?
    var allowRecording: Bool?
    var remoteStream: Bool?
    var passcode: String?

    init() {

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

enum RemoteMessage {
    case sdp(SDP)
    case candidate(Candidate)
}

struct Syn: Codable {
    
    let clientType: String
    let sourceId: String
}

struct SDP {
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
    
    init(dictionary: Dictionary<String, Any>) throws {
        let sdp = dictionary["sdp"] as! String
        let sdpType = dictionary["sdpType"] as! String
        
        self.init(sdp: sdp, sdpType: .offer)
    }
}

struct AnswerSDP {
    let sdp: String
    let sdpType: SdpType
}

extension AnswerSDP {
    
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
    
    init(dictionary: Dictionary<String, Any>) throws {
        let sdp = dictionary["sdp"] as! String
//        let sdpType = dictionary["sdpType"] as! String
        
        self.init(sdp: sdp, sdpType: .answer)
    }
}

struct Candidate {
    
    let sdp: String
    let sdpMLineIndex: Int32
    let sdpMid: String?
}

extension Candidate {
    
    init(dictionary: Dictionary<String, Any>) throws {
        let sdpMLineIndex = dictionary["sdpMLineIndex"] as! Int32
        let sdp = dictionary["sdp"] as! String
        let sdpMid = dictionary["sdpMid"] as? String
        
        self.init(sdp: sdp, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
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

extension RemoteMessage {
    
    init(dictionary: [String: Any]) throws {
        self = try RemoteMessage(dictionary: dictionary)
    }
    
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

