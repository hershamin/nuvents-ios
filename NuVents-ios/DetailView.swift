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
        
        // Write event json to file /data
        let dir = NuVentsBackend.getResourcePath("tmp", type: "tmp")
        let file = dir.stringByReplacingOccurrencesOfString("tmp/tmp", withString: "") + "data"
        "\(json)".writeToFile(file, atomically: true, encoding: NSUTF8StringEncoding, error: nil)
        
        // Load webview
        var webView = UIWebView()
        webView.delegate = self
        webView.frame = CGRectMake(0, 0, bounds.width, bounds.height)
        self.view.addSubview(webView)
        var baseURL = NuVentsBackend.getResourcePath("tmp", type: "tmp")
        baseURL = baseURL.stringByReplacingOccurrencesOfString("tmp/tmp", withString: "")
        let fileURL = NuVentsBackend.getResourcePath("detailView", type: "html")
        let htmlStr = NSString(contentsOfFile: fileURL, encoding: NSUTF8StringEncoding, error: nil) as! String
        webView.loadHTMLString(htmlStr, baseURL: NSURL(fileURLWithPath: baseURL))
    }
    
    // Webview delegate methods
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        let reqStr = request.URL?.absoluteString
        if reqStr!.rangeOfString("closeDetailView://") != nil {
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