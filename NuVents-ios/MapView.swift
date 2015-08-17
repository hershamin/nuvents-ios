//
//  MapView.swift
//  NuVents-ios
//
//  Created by hersh amin on 8/1/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import Foundation
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet var myLocBtn:UIButton!
    @IBOutlet var mapView:MKMapView!
    let annotationReuseIdentifier = "MKPointAnnotationIdentifier"
    var eventsJson : [String:JSON]!
    var mapMarkers:[MBXPointAnnotation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Init my location button
        myLocBtn.addTarget(self, action: "myLocBtnPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // Init MapBox Overlay
        MBXMapKit.setAccessToken(NuVentsEndpoint.sharedEndpoint.mapboxToken)
        var mapboxOverlay = MBXRasterTileOverlay(mapID: NuVentsEndpoint.sharedEndpoint.mapboxMapId)
        mapView.addOverlay(mapboxOverlay)
        
        // Init MapView
        let centerCoords = CLLocationCoordinate2DMake(30.27, -97.74)
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(centerCoords, span)
        mapView.setRegion(region, animated: true)
        mapView.showsUserLocation = true
        
        // Add map markers based from global variable to mapMarkers
        eventsJson = NuVentsEndpoint.sharedEndpoint.eventJSON
        for (key, event) in eventsJson {
            // Collect info
            let title = event["title"].stringValue
            let startTS = event["time"]["start"].stringValue
            let lat = (event["latitude"].stringValue as NSString).doubleValue
            let lng = (event["longitude"].stringValue as NSString).doubleValue
            // Add annotation
            let annotation = MBXPointAnnotation()
            annotation.eventID = key
            annotation.title = title
            annotation.subtitle = NuVentsHelper.getHumanReadableDate(startTS)
            annotation.coordinate = CLLocationCoordinate2DMake(lat, lng)
            mapMarkers.append(annotation)
            self.mapView.addAnnotation(annotation)
        }
        
        //Set up listeners for NSNotificationCenter
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "changeMapViewToSearch", name: NuVentsEndpoint.sharedEndpoint.categoryNotificationKey, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "changeMapViewToSearch", name: NuVentsEndpoint.sharedEndpoint.searchNotificationKey, object: nil)
    }
    
    func changeMapViewToCategory() {
        let categorizeList = NuVentsEndpoint.sharedEndpoint.categories
        //Iterate through the mapMarkers getting each annotation
        for annotation in mapMarkers {
            let mbxAnn = annotation as MBXPointAnnotation
            let eventJson:JSON = eventsJson[mbxAnn.eventID]!
            if (categorizeList.count == 0) {
                mapView.addAnnotation(annotation)
            } else if (categorizeList.contains(eventJson["marker"].stringValue))  {
                mapView.addAnnotation(annotation)
            } else {
                mapView.removeAnnotation(annotation)
            }
        }
    }
    
    // Function to change map view to search bar text changed
    func changeMapViewToSearch() {
        let searchText = NuVentsEndpoint.sharedEndpoint.searchText.lowercaseString
        changeMapViewToCategory() // Get categorized event markers
        // Iterate & search in title
        for annotation in self.mapView.annotations {
            if let mbxAnn = annotation as? MBXPointAnnotation {
                let title = mbxAnn.title.lowercaseString
                if (count(searchText) == 0) {
                    mapView.addAnnotation(mbxAnn)
                } else if (title.rangeOfString(searchText) != nil) {
                    mapView.addAnnotation(mbxAnn)
                } else {
                    mapView.removeAnnotation(mbxAnn)
                }
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
        if let currLoc = mapView.userLocation {
            let coords = currLoc.coordinate
            var camera = MKMapCamera(lookingAtCenterCoordinate: coords, fromEyeCoordinate: coords, eyeAltitude: 2500)
            self.mapView.setCamera(camera, animated: true)
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
    
    // MARK: MapView Delegate Methods
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        if (overlay.isKindOfClass(MBXRasterTileOverlay)) {
            let renderer = MBXRasterTileRenderer(overlay: overlay)
            return renderer
        }
        return nil
    }
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        if (annotation.isKindOfClass(MBXPointAnnotation)) {
            var annView = mapView.dequeueReusableAnnotationViewWithIdentifier(annotationReuseIdentifier)
            let annotationMBX = annotation as! MBXPointAnnotation
            if (annView == nil) {
                annView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationReuseIdentifier)
                let eventJson:JSON = eventsJson[annotationMBX.eventID]! // Event properties
                if let markerImgRaw = UIImage(contentsOfFile: NuVentsHelper.getResourcePath(eventJson["marker"].stringValue, type: "mapMarkerLow")) {
                    let markerImg = NuVentsHelper.resizeImage(markerImgRaw, width: 32)
                    annView.image = markerImg
                }
                annView.canShowCallout = true
                return annView
            } else {
                annView.annotation = annotation
                return annView
            }
        }
        return nil
    }
    
}