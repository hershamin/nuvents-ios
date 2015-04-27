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
    //func didReceiveNearbyEvent(event: NSDictionary)
    //func didReceiveEventDetail(event: NSDictionary)
    optional func didGetNewData(channel:NSString, data:AnyObject)
    optional func didGetStatus(status:NSString)
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
    
    //MARK: Get nearby events
    func getNearbyEvents(location: CLLocationCoordinate2D, radius: Float) {
        //
    }
    
    //MARK: Get event detail
    func getEventDetail(eventID: NSString) {
        //
    }
    
    //MARK: Ping server for sanity check
    func pingServer() {
        self.nSocket.emit("ping", self.deviceID)
    }
    
    //MARK: socket handling methods
    func addSocketHandlingMethods() {
        //TODO: Nearby Event Received
        
        //TODO: Nearby Event Error
        
        //TODO: Detail Event Received
        
        //TODO: Detail Event Error
        
        //TODO: Server Ping
        
        //MARK: Connection Status
        nSocket.on("connect") {data, ack in
            self.delegate.didGetStatus!("Connected to NuVents backend")
        }
        nSocket.on("disconnect") {data, ack in
            self.delegate.didGetStatus!("Disconnected from NuVents backend")
        }
        nSocket.on("error") {data, ack in
            self.delegate.didGetStatus!("Error connecting")
            println("Error: \(data?[0])")
        }
        
    }
    
}
