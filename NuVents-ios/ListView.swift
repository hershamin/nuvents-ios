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
    }
    
    // Restrict to portrait only
    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
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
        println(eventArray[indexPath.row])
        
        // Deselect row
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    
}