//
//  DetailViewSegue.swift
//  NuVents-ios
//
//  Created by Hersh on 8/21/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import UIKit

class DetailViewSegue: UIStoryboardSegue {
    
    override func perform() {
        // Assign the source and destination views to local variables
        let sourceVC = self.sourceViewController.view as UIView!
        let destVC = self.destinationViewController.view as UIView!
        
        // Get the screen width & height
        let screenWidth = UIScreen.mainScreen().bounds.size.width
        let screenHeight = UIScreen.mainScreen().bounds.size.height
        
        // Initial position of destination view controller
        destVC.frame = CGRectMake(screenWidth, 0, screenWidth, screenHeight)
        
        // Access the app's key window and insert the destination view (source) above the current one
        let window = UIApplication.sharedApplication().keyWindow
        window?.insertSubview(destVC, aboveSubview: sourceVC)
        
        // Animate the transition
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            destVC.frame = CGRectMake(0, 0, screenWidth, screenHeight)
            
            }) { (Finished) -> Void in
                self.sourceViewController.presentViewController(self.destinationViewController , animated: false, completion: nil)
        }
    }

}
