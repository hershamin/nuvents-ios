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
    var calloutViewVisible:Bool!
    var selectedEventID:String!
    @IBOutlet var attributionBtn:UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Init my location button
        myLocBtn.addTarget(self, action: "myLocBtnPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // Init MapBox Overlay
        MBXMapKit.setAccessToken(NuVentsEndpoint.sharedEndpoint.mapboxToken)
        let mapboxOverlay = MBXRasterTileOverlay(mapID: NuVentsEndpoint.sharedEndpoint.mapboxMapId)
        mapView.addOverlay(mapboxOverlay)
        
        // Init Attribution button
        attributionBtn.tintColor = UIColor(red: 0.91, green: 0.337, blue: 0.427, alpha: 1) // #E8566D
        attributionBtn.addTarget(self, action: "mapAttrBtnClicked:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // Init MapView
        // Change color of user location dot to branding pink color
        mapView.tintColor = UIColor(red: 0.91, green: 0.337, blue: 0.427, alpha: 1) // #E8566D
        
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
        
        // Mapview region to fit all annotations
        containAllAnnotations()
        
        //Set up listeners for NSNotificationCenter
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "changeMapViewToSearch", name: NuVentsEndpoint.sharedEndpoint.categoryNotificationKey, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "changeMapViewToSearch", name: NuVentsEndpoint.sharedEndpoint.searchNotificationKey, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "changeListViewToSearch", name: NuVentsEndpoint.sharedEndpoint.mapFilterNotificationKey, object: nil)
    }
    
    // Function to set map region to contain all annotations
    func containAllAnnotations() {
        
        if self.mapView.annotations.count == 0 {
            return
        }
        
        var zoomRect:MKMapRect = MKMapRectNull
        for (var i=0; i<self.mapView.annotations.count; i++) {
            if let annotation:MBXPointAnnotation = self.mapView.annotations[i] as? MBXPointAnnotation {
                let annotationPoint:MKMapPoint = MKMapPointForCoordinate(annotation.coordinate)
                let pointRect:MKMapRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0, 0)
                if (MKMapRectIsNull(zoomRect)) {
                    zoomRect = pointRect
                } else {
                    zoomRect = MKMapRectUnion(zoomRect, pointRect)
                }
            }
        }
        
        self.mapView.setVisibleMapRect(zoomRect, edgePadding: UIEdgeInsetsMake(20, 20, 20, 20), animated: true)
    }
    
    // Function to return image for map marker
    func getMarkerImg(eventJson:JSON!) -> UIImage {
        if let markerImg = UIImage(contentsOfFile: NuVentsHelper.getResourcePath(eventJson["marker"].stringValue, type: "mapMarkerHigh")) {
            return markerImg // Marker Image
        } else {
            return UIImage() // Empty UIImage
        }
    }
    
    // Function to request event detail
    func openDetailView(sender:UIButton!) {
        // Get json from event ID
        let eventID:String = selectedEventID
        NuVentsEndpoint.sharedEndpoint.getEventDetail(eventID)
    }
    
    // Open detail view upon hearing notification
    func goToDetailView() {
        self.performSegueWithIdentifier("showDetailView", sender: nil)
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
    
    // Function to sort list view array
    func sortMapView() {
        let sortBy = NuVentsEndpoint.sharedEndpoint.mapViewFilter
        if sortBy == 0 {
            // All
        } else if sortBy == 1 {
            // Today
            //
        } else if sortBy == 2 {
            // Tomorrow
            //
        }
    }
    
    // Function to change map view to search bar text changed
    func changeMapViewToSearch() {
        if (calloutView != nil) {
            calloutView.dismissCalloutAnimated(true)
        } // Dismiss SMCalloutView if presented
        let searchText = NuVentsEndpoint.sharedEndpoint.searchText.lowercaseString
        changeMapViewToCategory() // Get categorized event markers
        // Iterate & search in title
        for annotation in self.mapView.annotations {
            if let mbxAnn = annotation as? MBXPointAnnotation {
                let title = mbxAnn.title!.lowercaseString
                if (searchText.characters.count == 0) {
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
        let currLoc = mapView.userLocation
        let coords = currLoc.coordinate
        var camera = MKMapCamera(lookingAtCenterCoordinate: coords, fromEyeCoordinate: coords, eyeAltitude: 2500)
        self.mapView.setCamera(camera, animated: true)
    }
    
    // Restrict to portrait only
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
    // MARK: MapView Delegate Methods
    // Called when mapview updated user location
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        // Set new location in global variables
        NuVentsEndpoint.sharedEndpoint.currLoc = userLocation.coordinate
    }
    
    // Delegate method to determine how to render map tiles
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer! {
        if (overlay.isKindOfClass(MBXRasterTileOverlay)) {
            let renderer = MBXRasterTileRenderer(overlay: overlay)
            return renderer
        }
        return nil
    }
    
    // Delegate method to determine how map markers would look
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView! {
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
            annView!.image = self.getMarkerImg(eventJson) // Set marker image
            annView!.canShowCallout = false
            
            return annView
        }
        
        return nil
    }
    
    // Delegate method to listen to marker deselect to dismiss SMCalloutView
    func mapView(mapView: MKMapView, didDeselectAnnotationView view: MKAnnotationView) {
        // Return if annotation is current location
        if (view.annotation!.isKindOfClass(MKUserLocation)) {
            return
        }
        
        // Dismiss SMCalloutView
        if (calloutView != nil) {
            calloutView.dismissCalloutAnimated(true)
            calloutViewVisible = false
        }
    }
    
    // Delegate method to listen for map region changed to move SMCalloutView with map
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if (calloutView != nil && calloutViewVisible == true) {
            // Get appropriate points to move callout location
            let mapPt:CGPoint = mapView.convertCoordinate(calloutView.eventLocation, toPointToView: mapView)
            let calloutRect:CGRect = CGRectMake(mapPt.x, mapPt.y, 0, 0)
            // Update callout frame
            calloutView.presentCalloutFromRect(calloutRect, inView: mapView, constrainedToView: mapView, animated: false)
            calloutView.layer.zPosition = CGFloat(MAXFLOAT)
        }
    }
    
    // Delegate method to listen for map region will change to hide SMCalloutView with map
    func mapView(mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        if (calloutView != nil) {
            self.calloutView.dismissCalloutAnimated(false)
        }
    }
    
    // Delegate method to listen to marker click to show SMCalloutView
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        // Return if annotation is current location
        if (view.annotation!.isKindOfClass(MKUserLocation)) {
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
        calloutView.eventLocation = annMBX.coordinate
        calloutView.permittedArrowDirection = SMCalloutArrowDirection.Down
        // Set callout assessories
        let mediaImgData = NSData(contentsOfURL: NSURL(string: eventJson["media"].stringValue)!)
        let mediaImgView:UIImageView = UIImageView(image: UIImage(data: mediaImgData!))
        mediaImgView.frame = CGRectMake(0, 0, 55, 55)
        calloutView.leftAccessoryView = mediaImgView
        // Detail view button
        let detailViewBtn:UIButton = UIButton(type: UIButtonType.DetailDisclosure)
        detailViewBtn.tintColor = UIColor(red: 0.91, green: 0.337, blue: 0.427, alpha: 1) // #E8566D
        selectedEventID = annMBX.eventID // Set event ID to retrieve when button is pressed
        detailViewBtn.addTarget(self, action: "openDetailView:", forControlEvents: UIControlEvents.TouchUpInside)
        detailViewBtn.exclusiveTouch = true
        calloutView.rightAccessoryView = detailViewBtn
        // Show callout
        let point = mapView.convertCoordinate(annMBX.coordinate, toPointToView: mapView)
        var calloutRect:CGRect = CGRectZero
        calloutRect.origin = point
        calloutView.userInteractionEnabled = true
        //calloutView.presentCalloutFromRect(calloutRect, inLayer: mapView.layer, constrainedToLayer: mapView.layer, animated: true)
        calloutView.presentCalloutFromRect(calloutRect, inView: mapView, constrainedToView: mapView, animated: true)
        calloutViewVisible = true
        calloutView.layer.zPosition = CGFloat(MAXFLOAT)
    }
    
    // MARK: Attribution Function when map attribution is clicked
    func mapAttrBtnClicked(sender:UIButton!) {
        let alertController = UIAlertController(title: "Map Attribution", message: "© Mapbox, © OpenStreetMap", preferredStyle: UIAlertControllerStyle.Alert)
        // Go to mapbox about page
        let aboutAction = UIAlertAction(title: "About", style: UIAlertActionStyle.Default) {
            (action) in
            UIApplication.sharedApplication().openURL(NSURL(string: "https://www.mapbox.com/about/maps/")!)
        }
        alertController.addAction(aboutAction)
        // Go to mapbox improve this map page
        let improveAction = UIAlertAction(title: "Improve this map", style: UIAlertActionStyle.Default) {
            (action) in
            UIApplication.sharedApplication().openURL(NSURL(string: "https://www.mapbox.com/map-feedback/")!)
        }
        alertController.addAction(improveAction)
        // Cancel alert
        let cancelAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler:nil)
        alertController.addAction(cancelAction)
        // Present alert view
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
}