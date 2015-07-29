//
//  NuVentsBackend.swift
//  NuVents-ios
//
//  Created by hersh amin on 4/27/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import UIKit

// NuVents backend protocol
protocol NuVentsBackendDelegate {
    
    // MARK: Resources ready
    func nuventsServerDidSyncResources()                                    // Resources are synced with device
    
    // MARK: Client Request
    func nuventsServerDidReceiveNearbyEvent(event: JSON)                    // Got nearby event
    
    // MARK: Connection Status
    func nuventsServerDidGetNewData(channel:NSString, data:AnyObject)       // Got new data from any WS event
    func nuventsServerDidConnect()                                          // Connected
    func nuventsServerDidDisconnect()                                       // Disconnected
    func nuventsServerDidRespondToPing(response: NSString)                  // Got ping response
    
    // MARK: Client Request Status & Other errors
    func nuventsServerDidReceiveError(type: NSString, error: NSString)      // Error
    func nuventsServerDidReceiveStatus(type: NSString, status: NSString)    // Status

}

// NuVents backend class
class NuVentsBackend {
    
    var nSocket: SocketIOClient
    var delegate: NuVentsBackendDelegate
    var deviceID: NSString
    
    //MARK: initialization called
    init(delegate: NuVentsBackendDelegate, server: NSString, device: NSString) {
        self.delegate = delegate // Assign delegate
        self.deviceID = device // Get device vendorID
        // Socket connection handling
        nSocket = SocketIOClient(socketURL: server as String, opts:["log":false])
        addSocketHandlingMethods()
        nSocket.connect()
    }
    
    func pingServer() { // Ping server for sanity check
        self.nSocket.emit("ping", self.deviceID as String)
    }
    
    //MARK: socket handling methods
    func addSocketHandlingMethods() {
        
        // MARK: On any socket event
        nSocket.onAny {self.delegate.nuventsServerDidGetNewData("\($0.event)", data: "\($0.items)")}
        
    }
    
}
