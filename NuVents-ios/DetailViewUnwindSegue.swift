//
//  DetailViewUnwindSegue.swift
//  NuVents-ios
//
//  Created by Hersh on 8/21/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import UIKit

class DetailViewUnwindSegue: UIStoryboardSegue {
    
    override func perform() {
        // Assign the source and destination views to local variables
        let sourceVC = self.sourceViewController.view as UIView!
        let destVC = self.destinationViewController.view as UIView!
        
        // Get the screen width & height
        let screenWidth = UIScreen.mainScreen().bounds.size.width
        let screenHeight = UIScreen.mainScreen().bounds.size.height
        
        // Access the app's key window and insert the source view above the destination one & vice-versa
        let window = UIApplication.sharedApplication().keyWindow
        window?.insertSubview(destVC, aboveSubview: sourceVC)
        window?.insertSubview(sourceVC, aboveSubview: destVC)
        
        // Animate the transition
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            sourceVC.frame = CGRectMake(screenWidth, 0, screenWidth, screenHeight)
            destVC.frame = CGRectMake(0, 0, screenWidth, screenHeight)
            
            }) { (Finished) -> Void in
                self.sourceViewController.dismissViewControllerAnimated(false, completion: nil)
        }
    }

}
