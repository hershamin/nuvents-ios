//
//  CategoryView.swift
//  NuVents-ios
//
//  Created by hersh amin on 8/1/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import Foundation

class CategoryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet var myCollectionView:UICollectionView!
    
    let reuseIdentifier = "Cell"
    var iconList:JSON = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        //Get the JSON object.
        let filePath = NuVentsHelper.getResourcePath("categoryNames", type: "misc")
        let fm = NSFileManager.defaultManager()
        if (fm.fileExistsAtPath(filePath)) {
            let fileData = NSData(contentsOfFile: filePath)
            iconList = JSON(data: fileData!)
        }

    }
    
    //Setup the collection view.
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        // 1
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //return count
        return iconList.count
    }
    
    // Called to set cell appearence
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        // Check for intention to set background
        let background:Bool = iconList[indexPath.row]["bg"].boolValue
        
        // Get appropriate collection view cell
        let cell: CategoryViewCell = self.myCollectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! CategoryViewCell
        
        // Basic cell appearence
        var bgColor: UIColor! // Cell background color
        var borderColor: CGColor! // Cell border color
        var textColor: UIColor! // Cell text color
        cell.layer.cornerRadius = 3
        cell.layer.borderWidth = 2.0
        var imgType: String! // Cell image type (highlighted or normal)
        
        // 2 Different cell appearences
        if (background) { // Pink background to match branding
            bgColor = UIColor(red: 0.91, green: 0.337, blue: 0.427, alpha: 1) // #E8566D
            borderColor = bgColor.CGColor
            imgType = "categoryIconHighlighted"
            textColor = UIColor.whiteColor()
        } else {
            bgColor = UIColor.clearColor()
            borderColor = UIColor(red: 0.84, green: 0.844, blue: 0.852, alpha: 1).CGColor // Light gray
            imgType = "categoryIcon"
            textColor = UIColor.blackColor()
        }
        
        // Set appearence
        cell.backgroundColor = bgColor
        cell.layer.borderColor = borderColor
        let imgPath = NuVentsHelper.getResourcePath(iconList[indexPath.row]["value"].stringValue, type: imgType)
        cell.imageCell.image = UIImage(contentsOfFile: imgPath)
        cell.labelCell.textColor = textColor
        cell.labelCell.text = iconList[indexPath.row]["name"].stringValue
        
        return cell
    }
    
    // Cell tapped
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let bgIntent:Bool = iconList[indexPath.row]["bg"].boolValue
        if (bgIntent) {
            iconList[indexPath.row]["bg"] = false
            collectionView.reloadItemsAtIndexPaths([indexPath])
            collectionView.deselectItemAtIndexPath(indexPath, animated: true)
        } else {
            iconList[indexPath.row]["bg"] = true
            collectionView.reloadItemsAtIndexPaths([indexPath])
            collectionView.deselectItemAtIndexPath(indexPath, animated: true)
        }
    }
    
    //Make function for notification
    @IBAction func changeCombinationView(sender: UICollectionViewCell){
        
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