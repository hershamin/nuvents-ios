//
//  NuVentsEndpoint.swift
//  NuVents-ios
//
//  Created by hersh amin on 7/29/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import Foundation


class NuVentsEndpoint {
    
    // Singleton Initialization
    class var sharedEndpoint: NuVentsEndpoint {
        struct Static {
            static let instance = NuVentsEndpoint()
        }
        return Static.instance
    }
    
    // Global Constants
    internal let udid:String = UIDevice.currentDevice().identifierForVendor.UUIDString // Unique Device ID
    internal let mapboxToken:String = "sk.eyJ1IjoiaGVyc2hhbWluIiwiYSI6ImUxOGRkZWQ0NGE4YjcyNjZmOGU4MzYxNWI3NTEzMTIzIn0.b5wf8U-tHvq00cPlEGrFhQ"
    internal let mapboxMapId:String = "hershamin.n2ld8p7j"
    internal let categoryNotificationKey = "categoryNotificationKey"
    internal let searchNotificationKey = "searchNotificationKey"
    internal let eventDetailNotificationKey = "eventDetailNotificationKey"

    
    // Global Variables
    internal var eventJSON = [String: JSON]() // To store events
    internal var categories:Set<String> = Set() // To store selected categories
    internal var searchText:String = "" // To store search bar text
    internal var currLoc:CLLocationCoordinate2D! // To store current device location
    internal var tempJson = JSON("") // To store eventJson when going to detail view
    internal var detailFromWelcome:Bool = false // To store whether detail view was loaded from welcome view
    
    
    // Internally used variables
    private var nSocket: SocketIOClient = SocketIOClient(socketURL: backend, options: ["log":false])
        // The variable "backend" is Compiled during build, Set in AppDelegate.swift
    private var connected:Bool = false // To keep track of server connection status
    private var retryTimer:NSTimer! // To store NSTimer object for retrying server connection
    private var lastNearbyEventRequest:String = "" // To keep track of last event nearby request
        // lat,lng,rad
    
