//
//  PartialView.swift
//  NuVents-ios
//
//  Created by hersh amin on 5/11/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import Foundation

class DetailView: UIViewController, UIWebViewDelegate {
    
    internal var json: JSON = JSON("") // Event variable to be passed
    let size = UIScreen.mainScreen().bounds
    var webView: UIWebView!
    var panoView: GMSPanoramaView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib
        
        loadPartialView()
    }
    
    // Load detail view
    func loadDetailView() {
        webView.frame = CGRectMake(0, 0, size.width, size.height)
        var baseURL = NuVentsBackend.getResourcePath("tmp", type: "tmp") // Base URL: resources dir
        baseURL = baseURL.stringByReplacingOccurrencesOfString("tmp/tmp", withString: "")
        let fileURL = NuVentsBackend.getResourcePath("detailView", type: "html")
        let htmlStr = NSString(contentsOfFile: fileURL, encoding: NSUTF8StringEncoding, error: nil) as! String
        webView.loadHTMLString(htmlStr, baseURL: NSURL(fileURLWithPath: fileURL))
    }
    
    // Load partial view
    func loadPartialView() {
        // Add street view if not present
        if (panoView == nil){
            panoView = GMSPanoramaView(frame: CGRectMake(0, 0, size.width, size.height/2))
            let lat = (json["latitude"].stringValue as NSString).doubleValue
            let lng = (json["longitude"].stringValue as NSString).doubleValue
            panoView.moveNearCoordinate(CLLocationCoordinate2DMake(lat, lng))
            self.view.addSubview(panoView)
        }
        
        // Add webview
        if (webView == nil) {
            webView = UIWebView()
            webView.delegate = self
            self.view.addSubview(webView)
        }
        webView.frame = CGRectMake(0, size.height/2, size.width, size.height/2)
        var baseURL = NuVentsBackend.getResourcePath("tmp", type: "tmp") // Base URL: resources dir
        baseURL = baseURL.stringByReplacingOccurrencesOfString("tmp/tmp", withString: "")
        let fileURL = NuVentsBackend.getResourcePath("partialView", type: "html") // Partial view html
        let htmlStr = NSString(contentsOfFile: fileURL, encoding: NSUTF8StringEncoding, error: nil) as! String
        webView.loadHTMLString(htmlStr, baseURL: NSURL(fileURLWithPath: baseURL))
    }
    
    // Webview delegate methods
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        let reqStr = request.URL?.absoluteString
        if reqStr!.rangeOfString("openDetailView://") != nil {
            loadDetailView()
            return false
        } else if reqStr!.rangeOfString("closeDetailView://") != nil {
            loadPartialView()
            return false
        } else if reqStr!.rangeOfString("closePartialView://") != nil {
            self.dismissViewControllerAnimated(true, completion: nil)
            return false
        } else {
            return true
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose any resources that can be recreated
    }
    
}