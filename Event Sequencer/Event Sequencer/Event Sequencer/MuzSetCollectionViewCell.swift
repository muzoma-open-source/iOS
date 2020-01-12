//
//  MuzSetCollectionViewCell.swift
//  Event Sequencer
//
//  Created by Matthew Hopkins on 16/11/2015.
//  Copyright © 2015 Muzoma.com. All rights reserved.
//
//  Handle a set's cell on the UI
//

import UIKit

class MuzSetCollectionViewCell : UICollectionViewCell {
    @IBOutlet weak var artwork: UIImageView!
    @IBOutlet weak var ArtistLabel: UILabel!
    @IBOutlet weak var TitleLabel: UILabel!
    @IBOutlet weak var CloseButton: UIButton!
    
    internal var muzomaSetDoc:MuzomaSetDocument!
    
    
    func DeleteButtonPress(_ vc:SetsCollectionViewController) {
        let fs = _gFSH
        let alert = UIAlertController(title: "Delete Set?", message: "The set will be removed from your collection.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { (action: UIAlertAction!) in

            let alertSongs = UIAlertController(title: "Delete the underlying songs as well?", message: "The set has been deleted.\nDo you also want to delete all the ACTUAL songs from your song collection too?\n***THIS CANNOT BE UNDONE***", preferredStyle: UIAlertController.Style.alert)
            alertSongs.addAction(UIAlertAction(title: "Delete Songs", style: .destructive, handler: { (action: UIAlertAction!) in
                Logger.log("\(#function)  \(#file) User choose to delete all songs from set \(self.muzomaSetDoc._setURL.absoluteString)")
                for doc in self.muzomaSetDoc.muzDocs
                {
                    _ = fs.deleteDoc(doc)
                }
                
                _ = fs.deleteMuzSet(self.muzomaSetDoc) // delete set
                globalDocumentMapper.reLoad()
                DocumentsCollectionViewController.viewDirty = true
                let nc = NotificationCenter.default
                nc.post(name: Notification.Name(rawValue: "RefreshSetsView"), object: nil)
                nc.post(name: Notification.Name(rawValue: "RefreshDocsView"), object: nil)
            }))
            alertSongs.addAction(UIAlertAction(title: "No thanks", style: .default, handler: { (action: UIAlertAction!) in
                _ = _gFSH.deleteMuzSet(self.muzomaSetDoc) // delete set
                let nc = NotificationCenter.default
                nc.post(name: Notification.Name(rawValue: "RefreshSetsView"), object: nil)
            }))
            
            vc.present(alertSongs, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            //print("Handle Cancel Logic here")
        }))
        
        vc.present(alert, animated: true, completion: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
 
    internal func SetDocument(_ doc:MuzomaSetDocument!) {
        muzomaSetDoc = doc
        TitleLabel.text=doc._title
        ArtistLabel.text=doc._artist
        
        if( doc._coverArtURL != nil )
        {
            let url = doc.getArtworkURL()//NSURL(fileURLWithPath: doc._coverArt!)
            if( url != nil )
            {
                let data = try? Data(contentsOf: url! )
                if( data != nil )
                {
                    artwork.image = UIImage(data: data!)
                }
            }
        }
    }
}
