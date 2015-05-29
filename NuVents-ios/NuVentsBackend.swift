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
    
    // Sync resources with server
    func syncResources(jsonData: JSON) {
        var fm = NSFileManager.defaultManager()
        // Get resources if not present on the internal file system or different
        for (type : String, typeJson : JSON) in jsonData["resource"] { // Resource types
            for (resource: String, resJson: JSON) in typeJson { // Resources

                let path = NuVentsBackend.getResourcePath(resource, type: type, override: true)
                if (!fm.fileExistsAtPath(path)) { // File does not exist
                    self.downloadFile(path, url: resJson.stringValue) // Download from provided url
                } else {
                    let md5sumWeb = jsonData["md5sum"][type][resource].stringValue
                    let md5sumInt = self.getMD5SUM(path)
                    if (md5sumWeb != md5sumInt) { // MD5 sum does not match, redownload file
                        self.downloadFile(path, url: resJson.stringValue) // Download from provided url
                    }
                }
                
            }
        }
        self.delegate.nuventsServerDidSyncResources() // signal that resources are synced with the devce
    }
    
    // Function to download from web & save
    func downloadFile(filePath: String, url: String) {
        let urlU = NSURL(string: url)
        let urlData: NSData = NSData(contentsOfURL: urlU!)!
        urlData.writeToFile(filePath, atomically: true)
    }
    
    // Get MD5SUM of data
    func getMD5SUM(filePath: String) -> String {
        let inputData: NSData = NSData(contentsOfFile: filePath)!
        
        let digestLength = Int(CC_MD5_DIGEST_LENGTH)
        let md5Buffer = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLength)
        
        CC_MD5(inputData.bytes, CC_LONG(inputData.length), md5Buffer)
        var output = NSMutableString(capacity: Int(CC_MD5_DIGEST_LENGTH * 2))
        for i in 0..<digestLength {
            output.appendFormat("%02x", md5Buffer[i])
        }
        
        return NSString(format: output) as String
    }
    
    // Get device hardware type
    func getDeviceHardware() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let machine = systemInfo.machine
        let mirror = reflect(machine)
        var identifier = ""
            
        for i in 0..<mirror.count {
            if let value = mirror[i].1.value as? Int8 where value != 0 {
                identifier.append(UnicodeScalar(UInt8(value)))
            }
        }
        return identifier
    }
    
    // Resize image based on width
    class func resizeImage(origImage: UIImage, width: Float) -> UIImage {
        let oldWidth = origImage.size.width
        let scaleFactor = CGFloat(width) / oldWidth
        
        let newHeight = origImage.size.height * scaleFactor
        let newWidth = oldWidth * scaleFactor
        
        UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight))
        origImage.drawInRect(CGRectMake(0, 0, newWidth, newHeight))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    // Get resource from internal file system
    class func getResourcePath(resource: NSString!, type: NSString!, override: Bool) -> String {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
        // Create directories if not present
        var fm = NSFileManager.defaultManager()
        var isDir: ObjCBool = true
        let resDir = documentsPath.stringByAppendingPathComponent("resources").stringByAppendingPathComponent(type as String)
        if !fm.fileExistsAtPath(resDir, isDirectory: &isDir) {
            if isDir {
                fm.createDirectoryAtPath(resDir, withIntermediateDirectories: true, attributes: nil, error: nil)
            }
        }
        // Return filepath
        var filePath = resDir.stringByAppendingPathComponent(resource as String)
        // Check if marker icon exists, if not send a default one
        if !fm.fileExistsAtPath(filePath) && type.isEqualToString("marker") && !override {
            filePath = resDir.stringByAppendingPathComponent("default")
        } // Only triggered if override is set to true
        return filePath
    }
    
    // Get nearby events
    func getNearbyEvents(location: CLLocationCoordinate2D, radius: Float) {
        self.nSocket.emit("event:nearby", ["lat":"\(location.latitude)",
                                            "lng":"\(location.longitude)",
                                            "rad":"\(radius)",
                                            "did":self.deviceID as String])
    }
    
    // Get event detail
    func getEventDetail(eventID: NSString, callback:(JSON) -> Void) {
        let eventDict = ["did":self.deviceID as String,
                            "eid":eventID as String]
        self.nSocket.emitWithAck("event:detail", eventDict)(timeout: 0){data in
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
    
    func pingServer() { // Ping server for sanity check
        self.nSocket.emit("ping", self.deviceID as String)
    }
    
    //MARK: socket handling methods
    func addSocketHandlingMethods() {
        //MARK: Nearby Event Received
        nSocket.on("event:nearby") {data, ack in
            let dataFromString = "\(data![0])".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            let jsonData = JSON(data: dataFromString!)
            self.delegate.nuventsServerDidReceiveNearbyEvent(jsonData)
            
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
        
        //MARK: Resources Status
        nSocket.on("resources:status") {data, ack in
            let resp = "\(data?[0])"
            if resp.rangeOfString("Error") != nil { // error status
                self.delegate.nuventsServerDidReceiveError("Resources", error: resp)
            } else {
                self.delegate.nuventsServerDidReceiveStatus("Resources", status: resp)
            }
        }
        
        nSocket.on("pong") {data, ack in // MARK: Server ping response
            self.delegate.nuventsServerDidRespondToPing("\(data?[0])")
        }
        
        // MARK: Received resources from server
        nSocket.on("resources") {data, ack in
            let dataFromString = "\(data![0])".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            let jsonData = JSON(data: dataFromString!)
            self.syncResources(jsonData)
        }
        
        // MARK: Connection Status
        nSocket.on("connect") {data, ack in
            self.delegate.nuventsServerDidConnect()
            let deviceDict = ["did":self.deviceID as String,
                "dm":self.getDeviceHardware()]
            self.nSocket.emit("device:initial", deviceDict)
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
