//
//  ListView.swift
//  NuVents-ios
//
//  Created by hersh amin on 6/2/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import Foundation

class ListViewController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet var webView:UIWebView!
    var webViewReady = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib
        
        // Init
        let filePath = NSBundle.mainBundle().pathForResource("listView", ofType: "html")
        webView.loadRequest(NSURLRequest(URL: NSURL(string: filePath!)!))
        
    }
    
    @IBAction func eventFilterIndexChanged(sender:UISegmentedControl) {
        let index = sender.selectedSegmentIndex
        let title = sender.titleForSegmentAtIndex(index)
        if (title?.lowercaseString.rangeOfString("distance")) != nil {
            if (webViewReady) {
                webView.stringByEvaluatingJavaScriptFromString("sortBy('distance')")
            }
        } else if (title?.lowercaseString.rangeOfString("time")) != nil {
            if (webViewReady) {
                webView.stringByEvaluatingJavaScriptFromString("sortBy('time.start')")
            }
        }
    }
    
    // Webview delegate methods
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        let reqStr = request.URL?.absoluteString
        if reqStr!.rangeOfString("opendetailview://") != nil {
            let eid = reqStr!.componentsSeparatedByString("//").last
            // Get event detail and open detail view controller
            WelcomeViewController.getEventDetail(eid!, callback: {(jsonData: JSON) -> Void in
                GlobalVariables.sharedVars.tempJson = jsonData
                self.performSegueWithIdentifier("showDetailView", sender: nil)
            })
            return false
        } else {
            return true
        }
    }
    func webViewDidFinishLoad(webView: UIWebView) {
        // Convert dict to json
        let jsonDict = GlobalVariables.sharedVars.eventJSON
        var eventsJson:JSON = ["":""]
        for (key, var event) in jsonDict {
            let category:String = event["marker"].stringValue.lowercaseString
            let reqCat:String = GlobalVariables.sharedVars.category
            if (reqCat != "") {
                if (category.rangeOfString(reqCat) == nil) {
                    continue // Not in requested category, continue
                }
            }
            // Calculate distance between current location and event location
            let eventLoc:CLLocation = CLLocation(latitude: event["latitude"].doubleValue, longitude: event["longitude"].doubleValue)
            let currentLoc:CLLocation = GlobalVariables.sharedVars.currentLoc!
            let dist = eventLoc.distanceFromLocation(currentLoc) // Distance in meters
            event["distance"].string = dist.description
            eventsJson[key] = event
        }
        webViewReady = true
        // Send to webview
        webView.stringByEvaluatingJavaScriptFromString("setEvents(\(eventsJson))")
    }
    
    // Restrict to portrait only
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose any resources that can be recreated
    }
    
}