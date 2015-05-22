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
        // TODO: Remove markers not in view
        
        // Find zoom level difference
        let zoomDiff:Float
        let prevLoc = GlobalVariables.sharedVars.prevCam
        if (prevLoc.zoom > position.zoom) {
            zoomDiff = prevLoc.zoom - position.zoom
        } else {
            zoomDiff = position.zoom - prevLoc.zoom
        }
        if (zoomDiff > GlobalVariables.sharedVars.zoomLevelMargin) {
            clusterMarkers(mapView, position: position, specialEID: nil) // Zoom level different, cluster markers
        }
    }
    
    // Search events
    class func searchEventsByTitle(searchTerm: String!, webView: UIWebView!) {
        var mapView = GlobalVariables.sharedVars.mapView
        var events = GlobalVariables.sharedVars.eventJSON
        var markers = GlobalVariables.sharedVars.eventMarkers
        var searchText = searchTerm.lowercaseString
        
        // Call javascript function (webView)
        webView.stringByEvaluatingJavaScriptFromString("searchByTitle('\(searchText)')")
        // Iterate and filter (mapView)
        for marker: GMSMarker in markers {
            let event = events[marker.title]! // Get by EID
            let title = event["title"].stringValue.lowercaseString
            if (title.rangeOfString(searchText) != nil) { // Search term found in event title
                marker.map = nil
            } else {
                if (marker.map == nil) {
                    marker.map = mapView
                }
            }
        }
    }
    
    // Cluster markers
    class func clusterMarkers(mapView: GMSMapView!, position: GMSCameraPosition!, specialEID: String!) {
        let markers: Array = GlobalVariables.sharedVars.eventMarkers
        
        if position.zoom < GlobalVariables.sharedVars.zoomLevelClusteringLimit
        {
            let clusteringConstant = position.zoom * GlobalVariables.sharedVars.clusteringMultiplier
            // Used to determine the clustering of map markers.
            //  The lower the constant, the less clustering it has & vice-versa
            
            // Calculate tolerance
            let currentView: GMSProjection = mapView.projection
            let topLeftCorner = currentView.coordinateForPoint(CGPointMake(0, 0))
            let topRightCorner = currentView.coordinateForPoint(CGPointMake(mapView.bounds.size.width/CGFloat(clusteringConstant), CGFloat(0)))
            let topLeftLoc = CLLocation(latitude: topLeftCorner.latitude, longitude: topLeftCorner.longitude)
            let topRightLoc = CLLocation(latitude: topRightCorner.latitude, longitude: topRightCorner.longitude)
            let tolerance = topLeftLoc.distanceFromLocation(topRightLoc)
            
            // Arrange Markers
            var usedIndices: Array = Array<Int>()
            var tempIndices: Array = Array<Int>()
            for var i=0; i<markers.count; i++
            {
                if !contains(usedIndices, i) // Index not used yet
                {
                    for var j=i+1; j<markers.count; j++
                    {
                        let m1: GMSMarker = markers[i]
                        let m2: GMSMarker = markers[j]
                        let m11: CLLocation = CLLocation(latitude: m1.position.latitude, longitude: m1.position.longitude)
                        let m22: CLLocation = CLLocation(latitude: m2.position.latitude, longitude: m2.position.longitude)
                        let d12 = m11.distanceFromLocation(m22)
                        
                        if d12 < tolerance
                        {
                            tempIndices.append(i)
                            tempIndices.append(j)
                            usedIndices.append(j)
                        }
                    }
                    // Remove similar objects
                    let preSortArray: Array = tempIndices
                    tempIndices.removeAll()
                    var existingObjects: Array = Array<Int>()
                    for nums:Int in preSortArray
                    {
                        if !contains(existingObjects, nums)
                        {
                            existingObjects.append(nums)
                            tempIndices.append(nums)
                        }
                    }
                    if count(tempIndices) != 0
                    {
                        // cluster, change icons
                        // Random marker in cluster or special marker to not resize
                        let randomIndex: Int = Int(arc4random_uniform(UInt32(tempIndices.count)))
                        // Make the rest of the markers smaller
                        for var k=0; k<tempIndices.count; k++
                        {
                            if k != randomIndex && specialEID == nil {
                                let marker: GMSMarker = markers[tempIndices[k]]
                                marker.icon = UIImage(contentsOfFile: NuVentsBackend.getResourcePath("cluster", type: "marker"))
                                marker.zIndex = 1
                            } else if specialEID != nil && markers[tempIndices[k]].title == specialEID {
                                // marker to keep bigger
                                let marker: GMSMarker = markers[tempIndices[k]]
                                marker.icon = UIImage(contentsOfFile: NuVentsBackend.getResourcePath(marker.snippet, type: "marker"))
                                marker.zIndex = 2
                            } else {
                                // marker to keep bigger
                                let marker: GMSMarker = markers[tempIndices[k]]
                                marker.icon = UIImage(contentsOfFile: NuVentsBackend.getResourcePath(marker.snippet, type: "marker"))
                                marker.zIndex = 2
                            }
                        }
                    }
                }
                usedIndices.append(i)
                tempIndices.removeAll()
            }
        } else {
            // Zoom level is greater than equal to ZoomLevel clustering limit
            //  Return all markers to original specs
            for marker: GMSMarker in markers
            {
                marker.icon = UIImage(contentsOfFile: NuVentsBackend.getResourcePath(marker.snippet, type: "marker"))
            }
        }
    }
    
}