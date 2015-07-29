//
//  NuVentsHelper.swift
//  NuVents-ios
//
//  Created by hersh amin on 7/29/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import Foundation

class NuVentsHelper {
    
    // Get MD5SUM of data
    class func getMD5SUM(filePath: String) -> String {
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
    
}