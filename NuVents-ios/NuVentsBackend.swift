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
    func nuventsServerDidReceiveNearbyEvent(event: NSDictionary)            // Got nearby event
    func nuventsServerDidReceiveEventDetail(event: NSDictionary)            // Got event detail
    
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
        //MARK: Nearby Event Received
        nSocket.on("event:nearby") {data, ack in
            let dataTemp:NSData = NSKeyedArchiver.archivedDataWithRootObject(data!)
            let dataDict:NSDictionary = NSKeyedUnarchiver.unarchiveObjectWithData(dataTemp)! as! NSDictionary
            self.delegate.nuventsServerDidReceiveNearbyEvent(dataDict)
        }
        
        //MARK: Nearby Event Error & Status
        nSocket.on("event:nearby:status") {data, ack in
            let resp = "\(data?[0])"
            if resp.rangeOfString("Error") != nil { // error status
                self.delegate.nuventsServerDidReceiveError("Event Nearby", error: resp)
            } else {
                self.delegate.nuventsServerDidReceiveStatus("Event Nearby", status: resp)
            }
        }
        
        //MARK: Detail Event Received
        nSocket.on("event:detail") {data, ack in
            let dataTemp:NSData = NSKeyedArchiver.archivedDataWithRootObject(data!)
            let dataDict:NSDictionary = NSKeyedUnarchiver.unarchiveObjectWithData(dataTemp)! as! NSDictionary
            self.delegate.nuventsServerDidReceiveEventDetail(dataDict)
        }
        
        //MARK: Detail Event Error & Status
        nSocket.on("event:detail:status") {data, ack in
            let resp = "\(data?[0])"
            if resp.rangeOfString("Error") != nil { // error status
                self.delegate.nuventsServerDidReceiveError("Event Detail", error: resp)
            } else {
                self.delegate.nuventsServerDidReceiveStatus("Event Detail", status: resp)
            }
        }
        
        nSocket.on("pong") {data, ack in // MARK: Server ping response
            self.delegate.nuventsServerDidRespondToPing("\(data?[0])")
        }
        
        // MARK: Connection Status
        nSocket.on("connect") {data, ack in
            self.delegate.nuventsServerDidConnect()
        }
        nSocket.on("disconnect") {data, ack in
            self.delegate.nuventsServerDidDisconnect()
        }
        nSocket.on("error") {data, ack in
            self.delegate.nuventsServerDidReceiveError("Connection", error: "\(data?[0])")
        }
        
        // MARK: On any socket event
        nSocket.onAny {self.delegate.nuventsServerDidGetNewData("\($0.event)", data: "\($0.items)")}
        
    }
    
}
