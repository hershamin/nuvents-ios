//
//  MapView.swift
//  NuVents-ios
//
//  Created by hersh amin on 8/1/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import Foundation

class MapViewController: UIViewController {
    
    @IBOutlet var myLocBtn:UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Init my location button
        myLocBtn.addTarget(self, action: "myLocBtnPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // Init MapView
        //
        
        // Add map markers based from global variable to mapMarkers
        let events = NuVentsEndpoint.sharedEndpoint.eventJSON
        for (key, event) in events {
            let title = event["title"].stringValue
            let startTS = event["time"]["start"].stringValue
            let markerIcon = event["marker"].stringValue
            let media = event["media"].stringValue
            let lat = (event["latitude"].stringValue as NSString).doubleValue
            let lng = (event["longitude"].stringValue as NSString).doubleValue
            //
        }
        
        //Set up listeners for NSNotificationCenter
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "changeMapViewToSearch", name: NuVentsEndpoint.sharedEndpoint.categoryNotificationKey, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "changeMapViewToSearch", name: NuVentsEndpoint.sharedEndpoint.searchNotificationKey, object: nil)
    }
    
    func changeMapViewToCategory() {
        let categorizeList = NuVentsEndpoint.sharedEndpoint.categories
        //Iterate through the mapMarkers getting each annotation
        //
    }
    
    // Function to change map view to search bar text changed
    func changeMapViewToSearch() {
        let searchText = NuVentsEndpoint.sharedEndpoint.searchText.lowercaseString
        changeMapViewToCategory() // Get categorized event markers
        // Iterate & search in title
       //
    }
    
    // Called when view is deallocated from memory
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // My Location button pressed
    func myLocBtnPressed(sender:UIButton!) {
        // Zoom in to go to user location if visible on map
        //
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