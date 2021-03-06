
//
//  CombinationView.swift
//  NuVents-ios
//
//  Created by hersh amin on 8/1/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import Foundation

class CombinationViewController: UIViewController, UISearchBarDelegate, UIGestureRecognizerDelegate, UIPopoverPresentationControllerDelegate {
    // Container outlets
    @IBOutlet var categoryView:UIView!
    @IBOutlet var listView:UIView!
    @IBOutlet var mapView:UIView!
    @IBOutlet var segmentedCtrlView:UIView!
    @IBOutlet var searchBar:UISearchBar!
    @IBOutlet var filterBtn:UIButton!
    @IBOutlet var refreshBtn:UIButton!
    var segmentedCtrl:URBSegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Show List view
        categoryView.hidden = true
        listView.hidden = false
        mapView.hidden = true
        
        // Search bar setup
        searchBar.backgroundImage = UIImage() // Clear background image
        
        // Init buttons
        filterBtn.addTarget(self, action: "filterBtnPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        refreshBtn.addTarget(self, action: "refreshBtnPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // Segmented control setup
        let titles:Array = ["CATEGORIES", "EVENT LIST", "MAP"]
        segmentedCtrl = URBSegmentedControl(items: titles)
        segmentedCtrl.selectedSegmentIndex = 1 // Select List View Segment
        segmentedCtrl.addTarget(self, action: "handleSegmentChanged:", forControlEvents: UIControlEvents.ValueChanged)
        segmentedCtrl.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, 40)
        segmentedCtrl.baseColor = UIColor(red: 0.91, green: 0.298, blue: 0.4, alpha: 1) // e84c66
        segmentedCtrl.cornerRadius = 0
        segmentedCtrl.segmentEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
        segmentedCtrl.strokeWidth = 0
        segmentedCtrl.strokeColor = UIColor(red: 0.91, green: 0.298, blue: 0.4, alpha: 1) // e84c66
        segmentedCtrl.showsGradient = false
        segmentedCtrl.imageColor = nil
        segmentedCtrl.selectedImageColor = UIColor.clearColor()
        segmentedCtrl.segmentBackgroundColor = UIColor(red: 0.831, green: 0.278, blue: 0.373, alpha: 1) // d4475f
        segmentedCtrl.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
        segmentedCtrl.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
        segmentedCtrl.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
        segmentedCtrlView.addSubview(segmentedCtrl)
        
        // Tap gesture recognizer to dismiss keyboard
        let tapGestureRecognizer:UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "DismissSearchBarKeyboard")
        tapGestureRecognizer.delegate = self
        self.view.addGestureRecognizer(tapGestureRecognizer)
        
        // Signup for notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "openDeepLinkCtrl", name: NuVentsEndpoint.sharedEndpoint.deepLinkOpenNotificationKey, object: nil)
    }
    
    // Open deep links
    func openDeepLinkCtrl() {
        let detailViewOpen = NuVentsEndpoint.sharedEndpoint.deepLinkFromWelcome
        if (detailViewOpen && self.isViewLoaded() && self.view.window != nil) {
            // Open Detail view controller
            NuVentsEndpoint.sharedEndpoint.deepLinkFromWelcome = false
            self.performSegueWithIdentifier("showDetailView", sender: nil)
        }
    }
    
    // Tap gesture recognizer delegate
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (touch.view!.isDescendantOfView(listView) || touch.view!.isDescendantOfView(mapView) || touch.view!.isDescendantOfView(categoryView)) {
            // Don't let list view, category view, or map view tap fire gesture recognizer
            return false
        }
        return true
    }
    
    // Refresh Button pressed
    func refreshBtnPressed(sender:UIButton!) {
        self.performSegueWithIdentifier("unwindCombinationView", sender: nil)
    }
    
    // Filter Button pressed
    func filterBtnPressed(sender:UIButton!) {
        let selectedSegmentInd = segmentedCtrl.selectedSegmentIndex
        if selectedSegmentInd == 0 {
            // Category view, no popover
        } else if selectedSegmentInd == 1 {
            // List view
            self.performSegueWithIdentifier("popoverListFilter", sender: nil)
        } else if selectedSegmentInd == 2 {
            // Map view
            self.performSegueWithIdentifier("popoverMapFilter", sender: nil)
        }
    }
    
    // Dismiss keyboard from search bar
    func DismissSearchBarKeyboard() {
        searchBar.resignFirstResponder()
    }
    
    // Called when unwinded from detail view controller
    @IBAction func unwindToCombinationView(sender: UIStoryboardSegue) {
        // Combination View from Detail View
    }
    
    // Called when view is deallocated from memory
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // Segue transition delegate
    override func segueForUnwindingToViewController(toViewController: UIViewController, fromViewController: UIViewController, identifier: String?) -> UIStoryboardSegue {
        if let id = identifier {
            if id == "unwindCombinationView" {
                let unwindSegue = DetailViewUnwindSegue(identifier: id, source: fromViewController, destination: toViewController, performHandler: { () -> Void in
                    //
                })
                
                return unwindSegue
            }
        }
        
        return super.segueForUnwindingToViewController(toViewController, fromViewController: fromViewController, identifier: identifier!)!
    }
    
    // Segue transition delegate
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "popoverListFilter" || segue.identifier == "popoverMapFilter" {
            let popoverVC = segue.destinationViewController
            popoverVC.modalPresentationStyle = UIModalPresentationStyle.Popover
            popoverVC.popoverPresentationController?.delegate = self
        }
        
    }
    
    // Popover controller delegate, some required stuff
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
    // Segment changed
    func handleSegmentChanged(sender: URBSegmentedControl!) {
        let segmentCtrl = sender as URBSegmentedControl
        let title = segmentCtrl.titleForSegmentAtIndex(segmentCtrl.selectedSegmentIndex)!
        
        if (title.lowercaseString.rangeOfString("categories") != nil) {
            // Show category view
            categoryView.hidden = false
            listView.hidden = true
            mapView.hidden = true
        } else if (title.lowercaseString.rangeOfString("list") != nil) {
            // Show Event List
            categoryView.hidden = true
            listView.hidden = false
            mapView.hidden = true
        } else if (title.lowercaseString.rangeOfString("map") != nil) {
            // Show Map View
            categoryView.hidden = true
            listView.hidden = true
            mapView.hidden = false
        }
        
    }
    
    // Search bar delegate methods
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        DismissSearchBarKeyboard()
    } // resigning keyboard when search button is pressed
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        NuVentsEndpoint.sharedEndpoint.searchText = searchText
        NSNotificationCenter.defaultCenter().postNotificationName(NuVentsEndpoint.sharedEndpoint.searchNotificationKey, object: nil)
    } // Search bar text changed
    
    // Restrict to portrait only
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
}