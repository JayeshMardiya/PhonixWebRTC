//
//  WebRTCModels.swift
//  VoW
//
//  Created by Sumit Anantwar on 23/12/2019.
//  Copyright © 2019 Jayesh Mardiya. All rights reserved.
//

import Foundation

struct SignalingMessage: Codable {
    let type: String
    let sessionDescription: SDP?
    let candidate: Candidate?
    let password: String?
    let allowRecording: Bool?
    
    init(type: String,
         sessionDescription: SDP? = nil,
         candidate: Candidate? = nil,
         password: String? = nil,
         allowRecording: Bool = false) {
        
        self.type = type
        self.sessionDescription = sessionDescription
        self.candidate = candidate
        self.password = password
        self.allowRecording = allowRecording
    }
}
