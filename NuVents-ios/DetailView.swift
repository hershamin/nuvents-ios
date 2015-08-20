//
//  DetailView.swift
//  NuVents-ios
//
//  Created by hersh amin on 8/1/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import Foundation
import EventKit
import EventKitUI

class DetailViewController: UIViewController, EKEventEditViewDelegate {
    
    let eventJson:JSON = NuVentsEndpoint.sharedEndpoint.tempJson
    @IBOutlet var mediaImgView:UIImageView!
    @IBOutlet var backBtn:UIButton!
    @IBOutlet var addToCalBtn:UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Init back button
        backBtn.addTarget(self, action: "backBtnPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // Init add to calendar button
        addToCalBtn.layer.borderColor = UIColor.whiteColor().CGColor
        addToCalBtn.layer.borderWidth = 2
        addToCalBtn.layer.cornerRadius = addToCalBtn.bounds.size.height/2
        addToCalBtn.addTarget(self, action: "addToCalBtnPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // Set media image
        if let mediaImgData = NSData(contentsOfURL: NSURL(string: eventJson["media"].stringValue)!) {
            mediaImgView.image = UIImage(data: mediaImgData)
        }
        
        // Record hit on website by issuing a http get request
        let urlString = eventJson["website"].stringValue
        let url = NSURL(string: urlString)!
        let httpGetTask = NSURLSession.sharedSession().dataTaskWithURL(url) {
            (data, response, error) in
            let resp = response as! NSHTTPURLResponse
            NuVentsEndpoint.sharedEndpoint.sendWebsiteCode(urlString, code: "\(resp.statusCode)")
        }
        httpGetTask.resume()
    }
    
    // Add to calendar button pressed
    func addToCalBtnPressed(sender:UIButton!) {
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
            message = "In order to add events to calendar, please open this app's settings and turn on Calendar access"
        } else if (calendarAuthStatus == EKAuthorizationStatus.Restricted) { // Notify regarding parental controls
            showAlert = true
            title = "Calendar Access Restricted"
            message = "Parental Controls might be enabled or Calendars might be disabled on yoru device, if possible, Please open this app's settings to disable Parental Controls or enable Calendars"
        }
        
        // Show alert view
        if (showAlert) {
            var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
            let cancelAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil)
            alert.addAction(cancelAction)
            let openAction = UIAlertAction(title: "Open Settings", style: UIAlertActionStyle.Default) {
                (action) in
                let url = NSURL(string: UIApplicationOpenSettingsURLString)
                UIApplication.sharedApplication().openURL(url!)
            }
            alert.addAction(openAction)
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    // Back button pressed
    func backBtnPressed(sender:UIButton!) {
        // Unwind to welcome view or map/list view
        if NuVentsEndpoint.sharedEndpoint.detailFromWelcome {
            // Go to welcome view as this view was loaded from welcome view
            NuVentsEndpoint.sharedEndpoint.detailFromWelcome = false
            self.performSegueWithIdentifier("unwindWelcomeView", sender: nil)
        } else {
            // Go to combination view
            self.performSegueWithIdentifier("unwindCombinationView", sender: nil)
        }
    }
    
    // Helper function to add event to calendar
    func addEventToCalendar(eventStore: EKEventStore) {
        var event:EKEvent = EKEvent(eventStore: eventStore)
        
        // Set event attributes
        event.calendar = eventStore.defaultCalendarForNewEvents
        event.title = eventJson["title"].stringValue
        event.startDate = NSDate(timeIntervalSince1970: eventJson["time"]["start"].doubleValue)
        event.endDate = NSDate(timeIntervalSince1970: eventJson["time"]["end"].doubleValue)
        event.location = eventJson["address"].stringValue
        event.URL = NSURL(string: eventJson["website"].stringValue)
        
        // Open eventkit UI so user can save to calendar
        var eventController:EKEventEditViewController = EKEventEditViewController()
        eventController.eventStore = eventStore
        eventController.event = event
        eventController.editViewDelegate = self
        
        self.presentViewController(eventController, animated: true, completion: nil)
    }
    
    // Event kit (calendar) edit view delegate
    func eventEditViewController(controller: EKEventEditViewController!, didCompleteWithAction action: EKEventEditViewAction) {
        if (Int(action.value) == Int(EKEventEditViewActionCanceled.value)) {
            // User tapped cancel
        } else if (Int(action.value) == Int(EKEventEditViewActionSaved.value)) {
            // User saved event
            let eventTitle = eventJson["title"].stringValue
            let eventTime = NuVentsHelper.getHumanReadableDate(eventJson["time"]["start"].stringValue)
            let message:String = "\(eventTitle)\n\(eventTime)"
            var alert = UIAlertController(title: "Event added to calendar!", message: message, preferredStyle: UIAlertControllerStyle.Alert)
            let cancelAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil)
            alert.addAction(cancelAction)
            dispatch_async(dispatch_get_main_queue(), { // Ensure alert is shown on UI (main) thread
                self.presentViewController(alert, animated: true, completion: nil)
            })
        } else if (Int(action.value) == Int(EKEventEditViewActionDeleted.value)) {
            // User tapped delete
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // Restrict to portrait only
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
}