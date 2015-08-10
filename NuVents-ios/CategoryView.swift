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
        let filePath = NuVentsHelper.getResourcePath("categoryNames", type: "misc", override: false)
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
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell: CategoryViewCell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! CategoryViewCell
        
        //Set the image in the cell
        let filePathImage = NuVentsHelper.getResourcePath(iconList[indexPath.row]["value"].stringValue, type: "categoryIcon", override: false)
        println(filePathImage)
        cell.imageCell.image = UIImage(contentsOfFile: filePathImage)
        
        //Give the cell a label
        cell.labelCell.text = iconList[indexPath.row]["name"].stringValue
        
        //Produce a border for the cells and color them.
        var color: UIColor = UIColor(red: 0.84, green: 0.844, blue: 0.852, alpha: 1)
        
        cell.backgroundColor = UIColor.clearColor()
        cell.layer.borderColor = color.CGColor
        cell.layer.borderWidth = 2.0
        cell.layer.cornerRadius = 3
        
        return cell
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