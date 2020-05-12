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
    
    let udid: String = UIDevice.current.identifierForVendor!.uuidString
    var socket: Socket? = nil
    var topic: String = "room:conf1"
    var lobbyChannel: Channel!
    
    // WebRTC
    private var signalClient: SignalingClient?
    private var webRTCClient: WebRTCClient?
    private let config = Config.default
    private var isListening: Bool = false
    
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    // Listener
    override func viewDidLoad() {
        super.viewDidLoad()
        
        socket = Socket("https://vowdemo.herokuapp.com/vow_socket", params: ["token": "TOKEN123", "uuid": self.udid])
        // To automatically manage retain cycles, use `delegate*(to:)` methods.
        // If you would prefer to handle them yourself, youcan use the same
        // methods without the `delegate` functions, just be sure you avoid
        // memory leakse with `[weak self]`
        socket?.delegateOnOpen(to: self) { (self) in
            self.addText("Socket Opened")
            self.connectButton.setTitle("Disconnect", for: .normal)
        }
        
        socket?.delegateOnClose(to: self) { (self) in
            self.addText("Socket Closed")
            self.connectButton.setTitle("Connect", for: .normal)
        }
        
        socket?.delegateOnError(to: self) { (self, error) in
            self.addText("Socket Errored: " + error.localizedDescription)
        }
        
        socket?.logger = { msg in
            print("LOG:", msg)
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
    
    @IBAction func sendMessage(_ sender: UIButton) {
        
        let payload = ["listener_msg": ["a": 1, "b": 2, "c": 4]]
        
        self.lobbyChannel
            .push("listener_msg", payload: payload)
            .receive("ok") { (message) in
                print("success", message)
        }
        .receive("error") { (errorMessage) in
            print("error: ", errorMessage)
        }
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
    
    func sendOffer(to presenter: String) {
        self.isListening = true
        
        self.setupWebRTC(with: "listener", and: presenter)
        
        self.webRTCClient?.offer { (sdp) in
            
            let localsdp = SDP(with: "listener", sourceId: self.udid, destinationId: presenter, rtcSDP: sdp)
            let messageSDP = Message.sdp(localsdp)
            
            do {
                let dataMessage = try self.encoder.encode(messageSDP)
                let json = try JSONSerialization.jsonObject(with: dataMessage, options: []) as? [String : Any]

                let payload = ["listener_msg": ["offer": json]]
                // this.channel.push("listener_msg", {a: 1, b: 2, c: 3})
                self.lobbyChannel
                    .push("listener_msg", payload: payload)
                    .receive("ok") { (message) in
                        print("success", message)
                }
                .receive("error") { (errorMessage) in
                    print("error: ", errorMessage)
                }
            } catch {
                debugPrint("Warning: Could not encode sdp: \(error)")
            }
            
            
            
            // self.signalClient?.send(sdp: sdp, to: presenter)
        }
    }
    
    func setupWebRTC(with userType: String, and presenterId: String) {
        
        self.webRTCClient = WebRTCClient(iceServers: self.config.webRTCIceServers, and: userType, clientId: presenterId)
        self.webRTCClient!.delegate = self
    }
    
    private func connectAndJoin() {
        let channel = socket?.channel(topic, params: ["role": "listener"])
        channel?.delegateOn("join", to: self) { (self, _) in
            self.addText("You joined the room.")
        }
        
        channel?.delegateOn("new:msg", to: self) { (self, message) in
            let payload = message.payload
            guard
                let username = payload["user"],
                let body = payload["body"] else { return }
            let newMessage = "[\(username)] \(body)"
            self.addText(newMessage)
        }
        
        channel?.delegateOn("user:entered", to: self) { (self, message) in
            self.addText("[anonymous entered]")
        }
        
        channel?.onMessage(callback: { message in
            print("OnMessage callback: \(message.payload)")
            
            if let response = message.payload["response"] as? [String: Any] {
                print(response)
                if let status = response["speaker_status"] as? String {
                    if status == "online" {
                        self.sendOffer(to: self.udid)
                    }
                }
                
                if let answer = response["answer"] as? [String: Any] {
                    // accept the answer
                    print(answer)
                }
            }
            
            return message
        })
        
        self.lobbyChannel = channel
        self.lobbyChannel
            .join()
            .delegateReceive("ok", to: self) { (self, _) in
                self.addText("Joined Channel")
                
                self.buildMainViewController()
                
                self.signalClient!.delegate = self
                self.signalClient!.connect()
                
                DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
                    self.signalClient?.sendSyn()
                }
                
        }.delegateReceive("error", to: self) { (self, message) in
            self.addText("Failed to join channel: \(message.payload)")
        }
        self.socket?.connect()
        
    }
    
    private func addText(_ text: String) {
        print("New Message: \(text)\n")
        //        let updatedText = self.chatWindow.text.appending(text).appending("\n")
        //        self.chatWindow.text = updatedText
    }
    
    // WebRTC
    private func buildMainViewController() {
        self.signalClient = self.buildSignalingClient()
    }
    
    private func buildSignalingClient() -> SignalingClient {
        
        // iOS 13 has native websocket support. For iOS 12 or lower we will use 3rd party library.
        let webSocketProvider: WebSocketProvider
        
        if #available(iOS 13.0, *) {
            webSocketProvider = NativeWebSocket(url: self.config.signalingServerUrl)
        } else {
            webSocketProvider = StarscreamWebSocket(url: self.config.signalingServerUrl)
        }
        
        return SignalingClient(webSocket: webSocketProvider)
    }
    
    private func sendAnswer(to listener: String) {
        
        self.webRTCClient?.answer { (localSdp) in
            self.signalClient?.send(sdp: localSdp, to: listener)
        }
    }
}

