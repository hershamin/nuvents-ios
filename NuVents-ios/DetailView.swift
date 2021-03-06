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

// String extension to convert html to attributed string
extension String {
    var html2AttributedString:NSAttributedString {
        return try! NSAttributedString(data: dataUsingEncoding(NSUTF8StringEncoding)!, options:[NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: NSUTF8StringEncoding], documentAttributes: nil)
    }
}

class DetailViewController: UIViewController, EKEventEditViewDelegate, UITextViewDelegate {
    
    var eventJson:JSON!
    @IBOutlet var mediaImgView:UIImageView!
    @IBOutlet var backBtn:UIButton!
    @IBOutlet var addToCalBtn:UIButton!
    @IBOutlet var viewMapBtn:UIButton!
    @IBOutlet var shareBtn:UIButton!
    @IBOutlet var dateTimeLabel:UILabel!
    @IBOutlet var titleLabel:UILabel!
    @IBOutlet var addressLabel:UILabel!
    @IBOutlet var distanceLabel:UILabel!
    @IBOutlet var descriptionView:UITextView!
    @IBOutlet var activityIndicator:YRActivityIndicator!
    @IBOutlet var loadingLabel:UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Init back button
        backBtn.addTarget(self, action: "backBtnPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // Activity Indicator setup
        activityIndicator.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.9)
        showLoadingViewWithText("Loading Event Detail...")
        
