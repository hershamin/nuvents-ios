//
//  ViewController.swift
//  NuVents-ios
//
//  Created by hersh amin on 4/26/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController, NuVentsBackendDelegate, UIWebViewDelegate, CLLocationManagerDelegate {
    
    var api:NuVentsBackend?
    var serverConn:Bool = false
    var locationManager:CLLocationManager = CLLocationManager()
    @IBOutlet var pickerButton:UIButton!
    @IBOutlet var backgroundImg:UIImageView!
    @IBOutlet var activityIndicator:UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let deviceID:String = UIDevice.currentDevice().identifierForVendor.UUIDString
        GlobalVariables.sharedVars.udid = deviceID
        api = NuVentsBackend(delegate: self, server: GlobalVariables.sharedVars.server, device: deviceID)
        GlobalVariables.sharedVars.api = api
        
        // Set status bar text to white color
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
        
        // Picker button
        pickerButton.addTarget(self, action: "pickerButtonPressed:", forControlEvents: .TouchUpInside)
        pickerButton.hidden = true
        
        // Set location manager
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.delegate = self
        // Location manager special setup for different iOS versions
        switch UIDevice.currentDevice().systemVersion.compare("8.0.0", options: NSStringCompareOptions.NumericSearch) {
        case .OrderedSame, .OrderedDescending: // iOS 8 & above
            println("iOS >= 8.0")
            locationManager.requestWhenInUseAuthorization()
        case .OrderedAscending: // iOS below 8
            println("iOS < 8.0")
        }
        locationManager.startUpdatingLocation()
        
        activityIndicator.startAnimating() // Start activity indicator
        
        // Restore detail view controller
        restoreDetailView() // Will only restore detail view if restore file found
        
    }
    
    // Restore detail view controller
    func restoreDetailView() {
        let filePath = NuVentsBackend.getResourcePath("detailView", type: "tmp", override: false)
        let fm = NSFileManager.defaultManager()
        if (fm.fileExistsAtPath(filePath)) { // Detail view controller restore file exists signifying app crashed when user was at detail view last time
            let fileData = NSData(contentsOfFile: filePath)
            GlobalVariables.sharedVars.tempJson = JSON(data: fileData!)
            // Open detail view controller from main storybaord
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let dvc = storyboard.instantiateViewControllerWithIdentifier("detailViewController") as! UIViewController
            dispatch_async(dispatch_get_main_queue(), {
                self.presentViewController(dvc, animated: true, completion: nil)
            })
        }
    }
    
    // Called when picker view is dismissed to get to welcome view, Next steps will be to rescan for events with new location
    @IBAction func unwindSegueToWelcomeView(segue: UIStoryboardSegue) {
        // Set status bar text to white color
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
        pickerButton.hidden = true // Hide picker button
        GlobalVariables.sharedVars.eventJSON.removeAll(keepCapacity: false)
        // Start location manager
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.startUpdatingLocation()
        activityIndicator.startAnimating() // Start activity indicator
    }
    
    // Picker button pressed
    func pickerButtonPressed(sender: UIButton!) {
        self.performSegueWithIdentifier("showPickerView", sender: nil)
    }
    
    // Device Location authorization status
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        var message:String = ""
        var title:String = ""
        var showAlert = false
        if (status == CLAuthorizationStatus.Denied) {
            // App is denied permission
            showAlert = true
            title = "Location Access Disabled"
            if objc_getClass("UIAlertController") != nil { // ios 8+
                message = "In order to show events, Please open this app's settings and set Location access to 'While Using the App'"
            } else { // ios 7
                message = "In order to show events, Please open settings, go to Privacy > Location Services > NuVents and Turn on Location Services"
            }
        } else if (status == CLAuthorizationStatus.Restricted) {
            // Could be not available or parental controls
            showAlert = true
            title = "Location Access Restricted"
            message = "Parental Controls might be enabled or Location Services might be disabled on your device, if possible, Please open this app's settings to disable Parental Controls or enable Location Services"
        }
        // Show alert view depending on OS
        if (showAlert) {
            if objc_getClass("UIAlertController") != nil { // ios 8+
                var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                let cancelAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil)
                alert.addAction(cancelAction)
                let openAction = UIAlertAction(title: "Open Settings", style: UIAlertActionStyle.Default) { (action) in
                    let url = NSURL(string: UIApplicationOpenSettingsURLString)
                    UIApplication.sharedApplication().openURL(url!)
                }
                alert.addAction(openAction)
                self.presentViewController(alert, animated: true, completion: nil)
            } else { // ios 7
                var alert = UIAlertView(title: title, message: message, delegate: nil, cancelButtonTitle: "OK")
                alert.show()
            }
        }
    }
    
    // Got device location
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        if (serverConn) { // Only use when connected to server
            var latestLoc:CLLocation = locations[locations.count - 1] as! CLLocation
            api?.getNearbyEvents(latestLoc.coordinate, radius: 5000, timestamp: NSDate().timeIntervalSince1970) // Search within 5000 meters
            GlobalVariables.sharedVars.currentLoc = latestLoc // Set current location
            pickerButton.hidden = false
            locationManager.stopUpdatingLocation()
            activityIndicator.stopAnimating() // Stop activity indicator
        }
    }
    
    // Restrict to portrait only
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // NuVents server resources sync complete
    func nuventsServerDidSyncResources() {
        // Set background image
        var imgDir = NuVentsBackend.getResourcePath("tmp", type: "welcomeViewImgs", override: false)
        imgDir = imgDir.stringByReplacingOccurrencesOfString("tmp", withString: "")
        let fileManager:NSFileManager = NSFileManager()
        let files = fileManager.enumeratorAtPath(imgDir)
        var imgs: [String] = []
        while let file: AnyObject = files?.nextObject() {
            imgs.append(imgDir + (file as! String))
        }
        let randomInd = Int(arc4random_uniform(UInt32(imgs.count))) // Pick random img to display
        backgroundImg.image = UIImage(contentsOfFile: imgs[randomInd]) // Set image
    }
    
    // Send event website response code
    class func sendWebRespCode(website: String, statusCode: String) {
        GlobalVariables.sharedVars.api!.sendWebsiteCode(website, code: statusCode)
    }
    
    // Send event request to add city
    class func sendEventRequest(request: String) {
        GlobalVariables.sharedVars.api!.sendEventReq(request)
    }
    
    // Get event detail
    class func getEventDetail(eid: String, callback:(JSON) -> Void) {
        GlobalVariables.sharedVars.api!.getEventDetail(eid, callback: { (jsonData: JSON) -> Void in
            // Merge event summary & detail
            let summary:JSON = GlobalVariables.sharedVars.eventJSON[eid]!
            var jsonData = jsonData
            for (summ: String, subJson: JSON) in summary {
                jsonData[summ] = subJson
            }
            callback(jsonData)
        })
    }
    
    // MARK: NuVents backend delegate methods
    func nuventsServerDidConnect() {
        println("NuVents backend connected")
        api?.pingServer()
        serverConn = true
    }
    
    func nuventsServerDidDisconnect() {
        println("NuVents backend disconnected")
    }
    
    func nuventsServerDidGetNewData(channel: NSString, data: AnyObject) {
        //println("NuVents channel \(channel) with data \(data)")
    }
    
    func nuventsServerDidRespondToPing(response: NSString) {
        //
    }
    
    func nuventsServerDidReceiveError(type: NSString, error: NSString) {
        //
    }
    
    func nuventsServerDidReceiveStatus(type: NSString, status: NSString) {
        //
    }
    
    func nuventsServerDidReceiveNearbyEvent(event: JSON) {
        // Add to global vars
        GlobalVariables.sharedVars.eventJSON[event["eid"].stringValue] = event
        // Update count in picker view
        PickerViewController.updateEventCount()
    }

}

