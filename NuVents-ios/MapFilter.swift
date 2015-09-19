//
//  MapFilter.swift
//  NuVents-ios
//
//  Created by hersh amin on 9/18/15.
//  Copyright © 2015 NuVents. All rights reserved.
//

import UIKit

class MapFilter: UIViewController {
    
    @IBOutlet var segmentedCtrl:UISegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set border color
        self.view.layer.borderColor = UIColor(red: 0.91, green: 0.337, blue: 0.427, alpha: 1).CGColor // #E8566D
        self.view.layer.borderWidth = 1.5
        self.view.layer.cornerRadius = 10
        
        // Init segmented control
        segmentedCtrl.selectedSegmentIndex = NuVentsEndpoint.sharedEndpoint.mapViewFilter
        segmentedCtrl.addTarget(self, action: "segmentChanged:", forControlEvents: UIControlEvents.ValueChanged)

        // Do any additional setup after loading the view.
    }
    
    // Segment changed
    func segmentChanged(sender:UISegmentedControl!) {
        // Set segment in global vars
        NuVentsEndpoint.sharedEndpoint.mapViewFilter = sender.selectedSegmentIndex
        // Notify views
        NSNotificationCenter.defaultCenter().postNotificationName(NuVentsEndpoint.sharedEndpoint.mapFilterNotificationKey, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