        // Request event details
        let eventID:String = NuVentsEndpoint.sharedEndpoint.selectedEID
        if (eventID != "") {
            // Only request if not empty
            NuVentsEndpoint.sharedEndpoint.getEventDetail(NuVentsEndpoint.sharedEndpoint.selectedEID)
        } else {
            hideLoadingView()
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
        // Init add to calendar button
        addToCalBtn.layer.borderColor = UIColor.whiteColor().CGColor
        addToCalBtn.layer.borderWidth = 3
        addToCalBtn.layer.cornerRadius = addToCalBtn.bounds.size.height/2
        addToCalBtn.addTarget(self, action: "addToCalBtnPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // Init other buttons
        viewMapBtn.addTarget(self, action: "viewMapBtnPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        shareBtn.addTarget(self, action: "shareBtnPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // Signup for notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "detailViewJsonReceived", name: NuVentsEndpoint.sharedEndpoint.eventDetailNotificationKey, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // Detail View Json received
    func detailViewJsonReceived() {
        // Populate data
        eventJson = NuVentsEndpoint.sharedEndpoint.tempJson
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
        // Return if data not found
        if !(eventJson != nil) {
            return
        }
        
        // Init Description WebView
        let descHtmlStr:String = eventJson["description"].stringValue
        let descHtmlAttr:NSMutableAttributedString = NSMutableAttributedString(attributedString: descHtmlStr.html2AttributedString)
        descHtmlAttr.enumerateAttribute(NSFontAttributeName, inRange: NSMakeRange(0, descHtmlAttr.length), options: NSAttributedStringEnumerationOptions.LongestEffectiveRangeNotRequired) {
            (attribute:AnyObject?, range:NSRange, stop:UnsafeMutablePointer<ObjCBool>) -> Void in
            if let attrFont = attribute as? UIFont {
                let scaledFont = UIFont(descriptor: attrFont.fontDescriptor(), size: 13.0)
                descHtmlAttr.addAttribute(NSFontAttributeName, value: scaledFont, range: range)
            }
        }
        descriptionView.attributedText = descHtmlAttr
        
        // Init date/time label
        let timeStr:String = NuVentsHelper.getHumanReadableDate(eventJson["time"]["start"].stringValue)
        dateTimeLabel.text = timeStr.stringByReplacingOccurrencesOfString("at", withString: "|")
        
        // Init distance label
        if let currLocCoord = NuVentsEndpoint.sharedEndpoint.currLoc {
            let currLoc = CLLocation(latitude: currLocCoord.latitude, longitude: currLocCoord.longitude)
            let eventLoc = CLLocation(latitude: eventJson["latitude"].doubleValue, longitude: eventJson["longitude"].doubleValue)
            let distRaw = eventLoc.distanceFromLocation(currLoc) * 0.000621371 // Distance in miles
            let dist = Double(round(10 * distRaw)/10) // Round the number
            let distStr = String(format: "%g", dist)
            if (dist < 0.1) { // Change distance label based on calculated distance
                distanceLabel.text = "< 0.1 mi"
            } else {
                distanceLabel.text = "\(distStr) mi"
            }
        } else {
            distanceLabel.text = "n/a"
        }
        
        // Init title & address labels
        titleLabel.text = eventJson["title"].stringValue
        addressLabel.text = eventJson["address"].stringValue
        
        // Set media image
        if let mediaImgData = NSData(contentsOfURL: NSURL(string: eventJson["media"].stringValue)!) {
            mediaImgView.image = UIImage(data: mediaImgData)
        }
        
        // Record hit on website by issuing a http get request
        let urlString = eventJson["website"].stringValue
        let url = NSURL(string: urlString)!
        let httpGetTask = NSURLSession.sharedSession().dataTaskWithURL(url) {
            (data, response, error) in
            if let resp = response as? NSHTTPURLResponse { // Got some response
                NuVentsEndpoint.sharedEndpoint.sendWebsiteCode(urlString, code: "\(resp.statusCode)")
            } else { // No response
                NuVentsEndpoint.sharedEndpoint.sendWebsiteCode(urlString, code: "500")
            }
        }
        httpGetTask.resume()
        
        // Write json to file just in case when app crashes, it is known to crash when privacy settings such as accessing calendar, contacts, are changed while app is open in background
        let jsonFilePath = NuVentsHelper.getResourcePath("detailView", type: "tmp")
        var event:JSON = eventJson
        if let currentLoc:CLLocationCoordinate2D = NuVentsEndpoint.sharedEndpoint.currLoc {
            event["currLat"].stringValue = currentLoc.latitude.description  // Adding current latitude
            event["currLng"].stringValue = currentLoc.longitude.description // Adding current longitude
        }
        let jsonFileData = "\(event)".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        jsonFileData?.writeToFile(jsonFilePath, atomically: true)
        
        hideLoadingView() // Hide loading view
    }
    
    // Called when controller disappears from the stack
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(true)
        // Erase json file written at the start of this view controller, this signifies that app did not crash while on this view
        let jsonFilePath = NuVentsHelper.getResourcePath("detailView", type: "tmp")
        let fm = NSFileManager.defaultManager()
        do {
            try fm.removeItemAtPath(jsonFilePath)
        } catch _ {
        }
        // Remove temp event
        NuVentsEndpoint.sharedEndpoint.tempJson = nil
    }
    
    // Method to show loading view
    func showLoadingViewWithText(status:String!) {
        activityIndicator.startAnimating()
        loadingLabel.text = "\(status)..."
        activityIndicator.hidden = false
        loadingLabel.hidden = false
    }
    
    // Method to hide loading view
    func hideLoadingView() {
        activityIndicator.stopAnimating()
        loadingLabel.text = ""
        activityIndicator.hidden = true
        loadingLabel.hidden = true
    }
    
    // View Map button pressed
    func viewMapBtnPressed(sender:UIButton!) {
        let lat = eventJson["latitude"].stringValue
        let lng = eventJson["longitude"].stringValue
        var address = eventJson["address"].stringValue
        address = address.stringByReplacingOccurrencesOfString(" ", withString: "+", options: NSStringCompareOptions.LiteralSearch, range: nil)
        let urlToOpen:String
        if (UIApplication.sharedApplication().canOpenURL(NSURL(string: "comgooglemaps-x-callback://")!)) {
            // Google maps available with x-callback functionality
            urlToOpen = "comgooglemaps-x-callback://?q=\(address)&center=\(lat),\(lng)&views=traffic&x-success=nuvents://&x-source=NuVents"
        } else if (UIApplication.sharedApplication().canOpenURL(NSURL(string: "comgooglemaps://")!)) {
            urlToOpen = "comgooglemaps://?q=\(address)&center=\(lat),\(lng)&views=traffic"
        } else {
            urlToOpen = "http://maps.apple.com/?ll=\(lat),\(lng)&q=\(address)"
        }
        UIApplication.sharedApplication().openURL(NSURL(string: urlToOpen)!)
    }
    
    // Add to calendar button pressed
    func addToCalBtnPressed(sender:UIButton!) {
        // Event store (calendar) config
        let eventStore:EKEventStore = EKEventStore()
        var calendarAuthStatus = EKAuthorizationStatus.Denied
        
        // Get calendar authorization status & act accordingly
        var showAlert = false
        var title:String = ""
        var message:String = ""
        calendarAuthStatus = EKEventStore.authorizationStatusForEntityType(EKEntityType.Event)
        if (calendarAuthStatus == EKAuthorizationStatus.NotDetermined) { // Ask for access then add
            eventStore.requestAccessToEntityType(EKEntityType.Event, completion: {
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
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
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
        let event:EKEvent = EKEvent(eventStore: eventStore)
        
        // Set event attributes
        event.calendar = eventStore.defaultCalendarForNewEvents
        event.title = eventJson["title"].stringValue
        event.startDate = NSDate(timeIntervalSince1970: eventJson["time"]["start"].doubleValue)
        event.endDate = NSDate(timeIntervalSince1970: eventJson["time"]["end"].doubleValue)
        event.location = eventJson["address"].stringValue
        event.URL = NSURL(string: eventJson["website"].stringValue)
        
        // Open eventkit UI so user can save to calendar
        let eventController:EKEventEditViewController = EKEventEditViewController()
        eventController.eventStore = eventStore
        eventController.event = event
        eventController.editViewDelegate = self
        
        self.presentViewController(eventController, animated: true, completion: nil)
    }
    
    // Event kit (calendar) edit view delegate
    func eventEditViewController(controller: EKEventEditViewController, didCompleteWithAction action: EKEventEditViewAction) {
        if (action == EKEventEditViewAction.Canceled) {
            // User tapped cancel
        } else if (action == EKEventEditViewAction.Saved) {
            // User saved event
            let eventTitle = eventJson["title"].stringValue
            let eventTime = NuVentsHelper.getHumanReadableDate(eventJson["time"]["start"].stringValue)
            let message:String = "\(eventTitle)\n\(eventTime)"
            let alert = UIAlertController(title: "Event added to calendar!", message: message, preferredStyle: UIAlertControllerStyle.Alert)
            let cancelAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil)
            alert.addAction(cancelAction)
            dispatch_async(dispatch_get_main_queue(), { // Ensure alert is shown on UI (main) thread
                self.presentViewController(alert, animated: true, completion: nil)
            })
        } else if (action == EKEventEditViewAction.Deleted) {
            // User tapped delete
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // Share button pressed
    func shareBtnPressed(sender:UIButton!) {
        // Items
        var items:Array = [AnyObject]()
        // Adding text
        let shareString = "Share this event with friends!"
        items.append(shareString)
        // Adding an image
        let shareImgData:NSData = NSData(contentsOfURL: NSURL(string: eventJson["media"].stringValue)!)!
        let shareImg:UIImage = UIImage(data: shareImgData)!
        items.append(shareImg)
        // Custom data
        let eventID = eventJson["eid"].stringValue
        var params = ["eventID":"\(eventID)"]
        params["product_name"] = "NuVents"
        params["$og_title"] = eventJson["title"].stringValue
        params["$og_description"] = eventJson["description"].stringValue
        params["$og_image_url"] = eventJson["media"].stringValue
        let feature = "share"
        let stage = "discovered"
        // Adding a link - Branch UIActivityItemProvider
        let itemProvider = Branch.getBranchActivityItemWithParams(params, andFeature: feature, andStage: stage)
        items.append(itemProvider)
        // Pass into uiactivity view controller
        let shareVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        // Present share sheet
        self.presentViewController(shareVC, animated: true, completion: nil)
    }
    
    // UITextView (Description) view delegate, when links are clicked
    func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool {
        // Open in external browser
        UIApplication.sharedApplication().openURL(URL)
        return true
    }
    
    // Restrict to portrait only
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
}