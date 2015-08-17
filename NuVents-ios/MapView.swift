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
    var calloutView:SMCalloutView!
    
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
        // Change color of user location dot to branding pink color
        mapView.tintColor = UIColor(red: 0.91, green: 0.337, blue: 0.427, alpha: 1) // #E8566D
        // Rest of the setup
        let centerCoords = CLLocationCoordinate2DMake(30.27, -97.74)
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(centerCoords, span)
        mapView.setRegion(region, animated: true)
        
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
    
    // Function to return image for map marker
    func getMarkerImg(eventJson:JSON!) -> UIImage {
        if let markerImg = UIImage(contentsOfFile: NuVentsHelper.getResourcePath(eventJson["marker"].stringValue, type: "mapMarkerHigh")) {
            return markerImg // Marker Image
        } else {
            return UIImage.new() // Empty UIImage
        }
    }
    
    // Function to change map view to category changed
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
    
    // Delegate method to determine how map markers would look
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        // User location map marker
        if (annotation.isKindOfClass(MKUserLocation)) {
            return nil
        }
        
        // Any other map marker
        if (annotation.isKindOfClass(MBXPointAnnotation)) {
            var annView = mapView.dequeueReusableAnnotationViewWithIdentifier(annotationReuseIdentifier)
            
            let annotationMBX = annotation as! MBXPointAnnotation
            if (annView == nil) {
                annView = MapViewAnnotationView(annotation: annotation, reuseIdentifier: annotationReuseIdentifier)
            }
            
            let eventJson:JSON = eventsJson[annotationMBX.eventID]! // Event properties
            annView.image = self.getMarkerImg(eventJson) // Set marker image
            annView.canShowCallout = false
            
            return annView
        }
        
        return nil
    }
    
    // Delegate method to listen to marker deselect to dismiss SMCalloutView
    func mapView(mapView: MKMapView!, didDeselectAnnotationView view: MKAnnotationView!) {
        // Return if annotation is current location
        if (view.annotation.isKindOfClass(MKUserLocation)) {
            return
        }
        
        // Dismiss SMCalloutView
        if (calloutView != nil) {
            calloutView.dismissCalloutAnimated(true)
        }
    }
    
    // Delegate method to listen for map region changed to dismiss SMCalloutView
    func mapView(mapView: MKMapView!, regionWillChangeAnimated animated: Bool) {
        // Dismiss SMCalloutView
        if (calloutView != nil) {
            calloutView.dismissCalloutAnimated(true)
        }
    }
    
    // Delegate method to listen to marker click to show SMCalloutView
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        // Return if annotation is current location
        if (view.annotation.isKindOfClass(MKUserLocation)) {
            return
        }
        
        // Gather Variables
        if (calloutView != nil) {
            calloutView.dismissCalloutAnimated(true)
        }
        self.calloutView = SMCalloutView.platformCalloutView()
        let annMBX = view.annotation as! MBXPointAnnotation
        let eventJson:JSON = eventsJson[annMBX.eventID]!
        // Set callout properties
        calloutView.title = annMBX.title
        calloutView.subtitle = annMBX.subtitle
        calloutView.eventID = annMBX.eventID
        calloutView.permittedArrowDirection = SMCalloutArrowDirection.Down
        // Set callout assessories
        let mediaImgData = NSData(contentsOfURL: NSURL(string: eventJson["media"].stringValue)!)
        let mediaImgView:UIImageView = UIImageView(image: UIImage(data: mediaImgData!))
        mediaImgView.frame = CGRectMake(0, 0, 55, 55)
        calloutView.leftAccessoryView = mediaImgView
        calloutView.rightAccessoryView = UIButton.buttonWithType(UIButtonType.DetailDisclosure) as! UIView
        calloutView.rightAccessoryView.tintColor = UIColor(red: 0.91, green: 0.337, blue: 0.427, alpha: 1) // #E8566D
        // Show callout
        let point = mapView.convertCoordinate(annMBX.coordinate, toPointToView: mapView)
        var calloutRect:CGRect = CGRectZero
        calloutRect.origin = point
        calloutView.userInteractionEnabled = true
        calloutView.presentCalloutFromRect(calloutRect, inLayer: mapView.layer, constrainedToLayer: mapView.layer, animated: true)
        calloutView.layer.zPosition = CGFloat(MAXFLOAT)
    }
    
}