    // Connect to Backend
    func connect() {
        addSocketHandlingMethods()
        nSocket.connect()
        // Initialte reconnection timer
        self.retryTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "RetryServerConnection:", userInfo: nil, repeats: true) // Check for connection every second
    }
    
    // Disconnect from backend
    func disconnect(fast: Bool) {
        nSocket.disconnect(fast: fast)
        // Invalidate reconnection timer
        self.retryTimer.invalidate()
    }
    
    // Server connection retry timer
    @objc func RetryServerConnection(sender:NSTimer!) {
        if !connected { // Attempt to connect if disconnected
            nSocket.reconnect()
        }
    }
    
    // Send event website response code
    func sendWebsiteCode(website: String, code: String) {
        self.nSocket.emit("event:website", ["website":"\(website)",
            "respCode":"\(code)"])
    }
    
    // Send event request to add city
    func sendEventReq(request: String) {
        self.nSocket.emit("event:request", request)
    }
    
    // Get nearby events
    func getNearbyEvents(location: CLLocationCoordinate2D, radius: Float) {
        if (connected) { // Connected to server
            self.nSocket.emit("event:nearby", ["lat":"\(location.latitude)",
                "lng":"\(location.longitude)",
                "rad":"\(radius)",
                "time":"\(NSDate().timeIntervalSince1970)",
                "did":NuVentsEndpoint.sharedEndpoint.udid])
        } else {
            // Server not connected yet, store in lastNearbyEventRequest variable
            lastNearbyEventRequest = "\(location.latitude),\(location.longitude),\(radius)"
        }
    }
    
    // Get event detail
    func getEventDetail(eventID: NSString) {
        let eventDict = ["did":NuVentsEndpoint.sharedEndpoint.udid,
            "eid":eventID as String,
            "time":"\(NSDate().timeIntervalSince1970)"]
        self.nSocket.emit("event:detail", eventDict)
    }
    
    // Get resources from server
    private func getResourcesFromServer() {
        let deviceDict = ["did":NuVentsEndpoint.sharedEndpoint.udid as String,
            "dm":NuVentsHelper.getDeviceHardware()]
        self.nSocket.emit("resources", deviceDict) // Request resource sync
    }
    
    // Sync resources with server
    private func syncResources(jsonData: JSON) {
        var fm = NSFileManager.defaultManager()
        // Get resources if not present on the internal file system or different
        for (type : String, typeJson : JSON) in jsonData["resource"] { // Resource types
            for (resource: String, resJson: JSON) in typeJson { // Resources
                let path = NuVentsHelper.getResourcePath(resource, type: type)
                if (!fm.fileExistsAtPath(path)) { // File does not exist
                    NuVentsHelper.downloadFile(path, url: resJson.stringValue) // Download from provided url
                } else {
                    let md5sumWeb = jsonData["md5sum"][type][resource].stringValue
                    let md5sumInt = NuVentsHelper.getMD5SUM(path)
                    if (md5sumWeb != md5sumInt) { // MD5 sum does not match, redownload file
                        NuVentsHelper.downloadFile(path, url: resJson.stringValue) // Download from provided url
                    }
                }
                
            }
        }
        println("NuVents Endpoint: Resources Sync Complete")
    }
    
    // Send request to retrieve missed messages from server
    private func retrieveMissedMessages() {
        let deviceDict = ["did":NuVentsEndpoint.sharedEndpoint.udid as String,
            "dm":NuVentsHelper.getDeviceHardware()]
        self.nSocket.emit("history", deviceDict)
    }
    
    // MARK: socket handling methods
    private func addSocketHandlingMethods() {
        // Nearby Event Received
        nSocket.on("event:nearby") {data, ack in
            let dataFromString = "\(data![0])".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            let jsonData = JSON(data: dataFromString!)
            // Add to global vars
            NuVentsEndpoint.sharedEndpoint.eventJSON[jsonData["eid"].stringValue] = jsonData
            // Acknowledge Server
            ack!("Nearby Event Received")
        }
        
        // Nearby Event Error & Status
        nSocket.on("event:nearby:status") {data, ack in
            let resp = "\(data![0])"
            if resp.rangeOfString("Error") != nil { // error status
                println("NuVents Endpoint: ERROR: Event Nearby: \(resp)")
            } else {
                println("NuVents Endpoint: Event Nearby Received")
            }
            // Acknowledge Server
            ack!("Nearby Event Status Received")
        }
        
        // Event Detail Received
        nSocket.on("event:detail") {data, ack in
            let dataFromString = "\(data![0])".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            let jsonData = JSON(data: dataFromString!)
            // Set global variable
            NuVentsEndpoint.sharedEndpoint.tempJson = jsonData
            // Notify Views
            NSNotificationCenter.defaultCenter().postNotificationName(NuVentsEndpoint.sharedEndpoint.eventDetailNotificationKey, object: nil)
            // Acknowledge Server
            ack!("Event Detail Received")
        }
        
        // Event Detail Error & Status
        nSocket.on("event:detail:status") {data, ack in
            let resp = "\(data![0])"
            if resp.rangeOfString("Error") != nil { // error status
                println("NuVents Endpoint: ERROR: Event Detail: \(resp)")
            } else {
                println("NuVents Endpoint: Event Detail Received")
            }
        }
        
        // Resources received from server
        nSocket.on("resources") {data, ack in
            let resp = "\(data![0])"
            if resp.rangeOfString("Error") != nil { // error status
                println("NuVents Endpoint: ERROR: Resources: \(resp)")
            } else {
                println("NuVents Endpoint: Resources Received")
                let jsonData:NSData = resp.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
                self.syncResources(JSON(data: jsonData)) // Sync Resources
            }
            // Acknowledge Server
            ack!("Resources Received")
        }
        
        // Connection Status
        nSocket.on("connect") {data, ack in
            self.retrieveMissedMessages()
            self.getResourcesFromServer()
            self.connected = true
            // Send last known nearby event request if it exists
            if (count(self.lastNearbyEventRequest) > 0) {
                let comps = self.lastNearbyEventRequest.componentsSeparatedByString(",")
                let lat = (comps[0] as NSString).doubleValue
                let lng = (comps[1] as NSString).doubleValue
                let rad = (comps[2] as NSString).floatValue
                self.getNearbyEvents(CLLocationCoordinate2DMake(lat, lng), radius: rad)
                self.lastNearbyEventRequest = "" // Reset last nearby event request variable
            }
            println("NuVents Endpoint: Connected")
        }
        nSocket.on("disconnect") {data, ack in
            self.connected = false
            println("NuVents Endpoint: Disconnected")
            self.nSocket.removeAllHandlers()
        }
        nSocket.on("error") {data, ack in
            self.connected = false
            println("NuVents Endpoint: ERROR: Connection: \(data![0])")
        }
    }
    
}