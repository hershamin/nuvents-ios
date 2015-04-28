//
//  NuVentsBackend.swift
//  NuVents-ios
//
//  Created by hersh amin on 4/27/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import UIKit

// NuVents backend protocol
@objc protocol NuVentsBackendDelegate {
    
    // MARK: Client Request
    func nuventsServerDidReceiveNearbyEvent(event: NSDictionary)                // Got nearby event
    func nuventsServerDidReceiveEventDetail(event: NSDictionary)                // Got event detail
    
    // MARK: Client Status
    func nuventsServerDidRemoveEvent(event: NSDictionary)                       // Remove event from client
    func nuventsServerDidAddEvent(event:NSDictionary)                           // Add event to client
    
    // MARK: Connection Status
    optional func nuventsServerDidGetNewData(channel:NSString, data:AnyObject)  // Got new data from any WS event
    func nuventsServerDidConnect()                                              // Connected
    func nuventsServerDidDisconnect()                                           // Disconnected
    func nuventsServerDidReceiveError(error: NSString)                          // Error
    optional func nuventsServerDidRespondToPing(response: NSString)             // Got ping response
    
    // MARK: Experimental
    func nuventsServerDidAskStatus() -> NSDictionary                            // Server asking for status
    func nuventsServerDidSendCommand() -> NSString                              // Server sending command
}

// NuVents backend class
class NuVentsBackend {
    
    var nSocket: SocketIOClient
    var delegate: NuVentsBackendDelegate
    var deviceID: NSString
    
    //MARK: initialization called
    init(delegate: NuVentsBackendDelegate, server: NSString) {
        self.delegate = delegate // Assign delegate
        self.deviceID = UIDevice.currentDevice().identifierForVendor.UUIDString as NSString // Get device vendorID
        // Socket connection handling
        nSocket = SocketIOClient(socketURL: server as String, opts:["log":false])
        addSocketHandlingMethods()
        nSocket.connect()
    }
    
    // Get nearby events
    func getNearbyEvents(location: CLLocationCoordinate2D, radius: Float) {
        self.nSocket.emit("event:nearby", ["lat":"\(location.latitude)",
                                            "lng":"\(location.longitude)",
                                            "rad":"\(radius)",
                                            "did":self.deviceID as String])
    }
    
    // Get event detail
    func getEventDetail(eventID: NSString) {
        self.nSocket.emit("event:detail", ["eid":eventID as String,
                                            "did":self.deviceID as String])
    }
    
    func pingServer() { // Ping server for sanity check
        self.nSocket.emit("ping", self.deviceID as String)
    }
    
    //MARK: socket handling methods
    func addSocketHandlingMethods() {
        //TODO: Nearby Event Received
        
        //TODO: Nearby Event Error
        
        //TODO: Detail Event Received
        
        //TODO: Detail Event Error
        
        
        nSocket.on("pong") {data, ack in // Server ping response
            self.delegate.nuventsServerDidRespondToPing!("Ping response: \(data?[0])")
        }
        
        // Connection Status
        nSocket.on("connect") {data, ack in
            self.delegate.nuventsServerDidConnect()
        }
        nSocket.on("disconnect") {data, ack in
            self.delegate.nuventsServerDidDisconnect()
        }
        nSocket.on("error") {data, ack in
            self.delegate.nuventsServerDidReceiveError("Error: \(data?[0])")
        }
        
    }
    
}
