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
        
        zoomToFitAllAnnotationsAnimated(true) // Zoom to fit all markers
        
        //Set up listeners for NSNotificationCenter
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "changeMapViewToSearch", name: NuVentsEndpoint.sharedEndpoint.categoryNotificationKey, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "changeMapViewToSearch", name: NuVentsEndpoint.sharedEndpoint.searchNotificationKey, object: nil)
    }
    
    func changeMapViewToCategory() {
        let categorizeList = NuVentsEndpoint.sharedEndpoint.categories
        //Iterate through the mapMarkers getting each annotation
        for annotation in mapMarkers {
            if let categoryViewAnnotations = annotation.userInfo as? Dictionary<String,String> {
                if (categorizeList.count == 0) {
                    mapView.addAnnotation(annotation)
                }
                else if (categorizeList.contains(categoryViewAnnotations["marker"]!))  {
                    mapView.addAnnotation(annotation)
                }
                else {
                    mapView.removeAnnotation(annotation)
                }
            }
        }
    }
    
    // Function to change map view to search bar text changed
    func changeMapViewToSearch() {
        let searchText = NuVentsEndpoint.sharedEndpoint.searchText.lowercaseString
        changeMapViewToCategory() // Get categorized event markers
        // Iterate & search in title
        for annotation in mapMarkers {
            let title = annotation.title.lowercaseString
            if (count(searchText) == 0) {
                mapView.addAnnotation(annotation)
            } else if (title.rangeOfString(searchText) != nil) {
                mapView.addAnnotation(annotation)
            } else {
                mapView.removeAnnotation(annotation)
            }
        }
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
    
    // Function to zoom mapview according to visible annotations
    //  Code from: https://github.com/mapbox/mapbox-ios-sdk/issues/33
    func zoomToFitAllAnnotationsAnimated(animated:Bool) {
        
        let rawAnnotations = mapMarkers
        
        // Only get visible annotations
        var annotations:[RMAnnotation] = []
        if let mapViewAnnotations:[RMAnnotation] = (self.mapView.annotations as? [RMAnnotation]) {
            for annotation in rawAnnotations {
                if contains(mapViewAnnotations, annotation) {
                    annotations.append(annotation)
                }
            }
        }
        
        if annotations.count > 0 {
            
            let firstCoordinate = annotations[0].coordinate
            
            //Find the southwest and northeast point
            var northEastLatitude = firstCoordinate.latitude
            var northEastLongitude = firstCoordinate.longitude
            var southWestLatitude = firstCoordinate.latitude
            var southWestLongitude = firstCoordinate.longitude
            
            for annotation in annotations {
                let coordinate = annotation.coordinate
                
                northEastLatitude = max(northEastLatitude, coordinate.latitude)
                northEastLongitude = max(northEastLongitude, coordinate.longitude)
                southWestLatitude = min(southWestLatitude, coordinate.latitude)
                southWestLongitude = min(southWestLongitude, coordinate.longitude)
                
                
            }
            let verticalMarginInPixels = 80.0
            let horizontalMarginInPixels = 40.0
            
            let verticalMarginPercentage = verticalMarginInPixels/Double(UIScreen.mainScreen().bounds.height - 120)
            let horizontalMarginPercentage = horizontalMarginInPixels/Double(UIScreen.mainScreen().bounds.width)
            
            let verticalMargin = (northEastLatitude-southWestLatitude)*verticalMarginPercentage
            let horizontalMargin = (northEastLongitude-southWestLongitude)*horizontalMarginPercentage
            
            southWestLatitude -= verticalMargin
            southWestLongitude -= horizontalMargin
            
            northEastLatitude += verticalMargin
            northEastLongitude += horizontalMargin
            
            if (southWestLatitude < -85.0) {
                southWestLatitude = -85.0
            }
            if (southWestLongitude < -180.0) {
                southWestLongitude = -180.0
            }
            if (northEastLatitude > 85) {
                northEastLatitude = 85.0
            }
            if (northEastLongitude > 180.0) {
                northEastLongitude = 180.0
            }
            
            self.mapView.zoomWithLatitudeLongitudeBoundsSouthWest(CLLocationCoordinate2DMake(southWestLatitude, southWestLongitude), northEast: CLLocationCoordinate2DMake(northEastLatitude, northEastLongitude), animated: animated)
            
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