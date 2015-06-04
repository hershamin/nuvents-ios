//
//  MapView.swift
//  NuVents-ios
//
//  Created by hersh amin on 6/2/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import Foundation

class MapViewController: UIViewController, GMSMapViewDelegate {
    
    @IBOutlet var mapView:GMSMapView!
    @IBOutlet var searchField:UITextField!
    @IBOutlet var myLocBtn:UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib
        
        // Init Vars
        myLocBtn.addTarget(self, action: "myLocBtnPressed:", forControlEvents: .TouchUpInside)
        searchField.addTarget(self, action: "searchFieldChanged:", forControlEvents: .EditingChanged)
        searchField.backgroundColor = UIColor.clearColor()
        
        // MapView
        let currentLoc = GlobalVariables.sharedVars.currentLoc!
        var camera = GMSCameraPosition.cameraWithLatitude(currentLoc.coordinate.latitude, longitude: currentLoc.coordinate.longitude, zoom: 13)
        mapView.moveCamera(GMSCameraUpdate.setCamera(camera))
        mapView.myLocationEnabled = true
        mapView.addObserver(self, forKeyPath: "myLocation", options: nil, context: nil)
        mapView.settings.myLocationButton = false
        mapView.settings.rotateGestures = false
        mapView.delegate = self
        GlobalVariables.sharedVars.mapView = mapView
        
        // Add markers to mapview
        let jsonDict = GlobalVariables.sharedVars.eventJSON
        var eventsJson:JSON = ["":""]
        GlobalVariables.sharedVars.eventMarkers.removeAll() // Clear markers global var
        // iterate through events to add to map
        for (key, event) in jsonDict {
            // Build marker
            var marker: GMSMarker = GMSMarker()
            marker.title = event["eid"].stringValue
            marker.snippet = event["marker"].stringValue
            let latitude = (event["latitude"].stringValue as NSString).doubleValue
            let longitude = (event["longitude"].stringValue as NSString).doubleValue
            marker.position = CLLocationCoordinate2DMake(latitude as CLLocationDegrees, longitude as CLLocationDegrees)
            let markerImg:UIImage = UIImage(contentsOfFile: NuVentsBackend.getResourcePath(marker.snippet, type: "marker", override: false))!
            marker.icon = NuVentsBackend.resizeImage(markerImg, width: 32)
            // Add to map & global variable
            var mapView = GlobalVariables.sharedVars.mapView
            marker.map = mapView
            GlobalVariables.sharedVars.eventMarkers.append(marker)
            GMapCamera.clusterMarkers(mapView, position: mapView.camera, specialEID: marker.title)
        }
    }
    
    // Dismiss text field on clicks anywhere other than keyboard
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        searchField.resignFirstResponder()
    }
    
    // Restrict to portrait only
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }
    
    // My location button pressed
    func myLocBtnPressed(sender: UIButton!) {
        var mapView = GlobalVariables.sharedVars.mapView
        let location = mapView.myLocation
        let camera = GMSCameraPosition.cameraWithLatitude(location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: 15)
        mapView.animateToCameraPosition(camera)
    }
    
    // Search field changed value
    func searchFieldChanged(sender: UITextField!) {
        var searchProcess = GlobalVariables.sharedVars.searchProc
        if (!searchProcess) { // Search process free
            searchProcess = true
            GMapCamera.searchEventsByTitle(sender.text)
            searchProcess = false
        }
    }
    
    // Google Maps Marker Click Event
    func mapView(mapView: GMSMapView!, didTapMarker marker: GMSMarker!) -> Bool {
        // Get event detail and open detail view controller
        WelcomeViewController.getEventDetail(marker.title, callback: {(jsonData: JSON) -> Void in
            GlobalVariables.sharedVars.tempJson = jsonData
            self.performSegueWithIdentifier("showDetailView", sender: nil)
        })
        return true;
    }
    
    // Google Maps Camera Change Event
    func mapView(mapView: GMSMapView!, didChangeCameraPosition position: GMSCameraPosition!) {
        var cameraProcess = GlobalVariables.sharedVars.cameraProc
        if (!cameraProcess) { // Camera process free
            cameraProcess = true
            GMapCamera.cameraChanged(mapView, position: position) // Call clustering function
            GlobalVariables.sharedVars.prevCam = position // Make current position previous position
            cameraProcess = false
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose any resources that can be recreated
    }
    
}