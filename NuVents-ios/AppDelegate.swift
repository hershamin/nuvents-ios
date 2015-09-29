//
//  AppDelegate.swift
//  NuVents-ios
//
//  Created by hersh amin on 4/26/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

// Compiler flags for debug & release
#if DEBUG
    let backend = "repo.nuvents.com:1027"
    let fabricIntegration = false
#else
    let backend = "backend.nuvents.com"
    let fabricIntegration = true
#endif

import UIKit
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        let appStoreID = "792991234"
        // Initiate fabricIO with crashlytics if in release build
        if (fabricIntegration) { Fabric.with([Crashlytics()]) }
        // Change status bar color to white throughout app
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true)
        NuVentsEndpoint.sharedEndpoint.connect() // Begin NuVents backend connection
        // Siren Framework for notifying users when new updates are available
        let siren = Siren.sharedInstance
        siren.appID = appStoreID
        siren.majorUpdateAlertType = SirenAlertType.Option  // x.1.1
        siren.minorUpdateAlertType = SirenAlertType.Skip    // 1.x.1
        siren.patchUpdateAlertType = SirenAlertType.Force   // 1.1.x
        siren.checkVersion(SirenVersionCheckType.Immediately) // Check for new app version at app start
        
        // Initiate branchIO instance, test or live depending on build
        var branchIO:Branch!
        if (fabricIntegration) {
            // Get live
            branchIO = Branch.getInstance()
        } else {
            // Get test
            branchIO = Branch.getTestInstance()
        }
        branchIO.initSessionWithLaunchOptions(launchOptions, andRegisterDeepLinkHandler: { params, error in
            // Check if eventID is present, if present, call detail view
            if let eid = params["eventID"] as? String {
                NuVentsEndpoint.sharedEndpoint.selectedEID = eid
                NuVentsEndpoint.sharedEndpoint.detailFromDelegate = true
                // Present controller
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let dvc = storyboard.instantiateViewControllerWithIdentifier("DetailView")
                dispatch_async(dispatch_get_main_queue(), {
                    self.window?.rootViewController?.presentViewController(dvc, animated: true, completion: nil)
                })
            }
        })
        
        return true
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        if (fabricIntegration) {
            // Live
            Branch.getInstance().handleDeepLink(url)
        } else {
            // Test
            Branch.getTestInstance().handleDeepLink(url)
        }
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        NuVentsEndpoint.sharedEndpoint.disconnect(true) // End NuVents backend connection
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        NuVentsEndpoint.sharedEndpoint.connect() // Begin NuVents backend connection
        Siren.sharedInstance.checkVersion(SirenVersionCheckType.Immediately) // Check for new app version
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        Siren.sharedInstance.checkVersion(SirenVersionCheckType.Daily) // Perform daily checks for new version
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        NuVentsEndpoint.sharedEndpoint.disconnect(true) // End NuVents backend connection
    }


}

