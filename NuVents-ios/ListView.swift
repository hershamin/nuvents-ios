//
//  ListView.swift
//  NuVents-ios
//
//  Created by hersh amin on 5/11/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import Foundation

class ListView: UIViewController {
    
    internal var events = [String: JSON]() // Events in the form of NSDict or Hashmap
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after oadign the view, typically from a nib
        
        // Write events json to file /data
        let dir = NuVentsBackend.getResourcePath("tmp", type: "tmp")
        let file = dir.stringByReplacingOccurrencesOfString("tmp/tmp", withString: "") + "data"
        "\(events)".writeToFile(file, atomically: true, encoding: NSUTF8StringEncoding, error: nil)
        
        println("\(events)")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose any resources that can be recreated
    }
    
}