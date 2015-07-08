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
     
    }
    
    // Restrict to portrait only
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }
    
    // Webview finished loading
    func webViewDidFinishLoad(webView: UIWebView) {
        // Calculate distance between current location and event location
        let eventLoc:CLLocation = CLLocation(latitude: event["latitude"].doubleValue, longitude: event["longitude"].doubleValue)
        let currentLoc:CLLocation = GlobalVariables.sharedVars.currentLoc!
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
        
        // Add to calendar
        eventStore.requestAccessToEntityType(EKEntityTypeEvent, completion: {
            (granted, error) in
            if (granted) && (error == nil) {
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
        })
        
    }
    
    // Event kit (Calendar) edit view delegate
    func eventEditViewController(controller: EKEventEditViewController!, didCompleteWithAction action: EKEventEditViewAction) {
        
        if (action.value == EKEventEditViewActionCanceled.value) {
            // User tapped cancel
        } else if (action.value == EKEventEditViewActionSaved.value) {
            // User saved event
        } else if (action.value == EKEventEditViewActionDeleted.value) {
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