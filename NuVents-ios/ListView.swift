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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "changeListViewToCategory", name: NuVentsEndpoint.sharedEndpoint.categoryNotificationKey, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "changeListViewToSearch", name: NuVentsEndpoint.sharedEndpoint.searchNotificationKey, object: nil)
    }
    
    // Restrict to portrait only
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
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
    
    // Function to change list view to search bar text changed
    func changeListViewToSearch() {
        println("ListViewSearch: " + NuVentsEndpoint.sharedEndpoint.searchText)
    }
    
    //MARK - Table View Methods
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return eventArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: ListViewCell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier) as! ListViewCell
        
        // Add right accessory
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        
        // Set event title & time
        let eventJSON = eventArray[indexPath.row]
        cell.titleLabel.text = eventJSON["title"].stringValue
        cell.infoLabel.text = NuVentsHelper.getHumanReadableDate(eventJSON["time"]["start"].stringValue)
        
        // Set event category image
        let imgPath = NuVentsHelper.getResourcePath(eventJSON["marker"].stringValue, type: "categoryIcon")
        cell.iconView.image = UIImage(contentsOfFile: imgPath)
        
        return cell
    }
    
    // Called when row is selected
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // Go to detail view
        self.performSegueWithIdentifier("showDetailView", sender: nil)
        
        // Deselect row
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
}