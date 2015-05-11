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
        println("\(events)")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose any resources that can be recreated
    }
    
}