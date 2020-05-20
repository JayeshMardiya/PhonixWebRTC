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

class PresenterViewController: UIViewController {
    
    //----------------------------------------------------------------------
    // MARK: - Child Views
    //----------------------------------------------------------------------
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var roomNameTextField: UITextField!
    @IBOutlet var listenerCountLabel: UILabel!
    
    let udid: String = "SPEAKER" // UIDevice.current.identifierForVendor!.uuidString
    var socket: Socket? = nil
    var topic: String = "room:party"
    var lobbyChannel: Channel!
    
    private var clientMap: [String: WebRTCClient] = [:]
    
    // WebRTC
    private let config = Config.default
    
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    private var twilioCreds: TwilioCreds!
    
    // Listener
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.roomNameTextField.becomeFirstResponder()
        
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
        for client in self.clientMap.values {
            client.disconnect()
        }
        self.clientMap.removeAll()
        lobbyChannel.leave()
        socket?.disconnect {
            self.addText("Socket Disconnected")
        }
    }
    
    private func sendPayload(_ payload: [String : Any], to listener: String) {
        var message = payload
        message["to"] = listener
        self.lobbyChannel.push("speaker_msg", payload: message)
    }
    
    private func connectAndJoin() {
        topic = "room:\(self.roomNameTextField.text!)"
        let channel = socket?.channel(topic, params: ["role": "speaker"])
        
        channel?.delegateOn("status", to: self, callback: { (slf, message) in
            print(message)
        })
        
        channel?.delegateOn("listener_msg", to: self) { (slf, message) in
            let payload = message.payload
            slf.handlePayload(payload)
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
        if let joinResponse = try? SpeakerJoinResponse(dictionary: payload) {
            self.twilioCreds = joinResponse.twilio_creds
            return
        }
        
        if payload["type"] as? String == "sdp" {
            if let offerMessage = try? OfferMessage(dictionary: payload) {
                if let creds = self.twilioCreds {
                    let iceServer = RTCIceServer(urlStrings: creds.servers(),
                                                 username: creds.username,
                                                 credential: creds.password)
                    
                    let rtcClient = WebRTCClient(iceServer: iceServer, userType: "presenter", clientId: offerMessage.src)
                    rtcClient.delegate = self
                    self.clientMap[offerMessage.src] = rtcClient
                    rtcClient.set(remoteSdp: offerMessage.payload.rtcSDP()) { error in
                        self.sendAnswer(to: offerMessage.src)
                    }
                }
                return
            }
        } else if payload["type"] as? String == "candidate" {
            if let candidate = try? CandidateMessage(dictionary: payload) {
                if let client = self.clientMap.value(forKey: candidate.src!) {
                    client.set(remoteCandidate: candidate.candidate.rtcCandidate())
                }
                return
            }
        }
    }
    
    private func sendAnswer(to listener: String) {
        if let client = self.clientMap.value(forKey: listener) {
            client.answer { answer in
                let sdp = SDP(rtcSDP: answer)
                self.sendPayload(sdp.toDictionary(), to: listener)
            }
        }
    }
    
    private func sendCandidate(_ candidate: RTCIceCandidate, to listener: String) {
        let can = Candidate(rtcICE: candidate)
        self.sendPayload(can.toDictionary(), to: listener)
    }
    
    private func updateListenerCount() {
        self.listenerCountLabel.text = "Listener Count: \(self.clientMap.count)"
    }
    
    private func addText(_ message: String) {
        print(message)
    }
}

extension PresenterViewController : WebRTCClientDelegate {
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate, clientId: String?) {
        if let listener = clientId {
            self.sendCandidate(candidate, to: listener)
        }
    }
    
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState, clientId: String?) {
        
        switch state {
            case .closed, .disconnected, .failed:
                DispatchQueue.main.async {
                    if let strClientId = clientId {
                        self.clientMap.value(forKey: strClientId)?.disconnect()
                        self.clientMap.removeValue(forKey: strClientId)
                    }
                    
                    self.updateListenerCount()
                }
            
            case .connected:
                DispatchQueue.main.async {
                    self.updateListenerCount()
                }
            
            default:
                print("default")
        }
    }
    
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data, clientId: String?) {
        
    }
}
