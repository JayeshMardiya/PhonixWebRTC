//
//  ListenerViewController.swift
//  PhonixWebRTC
//
//  Created by Jayesh Mardiya on 12/05/20.
//  Copyright © 2020 Jayesh Mardiya. All rights reserved.
//

import UIKit
import SwiftPhoenixClient

class PresenterViewController: UIViewController {
    
    //----------------------------------------------------------------------
    // MARK: - Child Views
    //----------------------------------------------------------------------
    @IBOutlet weak var connectButton: UIButton!
    
    let udid: String = "SPEAKER" // UIDevice.current.identifierForVendor!.uuidString
    var socket: Socket? = nil
    var topic: String = "room:party"
    var lobbyChannel: Channel!
    
    private var arrayListener: [String: WebRTCClient] = [:]
    
    // WebRTC
    private let config = Config.default
    private var isListening: Bool = false
    
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
    
    private func sendMessage(to listener: String) {
        self.lobbyChannel.push("speaker_msg",
                               payload: ["message" : "Message From Speaker",
                                         "to": listener]
        )
            .delegateReceive("ok", to: self) { (slf, message) in
                print(message)
        }.delegateReceive("error", to: self) { (slf, message) in
            print(message)
        }
    }
    
    private func connectAndJoin() {
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
            .delegateReceive("ok", to: self) { (slf, _) in
                slf.addText("Joined Channel")
            }.delegateReceive("error", to: self) { (slf, message) in
                slf.addText("Failed to join channel: \(message.payload)")
            }
        
        self.socket?.connect()
    }
    
    private func handlePayload(_ payload: [String : Any]) {
        if let offer = try? OfferMessage(dictionary: payload) {
            print(offer)
        }
        if let candidate = try? CandidateMessage(dictionary: payload) {
            print(candidate)
        }
    }
    
    private func addText(_ message: String) {
        print(message)
    }
}
