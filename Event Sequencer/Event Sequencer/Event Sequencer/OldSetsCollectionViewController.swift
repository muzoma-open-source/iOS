//
//  SetsCollectionViewController.swift
//  Event Sequencer
//
//  Created by Matthew Hopkins on 16/11/2015.
//  Copyright © 2015 Muzoma.com. All rights reserved.
//

import UIKit


class OldSetsCollectionViewController: UICollectionViewController {
    private let reuseIdentifier = "MuzSetCell"
    private let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    
    
    @IBAction func ShareActionPressed(sender: AnyObject) {
        
        let textToShare = "Swift is awesome!  Check out this website about it!"
            
        if let myWebsite = NSURL(string: "http://www.codingexplorer.com/")
        {
            let objectsToShare = [textToShare, myWebsite]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            
            self.presentViewController(activityVC, animated: true, completion: nil)
        }
    }
        
        
        /*
        // display UIActivityViewController for saving, printing, sharing
        let activityViewController = /*ShareDocumentViewController */UIActivityViewController(
                activityItems:  ["Export as chord pro", NSURL(fileURLWithPath: "http://google.com/")], applicationActivities: nil)
        presentViewController(activityViewController, animated: true,completion: nil)
       
        
        let myWebsite = NSURL(string:"http://www.google.com/")
        
        var img : UIImage! = nil
        
        guard let url = myWebsite else {
            print("nothing found")
            return
        }
        
        let shareItems:Array = [url, url]
        let activityViewController:UIActivityViewController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
        activityViewController.excludedActivityTypes = [UIActivityTypePrint, UIActivityTypePostToWeibo, UIActivityTypeCopyToPasteboard, UIActivityTypeAddToReadingList, UIActivityTypePostToVimeo]
        self.presentViewController(activityViewController, animated: true, completion: nil)

    }*/

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        //self.collectionView!.registerClass(MuzDocCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return 10
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let gencell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath)
        let cell = gencell as! MuzSetCollectionViewCell
        
        //let cell1 = collectionView.deq(reuseIdentifier) as MuzDocCollectionViewCell
        //let cell1 = cell as! MuzDocCollectionViewCell
 
        cell.backgroundColor = UIColor.whiteColor()
        
        return cell
    }
    

    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
            
            /*let flickrPhoto =  photoForIndexPath(indexPath)
            //2
            if var size = flickrPhoto.thumbnail?.size {
                size.width += 10
                size.height += 10
                return size
            }*/
            return CGSize(width: 100, height: 100)
    }

    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAtIndex section: Int) -> UIEdgeInsets {
            return sectionInsets
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */

}
