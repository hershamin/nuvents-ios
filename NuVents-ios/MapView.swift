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
    var mapView:RMMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Init my location button
        myLocBtn.addTarget(self, action: "myLocBtnPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // Init MapBox maps
        RMConfiguration.sharedInstance().accessToken = NuVentsEndpoint.sharedEndpoint.mapboxToken
        let tileSource:RMMapboxSource = RMMapboxSource(mapID: NuVentsEndpoint.sharedEndpoint.mapboxMapId)
        mapView = RMMapView(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.size.width, UIScreen.mainScreen().bounds.size.height - 120), andTilesource: tileSource)
        mapView.zoom = 10
        let centerCoord = CLLocationCoordinate2DMake(30.27, -97.74)
        mapView.centerCoordinate = centerCoord
        mapView.userTrackingMode = RMUserTrackingModeFollow
        self.view.addSubview(mapView)
        self.view.sendSubviewToBack(mapView)
    }
    
    // My Location button pressed
    func myLocBtnPressed(sender:UIButton!) {
        // Zoom in to go to user location if visible on map
        if let locationDetected = mapView.userLocation {
            let location = mapView.userLocation.location
            mapView.setZoom(14, animated: true)
            mapView.setCenterCoordinate(location.coordinate, animated: true)
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