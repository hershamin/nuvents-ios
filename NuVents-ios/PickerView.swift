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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib
        
        // Init
        webView.loadRequest(NSURLRequest(URL: NSURL(string: GlobalVariables.sharedVars.pickerView)!))
        
    }
    
    @IBAction func unwindSegueToPickerView(segue: UIStoryboardSegue) {
        // Called when category, map, or list view is dismissed to get to picker view
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
        } else {
            return true
        }
    }
    func webViewDidFinishLoad(webView: UIWebView) {
        // Convert dict to json
        let jsonDict = GlobalVariables.sharedVars.eventJSON
        // Send to webview
        webView.stringByEvaluatingJavaScriptFromString("setEventCount(\(jsonDict.count))")
        // Get image url from resource
        let imgURL = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("catViewBack", ofType: "png")!)
        // Send to webview
        webView.stringByEvaluatingJavaScriptFromString("setImgUrl(\"\(imgURL)\")")
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