//
//  RequestView.swift
//  NuVents-ios
//
//  Created by hersh amin on 8/1/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import Foundation
 
class RequestViewController: UIViewController, CZPickerViewDataSource, CZPickerViewDelegate {
    
    @IBOutlet var backBtn:UIButton!
    @IBOutlet weak var illustrationImage: UIImageView!
    @IBOutlet weak var nuventsMessage: UILabel!
    @IBOutlet weak var zipCodeLabel:UILabel!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var textForName: UITextField!
    @IBOutlet weak var textForEmail: UITextField!
    @IBOutlet weak var email: UILabel!
    @IBOutlet weak var bringItHere: UIButton!
    @IBOutlet weak var skipBtn:UIButton!
    var locationPlacemark:CLPlacemark!
    var currentCities:[JSON] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Back button functionality
        backBtn.addTarget(self, action: "backBtnPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // Skip button functionality
        skipBtn.addTarget(self, action: "skipBtnPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // Init location stuff
        let locCoord:CLLocationCoordinate2D = NuVentsEndpoint.sharedEndpoint.currLoc
        let location:CLLocation = CLLocation(latitude: locCoord.latitude, longitude: locCoord.longitude)
        //Reverse geocode the lat/lng for an address
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
            if error != nil {
                print(error)
                return
            }
            if placemarks!.count > 0 {
                let placemark:CLPlacemark = (placemarks?[0])!
                self.locationPlacemark = placemark
                self.displayLocationInfo(placemark)
            }
        })
        
        //Convert the background color
        self.view.backgroundColor = UIColor(red:0.61, green:0.34, blue:0.65, alpha:1.0) //#9C57A6
        
        //Load the image
        illustrationImage.image = UIImage(named: "RequestIllustration1.png")
        
        //Add text to the nuvents message
        nuventsMessage.numberOfLines = 0;
        nuventsMessage.textAlignment = NSTextAlignment.Center
        
        //Add name and email
        self.name.text = "NAME"
        self.email.text = "EMAIL"
        
        //Change attributes of name and email textfield, and put placeholder text
        textForName.alpha = 0.8
        textForEmail.alpha = 0.8
        
        //Edit the bringItHere button
        bringItHere.layer.borderColor = UIColor.whiteColor().CGColor
        bringItHere.layer.borderWidth = 3
        bringItHere.layer.cornerRadius = bringItHere.frame.height/2
        bringItHere.addTarget(self, action: "bringItHerePressed:", forControlEvents: UIControlEvents.TouchUpInside)
        bringItHere.hidden = true
        
        // Tap gesture recognizer to dismiss keybaord
        let tapgGestureRecognizer:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        self.view.addGestureRecognizer(tapgGestureRecognizer)
        
        // Text field editing begin/end listeners
        textForName.addTarget(self, action: "editingBegin", forControlEvents: UIControlEvents.EditingDidBegin)
        textForEmail.addTarget(self, action: "editingBegin", forControlEvents: UIControlEvents.EditingDidBegin)
        textForName.addTarget(self, action: "editingEnd", forControlEvents: UIControlEvents.EditingDidEnd)
        textForEmail.addTarget(self, action: "editingEnd", forControlEvents: UIControlEvents.EditingDidEnd)
        
    }
    
    // Text field editing began
    func editingBegin() {
        // Move screen up
        let height = UIScreen.mainScreen().bounds.height
        let width = UIScreen.mainScreen().bounds.width
        UIView.animateWithDuration(0.25, animations: {
            self.view.window?.frame = CGRectMake(0, -height/3, width, height)
            // x, y, width, height
        })
    }
    
    // Text field editing end
    func editingEnd() {
        // Move screen back down
        let height = UIScreen.mainScreen().bounds.height
        let width = UIScreen.mainScreen().bounds.width
        UIView.animateWithDuration(0.25, animations: {
            self.view.window?.frame = CGRectMake(0, 0, width, height)
            // x, y, width, height
        })
    }
    
    // Dismiss keyboard from both textfields
    func dismissKeyboard() {
        textForName.resignFirstResponder()
        textForEmail.resignFirstResponder()
    }
    
    func displayLocationInfo (placemark: CLPlacemark) {
        // Add the city to the message text.
        self.nuventsMessage.text = "Oh no! Nuvents is not yet available in " + placemark.locality! + ", " + placemark.administrativeArea!
        self.zipCodeLabel.text = locationPlacemark.postalCode!
        bringItHere.hidden = false
    }
    
    // Skip button pressed
    func skipBtnPressed(sender:UIButton!) {
        // Open picker view
        let picker:CZPickerView = CZPickerView(headerTitle: "Existing Cities", cancelButtonTitle: "Cancel", confirmButtonTitle: "OK")
        picker.headerBackgroundColor = UIColor(red: 0.91, green: 0.298, blue: 0.4, alpha: 1) // e84c66
        picker.delegate = self
        picker.dataSource = self
        // Fetch data before showing picker
        let urlString = "http://\(backend)/cities"
        let url = NSURL(string: urlString)!
        let httpGetTask = NSURLSession.sharedSession().dataTaskWithURL(url) {
            (data, response, error) in
            let json:JSON = JSON(data: data!)
            self.currentCities.removeAll()
            for (key,subJson):(String, JSON) in json {
                self.currentCities.append(subJson)
            }
            dispatch_async(dispatch_get_main_queue(), {
                picker.show()
            })
        }
        httpGetTask.resume()
    }
    
    // Bring it Here button pressed
    func bringItHerePressed(sender: UIButton!) {
        // Dismiss keyboard & bring view down if needed
        dismissKeyboard()
        editingEnd()
        // Send request to backend, if not blank
        if !textForName.text!.isEmpty && !textForEmail.text!.isEmpty {
            NuVentsEndpoint.sharedEndpoint.sendEventReq(locationPlacemark.locality!, state: locationPlacemark.administrativeArea!, zip: locationPlacemark.postalCode!, name: textForName.text!, email: textForEmail.text!)
            skipBtnPressed(nil)
        }
    }

    // Back button action
    func backBtnPressed(sender:UIButton!) {
        self.performSegueWithIdentifier("unwindRequestView", sender: nil)
    }
    
    // MARK: Picker View delegate/datasource methods
    func numberOfRowsInPickerView(pickerView: CZPickerView!) -> Int {
        return currentCities.count
    }
    
    func czpickerView(pickerView: CZPickerView!, titleForRow row: Int) -> String! {
        let json:JSON = self.currentCities[row]
        return json["name"].stringValue
    }
    
    func czpickerView(pickerView: CZPickerView!, didConfirmWithItemAtRow row: Int) {
        let json:JSON = self.currentCities[row]
        let coordString:String = json["location"].stringValue
        let coordStrArr = coordString.componentsSeparatedByString(",")
        NuVentsEndpoint.sharedEndpoint.requestedEventLoc = CLLocationCoordinate2DMake((coordStrArr[0] as NSString).doubleValue, (coordStrArr[1] as NSString).doubleValue)
        self.performSegueWithIdentifier("unwindRequestView", sender: nil)
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