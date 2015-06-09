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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let deviceID:String = UIDevice.currentDevice().identifierForVendor.UUIDString
        api = NuVentsBackend(delegate: self, server: GlobalVariables.sharedVars.server, device: deviceID)
        GlobalVariables.sharedVars.api = api
        
        // Picker button
        pickerButton.addTarget(self, action: "pickerButtonPressed:", forControlEvents: .TouchUpInside)
        pickerButton.hidden = true
        
        // Set location manager
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
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
        
    }
    
    // Picker button pressed
    func pickerButtonPressed(sender: UIButton!) {
        self.performSegueWithIdentifier("showPickerView", sender: nil)
    }
    
    // Got device location
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        if (serverConn) { // Only use when connected to server
            var latestLoc:CLLocation = locations[locations.count - 1] as! CLLocation
            api?.getNearbyEvents(latestLoc.coordinate, radius: 5000) // Search within 5000 meters
            GlobalVariables.sharedVars.currentLoc = latestLoc // Set current location
            pickerButton.hidden = false
            locationManager.stopUpdatingLocation()
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
        //
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
    }

}
