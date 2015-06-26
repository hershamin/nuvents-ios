//
//  PartialView.swift
//  NuVents-ios
//
//  Created by hersh amin on 5/11/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import Foundation

class DetailViewController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet var webView:UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib
        
        // Init vars
        let filePath = NSBundle.mainBundle().pathForResource("detailView", ofType: "html")
        webView.loadRequest(NSURLRequest(URL: NSURL(string: filePath!)!))
        
        // Record hit on event website by issuing a http get request
        let urlString = GlobalVariables.sharedVars.tempJson["website"].stringValue
        let url = NSURL(string:urlString)!
        let httpGetTask = NSURLSession.sharedSession().dataTaskWithURL(url) {
            (data, response, error) in
            let resp = response as! NSHTTPURLResponse
            WelcomeViewController.sendWebRespCode(urlString, statusCode: "\(resp.statusCode)")
        }
        httpGetTask.resume()
        
    }
    
    // Restrict to portrait only
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }
    
    // Webview finished loading
    func webViewDidFinishLoad(webView: UIWebView) {
        var event:JSON = GlobalVariables.sharedVars.tempJson
        // Calculate distance between current location and event location
        let eventLoc:CLLocation = CLLocation(latitude: event["latitude"].doubleValue, longitude: event["longitude"].doubleValue)
        let currentLoc:CLLocation = GlobalVariables.sharedVars.currentLoc!
        let dist = eventLoc.distanceFromLocation(currentLoc) // Distance in meters
        event["distance"].string = dist.description
        webView.stringByEvaluatingJavaScriptFromString("setEvent(\(event))") // Insert event data into webview
    }
    
    // Webview delegate methods
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        let reqStr = request.URL?.absoluteString
        if reqStr!.rangeOfString("closedetailview://") != nil {
            self.dismissViewControllerAnimated(true, completion: nil)
            return false
        } else if reqStr!.rangeOfString("opendirections://") != nil {
            let loc = reqStr!.componentsSeparatedByString("//").last
            let lat = loc?.componentsSeparatedByString(",").first
            let lng = loc?.componentsSeparatedByString(",").last
            openMapsApp(lat!, lng: lng!)
            return false
        } else {
            return true
        }
        
    }
    
    // Open location in maps app
    func openMapsApp(lat: String, lng: String) {
        let urlToOpen:String
        if (UIApplication.sharedApplication().canOpenURL(NSURL(string: "comgooglemaps://")!)) {
            // Google maps available
            urlToOpen = "comgooglemaps://?center=\(lat),\(lng)&views=traffic&q=\(lat),\(lng)"
        } else {
            // Use apple maps
            urlToOpen = "http://maps.apple.com/?ll=\(lat),\(lng)&q=\(lat),\(lng)"
        }
        UIApplication.sharedApplication().openURL(NSURL(string: urlToOpen)!)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose any resources that can be recreated
    }
    
}