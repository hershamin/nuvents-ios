//
//  ListView.swift
//  NuVents-ios
//
//  Created by hersh amin on 8/1/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import Foundation

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var tableView: UITableView!
    
    var eventArray: [JSON] = []
    
    let reuseIdentifier = "ListCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Add events to array from global variable
        let eventsJson = NuVentsEndpoint.sharedEndpoint.eventJSON
        for (key, event) in eventsJson {
            eventArray.append(event)
        }
        
        // Setup listeners for NSNotificationCenter
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "changeListViewToSearch", name: NuVentsEndpoint.sharedEndpoint.categoryNotificationKey, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "changeListViewToSearch", name: NuVentsEndpoint.sharedEndpoint.searchNotificationKey, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "changeListViewToSearch", name: NuVentsEndpoint.sharedEndpoint.listFilterNotificationKey, object: nil)
        
        // Initial sort
        sortListView()
    }
    
    // Restrict to portrait only
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
    // Called when view is deallocated from memory
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    //Function to change list view to the appropriate selected category. 
    func changeListViewToCategory() {
        eventArray.removeAll(keepCapacity: false)
        let categorizeList = NuVentsEndpoint.sharedEndpoint.categories
        let eventsJSONCategories = NuVentsEndpoint.sharedEndpoint.eventJSON
        //iterate
        for (key, event) in eventsJSONCategories {
            if (categorizeList.count == 0) {
                eventArray.append(event)
            } else if (categorizeList.contains(event["marker"].stringValue)) {
                eventArray.append(event)
            }
        }
        tableView.reloadData()
    }
    
    // Function to sort list view array
    func sortListView() {
        let sortBy = NuVentsEndpoint.sharedEndpoint.listViewFilter
        if sortBy == 0 {
            // Distance
            eventArray.sortInPlace {
                // Common var
                let currLoc = CLLocation(latitude: NuVentsEndpoint.sharedEndpoint.currLoc.latitude, longitude: NuVentsEndpoint.sharedEndpoint.currLoc.longitude)
                // event 1
                let e1 = $0
                let el1 = CLLocation(latitude: e1["latitude"].doubleValue, longitude: e1["longitude"].doubleValue)
                let d1 = el1.distanceFromLocation(currLoc) * 0.000621371 // Distance in miles
                // event 2
                let e2 = $1
                let el2 = CLLocation(latitude: e2["latitude"].doubleValue, longitude: e2["longitude"].doubleValue)
                let d2 = el2.distanceFromLocation(currLoc) * 0.000621371 // Distance in miles
                // Return
                return d1 < d2
            }
        } else if sortBy == 1 {
            // Time
            eventArray.sortInPlace {
                // event 1
                let e1 = $0
                let t1 = e1["time"]["start"].doubleValue
                // event 2
                let e2 = $1
                let t2 = e2["time"]["start"].doubleValue
                // Return
                return t1 < t2
            }
        }
    }
    
    // Function to change list view to search bar text changed
    func changeListViewToSearch() {
        let searchText = NuVentsEndpoint.sharedEndpoint.searchText.lowercaseString
        changeListViewToCategory() // Get categorized event array
        // Iterate & search in title
        let eventArrayTemp:[JSON] = eventArray
        eventArray.removeAll(keepCapacity: false)
        for event in eventArrayTemp {
            let title = event["title"].stringValue.lowercaseString
            if (searchText.characters.count == 0) {
                eventArray.append(event)
            } else if (title.rangeOfString(searchText) != nil) {
                eventArray.append(event)
            }
        }
        sortListView() // Sort according to selected filter
        tableView.reloadData()
    }
    
    //MARK - Table View Methods
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return eventArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: ListViewCell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) as! ListViewCell
        
        // Add right accessory
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        
        // Set event title, time & dist
        let eventJSON = eventArray[indexPath.row]
        let currLoc = CLLocation(latitude: NuVentsEndpoint.sharedEndpoint.currLoc.latitude, longitude: NuVentsEndpoint.sharedEndpoint.currLoc.longitude)
        let eventLoc = CLLocation(latitude: eventJSON["latitude"].doubleValue, longitude: eventJSON["longitude"].doubleValue)
        let distRaw = eventLoc.distanceFromLocation(currLoc) * 0.000621371 // Distance in miles
        let dist = Double(round(10 * distRaw)/10) // Round the number
        cell.titleLabel.text = eventJSON["title"].stringValue
        let timeStr = NuVentsHelper.getHumanReadableDate(eventJSON["time"]["start"].stringValue)
        let distStr = String(format: "%g", dist)
        if (dist < 0.1) { // Change distance label based on calculated distance
            cell.infoLabel.text = "\(timeStr) | < 0.1 mi"
        } else {
            cell.infoLabel.text = "\(timeStr) | \(distStr) mi"
        }
        
        // Set event category image
        let imgPath = NuVentsHelper.getResourcePath(eventJSON["marker"].stringValue, type: "categoryIcon")
        cell.iconView.image = UIImage(contentsOfFile: imgPath)
        
        return cell
    }
    
    // Called when row is selected
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // Get json from event ID
        let eventID:String = eventArray[indexPath.row]["eid"].stringValue
        NuVentsEndpoint.sharedEndpoint.getEventDetail(eventID)
        
        // Deselect row
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
}