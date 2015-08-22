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
    @IBOutlet var requestViewBtn:UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // TEMP CODE, find events in austin, tx
        NuVentsEndpoint.sharedEndpoint.getNearbyEvents(CLLocationCoordinate2DMake(30.2766, -97.7324), radius: 10000)
        NuVentsEndpoint.sharedEndpoint.currLoc = CLLocationCoordinate2DMake(30.2766, -97.7324)
        
        combinationViewBtn.addTarget(self, action: "goToCombinationView:", forControlEvents: UIControlEvents.TouchUpInside) // Combination button action
        detailViewBtn.addTarget(self, action: "goToDetailView:", forControlEvents: UIControlEvents.TouchUpInside) // Detail button action
        requestViewBtn.addTarget(self, action: "goToRequestView:", forControlEvents: UIControlEvents.TouchUpInside) // Request button action
        
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
    
    // Segue transition delegate
    override func segueForUnwindingToViewController(toViewController: UIViewController, fromViewController: UIViewController, identifier: String?) -> UIStoryboardSegue {
        if let id = identifier {
            if id == "unwindWelcomeView" {
                let unwindSegue = DetailViewUnwindSegue(identifier: id, source: fromViewController, destination: toViewController, performHandler: { () -> Void in
                    //
                })
                
                return unwindSegue
            }
        }
        
        return super.segueForUnwindingToViewController(toViewController, fromViewController: fromViewController, identifier: identifier)
    }
    
    // Func to go to detail view
    func goToDetailView(sender:UIButton!) {
        NuVentsEndpoint.sharedEndpoint.detailFromWelcome = true
        self.performSegueWithIdentifier("showDetailView", sender: nil)
    }
    
    // Func to go to combination view
    func goToCombinationView(sender:UIButton!) {
        self.performSegueWithIdentifier("showCombinationView", sender: nil)
    }
    
    // Func to go to request view
    func goToRequestView(sender:UIButton!) {
        self.performSegueWithIdentifier("showRequestView", sender: nil)
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
                self.goToDetailView(nil)
            })
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

