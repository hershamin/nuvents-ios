//
//  NuVentsHelper.swift
//  NuVents-ios
//
//  Created by hersh amin on 7/29/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import Foundation
import JavaScriptCore

class NuVentsHelper {
    
    // Get MD5SUM of data
    class func getMD5SUM(filePath: String) -> String {
        let inputData: NSData = NSData(contentsOfFile: filePath)!
        
        let digestLength = Int(CC_MD5_DIGEST_LENGTH)
        let md5Buffer = UnsafeMutablePointer<CUnsignedChar>.alloc(digestLength)
        
        CC_MD5(inputData.bytes, CC_LONG(inputData.length), md5Buffer)
        let output = NSMutableString(capacity: Int(CC_MD5_DIGEST_LENGTH * 2))
        for i in 0..<digestLength {
            output.appendFormat("%02x", md5Buffer[i])
        }
        
        return NSString(format: output) as String
    }
    
    // Function to download from web & save
    class func downloadFile(filePath: String, url: String) {
        let urlU = NSURL(string: url)
        let urlData: NSData = NSData(contentsOfURL: urlU!)!
        urlData.writeToFile(filePath, atomically: true)
    }
    
    // Get device hardware type
    class func getDeviceHardware() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let machine = systemInfo.machine
        let mirror = Mirror(reflecting: machine)
        var identifier = ""
        
        for child in mirror.children where child.value as? Int8 != 0 {
            identifier.append(UnicodeScalar(UInt8(child.value as! Int8)))
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
    class func getResourcePath(resource: NSString!, type: NSString!) -> String {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] 
        // Create directories if not present
        let fm = NSFileManager.defaultManager()
        var isDir: ObjCBool = true
        let resDir = "\(documentsPath)/resources/\(type)/"
        if !fm.fileExistsAtPath(resDir, isDirectory: &isDir) {
            if isDir {
                do {
                    try fm.createDirectoryAtPath(resDir, withIntermediateDirectories: true, attributes: nil)
                } catch _ {
                }
            }
        }
        // Return filepath
        let filePath = "\(resDir)/\(resource)"
        return filePath
    }
    
    // Convert EPOCH timestamp to human readable date
    class func getHumanReadableDate(epochTimestamp: String) -> String {
        // Get javascript string from file
        let filePath = NSBundle.mainBundle().pathForResource("NuVentsHelperJS", ofType: "js")
        let fileStr = try! NSString(contentsOfFile: filePath!, encoding: NSUTF8StringEncoding)
        
        // Get javascript engine & evaluate
        let context = JSContext()
        context.evaluateScript(fileStr as String)
        
        // Call function to convert epoch to human readable date
        let currentTS = NSDate().timeIntervalSince1970
        let dateStr:JSValue = context.evaluateScript("getHumanReadableDate(\(epochTimestamp), \(currentTS))")
        
        // Return human readable date
        return dateStr.toString();
    }
    
    // Get day difference within a month
    class func getDayDifferenceWithinAMonth(epochTimestamp: String) -> Int {
        // Get javascript string from file
        let filePath = NSBundle.mainBundle().pathForResource("NuVentsHelperJS", ofType: "js")
        let fileStr = try! NSString(contentsOfFile: filePath!, encoding: NSUTF8StringEncoding)
        
        // Get javascript engine & evaluate
        let context = JSContext()
        context.evaluateScript(fileStr as String)
        
        // Call function to get day difference within a month
        let currentTS = NSDate().timeIntervalSince1970
        let diffInt:JSValue = context.evaluateScript("getDayDifferenceWithinAMonth(\(epochTimestamp), \(currentTS))")
        
        // Return readable int
        return Int(diffInt.toInt32())
    }
    
}