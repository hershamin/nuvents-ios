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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Start getting device location
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // Set background color
        self.view.backgroundColor = UIColor(red: 0.10, green: 0.73, blue: 0.60, alpha: 1.0) // #19B99A
        
        // Rounded corners to continue btn
        continueBtn.layer.borderColor = UIColor.whiteColor().CGColor
        continueBtn.layer.borderWidth = 3
        continueBtn.layer.cornerRadius = continueBtn.frame.height/2
        
        // TEMP CODE, Load the Image
        illustrationImg.image = UIImage(named: "RequestIllustration.png")
        
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
        println("WelcomeView From DetailView")
    }
    
    // Called when unwinded from request view controller
    @IBAction func unwindToWelcomeFromRequest(sender: UIStoryboardSegue) {
        println("WelcomeView From RequestView")
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
        println("Continue Button Pressed")
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
                    var alert = UIAlertController(title: "Server connection error", message: "Either Airplane mode is turned on or Internet is not reachable", preferredStyle: UIAlertControllerStyle.Alert)
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
        
        return super.segueForUnwindingToViewController(toViewController, fromViewController: fromViewController, identifier: identifier)
    }
    
    // Restore detail view controller
    func restoreDetailView() {
        let filePath = NuVentsHelper.getResourcePath("detailView", type: "tmp")
        let fm = NSFileManager.defaultManager()
        if (fm.fileExistsAtPath(filePath)) { // Detail view controller restore file exists signifying app crashed when user was at detail view last time
            let fileData = NSData(contentsOfFile: filePath)
            NuVentsEndpoint.sharedEndpoint.tempJson = JSON(data: fileData!)
            // Open detail view controller
            dispatch_async(dispatch_get_main_queue(), {
                self.performSegueWithIdentifier("showDetailView", sender: nil)
            })
        }
    }
    
    // MARK: Location manager delegate methods
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
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
    
    // Got device location
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        // Set in global variables
        var latestLoc:CLLocation = locations[locations.count - 1] as! CLLocation
        NuVentsEndpoint.sharedEndpoint.currLoc = latestLoc.coordinate
        locationManager.stopUpdatingLocation()
        // Initiate search for nearby events
        NuVentsEndpoint.sharedEndpoint.getNearbyEvents(latestLoc.coordinate, radius: 5000)
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

