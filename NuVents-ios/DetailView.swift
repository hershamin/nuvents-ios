//
//  DetailView.swift
//  NuVents-ios
//
//  Created by hersh amin on 8/1/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import Foundation

class DetailViewController: UIViewController {
    
    // TEMP BUTTONS
    @IBOutlet var goToComb:UIButton!
    @IBOutlet var goToWelc:UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // TEMP CODE
        goToComb.addTarget(self, action: "goToCombination:", forControlEvents: UIControlEvents.TouchUpInside)
        goToWelc.addTarget(self, action: "goToWelcome:", forControlEvents: UIControlEvents.TouchUpInside)
    }
    
    // TEMP CODE
    func goToCombination(sender:UIButton!) {
        self.performSegueWithIdentifier("unwindCombinationView", sender: nil)
    }
    func goToWelcome(sender:UIButton!) {
        self.performSegueWithIdentifier("unwindWelcomeView", sender: nil)
    }
    // TEMP CODE END
    
    // Restrict to portrait only
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
}