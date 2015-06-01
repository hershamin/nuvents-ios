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
    let bounds = UIScreen.mainScreen().bounds
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib
        
        // Load webview
        var webView = UIWebView()
        webView.delegate = self
        webView.frame = CGRectMake(0, 0, bounds.width, bounds.height)
        var baseURL = NuVentsBackend.getResourcePath("tmp", type: "tmp", override: false)
        baseURL = baseURL.stringByReplacingOccurrencesOfString("tmp/tmp", withString: "")
        let fileURL = NuVentsBackend.getResourcePath("detailView", type: "html", override: false)
        let htmlStr = NSString(contentsOfFile: fileURL, encoding: NSUTF8StringEncoding, error: nil) as! String
        webView.loadHTMLString(htmlStr, baseURL: NSURL(fileURLWithPath: baseURL))
        self.view.addSubview(webView)
    }
    
    // Restrict to portrait only
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }
    
    // Webview finished loading
    func webViewDidFinishLoad(webView: UIWebView) {
        webView.stringByEvaluatingJavaScriptFromString("setEvent(\(json))") // Insert event data into webview
    }
    
    // Webview delegate methods
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        let reqStr = request.URL?.absoluteString
        if reqStr!.rangeOfString("closedetailview://") != nil {
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