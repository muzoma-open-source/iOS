//
//  TracksTableViewCell.swift
//  Event Sequencer
//
//  Created by Matthew Hopkins on 02/12/2015.
//  Copyright © 2015 Muzoma.com. All rights reserved.
//
//  Cell for each set
//

import UIKit

class SetTableViewCell : UITableViewCell {
    internal var muzomaDoc:MuzomaDocument!
    
    @IBOutlet weak var trackName: UILabel!
    @IBOutlet weak var artist: UILabel!

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    @IBAction func selectButtonPress(_ sender: AnyObject) {
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.isSelected = false
    }
    
    override var isSelected : Bool {
        didSet {
            //print( "selected did select \(selected)" )
            if( isSelected )
            {
                self.contentView.alpha = 0.5
            }
            else
            {
                self.contentView.alpha = 1.0
            }
        }
    }
    
    func deleteButtonPress(_ vc:DocumentsCollectionViewController) {
        
        let alert = UIAlertController(title: "Remove Set?", message: "All data will be lost.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            
            
            let alertSongs = UIAlertController(title: "Remove songs", message: "Remove all songs from the set too?", preferredStyle: UIAlertController.Style.alert)
            alertSongs.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in

                _ = _gFSH.deleteMuzPackage(self.muzomaDoc) // delete set
                
                let nc = NotificationCenter.default
                nc.post(name: Notification.Name(rawValue: "RefreshDocsView"), object: nil)
            }))
            alertSongs.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (action: UIAlertAction!) in
                _ = _gFSH.deleteMuzPackage(self.muzomaDoc) // delete set
                
                let nc = NotificationCenter.default
                nc.post(name: Notification.Name(rawValue: "RefreshDocsView"), object: nil)
            }))

            vc.present(alertSongs, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            //print("Handle Cancel Logic here")
        }))

        vc.present(alert, animated: true, completion: nil)
    }
 
    
    internal func setDocument(_ doc:MuzomaDocument!) {
        muzomaDoc = doc
        if( muzomaDoc._isPlaceholder )
        {
            self.muzomaDoc.deserialize(doc.diskFolderFilePath)
            self.muzomaDoc._isPlaceholder = false
        }
        self.trackName.text = doc._title
        self.artist.text = doc._artist
    }
}