extension ListenerViewController: SignalClientDelegate {
    
    func signalClient(_ signalClient: SignalingClient, didReceiveRemoteSdp sdp: SDP) {
        
        self.webRTCClient?.set(remoteSdp: sdp.rtcSDP(), completion: { error in
            print(error ?? "")
            print("didReceiveRemoteSdp")
        })
    }
    
    func signalClient(_ signalClient: SignalingClient, didReceiveCandidate candidate: Candidate) {
        
        print("Received remote candidate")
        let rtcCandidate = candidate.rtcCandidate()
        self.webRTCClient?.set(remoteCandidate: rtcCandidate)
    }
    
    func signalClientList(_ list: [String]) {
        
        if !self.isListening {
            //            self.sendOffer(to: selectedStream)
        }
    }
    
    func signalClient(_ signalClient: SignalingClient, didAcceptListener clientType: String) {
        print("didAcceptListener")
    }
    
    func signalClientDidConnect(_ signalClient: SignalingClient) {
        print("signalClientDidConnect")
    }
    
    func signalClientDidDisconnect(_ signalClient: SignalingClient) {
        print("signalClientDidDisconnect")
    }
}

extension ListenerViewController: WebRTCClientDelegate {
    
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate, clientId: String) {
        print("discovered local candidate")
        self.signalClient?.send(candidate: candidate, to: clientId)
        
        let payload = ["listener_msg": ["sdp": candidate.sdp, "sdpMid": candidate.sdpMid ?? "", "sdpMLineIndex": candidate.sdpMLineIndex ]]
        // this.channel.push("listener_msg", {a: 1, b: 2, c: 3})
        self.lobbyChannel
            .push("listener_msg", payload: payload)
            .receive("ok") { (message) in
                print("success", message)
        }
        .receive("error") { (errorMessage) in
            print("error: ", errorMessage)
        }
    }
    
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState, clientId: String) {
        
        if state == .connected {
            
        }
        if state == .closed ||
            state == .disconnected ||
            state == .failed {
            
            DispatchQueue.main.async {
                self.isListening = false
            }
        }
    }
    
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data, clientId: String) {
        
        print("didReceiveData")
    }
}
