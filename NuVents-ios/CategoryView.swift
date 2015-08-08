//
//  CategoryView.swift
//  NuVents-ios
//
//  Created by hersh amin on 8/1/15.
//  Copyright (c) 2015 NuVents. All rights reserved.
//

import Foundation

class CategoryViewController: UIViewController, UICollectionViewDataSource,UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    
    @IBOutlet var myCollectionView:UICollectionView!
    
    
    let reuseIdentifier = "Cell"
    var iconList: [String] = ["music", "food","sports","charity","conference","productLaunch","games","singles", "tech"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
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
        
        //Configure the cell's with the category icon images.
        let filePath = NuVentsHelper.getResourcePath(iconList[indexPath.row], type: "categoryIcon", override: false)
        
        cell.imageCell.image = UIImage(contentsOfFile: filePath)
        
        //Give the cell a label
        cell.labelCell.text = iconList[indexPath.row].uppercaseString
        
        //Produce a border for the cells and color them.
        var color: UIColor = UIColor(red: 0.5, green: 0.2, blue: 0.3, alpha: 0.2)
        
        cell.backgroundColor = UIColor.clearColor()
        cell.layer.borderColor = color.CGColor
        cell.layer.borderWidth = 0.5
        cell.layer.cornerRadius = 3
        
        return cell
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