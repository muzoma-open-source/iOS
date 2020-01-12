//
//  MuzSetCollectionViewCell.swift
//  Event Sequencer
//
//  Created by Matthew Hopkins on 16/11/2015.
//  Copyright © 2015 Muzoma.com. All rights reserved.
//

import UIKit

class OldMuzSetCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var artwork: UIImageView!
    @IBOutlet weak var ArtistLabel: UILabel!
    @IBOutlet weak var TitleLabel: UILabel!
    internal var muzomaDoc:MuzomaDocument!
    @IBOutlet weak var CloseButton: UIButton!
    
    @IBOutlet weak var cellLabel: UILabel!
    
    func DeleteButtonPress(vc:DocumentsCollectionViewController) {
        /*let removeAlert = UIAlertView()
        removeAlert.title = "Remove Document?"
        removeAlert.message = "All data will be lost."
        removeAlert.addButtonWithTitle("Cancel")
        removeAlert.addButtonWithTitle("OK")
        removeAlert.show()*/

        let alert = UIAlertController(title: "Remove Document?", message: "All data will be lost.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action: UIAlertAction!) in
                //print("Handle Ok logic here")
            FileSystemHelper().deleteDoc(self.muzomaDoc)
            vc.refreshDocs()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action: UIAlertAction!) in
                //print("Handle Cancel Logic here")
        }))

        //self.window?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
        vc.presentViewController(alert, animated: true, completion: nil)

        
        //presentViewController(nil, animated: true, completion: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        //pickerView.viewForRow(<#row: Int#>, forComponent: <#Int#>)
    }
 
    internal func SetDocument(doc:MuzomaDocument!) {
        muzomaDoc = doc
        TitleLabel.text=doc._title
        ArtistLabel.text=doc._author
        
        if( doc._coverArtURL != nil )
        {
            let url = doc.getArtworkURL()//NSURL(fileURLWithPath: doc._coverArt!)
            if( url != nil )
            {
                let data = NSData(contentsOfURL: url! )
                if( data != nil )
                {
                    artwork.image = UIImage(data: data!)
                    //artwork.sizeToFit()
                    //self.sendSubviewToBack( artwork.viewWithTag(0)! )
                    //self.bringSubviewToFront( TitleLabel.viewWithTag(0)! )
                    //self.bringSubviewToFront( ArtistLabel.viewWithTag(0)! )
                }
            }
        }
    }
}
