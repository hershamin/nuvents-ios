//
//  GlobalVariables.swift
//  NuVents-ios
//
//  Created by hersh amin on 5/5/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import Foundation

class GlobalVariables {
    
    // Global constants
    internal let server: String = "repo.nuvents.com:1026"
    internal let zoomLevelMargin: Float = 0.5 // User must change camera by indicated zoom level to trigger clustering
    internal let zoomLevelClusteringLimit: Float = 14.5 // Markers cannot resize if zoom level is above that
    internal let nearbyEventsMargin: Float = 5 // Events must be within specified meters to be combined
    internal let clusteringMultiplier: Float = 1 // Determines the clustering behaviour of markers
    
    // Global variables
    internal var eventMarkers = Array<GMSMarker>()
    internal var eventJSON = [String: JSON]()
    internal var prevCam = GMSCameraPosition.new()
    internal var mapView = GMSMapView.new()
    internal var cameraProc = false // true if camera process is busy
    
    // Here is how you would get to it without being a global collision of varables.
    //    , or in other words, it is globally accessible parameter that is specific to the
    //    class
    class var sharedVars: GlobalVariables {
        struct Static {
            static let instance = GlobalVariables()
        }
        return Static.instance
    }
    
}