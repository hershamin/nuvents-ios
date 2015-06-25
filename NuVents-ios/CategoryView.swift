//
//  CategoryView.swift
//  NuVents-ios
//
//  Created by hersh amin on 6/2/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import Foundation

class CategoryViewController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib
        
        // Init
        let filePath = NSBundle.mainBundle().pathForResource("categoryView", ofType: "html")
        webView.loadRequest(NSURLRequest(URL: NSURL(string: filePath!)!))
    }
    
    // Webview delegate methods
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        let reqStr = request.URL?.absoluteString
        if reqStr!.rangeOfString("openmapview://") != nil {
            let category = reqStr!.componentsSeparatedByString("//").last
            GlobalVariables.sharedVars.category = category! // Set category in global
            self.performSegueWithIdentifier("showMapView", sender: nil)
            return false
        } else if reqStr!.rangeOfString("openlistview://") != nil {
            let category = reqStr!.componentsSeparatedByString("//").last
            GlobalVariables.sharedVars.category = category! // Set category in global
            self.performSegueWithIdentifier("showListView", sender: nil)
            return false
        } else {
            return true
        }
    }
    func webViewDidFinishLoad(webView: UIWebView) {
        //
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