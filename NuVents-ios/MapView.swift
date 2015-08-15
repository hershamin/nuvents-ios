//
//  MapView.swift
//  NuVents-ios
//
//  Created by hersh amin on 8/1/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import Foundation

class MapViewController: UIViewController, RMMapViewDelegate {
    
    @IBOutlet var myLocBtn:UIButton!
    var mapView:RMMapView!
    var mapMarkers:[RMAnnotation] = []
    
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
        mapView.delegate = self
        self.view.addSubview(mapView)
        self.view.sendSubviewToBack(mapView)
        
        // Add map markers based from global variable to mapMarkers
        let events = NuVentsEndpoint.sharedEndpoint.eventJSON
        for (key, event) in events {
            let title = event["title"].stringValue
            let startTS = event["time"]["start"].stringValue
            let markerIcon = event["marker"].stringValue
            let media = event["media"].stringValue
            let lat = (event["latitude"].stringValue as NSString).doubleValue
            let lng = (event["longitude"].stringValue as NSString).doubleValue
            let annotation = RMAnnotation(mapView: mapView, coordinate: CLLocationCoordinate2DMake(lat, lng), andTitle: title)
            annotation.subtitle = NuVentsHelper.getHumanReadableDate(startTS)
            annotation.userInfo = ["marker" : markerIcon, "eid" : key, "media" : media] // Store marker type & eid in user info
            mapMarkers.append(annotation)
        }
        mapView.addAnnotations(mapMarkers) // Add annotations to mapView
        
        //Set up listener for NSNotificationCenter
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "actOnSpecialNotification", name: NuVentsEndpoint.sharedEndpoint.categoryNotificationKey, object: nil)
    }
    
    // Called when view is deallocated from memory
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
    
    // MARK: Mapview Delegate Methods
    func mapView(mapView: RMMapView!, layerForAnnotation annotation: RMAnnotation!) -> RMMapLayer! {
        
        // No custom marker for user location
        if (annotation.isUserLocationAnnotation) {
            return nil
        }
        
        // Get image by getting media URL from user info
        let markerDict = annotation.userInfo as! NSDictionary
        let mediaURL = NSURL(string: markerDict["media"]! as! String)!
        let mediaImg = UIImage(data: NSData(contentsOfURL: mediaURL)!)
        
        // Add marker
        var marker:RMMarker = RMMarker(mapboxMarkerImage: "rocket", tintColor: UIColor(red: 0.5, green: 0.466, blue: 0.733, alpha: 1))
        marker.canShowCallout = true
        
        // Add callout
        var mediaImgView = UIImageView(image: mediaImg!)
        mediaImgView.frame = CGRectMake(0, 0, 55, 55)
        marker.leftCalloutAccessoryView = mediaImgView
        marker.rightCalloutAccessoryView = UIButton.buttonWithType(UIButtonType.DetailDisclosure) as! UIView
        marker.rightCalloutAccessoryView.tintColor = UIColor(red: 0.91, green: 0.337, blue: 0.427, alpha: 1) // #E8566D
        
        return marker
        
    }
    
    // Mapview right accessory button clicked
    func tapOnCalloutAccessoryControl(control: UIControl!, forAnnotation annotation: RMAnnotation!, onMap map: RMMapView!) {
        
        // Go to detail view
        self.performSegueWithIdentifier("showDetailView", sender: nil)
        
    }
    
    func actOnSpecialNotification() {
        println("I heard this notification")
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