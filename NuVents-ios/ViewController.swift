//
//  ViewController.swift
//  NuVents-ios
//
//  Created by hersh amin on 4/26/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import UIKit

class ViewController: UIViewController, NuVentsBackendDelegate {
    
    var api:NuVentsBackend?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        var camera = GMSCameraPosition.cameraWithLatitude(30.3077609, longitude: -97.7534014, zoom: 9)
        var mapView = GMSMapView.mapWithFrame(CGRectZero, camera: camera)
        mapView.myLocationEnabled = true
        self.view = mapView
        
        var marker = GMSMarker()
        marker.position = CLLocationCoordinate2DMake(30.2766, -97.734)
        marker.title = "Austin"
        marker.snippet = "TX"
        marker.map = mapView
        
        api = NuVentsBackend(delegate: self, server: "repo.nuvents.com:1026", device: "test")
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: NuVents backend delegate methods
    func nuventsServerDidConnect() {
        println("NuVents backend connected")
        api?.pingServer()
        var loc = CLLocationCoordinate2D(latitude: 30.2766, longitude: -97.7324)
        api?.getNearbyEvents(loc, radius: 500)
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
        println("OBJ")
        for (key: String, subJson: JSON) in event {
            println("    \(key): \(subJson)")
        }
    }
    
    func nuventsServerDidReceiveEventDetail(event: JSON) {
        //
    }

}

