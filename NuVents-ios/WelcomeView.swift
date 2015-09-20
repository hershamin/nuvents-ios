//
//  ViewController.swift
//  NuVents-ios
//
//  Created by hersh amin on 4/26/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController, CLLocationManagerDelegate {
    
    var locationManager:CLLocationManager = CLLocationManager()
    @IBOutlet var illustrationImg:UIImageView!
    @IBOutlet var skipBtn:UIButton!
    @IBOutlet var pageIndicator:UIPageControl!
    @IBOutlet var continueBtn:UIButton!
    @IBOutlet var titleLabel:UILabel!
    @IBOutlet var descLabel:UILabel!
    var illustrationImgs:[String] = []
    var titles:[String] = []
    var descs:[String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Load arrays for illustration images, titles, and descriptions
        illustrationImgs = ["OnboardIllustration1.png", "OnboardIllustration2.png", "OnboardIllustration3.png"]
        titles = ["Organize and discover events in your city all in one app", "Share experiences with old friends and contact with new people", "Build a calendar to keep track of events and never miss out"]
        descs = ["Create events, discover things to do, and find new friends and new hobbies all around you", "You can talk to new friends, read updates about events, and be alerted about new things to do in your area", "Build your schedule so that you never forget or overlap your events. Share with friends and spread the love"]
        
        // Start getting device location
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // Rounded corners to continue btn
        continueBtn.layer.borderColor = UIColor.whiteColor().CGColor
        continueBtn.layer.borderWidth = 3
        continueBtn.layer.cornerRadius = continueBtn.frame.height/2
        
        // Load Image, title, description, & background color
        illustrationImg.image = UIImage(named: illustrationImgs[0])
        titleLabel.text = titles[0]
        descLabel.text = descs[0]
        self.view.backgroundColor = UIColor(red: 0.10, green: 0.73, blue: 0.60, alpha: 1.0) // #19B99A
        
        // Alert user if server is not reachable
        checkServerConn()
        
        // Init Buttons
        skipBtn.addTarget(self, action: "skipBtnPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        continueBtn.addTarget(self, action: "continueBtnPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // Restore detail view controller
        restoreDetailView() // Will only restore detail view if restore file found
    }
    
    // Called when unwinded from detail view controller
    @IBAction func unwindToWelcomeView(sender: UIStoryboardSegue) {
        // Welcome View from Detail View
    }
    
    // Called when unwinded from request view controller
    @IBAction func unwindToWelcomeFromRequest(sender: UIStoryboardSegue) {
        // Welcome View from Request View
    }
    
    // Skip Button Pressed
    func skipBtnPressed(sender:UIButton!) {
        if NuVentsEndpoint.sharedEndpoint.eventJSON.count > 0 {
            // Events found, go to combination view
            self.performSegueWithIdentifier("showCombinationView", sender: nil)
        } else {
            // No events found, go to request view
            self.performSegueWithIdentifier("showRequestView", sender: nil)
        }
    }
    
    // Continue Button Pressed
    func continueBtnPressed(sender:UIButton!) {
        // Check current page
        if (pageIndicator.currentPage == 0) {
            // Load page 1, load from appropriate array indexes
            illustrationImg.image = UIImage(named: illustrationImgs[1])
            titleLabel.text = titles[1]
            descLabel.text = descs[1]
            self.view.backgroundColor = UIColor(red: 0.19, green: 0.64, blue: 0.86, alpha: 1.0) // #31A3DC
            pageIndicator.currentPage = 1 // Change page on page indicator
        } else if (pageIndicator.currentPage == 1) {
            // Load page 2, load from appropriate array indexes
            illustrationImg.image = UIImage(named: illustrationImgs[2])
            titleLabel.text = titles[2]
            descLabel.text = descs[2]
            self.view.backgroundColor = UIColor(red: 0.91, green: 0.30, blue: 0.40, alpha: 1.0) // #E84C66
            pageIndicator.currentPage = 2 // Change page on page indicator
            continueBtn.setTitle("GET STARTED", forState: UIControlState.Normal) // Change title of "CONTINUE" button
            skipBtn.hidden = true // Hide Skip button
        } else if (pageIndicator.currentPage == 2) {
            // Call Skip button function
            skipBtnPressed(nil)
        }
    }
    
    // Check for server connection & alert user if unreachable
    func checkServerConn() {
        let urlString = "http://" + backend + "/"
        let url = NSURL(string: urlString)!
        let httpGetTask = NSURLSession.sharedSession().dataTaskWithURL(url) {
            (data, response, error) in
            if let resp = response as? NSHTTPURLResponse {
                // Some kind of response is received, server is reachable
            } else {
                // Server unreachable alert user
                dispatch_async(dispatch_get_main_queue(), {
                    let alert = UIAlertController(title: "Server connection error", message: "Either Airplane mode is turned on or Internet is not reachable", preferredStyle: UIAlertControllerStyle.Alert)
                    let cancelAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil)
                    alert.addAction(cancelAction)
                    self.presentViewController(alert, animated: true, completion: nil)
                })
            }
        }
        httpGetTask.resume()
    }
    
    // Segue transition delegate
    override func segueForUnwindingToViewController(toViewController: UIViewController, fromViewController: UIViewController, identifier: String?) -> UIStoryboardSegue {
        if let id = identifier {
            if id == "unwindWelcomeView" {
                let unwindSegue = DetailViewUnwindSegue(identifier: id, source: fromViewController, destination: toViewController, performHandler: { () -> Void in
                    //
                })
                
                return unwindSegue
            }
            if id == "unwindRequestView" {
                let unwindSegue = RequestViewUnwindSegue(identifier: id, source: fromViewController, destination: toViewController, performHandler: { () -> Void in
                    //
                })
                
                return unwindSegue
            }
        }
        
        return super.segueForUnwindingToViewController(toViewController, fromViewController: fromViewController, identifier: identifier)!
    }
    
    // Restore detail view controller
    func restoreDetailView() {
        let filePath = NuVentsHelper.getResourcePath("detailView", type: "tmp")
        let fm = NSFileManager.defaultManager()
        if (fm.fileExistsAtPath(filePath)) { // Detail view controller restore file exists signifying app crashed when user was at detail view last time
            let fileData = NSData(contentsOfFile: filePath)
            NuVentsEndpoint.sharedEndpoint.tempJson = JSON(data: fileData!)
            // Open detail view controller
            NuVentsEndpoint.sharedEndpoint.detailFromWelcome = true
            dispatch_async(dispatch_get_main_queue(), {
                self.performSegueWithIdentifier("showDetailView", sender: nil)
            })
        }
    }
    
    // MARK: Location manager delegate methods
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        var message:String = ""
        var title:String = ""
        var showAlert = false
        // Determine negative statuses
        if (status == CLAuthorizationStatus.Denied) {
            // App is denied permission
            showAlert = true
            title = "Location Access Disabled"
            message = "In order to show nearby events, Please open this app's settings and set location access to 'While Using the App'"
        } else if (status == CLAuthorizationStatus.Restricted) {
            // Could not be available or parental controls
            showAlert = true
            title = "Location Access Restricted"
            message = "Parental Controls might be enabled or Location Services might be disabled on your device, if possible, Please open this app's settings to disable Parental Controls or enable Location Services"
        }
        // Show alert
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
    
    // Got device location
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Set in global variables
        let latestLoc:CLLocation = locations.last!
        NuVentsEndpoint.sharedEndpoint.currLoc = latestLoc.coordinate
        // Check if recent
        let eventDate:NSDate = latestLoc.timestamp
        let howRecent:NSTimeInterval = eventDate.timeIntervalSinceNow
        if (abs(howRecent) < 3.0) {
            // Only stop if less than 3 seconds old
            locationManager.stopUpdatingLocation()
            // Initiate search for nearby events
            NuVentsEndpoint.sharedEndpoint.getNearbyEvents(latestLoc.coordinate, radius: 5000)
        }
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

