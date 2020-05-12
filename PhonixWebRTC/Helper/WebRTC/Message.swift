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
    var timeStamp: String?
    var isTranslated: Bool?

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

enum Message {
    case handshake(Syn)
    case sdp(SDP)
    case candidate(Candidate)
}

struct Syn: Codable {
    
    let clientType: String
    let sourceId: String
}

struct SDP: Codable {
    
    let clientType: String
    let sourceId: String
    let destinationId: String
    let sdp: String
    let sdpType: SdpType
    
    init(with clientType: String,
         sourceId: String,
         destinationId: String,
         rtcSDP: RTCSessionDescription) {
        
        self.clientType = clientType
        self.sourceId = sourceId
        self.destinationId = destinationId
        self.sdp = rtcSDP.sdp
        
        switch rtcSDP.type {
        case .answer: self.sdpType = .answer
        case .offer: self.sdpType = .offer
        case .prAnswer: self.sdpType = .prAnswer
        @unknown default:
            fatalError("Invalid RTCSDPType")
        }
    }
    
    func rtcSDP() -> RTCSessionDescription {
        return RTCSessionDescription(type: self.sdpType.rtcSdpType, sdp: self.sdp)
    }
}

struct Candidate: Codable {
    
    let clientType: String
    let sourceId: String
    let destinationId: String
    let sdp: String
    let sdpMLineIndex: Int32
    let sdpMid: String?
    
    init(with clientType: String, sourceId: String, destinationId: String, rtcICE: RTCIceCandidate) {
        
        self.clientType = clientType
        self.sourceId = sourceId
        self.destinationId = destinationId
        self.sdp = rtcICE.sdp
        self.sdpMLineIndex = rtcICE.sdpMLineIndex
        self.sdpMid = rtcICE.sdpMid
    }
    
    func rtcCandidate() -> RTCIceCandidate {
        
        return RTCIceCandidate(sdp: self.sdp, sdpMLineIndex: self.sdpMLineIndex, sdpMid: sdpMid)
    }
}

enum Response {
    case presenterList([String]) // Presenter List
    case sdp(SDP)
    case candidate(Candidate)
}

extension Response: Decodable {
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "presenter_list":
            self = .presenterList(try container.decode([String].self, forKey: .payload))
        case "sdp":
            self = .sdp(try container.decode(SDP.self, forKey: .payload))
        case "ice":
            self = .candidate(try container.decode(Candidate.self, forKey: .payload))
        default:
            throw DecodeError.unknownType
        }
    }
    
    enum DecodeError: Error {
        case unknownType
    }
    
    enum CodingKeys: String, CodingKey {
        case type, payload
    }
}

extension Message: Encodable {
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .handshake(let syn):
            try container.encode("handshake", forKey: .type)
            try container.encode(syn, forKey: .payload)
        case .sdp(let sdp):
            try container.encode("sdp", forKey: .type)
            try container.encode(sdp, forKey: .payload)
        case .candidate(let candidate):
            try container.encode("ice", forKey: .type)
            try container.encode(candidate, forKey: .payload)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case type, payload
    }
}

