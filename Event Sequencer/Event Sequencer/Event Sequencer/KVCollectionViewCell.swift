//
//  ContentCollectionViewCell.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 01/12/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//
//  UI Cell representing a song in a store - Karaoke version store, - allows trigger of download

/* on the server use
 <table style="border:none; border-collapse: collapse; padding: 2px;" cellspacing="0" cellpadding="0">
 
 <tr>
 <td style="overflow: hidden; border: none; padding:2px 15px 2px 2px; width: 40%;  vertical-align:top; text-align:top;">
 <img id="coverArt" style="object-fit: scale-down; min-width: 10%; min-height: 10%; max-width: 100%; max-height: 100%; height: 100%; width: 100%;" src="http://muzoma.co.uk/wp-content/uploads/2016/10/Impossible-Dream-200x200.jpg" alt="Muzoma - The Impossible Dream" />
 </td>
 <td style="overflow: hidden; border: none; padding:10px 15px 2px 2px;  width: 60%; vertical-align:top; text-align:top;">
 <div style="overflow: hidden; max-width: 300px">
 <div>artist: <strong><span id="artist">Muzoma</span></strong></div>
 <div>title: <strong><span id="title">The Impossible Dream</span></strong></div>
 <div>author: <span id="Author">Matt Hopkins</span></div>
 <div>description: <span id="description" style="">Demo song for the Muzoma App and associated iBook demo</span></div>
 <div>copyright: <span id="copyright">2016 Muzoma Ltd</span></div>
 <div>published by: <span id="publisher">Muzoma Ltd</span></div>
 <div>category: <span id="category">Muzoma demo</span></div>
 <div>genre: <span id="genre">Pop</span></div>
 </div>
 </td>
 </tr>
 
 </table>
 */


import UIKit

class KVCollectionViewCell: UITableViewCell {
    
    var _kvDownload:KVDownload! = nil
    
    @IBOutlet weak var butCancel: UIButton!
    @IBOutlet weak var labArtist: UILabel!
    @IBOutlet weak var labTitle: UILabel!
    @IBOutlet weak var labProgress: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var progressSpinner: UIActivityIndicatorView!
    @IBOutlet weak var labTrackName: UILabel!
    @IBOutlet weak var labPctComplete: UILabel!
    @IBOutlet weak var labTrackNumBeingDownloaded: UILabel!
    
    
    @IBAction func cancelPressed(_ sender: AnyObject) {
        _kvDownload.cancel()
    }
    
    internal func SetDocument( _ kvDownload:KVDownload!, vc:MuzomaContentTableViewController, indexPath: IndexPath, table:UITableView!  ) {
        
        resetProgress()
        _kvDownload = kvDownload
        
        if(_kvDownload != nil )
        {
            labArtist.text = _kvDownload._artist
            labTitle.text = _kvDownload._songTitle
            imgView.image = _kvDownload._doc._artwork?.image(at: CGSize(width: 130, height: 80))
        }
    }

    func setProgress( _ progressPercent:Float )
    {
        progressBar.progress = progressPercent
        labPctComplete.text = "\(Int(progressPercent * 100)) %"
    }
    
    func setProgress( _ progress:String, progressPercent:Int )
    {
        progressSpinner.startAnimating()
        progressSpinner.isHidden = false
        butCancel.isEnabled = true
        labProgress.text = progress
        if( progressPercent > -1 )
        {
            progressBar.progress = Float(progressPercent)/100
            labPctComplete.text = "\(progressPercent) %"
        }
        labPctComplete.isHidden = false
        
        let trackCount = _kvDownload.KVTracks.count
        let currentTrack = _kvDownload._nextReqIdx
        if( currentTrack > -1 && currentTrack < _kvDownload.KVTracks.count )
        {
            labTrackName.text = _kvDownload.KVTracks[currentTrack]._trackName
            labTrackNumBeingDownloaded.text = "Track \(currentTrack + 1) of \(trackCount)"
        }
        else
        {
            labTrackName.text = ""
            labTrackNumBeingDownloaded.text = ""
        }
    }
    
    func setError( _ error:String )
    {
        labProgress.text = error
    }
    
    func resetProgress()
    {
        butCancel.isEnabled = false
        labProgress.text = ""
        progressBar.progress = 0.0
        progressSpinner.stopAnimating()
        progressSpinner.isHidden = true
        labPctComplete.isHidden = true
    }
    
    func completed()
    {
        butCancel.isEnabled = false
        progressSpinner.stopAnimating()
        progressBar.progress = 1.0
        labPctComplete.text = "100 %"
        labProgress.text = "Completed"
    }
}
