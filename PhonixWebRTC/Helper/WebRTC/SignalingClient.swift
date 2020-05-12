//
//  SignalClient.swift
//  WebRTC
//
//  Created by Stasel on 20/05/2018.
//  Copyright © 2018 Stasel. All rights reserved.
//

import Foundation
import WebRTC

protocol SignalClientDelegate: class {
    func signalClientDidConnect(_ signalClient: SignalingClient)
    func signalClientDidDisconnect(_ signalClient: SignalingClient)
    func signalClient(_ signalClient: SignalingClient, didReceiveRemoteSdp sdp: SDP)
    func signalClient(_ signalClient: SignalingClient, didReceiveCandidate candidate: Candidate)
    func signalClient(_ signalClient: SignalingClient, didAcceptListener clientType: String)
    func signalClientList(_ list: [String])
}

final class SignalingClient {
    
    var streamName: String? = nil
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let webSocket: WebSocketProvider
    weak var delegate: SignalClientDelegate?
    private var shouldDisconnect: Bool = false
    
    init(webSocket: WebSocketProvider) {
        self.webSocket = webSocket
    }
    
    func connect() {
        self.webSocket.delegate = self
        self.webSocket.connect()
    }
    
    func disConnect() {
        self.shouldDisconnect = true
        self.webSocket.disconnect()
    }
    
    func send(sdp rtcSdp: RTCSessionDescription, to client: String) {
        
        let sdp = SDP(with: self.getClientType(),
                      sourceId: self.getSourceId(),
                      destinationId: client,
                      rtcSDP: rtcSdp)
        self.send(message: Message.sdp(sdp))
    }
    
    func send(candidate rtcIceCandidate: RTCIceCandidate, to client: String) {
        
        let candidate = Candidate(with: self.getClientType(),
                                  sourceId: self.getSourceId(),
                                  destinationId: client,
                                  rtcICE: rtcIceCandidate)
        self.send(message: Message.candidate(candidate))
    }
    
    func sendSyn() {
        
        let syn = Syn(clientType: self.getClientType(),
                      sourceId: self.getSourceId())
        self.send(message: Message.handshake(syn))
    }
}

private extension SignalingClient {
    
    func getClientType() -> String {
        
        return (self.streamName != nil) ? "presenter" : "listener"
    }
    
    func getSourceId() -> String {
        
        return (self.streamName != nil) ? self.streamName! : UIDevice.current.identifierForVendor!.uuidString
    }
    
    func send(message: Message) {
        
        do {
            let dataMessage = try self.encoder.encode(message)
            self.webSocket.send(data: dataMessage)
        } catch {
            debugPrint("Warning: Could not encode sdp: \(error)")
        }
    }
}

extension SignalingClient: WebSocketProviderDelegate {
    
    func webSocketDidConnect(_ webSocket: WebSocketProvider) {
        self.delegate?.signalClientDidConnect(self)
    }
    
    func webSocketDidDisconnect(_ webSocket: WebSocketProvider) {
        self.delegate?.signalClientDidDisconnect(self)
        
        // try to reconnect every two seconds
        
        if !self.shouldDisconnect {
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                debugPrint("Trying to reconnect to signaling server...")
                self.webSocket.connect()
            }
        }
    }
    
    func webSocket(_ webSocket: WebSocketProvider, didReceiveData data: Data) {
        
        let responseData: Response
        do {
            responseData = try self.decoder.decode(Response.self, from: data)
            print(responseData)
            
            switch responseData {
            case .candidate(let candidate):
                print("candidate")
                self.delegate?.signalClient(self, didReceiveCandidate: candidate)
            case .presenterList(let list):
                self.delegate?.signalClientList(list)
            case .sdp(let sdp):
                self.delegate?.signalClient(self, didReceiveRemoteSdp: sdp)
            }
        } catch {
            debugPrint("Warning: Could not decode incoming message: \(error)")
            return
        }
    }
}
