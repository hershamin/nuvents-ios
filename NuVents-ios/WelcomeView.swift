//
//  ViewController.swift
//  NuVents-ios
//
//  Created by hersh amin on 4/26/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController, NuVentsBackendDelegate, UIWebViewDelegate {
    
    var api:NuVentsBackend?
    var serverConnn:Bool = false
    var initialLoc:Bool = false
    @IBOutlet var mapListViewBtn:UIButton!
    @IBOutlet var statusBarImg:UIImageView!
    @IBOutlet var navBarImg:UIImageView!
    @IBOutlet var webView:UIWebView!
    let size = UIScreen.mainScreen().bounds

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        api = NuVentsBackend(delegate: self, server: GlobalVariables.sharedVars.server, device: "test")
        
        // Init Vars
        mapListViewBtn.addTarget(self, action: "listViewBtnPressed:", forControlEvents: .TouchUpInside)
        webView.hidden = true
        
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
    
    // List view button pressed
    func listViewBtnPressed(sender: UIButton!) {
        // UI Setup
        webView.hidden = false
        let mapListImg = UIImage(contentsOfFile: NuVentsBackend.getResourcePath("mapView", type: "icon", override: false))
        mapListViewBtn.setImage(mapListImg, forState: .Normal)
        mapListViewBtn.removeTarget(self, action: "listViewBtnPressed:", forControlEvents: .TouchUpInside)
        mapListViewBtn.addTarget(self, action: "mapViewBtnPressed:", forControlEvents: .TouchUpInside)
        
        // Load webview
        /*var baseURL = NuVentsBackend.getResourcePath("tmp", type: "tmp", override: false)
        baseURL = baseURL.stringByReplacingOccurrencesOfString("tmp/tmp", withString: "")
        let fileURL = NuVentsBackend.getResourcePath("listView", type: "html", override: false)
        let htmlStr = NSString(contentsOfFile: fileURL, encoding: NSUTF8StringEncoding, error: nil) as! String
        webView.loadHTMLString(htmlStr, baseURL: NSURL(fileURLWithPath: fileURL))*/
        let title:String = webView.stringByEvaluatingJavaScriptFromString("document.title")!
        if (title.isEmpty) { // Load html from server
            webView.loadRequest(NSURLRequest(URL: NSURL(string: "http://storage.googleapis.com/nuvents-resources/listViewTest.html")!))
        } else { // Already loaded, send new events
            // Convert dict to json
            let jsonDict = GlobalVariables.sharedVars.eventJSON
            var eventsJson:JSON = ["":""]
            for (key, val) in jsonDict {
                eventsJson[key] = val
            }
            // Send to webview
            webView.stringByEvaluatingJavaScriptFromString("setEvents(\(eventsJson))")
            let searchText = searchField.text.lowercaseString
            webView.stringByEvaluatingJavaScriptFromString("searchByTitle('\(searchText)')")
        }
    }
    
    // Map view button pressed
    func mapViewBtnPressed(sender: UIButton!) {
        // UI Setup
        webView.hidden = true
        let mapListImg = UIImage(contentsOfFile: NuVentsBackend.getResourcePath("listView", type: "icon", override: false))
        mapListViewBtn.setImage(mapListImg, forState: .Normal)
        mapListViewBtn.removeTarget(self, action: "mapViewBtnPressed:", forControlEvents: .TouchUpInside)
        mapListViewBtn.addTarget(self, action: "listViewBtnPressed:", forControlEvents: .TouchUpInside)
    }
    
    // Webview delegate methods
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        let reqStr = request.URL?.absoluteString
        if reqStr!.rangeOfString("opendetailview://") != nil {
            let eid = reqStr!.componentsSeparatedByString("//").last
            openDetailView(eid!)
            return false
        } else {
            return true
        }
    }
    func webViewDidFinishLoad(webView: UIWebView) {
        // Convert dict to json
        let jsonDict = GlobalVariables.sharedVars.eventJSON
        var eventsJson:JSON = ["":""]
        for (key, val) in jsonDict {
            eventsJson[key] = val
        }
        // Send to webview
        webView.stringByEvaluatingJavaScriptFromString("setEvents(\(eventsJson))")
        let searchText = searchField.text.lowercaseString
        webView.stringByEvaluatingJavaScriptFromString("searchByTitle('\(searchText)')")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // NuVents server resources sync complete
    func nuventsServerDidSyncResources() {
        // Status Bar img
        let statusBar = UIImage(contentsOfFile: NuVentsBackend.getResourcePath("statusBar", type: "icon", override: false))!
        statusBarImg.image = statusBar
        
        // Nav Bar img
        let navBar = UIImage(contentsOfFile: NuVentsBackend.getResourcePath("navBar", type: "icon", override: false))
        navBarImg.image = navBar
        
        // My Location btn
        let myLocImg = UIImage(contentsOfFile: NuVentsBackend.getResourcePath("myLocation", type: "icon", override: false))!
        myLocBtn.setTitle("", forState: .Normal)
        myLocBtn.setImage(myLocImg, forState: .Normal)
        
        // Map/List View btn
        let mapListImg: UIImage
        if mapListViewBtn.respondsToSelector("mapViewBtnPressed:") {
            mapListImg = UIImage(contentsOfFile: NuVentsBackend.getResourcePath("mapView", type: "icon", override: false))!
        } else {
            mapListImg = UIImage(contentsOfFile: NuVentsBackend.getResourcePath("listView", type: "icon", override: false))!
        }
        mapListViewBtn.setTitle("", forState: .Normal)
        mapListViewBtn.setImage(mapListImg, forState: .Normal)
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
    
    // Open Detail View
    func openDetailView(eid: String) {
        api?.getEventDetail(eid, callback: { (jsonData: JSON) -> Void in
            // Merge event summary & detail
            let summary:JSON = GlobalVariables.sharedVars.eventJSON[eid]!
            var jsonData = jsonData
            for (summ: String, subJson: JSON) in summary {
                jsonData[summ] = subJson
            }
            // Present detail view
            let detailView = DetailViewController()
            detailView.json = jsonData
            self.presentViewController(detailView, animated: true, completion: nil)
        })
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

