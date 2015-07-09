//
//  PartialView.swift
//  NuVents-ios
//
//  Created by hersh amin on 5/11/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import Foundation
import EventKit
import EventKitUI

class DetailViewController: UIViewController, UIWebViewDelegate, EKEventEditViewDelegate {
    
    @IBOutlet var webView:UIWebView!
    @IBOutlet var titleText:UITextView!
    @IBOutlet var backButton:UIButton!
    @IBOutlet var mapButton:UIButton!
    var event:JSON = GlobalVariables.sharedVars.tempJson
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib
        
        // Init vars
        let filePath = NSBundle.mainBundle().pathForResource("detailView", ofType: "html")
        webView.loadRequest(NSURLRequest(URL: NSURL(string: filePath!)!))
        
        // Set status bar text to white color
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
        
        // Record hit on event website by issuing a http get request
        let urlString = event["website"].stringValue
        let url = NSURL(string:urlString)!
        let httpGetTask = NSURLSession.sharedSession().dataTaskWithURL(url) {
            (data, response, error) in
            let resp = response as! NSHTTPURLResponse
            WelcomeViewController.sendWebRespCode(urlString, statusCode: "\(resp.statusCode)")
        }
        httpGetTask.resume()
        
        //Add back button functionality.
        backButton.addTarget(self, action: "backButtonPressed:", forControlEvents: .TouchUpInside)
        
        //Add map button functionality.
        mapButton.addTarget(self, action: "mapButtonPressed:", forControlEvents: .TouchUpInside)
        
