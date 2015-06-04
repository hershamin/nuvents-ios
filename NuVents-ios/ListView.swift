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
    @IBOutlet var searchField:UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib
        
        // Init
        searchField.addTarget(self, action: "searchFieldChanged:", forControlEvents: .EditingChanged)
        searchField.backgroundColor = UIColor.clearColor()
        webView.loadRequest(NSURLRequest(URL: NSURL(string: GlobalVariables.sharedVars.listView)!))
        
    }
    
    // Dismiss text field on clicks anywhere other than keyboard
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        searchField.resignFirstResponder()
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
        for (key, event) in jsonDict {
            let category:String = event["marker"].stringValue.lowercaseString
            let reqCat:String = GlobalVariables.sharedVars.category
            if (reqCat != "") {
                if (category.rangeOfString(reqCat) == nil) {
                    continue // Not in requested category, continue
                }
            }
            eventsJson[key] = event
        }
        // Send to webview
        webView.stringByEvaluatingJavaScriptFromString("setEvents(\(eventsJson))")
    }
    
    // Search field changed value
    func searchFieldChanged(sender: UITextField!) {
        var searchProcess = GlobalVariables.sharedVars.searchProc
        if (!searchProcess) { // Search process free
            searchProcess = true
            let searchText = searchField.text.lowercaseString
            webView.stringByEvaluatingJavaScriptFromString("searchByTitle('\(searchText)')")
            searchProcess = false
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