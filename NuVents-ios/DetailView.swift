//
//  PartialView.swift
//  NuVents-ios
//
//  Created by hersh amin on 5/11/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import Foundation

class DetailView: UIViewController {
    
    internal var json: JSON = JSON("") // Event variable to be passed
    internal var marker: GMSMarker = GMSMarker() // Event marker
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after oadign the view, typically from a nib
        println("\(json)")
        println(marker.snippet)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose any resources that can be recreated
    }
    
}