//
//  RequestView.swift
//  NuVents-ios
//
//  Created by hersh amin on 8/1/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import Foundation   

class RequestViewController: UIViewController {
    
    @IBOutlet var backBtn:UIButton!
    @IBOutlet weak var illustrationImage: UIImageView!
    @IBOutlet weak var nuventsMessage: UILabel!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var textForName: UITextField!
    @IBOutlet weak var textForEmail: UITextField!
    @IBOutlet weak var email: UILabel!
    @IBOutlet weak var bringItHere: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Back button functionality
        backBtn.addTarget(self, action: "backBtnPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        //Convert the background color
        self.view.backgroundColor = UIColor(red:0.61, green:0.34, blue:0.65, alpha:1.0) //#9C57A6
        
        //Load the image
        illustrationImage.image = UIImage(named: "RequestIllustration")
        
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
        
        // Init location stuff
        let locCoord:CLLocationCoordinate2D = NuVentsEndpoint.sharedEndpoint.currLoc
        let location:CLLocation = CLLocation(latitude: locCoord.latitude, longitude: locCoord.longitude)
        //Reverse geocode the lat/lng for an address
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
            if error != nil {
                println(error)
                return
            }
            if placemarks.count > 0 {
                let placemark = placemarks[0] as! CLPlacemark
                self.displayLocationInfo(placemark)
            }
        })
        
    }
    
    // Called when autolayout is finished laying out subviews
    override func viewDidLayoutSubviews() {
        // Resize textfields
        let nameFrame:CGRect = textForName.frame
        textForName.frame = CGRectMake(nameFrame.origin.x, nameFrame.origin.y, UIScreen.mainScreen().bounds.width-60, nameFrame.size.height)
        let emailFrame:CGRect = textForEmail.frame
        textForEmail.frame = CGRectMake(emailFrame.origin.x, emailFrame.origin.y, UIScreen.mainScreen().bounds.width-60, emailFrame.size.height)
    }
    
    func displayLocationInfo (placemark: CLPlacemark) {
        // Add the city to the message text.
        self.nuventsMessage.text = "Oh no! Nuvents is not yet available in " + placemark.locality + ", " + placemark.administrativeArea
    }
    
    // Bring it Here button pressed
    func bringItHerePressed(sender: UIButton!) {
        println("Bring it here")
    }

    // Back button action
    func backBtnPressed(sender:UIButton!) {
        self.performSegueWithIdentifier("unwindRequestView", sender: nil)
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