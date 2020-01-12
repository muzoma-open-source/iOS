//
//  MuzDocCollectionViewCell.swift
//  Event Sequencer
//
//  Created by Matthew Hopkins on 16/11/2015.
//  Copyright © 2015 Muzoma.com. All rights reserved.
//
//  A cell that represents a song on the screen
//

import UIKit

class MuzDocCollectionViewCell: UICollectionViewCell {
    internal var muzomaDoc:MuzomaDocument!
    @IBOutlet weak var artwork: UIImageView!
    @IBOutlet weak var ArtistLabel: UILabel!
    @IBOutlet weak var TitleLabel: UILabel!
    @IBOutlet weak var CloseButton: UIButton!
    @IBOutlet weak var selectButton: UIButton!
    
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
    
    func DeleteButtonPress(_ vc:DocumentsCollectionViewController) {
        let alert = UIAlertController(title: "Remove Document?", message: "All data will be lost.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            //print("Handle Ok logic here")
            _ = _gFSH.deleteMuzPackage(self.muzomaDoc)
            let nc = NotificationCenter.default
            nc.post(name: Notification.Name(rawValue: "RefreshDocsView"), object: nil)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action: UIAlertAction!) in
            //print("Handle Cancel Logic here")
        }))
        
        vc.present(alert, animated: true, completion: nil)
    }
    
    
    internal func SetDocument( _ doc:MuzomaDocument!, vc:DocumentsCollectionViewController, indexPath: IndexPath, table:UICollectionView!  ) {
        
        // do this first, then sort out the deserialization
        TitleLabel.text = doc._title
        ArtistLabel.text = doc._artist
        artwork.image = doc._artwork?.image( at: CGSize(width: 200, height:200) )
        
        if( doc._isPlaceholder && !doc._isInDeserialize )
        {
            doc._isInDeserialize = true
            _gdocDeserializeQ.async(execute: {
                doc.deserialize(doc.diskFolderFilePath)
                DispatchQueue.main.async(execute: {
                    if( self.muzomaDoc == doc ) // doc cell has not been re-used or changed so we can update the cell
                    {
                        self.TitleLabel.text = doc._title
                        self.ArtistLabel.text = doc._artist
                        self.artwork.image = doc._artwork?.image( at: CGSize(width: 200, height:200) )
                        if( self.muzomaDoc?._setsOnly != nil && (self.muzomaDoc!._setsOnly! == true && !UserDefaults.standard.bool( forKey: "unhideSetOnly_preference" ) ))
                        {
                            vc._needsReload = true
                            vc.checkForReload()
                        }
                    }
                    else
                    {
                        vc._needsReload = true
                        vc.checkForReload()
                    }
                })
            })
        }
        
        self.muzomaDoc = doc
     }
}
