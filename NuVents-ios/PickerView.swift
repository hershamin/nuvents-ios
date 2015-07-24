//
//  PickerView.swift
//  NuVents-ios
//
//  Created by hersh amin on 6/2/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import Foundation

class PickerViewController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet var webView: UIWebView!
    @IBOutlet var activityIndicator:UIActivityIndicatorView!
    @IBOutlet var refreshBtn:UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib
        
        // Init
        let filePath = NSBundle.mainBundle().pathForResource("pickerView", ofType: "html")
        webView.loadRequest(NSURLRequest(URL: NSURL(string: filePath!)!))
        GlobalVariables.sharedVars.pickerWebView = webView
        activityIndicator.startAnimating()
        
        // Set status bar text color based on event count
        let eventCount = GlobalVariables.sharedVars.eventJSON.count
        if (eventCount == 0) { // White color
            UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
        } else { // Black color
            UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: true)
        }
        
    }
    
    @IBAction func unwindSegueToPickerView(segue: UIStoryboardSegue) {
        // Called when category, map, or list view is dismissed to get to picker view
        // Set status bar text to black color
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: true)
    }
    
    // Webview delegate methods
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        let reqStr = request.URL?.absoluteString
        if reqStr!.rangeOfString("openmapview://") != nil {
            GlobalVariables.sharedVars.category = "" // Set category in global
            self.performSegueWithIdentifier("showMapView", sender: nil)
            return false
        } else if reqStr!.rangeOfString("openlistview://") != nil {
            GlobalVariables.sharedVars.category = "" // Set category in global
            self.performSegueWithIdentifier("showListView", sender: nil)
            return false
        } else if reqStr!.rangeOfString("opencategoryview://") != nil {
            self.performSegueWithIdentifier("showCategoryView", sender: nil)
            return false
        } else if reqStr!.rangeOfString("sendeventrequest://") != nil { // Send request to add city to backend
            let request = reqStr!.componentsSeparatedByString("//").last!
            WelcomeViewController.sendEventRequest(request + "&did=" + GlobalVariables.sharedVars.udid!)
            return false
        } else {
            return true
        }
    }
    func webViewDidFinishLoad(webView: UIWebView) {
        activityIndicator.stopAnimating()
        // Convert dict to json
        let jsonDict = GlobalVariables.sharedVars.eventJSON
        // Send to webview
        webView.stringByEvaluatingJavaScriptFromString("setEventCount(\(jsonDict.count))")
        // Hide refresh btn if event count is 0
        if (jsonDict.count == 0) {
            refreshBtn.hidden = true
        } else {
            refreshBtn.hidden = false
        }
        // Get image url from welcome view backgrounds & send to webview
        var imgDir = NuVentsBackend.getResourcePath("tmp", type: "welcomeViewImgs", override: false)
        imgDir = imgDir.stringByReplacingOccurrencesOfString("tmp", withString: "")
        let fileManager:NSFileManager = NSFileManager()
        let files = fileManager.enumeratorAtPath(imgDir)
        var imgs: [String] = []
        while let file: AnyObject = files?.nextObject() {
            imgs.append(imgDir + (file as! String))
        }
        let randomInd = Int(arc4random_uniform(UInt32(imgs.count))) // Pick random img to display
        let imgURL = imgs[randomInd]
        let imgURLObj = NSURL(fileURLWithPath: imgURL)!
        webView.stringByEvaluatingJavaScriptFromString("setImgUrl(\"\(imgURLObj)\")") // Send to webview
        // Send current location coordinates to webview
        let currentLoc = GlobalVariables.sharedVars.currentLoc!
        webView.stringByEvaluatingJavaScriptFromString("setLocation(\"\(currentLoc.coordinate.latitude),\(currentLoc.coordinate.longitude)\")")
        // Send server url to webview
        webView.stringByEvaluatingJavaScriptFromString("setServer(\"http://\(GlobalVariables.sharedVars.server)/\")")
    }
    
    // Update event count
    class func updateEventCount() {
        // Convert dict to json
        let jsonDict = GlobalVariables.sharedVars.eventJSON
        let webView = GlobalVariables.sharedVars.pickerWebView
        if (webView != nil) {
            webView?.stringByEvaluatingJavaScriptFromString("setEventCount(\(jsonDict.count))")
        }
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