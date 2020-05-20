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
    @IBOutlet var connectionStatusLable: UILabel!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var roomNameTextField: UITextField!
    
    let udid: String = "LISTENER" // UIDevice.current.identifierForVendor!.uuidString
    var socket: Socket? = nil
    var topic: String = ""
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
            slf.webRtcClient?.disconnect()
        }
        
        socket?.delegateOnError(to: self) { (slf, error) in
            slf.addText("Socket Errored: " + error.localizedDescription)
        }
        
        socket?.logger = { msg in
            //            print("LOG:", msg)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    //----------------------------------------------------------------------
    // MARK: - IBActions
    //----------------------------------------------------------------------
    @IBAction func onConnectButtonPressed(_ sender: UIButton) {
        
        if self.roomNameTextField.text?.isEmpty ?? false {
            let alertController = UIAlertController(title: "Vox Connect", message: "Enter room name", preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction(title: "OK", style: .default) { action -> Void in
                self.roomNameTextField.becomeFirstResponder()
            })
            self.present(alertController, animated: true, completion: nil)
        } else {
            self.view.endEditing(true)
            if socket?.isConnected ?? false {
                disconnectAndLeave()
            } else {
                connectAndJoin()
            }
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
            self.webRtcClient.disconnect()
        }
    }
    
    private func sendMessage(_ message: RemoteMessage) {
        self.lobbyChannel.push("listener_msg", payload: message.toDictionary())
    }
    
    private func connectAndJoin() {
        topic = "room:\(self.roomNameTextField.text!)"
        let channel = socket?.channel(topic, params: ["role": "listener"])
        
        channel?.delegateOn("status", to: self) { (slf, message) in
            slf.handlePayload(message.payload)
        }
        
        channel?.delegateOn("speaker_msg", to: self) { (slf, message) in
            slf.handlePayload(message.payload)
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
        if let speakerStatus = try? SpeakerStatus(dictionary: payload) {
            if speakerStatus.status == "online" {
                self.joinStream()
            }
        }
        if let joinResponse = try? ListenerJoinResponse(dictionary: payload) {
            
            self.twilioCreds = joinResponse.twilio_creds
            if joinResponse.speaker_status.status == "online" {
                self.joinStream()
            } else {
                self.connectionStatusLable.text = "Waiting for the Presenter..."
            }
            
            return
        }
    
        if payload["status"] as? String != "offline" && payload["status"] as? String != "online" {
            if let answerMessage = try? AnswerMessage(dictionary: payload) {
                self.webRtcClient?.set(remoteSdp: answerMessage.sdp.rtcSDP()) { (error) in
                    if error != nil {
                        print("Answer Accepted")
                    }
                }
                return
            }
            if let candidate = try? CandidateMessage(dictionary: payload) {
                self.webRtcClient?.set(remoteCandidate: candidate.candidate.rtcCandidate())
                return
            }
        }
        
        print(payload)
    }
    
    private func joinStream() {
        if let creds = self.twilioCreds {
            let iceServer = RTCIceServer(urlStrings: creds.servers(), username: creds.username, credential: creds.password)
            self.webRtcClient = WebRTCClient(iceServer: iceServer, userType: "listener")
            self.webRtcClient.delegate = self
            
            self.webRtcClient.offer { [unowned self] offer in
                let sdp = SDP(rtcSDP: offer)
                let message = RemoteMessage.sdp(sdp)
                self.sendMessage(message)
            }
        }
    }
    
    private func addText(_ message: String) {
        print(message)
    }
    
    private func sendCandidate(_ candidate: RTCIceCandidate) {
        let can = Candidate(rtcICE: candidate)
        let message = RemoteMessage.candidate(can)
        self.sendMessage(message)
    }
}

extension ListenerViewController : WebRTCClientDelegate {
    
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate, clientId: String?) {
        self.sendCandidate(candidate)
    }
    
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState, clientId: String?) {
        
        switch state {
        case .closed, .disconnected, .failed:
            DispatchQueue.main.async {
                client.disconnect()
                self.disconnectAndLeave()
                
                self.connectionStatusLable.text = ""
            }
            
        case .connected:
            DispatchQueue.main.async {
                self.connectionStatusLable.text = "Listening..."
            }
            
        case .checking:
            DispatchQueue.main.async {
                self.connectionStatusLable.text = "Connecting..."
            }
            
        default:
            print("default")
        }
    }
    
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data, clientId: String?) {
        
    }
}
