//
//  DetailView.swift
//  NuVents-ios
//
//  Created by hersh amin on 8/1/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import Foundation

class DetailViewController: UIViewController {
    
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
            println("WEB: \(urlString)")
            println("RES: \(resp.statusCode)")
        }
        httpGetTask.resume()
    }
    
    // Add to calendar button pressed
    func addToCalBtnPressed(sender:UIButton!) {
        println("Addtocal")
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
    
    // Restrict to portrait only
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
}