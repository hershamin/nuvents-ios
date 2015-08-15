//
//  ViewController.swift
//  NuVents-ios
//
//  Created by hersh amin on 4/26/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController {
    
    @IBOutlet var combinationViewBtn:UIButton!
    @IBOutlet var detailViewBtn:UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // TEMP CODE, find events in austin, tx
        NuVentsEndpoint.sharedEndpoint.getNearbyEvents(CLLocationCoordinate2DMake(30.2766, -97.7324), radius: 10000)
        NuVentsEndpoint.sharedEndpoint.currLoc = CLLocationCoordinate2DMake(30.2766, -97.7324)
        
        combinationViewBtn.addTarget(self, action: "goToCombinationView:", forControlEvents: UIControlEvents.TouchUpInside) // Combination button action
        detailViewBtn.addTarget(self, action: "goToDetailView:", forControlEvents: UIControlEvents.TouchUpInside) // Detail button action
    }
    
    // Called when unwinded from detail view controller
    @IBAction func unwindToWelcomeView(sender: UIStoryboardSegue) {
        println("WelcomeView From DetailView")
    }
    
    // Func to go to detail view
    func goToDetailView(sender:UIButton!) {
        self.performSegueWithIdentifier("showDetailView", sender: nil)
    }
    
    // Func to go to combination view
    func goToCombinationView(sender:UIButton!) {
        self.performSegueWithIdentifier("showCombinationView", sender: nil)
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