        // Write json to file just in case when app crashes, it is known to crash when privacy settings such as accessing calendars, contacts, are changed while app is open in background
        let jsonFilePath = NuVentsBackend.getResourcePath("detailView", type: "tmp", override: false)
        if let currentLoc:CLLocation = GlobalVariables.sharedVars.currentLoc {
            event["currLat"].string = currentLoc.coordinate.latitude.description // Adding current latitude
            event["currLng"].string = currentLoc.coordinate.longitude.description // Adding current longitude
        }
        let jsonFileData = "\(event)".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        jsonFileData?.writeToFile(jsonFilePath, atomically: true)
     
    }
    
    // Called when view controller disappears from the stack
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(true)
        // Erase json file written at the start of this view controller, this signifies that app did not crash while on this view
        let jsonFilePath = NuVentsBackend.getResourcePath("detailView", type: "tmp", override: false)
        let fm = NSFileManager.defaultManager()
        fm.removeItemAtPath(jsonFilePath, error: nil)
    }
    
    // Restrict to portrait only
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }
    
    // Webview finished loading
    func webViewDidFinishLoad(webView: UIWebView) {
        // Calculate distance between current location and event location
        let eventLoc:CLLocation = CLLocation(latitude: event["latitude"].doubleValue, longitude: event["longitude"].doubleValue)
        var currentLoc:CLLocation = CLLocation()
        if let tempLoc:CLLocation = GlobalVariables.sharedVars.currentLoc {
            currentLoc = tempLoc
        } else {
            // Get from last known when state was restored
            currentLoc = CLLocation(latitude: event["currLat"].doubleValue, longitude: event["currLng"].doubleValue)
        }
        let dist = eventLoc.distanceFromLocation(currentLoc) * 0.000621371 // Distance in miles
        let distMi = Double(round(10 * dist)/10) //Round the number
        
        event["distance"].string = distMi.description
        webView.stringByEvaluatingJavaScriptFromString("setEvent(\(event))") // Insert event data into webview
        
        //Native nav-bar stuff. Add the label of the event to the nav-bar
        titleText.text = event["distance"].stringValue + " Miles Away!"
        

    }
    
 
    //Back button pressed
    func backButtonPressed(sender: UIButton!) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //Map button pressedp
    func mapButtonPressed(sender: UIButton!) {
        
        let lat = event["latitude"].stringValue
        let lng = event["longitude"].stringValue
        var addr = event["address"].stringValue
        addr = addr.stringByReplacingOccurrencesOfString(" ", withString: "+", options: NSStringCompareOptions.LiteralSearch, range: nil)
        openMapsApp(lat, lng: lng, Address: addr)
    }
    
    
    // Webview delegate methods
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
    let reqStr = request.URL?.absoluteString
        if reqStr!.rangeOfString("closedetailview://") != nil {
            self.dismissViewControllerAnimated(true, completion: nil)
            return false
        } else if reqStr!.rangeOfString("opencalendar://") != nil {
            openCalendarApp()
            return false
        } else {
            return true
        }
        
    }
    
    // Save event to calendar app
    func openCalendarApp() {
        // Event store (calendar) config
        var eventStore:EKEventStore = EKEventStore()
        var calendarAuthStatus = EKAuthorizationStatus.Denied
        
        // Get calendar authorization status & act accordingly
        var showAlert = false
        var title:String = ""
        var message:String = ""
        calendarAuthStatus = EKEventStore.authorizationStatusForEntityType(EKEntityTypeEvent)
        if (calendarAuthStatus == EKAuthorizationStatus.NotDetermined) { // Ask for access then add
            eventStore.requestAccessToEntityType(EKEntityTypeEvent, completion: {
                (granted, error) in
                if (granted) {
                    dispatch_async(dispatch_get_main_queue(), {self.addEventToCalendar(eventStore)})
                }
            })
        } else if (calendarAuthStatus == EKAuthorizationStatus.Authorized) { // Add event
            self.addEventToCalendar(eventStore)
        } else if (calendarAuthStatus == EKAuthorizationStatus.Denied) { // Show instructions to grant access
            showAlert = true
            title = "Calendar Access Disabled"
            if objc_getClass("UIAlertController") != nil { // ios 8+
                message = "In order to add events, Please open this app's settings and turn on Calendar access"
            } else { // ios 7
                message = "In order to add events, Please open settings, go to Privacy > Calendars > NuVents and Turn on Calendars"
            }
        } else if (calendarAuthStatus == EKAuthorizationStatus.Restricted) { // Notify regarding parental controls
            showAlert = true
            title = "Calendar Access Restricted"
            message = "Parental Controls might be enabled or Calendars might be disabled on your device, if possible, Please open this app's settings to disable Parental Controls or enable Calendars"
        }
        
        // Show Alert view
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
    
    // Helper function to add event to calendar
    func addEventToCalendar(eventStore: EKEventStore) {
        var event:EKEvent = EKEvent(eventStore: eventStore)
        
        // Set event attributes
        event.calendar = eventStore.defaultCalendarForNewEvents
        event.title = self.event["title"].stringValue
        event.startDate = NSDate(timeIntervalSince1970: self.event["time"]["start"].doubleValue)
        event.endDate = NSDate(timeIntervalSince1970: self.event["time"]["end"].doubleValue)
        event.notes = self.event["description"].stringValue
        event.location = self.event["address"].stringValue
        event.URL = NSURL(string: self.event["website"].stringValue)
        
        // Open eventkit UI so user can save to calendar
        var eventController:EKEventEditViewController = EKEventEditViewController()
        eventController.eventStore = eventStore
        eventController.event = event
        eventController.editViewDelegate = self
        
        self.presentViewController(eventController, animated: true, completion: nil)
    }
    
    // Event kit (Calendar) edit view delegate
    func eventEditViewController(controller: EKEventEditViewController!, didCompleteWithAction action: EKEventEditViewAction) {
        
        if (Int(action.value) == Int(EKEventEditViewActionCanceled.value)) {
            // User tapped cancel
        } else if (Int(action.value) == Int(EKEventEditViewActionSaved.value)) {
            // User saved event
            if objc_getClass("UIAlertController") != nil { // ios 8+
                dispatch_async(dispatch_get_main_queue(), {
                    var alert = UIAlertController(title: "Event added to calendar!", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
                    let cancelAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil)
                    alert.addAction(cancelAction)
                    self.presentViewController(alert, animated: true, completion: nil)
                })
            } else { // ios 7
                var alert = UIAlertView(title: "Event added to calendar!", message: nil, delegate: nil, cancelButtonTitle: "OK")
                alert.show()
            }
        } else if (Int(action.value) == Int(EKEventEditViewActionDeleted.value)) {
            // User tapped delete
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // Open location in maps app
    func openMapsApp(lat: String, lng: String, Address: String) {
        let urlToOpen:String
        if (UIApplication.sharedApplication().canOpenURL(NSURL(string: "comgooglemaps-x-callback://")!)) {
            // Google maps available with x-callback functionality
            urlToOpen = "comgooglemaps-x-callback://?q=\(Address)&center=\(lat),\(lng)&views=traffic&x-success=nuvents://&x-source=NuVents"
        } else if (UIApplication.sharedApplication().canOpenURL(NSURL(string:"comgooglemaps://")!)) {
            // Google maps available
            urlToOpen = "comgooglemaps://?q=\(Address)&center=\(lat),\(lng)&views=traffic"
        } else {
            // Use apple maps
            urlToOpen = "http://maps.apple.com/?ll=\(lat),\(lng)&q=\(lat),\(lng)"
        }
        UIApplication.sharedApplication().openURL(NSURL(string: urlToOpen)!)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose any resources that can be recreated
    }
    
}