//
//  ViewController.swift
//  NuVents-ios
//
//  Created by hersh amin on 4/26/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import UIKit

class ViewController: UIViewController, NuVentsBackendDelegate, GMSMapViewDelegate {
    
    var api:NuVentsBackend?
    var serverConnn:Bool = false
    var initialLoc:Bool = false
    var myLocBtn:UIButton!
    var listViewBtn:UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        api = NuVentsBackend(delegate: self, server: GlobalVariables.sharedVars.server, device: "test")
        
        // MapView
        var camera = GMSCameraPosition.cameraWithLatitude(30.3077609, longitude: -97.7534014, zoom: 9)
        var mapView = GMSMapView.mapWithFrame(CGRectZero, camera: camera)
        mapView.myLocationEnabled = true
        mapView.addObserver(self, forKeyPath: "myLocation", options: nil, context: nil)
        mapView.settings.myLocationButton = false
        mapView.settings.rotateGestures = false
        mapView.delegate = self
        GlobalVariables.sharedVars.mapView = mapView
        self.view = mapView
        
    }
    
    // My location button pressed
    func myLocBtnPressed(sender: UIButton!) {
        var mapView = GlobalVariables.sharedVars.mapView
        let location = mapView.myLocation
        let camera = GMSCameraPosition.cameraWithLatitude(location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: 15)
        mapView.animateToCameraPosition(camera)
    }
    
    // List view button pressed
    func listViewBtnPressed(sender: UIButton!) {
        let listView = ListView()
        listView.events = GlobalVariables.sharedVars.eventJSON
        listView.modalTransitionStyle = UIModalTransitionStyle.FlipHorizontal
        self.presentViewController(listView, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // NuVents server resources sync complete
    func nuventsServerDidSyncResources() {
        let config : JSON = GlobalVariables.sharedVars.config // get config
        
        // My Location button
        if self.myLocBtn == nil {
            self.myLocBtn = UIButton()
            self.view.addSubview(myLocBtn)
        }
        let myLocImg = UIImage(contentsOfFile: NuVentsBackend.getResourcePath("myLocation", type: "icon"))
        myLocBtn.setImage(myLocImg, forState: .Normal)
        let bounds = UIScreen.mainScreen().bounds
        myLocBtn.frame = CGRectMake(CGFloat(config["myLocBtnX"].floatValue) * bounds.width, CGFloat(config["myLocBtnY"].floatValue) * bounds.height, myLocImg!.size.width, myLocImg!.size.height)
        myLocBtn.addTarget(self, action: "myLocBtnPressed:", forControlEvents: .TouchUpInside)
        
        // List View button
        if self.listViewBtn == nil {
            self.listViewBtn = UIButton()
            self.view.addSubview(listViewBtn)
        }
        let listViewImg = UIImage(contentsOfFile: NuVentsBackend.getResourcePath("listView", type: "icon"))
        listViewBtn.setImage(listViewImg, forState: .Normal)
        listViewBtn.frame = CGRectMake(CGFloat(config["listViewBtnX"].floatValue) * bounds.width, CGFloat(config["listViewBtnY"].floatValue) * bounds.height, listViewImg!.size.width, listViewImg!.size.height)
        listViewBtn.addTarget(self, action: "listViewBtnPressed:", forControlEvents: .TouchUpInside)
    }
    
    // Google Maps did get my location
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if keyPath == "myLocation" && serverConnn && !initialLoc {
            let location : CLLocation = object.myLocation; // Get location
            object.moveCamera(GMSCameraUpdate.setTarget(location.coordinate, zoom:13))
            let projection: GMSProjection = object.projection
            let topLeftCorner = projection.coordinateForPoint(CGPointMake(0, 0))
            let topLeftLoc = CLLocation(latitude: topLeftCorner.latitude, longitude: topLeftCorner.longitude)
            let dist = topLeftLoc.distanceFromLocation(location) // Get radius
            api?.getNearbyEvents(location.coordinate, radius: Float(dist)) // Search nearby events
            initialLoc = true
        }
    }
    
    // Google Maps Marker Click Event
    func mapView(mapView: GMSMapView!, didTapMarker marker: GMSMarker!) -> Bool {
        api?.getEventDetail(marker.title, callback: { (jsonData: JSON) -> Void in
            let detailView = DetailView()
            detailView.json = jsonData
            self.presentViewController(detailView, animated: true, completion: nil)
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
    
    // MARK: NuVents backend delegate methods
    func nuventsServerDidConnect() {
        println("NuVents backend connected")
        api?.pingServer()
        serverConnn = true
    }
    
    func nuventsServerDidDisconnect() {
        println("NuVents backend disconnected")
    }
    
    func nuventsServerDidGetNewData(channel: NSString, data: AnyObject) {
        //println("NuVents channel \(channel) with data \(data)")
    }
    
    func nuventsServerDidRespondToPing(response: NSString) {
        //
    }
    
    func nuventsServerDidReceiveError(type: NSString, error: NSString) {
        //
    }
    
    func nuventsServerDidReceiveStatus(type: NSString, status: NSString) {
        //
    }
    
    func nuventsServerDidReceiveNearbyEvent(event: JSON) {
        // Add to global vars
        GlobalVariables.sharedVars.eventJSON[event["eid"].stringValue] = event
        // Build marker
        var marker: GMSMarker = GMSMarker()
        marker.title = event["eid"].stringValue
        marker.snippet = event["title"].stringValue
        let latitude = (event["latitude"].stringValue as NSString).doubleValue
        let longitude = (event["longitude"].stringValue as NSString).doubleValue
        marker.position = CLLocationCoordinate2DMake(latitude as CLLocationDegrees, longitude as CLLocationDegrees)
        marker.icon = UIImage(contentsOfFile: NuVentsBackend.getResourcePath(marker.snippet, type: "marker"))
        // Add to map & global variable
        var mapView = GlobalVariables.sharedVars.mapView
        marker.map = mapView
        GlobalVariables.sharedVars.eventMarkers.append(marker)
        GMapCamera.clusterMarkers(mapView, position: mapView.camera, specialEID: marker.title)
    }
    
    func nuventsServerDidReceiveEventDetail(event: JSON) {
        //
    }

}

