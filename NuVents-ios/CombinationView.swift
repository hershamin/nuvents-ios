
//
//  CombinationView.swift
//  NuVents-ios
//
//  Created by hersh amin on 8/1/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import Foundation

class CombinationViewController: UIViewController {
    // Container outlets
    @IBOutlet var categoryView:UIView!
    @IBOutlet var listView:UIView!
    @IBOutlet var mapView:UIView!
    @IBOutlet var segmentedCtrlView:UIView!
    @IBOutlet var searchBar:UISearchBar!
    @IBOutlet var filterBtn:UIButton!
    var filterViewOpen:Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Show List view
        categoryView.hidden = true
        listView.hidden = false
        mapView.hidden = true
        
        // Search bar setup
        searchBar.backgroundImage = UIImage.new() // Clear background image
        
        // Filter button setup
        filterBtn.addTarget(self, action: "filterBtnClicked:", forControlEvents: UIControlEvents.TouchUpInside)
        
        // Segmented control setup
        let titles:Array = ["CATEGORIES", "EVENT LIST", "MAP"]
        var segmentedCtrl = URBSegmentedControl(items: titles)
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
    }
    
    // Filter button clicked
    func filterBtnClicked(sender:UIButton!) {
        // Open/Close filter view using XYorigami framework
        let filterVC = FilterViewController()
        filterVC.view.frame = CGRectMake(0, 0, 150, UIScreen.mainScreen().bounds.height)
        if (!filterViewOpen) {
            // Filter view is not open, open it
            self.view.showOrigamiTransitionWith(filterVC.view, numberOfFolds: 2, duration: CGFloat(0.5), direction: UInt(XYOrigamiDirectionFromRight), completion: { (finished:Bool) -> Void in
                self.filterViewOpen = true
            })
        } else {
            // Filter view is open, close it
            self.view.hideOrigamiTransitionWith(filterVC.view, numberOfFolds: 2, duration: CGFloat(0.3), direction: UInt(XYOrigamiDirectionFromRight), completion: { (finished:Bool) -> Void in
                self.filterViewOpen = false
            })
        }
    }
    
    // View will disappear
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        // Close filter view if open
        if (filterViewOpen) {
            filterBtnClicked(nil)
        }
    }
    
    // Called when unwinded from detail view controller
    @IBAction func unwindToCombinationView(sender: UIStoryboardSegue) {
        println("CombinationView From DetailView")
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
    
    // Restrict to portrait only
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
}