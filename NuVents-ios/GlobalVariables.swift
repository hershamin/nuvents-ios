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
    internal let server: String = "repo.nuvents.com:1027"
    internal let pickerView     = "http://storage.googleapis.com/nuvents-resources/pickerView.html"
    internal let categoryView   = "http://storage.googleapis.com/nuvents-resources/categoryView.html"
    internal let listView       = "http://storage.googleapis.com/nuvents-resources/listView.html"
    internal let detailView     = "http://storage.googleapis.com/nuvents-resources/detailView.html"
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
    internal var searchProc = false // true if search process is busy
    internal var tempJson:JSON = JSON("") // Temp event json to pass to detail view
    internal var currentLoc:CLLocation? // Current location
    internal var eventReqLoc:String = "" // Location where events are requested
    internal var category = "" // To set event category
    internal var api:NuVentsBackend? // NuVents backend API
    internal var pickerWebView:UIWebView? // Picker View Web View
    internal var udid:String? // Unique device id
    
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