//
//  ListenerViewController.swift
//  PhonixWebRTC
//
//  Created by Jayesh Mardiya on 12/05/20.
//  Copyright © 2020 Jayesh Mardiya. All rights reserved.
//

import UIKit
import SwiftPhoenixClient
import WebRTC

class ListenerViewController: UIViewController {
    
    //----------------------------------------------------------------------
    // MARK: - Child Views
    //----------------------------------------------------------------------
    @IBOutlet weak var connectButton: UIButton!
    
    let udid: String = "LISTENER" // UIDevice.current.identifierForVendor!.uuidString
    var socket: Socket? = nil
    var topic: String = "room:party"
    var lobbyChannel: Channel!
    
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    // WebRTC
    private let config = Config.default
    private var isListening: Bool = false
    
    private var webRtcClient: WebRTCClient!
    
    private var twilioCreds: TwilioCreds!
    
    // Listener
    override func viewDidLoad() {
        super.viewDidLoad()
        
        socket = Socket("https://vowdemo.herokuapp.com/vow_socket", params: ["token": "TOKEN123", "uuid": self.udid])
        // To automatically manage retain cycles, use `delegate*(to:)` methods.
        // If you would prefer to handle them yourself, youcan use the same
        // methods without the `delegate` functions, just be sure you avoid
        // memory leakse with `[weak self]`
        socket?.delegateOnOpen(to: self) { (slf) in
            slf.addText("Socket Opened")
            slf.connectButton.setTitle("Disconnect", for: .normal)
        }
        
        socket?.delegateOnClose(to: self) { (slf) in
            slf.addText("Socket Closed")
            slf.connectButton.setTitle("Connect", for: .normal)
        }
        
        socket?.delegateOnError(to: self) { (slf, error) in
            slf.addText("Socket Errored: " + error.localizedDescription)
        }
        
        socket?.logger = { msg in
//            print("LOG:", msg)
        }
    }
    
    
    //----------------------------------------------------------------------
    // MARK: - IBActions
    //----------------------------------------------------------------------
    @IBAction func onConnectButtonPressed(_ sender: UIButton) {
        
        if socket?.isConnected ?? false {
            disconnectAndLeave()
        } else {
            connectAndJoin()
        }
    }
    
    @IBAction func onBackButtonPressed(_ sender: UIButton) {
        
        self.navigationController?.popViewController(animated: true)
    }
    
    //----------------------------------------------------------------------
    // MARK: - Private
    //----------------------------------------------------------------------
    private func disconnectAndLeave() {
        // Be sure the leave the channel or call socket.remove(lobbyChannel)
        lobbyChannel.leave()
        socket?.disconnect {
            self.addText("Socket Disconnected")
        }
    }
    
    private func sendPayload(_ payload: [String : Any]) {
        self.lobbyChannel.push("listener_msg", payload: payload)
    }
    
    private func sendMessage() {
        self.lobbyChannel.push("listener_msg", payload: ["message" : "Message From Speaker"])
            .delegateReceive("ok", to: self) { (slf, message) in
                print(message)
        }.delegateReceive("error", to: self) { (slf, message) in
            print(message)
        }
    }
    
    private func connectAndJoin() {
        let channel = socket?.channel(topic, params: ["role": "listener"])

        channel?.delegateOn("status", to: self) { (slf, message) in
            slf.handlePayload(message.payload)
        }
        
        channel?.delegateOn("speaker_msg", to: self) { (slf, message) in
            let payload = message.payload as [String : Any]
                
            if let answer = payload["answer"] {
                print(answer)
            }
        }
        
        self.lobbyChannel = channel
        self.lobbyChannel.join()
            .delegateReceive("ok", to: self) { (slf, message) in
                slf.handlePayload(message.payload)
            }.delegateReceive("error", to: self) { (slf, message) in
                slf.addText("Failed to join channel: \(message.payload)")
            }
        
        self.socket?.connect()
    }
    
    private func handlePayload(_ payload: [String : Any]) {
        
        if let response = payload["response"] as? [String : Any],
            let joinResponse = try? JoinResponse(dictionary: response) {
            
            self.twilioCreds = joinResponse.twilio_creds
            if joinResponse.speaker_status.status == "online" {
                self.joinStream()
            }
            print(joinResponse)
            
            return
        }
        
        print(payload)
    }
    
    private func joinStream() {
        if let creds = self.twilioCreds {
            let servers = creds.ice_servers.map { $0.url }
            let iceServer = RTCIceServer(urlStrings: servers, username: creds.username, credential: creds.password)
            self.webRtcClient = WebRTCClient(iceServer: iceServer, userType: "listener")
            self.webRtcClient.delegate = self
            
            self.webRtcClient.offer { [unowned self] offer in
                let sdp = RemoteSDP(with: "listener",
                              rtcSDP: offer)
                let payload = ["offer" : sdp]
                self.sendPayload(payload)
            }
        }
    }
    
    private func addText(_ message: String) {
        print(message)
    }
    
    private func sendCandidate(_ candidate: RTCIceCandidate) {
        let can = Candidate(rtcICE: candidate)
        let payload = ["candidate" : can]
        self.sendPayload(payload)
    }
}

extension ListenerViewController : WebRTCClientDelegate {
    
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate, clientId: String?) {
        self.sendCandidate(candidate)
    }
    
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState, clientId: String?) {
        
    }
    
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data, clientId: String?) {
        
    }
}
