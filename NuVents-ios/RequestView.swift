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
    @IBOutlet weak var city: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Back button functionality
        backBtn.addTarget(self, action: "backBtnPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        //Convert the background color
        self.view.backgroundColor = UIColor(red:0.61, green:0.34, blue:0.65, alpha:1.0) //#9c57a6
        
        //Load the image
        illustrationImage.image = UIImage(named: "RequestIllustration")
        
        //Add text to the nuvents message
        self.nuventsMessage.text = "Oh no! Nuvents is not yet available in your city."
        nuventsMessage.numberOfLines = 0;
        nuventsMessage.textAlignment = NSTextAlignment.Center
        
        //Add name + city
        self.name.text = "NAME"
        self.city.text = "CITY"
        
        
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