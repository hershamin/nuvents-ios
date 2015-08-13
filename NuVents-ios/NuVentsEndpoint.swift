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
    
    // Global Variables
    internal var eventJSON = [String: JSON]() // To store events
    internal var categories:Set<String> = Set() // To store selected categories
    
    // Internally used variables
    private var nSocket: SocketIOClient = SocketIOClient(socketURL: backend, options: ["log":false])
        // The variable "backend" is Compiled during build, Set in AppDelegate.swift
    private var connected:Bool = false // To keep track of server connection status
    private var lastNearbyEventRequest:String = "" // To keep track of last event nearby request
        // lat,lng,rad
    
    // Connect to Backend
    func connect() {
        addSocketHandlingMethods()
        nSocket.connect()
    }
    
    // Disconnect from backend
    func disconnect(fast: Bool) {
        nSocket.removeAllHandlers()
        nSocket.disconnect(fast: fast)
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
    func getEventDetail(eventID: NSString, callback:(JSON) -> Void) {
        let eventDict = ["did":NuVentsEndpoint.sharedEndpoint.udid,
            "eid":eventID as String]
        self.nSocket.emitWithAck("event:detail", eventDict)(timeoutAfter: 0){data in
            let retStr = "\(data![0])"
            if (retStr.rangeOfString("Error") == nil) {
                let dataFromString = retStr.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
                let jsonData = JSON(data: dataFromString!)
                callback(jsonData)
            } else {
                // TODO: Handle ERROR
            }
        }
    }
    
    // Get resources from server
    private func getResourcesFromServer() {
        let deviceDict = ["did":NuVentsEndpoint.sharedEndpoint.udid as String,
            "dm":NuVentsHelper.getDeviceHardware()]
        self.nSocket.emitWithAck("resources", deviceDict)(timeoutAfter: 0){data in
            println("NuVents Endpoint: Resources Received")
            let dataFromString = "\(data![0])".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            let jsonData = JSON(data: dataFromString!)
            self.syncResources(jsonData)
        }
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
    
    // MARK: socket handling methods
    private func addSocketHandlingMethods() {
        // Nearby Event Received
        nSocket.on("event:nearby") {data, ack in
            let dataFromString = "\(data![0])".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            let jsonData = JSON(data: dataFromString!)
            // Add to global vars
            NuVentsEndpoint.sharedEndpoint.eventJSON[jsonData["eid"].stringValue] = jsonData
        }
        
        // Nearby Event Error & Status
        nSocket.on("event:nearby:status") {data, ack in
            let resp = "\(data?[0])"
            if resp.rangeOfString("Error") != nil { // error status
                println("NuVents Endpoint: ERROR: Event Nearby: \(resp)")
            } else {
                println("NuVents Endpoint: Event Nearby Received")
            }
        }
        
        // Connection Status
        nSocket.on("connect") {data, ack in
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
        }
        nSocket.on("error") {data, ack in
            println("NuVents Endpoint: ERROR: Connection: \(data?[0])")
        }
    }
    
}