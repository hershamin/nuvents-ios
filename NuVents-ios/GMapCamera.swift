//
//  GMapCamera.swift
//  NuVents-ios
//
//  Created by hersh amin on 5/6/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import Foundation

// Called for Google Maps Camera Change
class GMapCamera {
    
    // Camera changed
    class func cameraChanged(mapView: GMSMapView!, position: GMSCameraPosition!) {
        println("Camera change")
    }
    
}