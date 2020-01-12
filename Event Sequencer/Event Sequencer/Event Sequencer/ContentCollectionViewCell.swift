//
//  ContentCollectionViewCell.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 01/12/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//
//  UI Cell representing a song in a store - Muzoma demo store, - allows trigger of download

/* on the server use html format as follows:
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
import AEXML
import SwaggerWPSite

class ContentCollectionViewCell: UITableViewCell {
    
    var _doc:Attachment! = nil
    
    @IBOutlet weak var butDownload: UIButton!
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var labProgress: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    
    internal func SetDocument( _ doc:Attachment!, vc:MuzomaContentTableViewController, indexPath: IndexPath, table:UITableView!  ) {
        resetProgress()
        _doc = doc
        if(_doc != nil )
        {
            var mainDocStr:String! = ""
            
            if( _doc.description != nil )
            {
                let xml = "<xml>\n" + (_doc.description?.rendered!)! + "</xml>"
                
                let mainDoc = try? AEXMLDocument(xml: xml, encoding: String.Encoding.utf8, options: AEXMLOptions())
                
                if mainDoc != nil {
                    
                    if( (mainDoc?.children.count)! > 0 && (mainDoc?.children[0].children.count)! > 1 && mainDoc?.children[0].children[1].first?.attributes["id"] != nil &&
                        (mainDoc?.children[0].children[1].first?.attributes["id"] )! == "mainTable" )
                    {
                        mainDocStr = mainDoc!.children[0].children[1].xml
                        webView.loadHTMLString(mainDocStr, baseURL: nil)
                        //print( mainDocStr )
                    }
                    
                    if( _doc.sourceUrl == nil || _doc.sourceUrl == "" )
                    {
                        if( (mainDoc?.children.count)! >= 1 &&
                            (mainDoc?.children[0].children.count)! >= 1 &&
                            (mainDoc?.children[0].children[0].children.count)! >= 1 )
                        {
                            // eg "attachment"
                            let cl = mainDoc?.children[0].children[0].first!.attributes["class"]!
                            
                            if( cl == "attachment")
                            {
                                // eg  "http://muzoma.co.uk/wp-content/uploads/2016/12/Traditional-Scottish-Auld-Lang-Syne.muz"
                                let loc = mainDoc?.children[0].children[0].children[0].attributes["href"]!
                                _doc.sourceUrl = loc
                            }
                        }
                    }
                }
                else
                {
                    Logger.log("Error parsing xml in SetDocument")
                }
            }
        }
    }
    
    
    func DownloadButtonPress(_ vc: MuzomaContentTableViewController) {
        
        var caption:String! = "the selected file"
        
        let captionData =  _doc.caption?.rendered
        if( captionData != nil )
        {
            let captionDoc = try? AEXMLDocument(xml: captionData!, encoding: String.Encoding.utf8, options: AEXMLOptions())
            if captionDoc != nil {

                if( captionDoc?.children.first != nil )
                {
                    caption = captionDoc?.children.first?.value
                }
            }
        }
        
        let alert = UIAlertController(title: "Download Muzoma Content", message: "Do you wish to download \(caption!)?", preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
            //print("download file Yes")
            DispatchQueue.main.async(execute: {
                let dld = Downloader( yourOwnObject: self )
                let url = URL (string: self._doc.sourceUrl!)
                dld.download(url!)
            })
        }))
        
        alert.addAction(UIAlertAction(title: "No", style: .default, handler: { (action: UIAlertAction!) in
            //print("load file No")
        }))
        
        alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        vc.present(alert, animated: true, completion: {})
    }
    
    func setProgress( _ downloader:Downloader! )
    {
        butDownload.isEnabled = false
        let decProg = (Float(downloader._totalBytesWritten) / Float(downloader._totalBytesExpectedToWrite))
        let stringProgress = String(format: "%0.0f", (decProg * 100))
        labProgress.text = "\(stringProgress)%"
        progressBar.progress = Float(downloader._totalBytesWritten) / Float(downloader._totalBytesExpectedToWrite)
    }
    
    func resetProgress()
    {
        butDownload.isEnabled = true
        labProgress.text = ""
        progressBar.progress = 0.0
    }
}
