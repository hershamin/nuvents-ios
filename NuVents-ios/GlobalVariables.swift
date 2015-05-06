//
//  GlobalVariables.swift
//  NuVents-ios
//
//  Created by hersh amin on 5/5/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import Foundation

class GlobalVariables {
    
    // These are the properties you can store in your singeton class
    internal var server: String = "repo.nuvents.com:1026"
    
    // Here is how you would get to it without being a global collision of varables.
    //    , or in other words, it is globally accessible parameter that is specific to the
    //    class
    class var sharedVars: GlobalVariables {
        struct Static {
            static let instance = GlobalVariables()
        }
        return Static.instance
    }
    
}