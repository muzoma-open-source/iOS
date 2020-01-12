//
//  MuzomaContentTableViewController.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 01/12/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//
//  Represents the store - allows downloading from various sites including Karaoke Version
//

import UIKit
import AEXML
import SwaggerWPSite

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}


class MuzomaContentTableViewController: UITableViewController, UIWebViewDelegate {
    fileprivate let reuseIdentifier = "ContentCollectionViewCell"
    fileprivate let reuseIdentifierMyCB = "MyCBCollectionViewCell"
    fileprivate let reuseIdentifierKV = "KVCollectionViewCell"
    
    
    fileprivate let nc = NotificationCenter.default
    fileprivate var _transport:Transport! = nil
    fileprivate var remoteDocs = [Attachment]()
    let reg = UserRegistration()
    
    /* Karaoke Version Stuff*/
    var _KVDownload:KVDownload! = nil
    //var _MYCBDownload:MYCBDownload! = nil
    
    
    @IBOutlet weak var segControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshControl?.addTarget(self, action: #selector(MuzomaContentTableViewController.refresh(_:)), for: UIControl.Event.valueChanged)

        refreshDocs()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //print( "viewDidAppear Docs View" )
        
        //_transport = Transport( viewController: self, hideAllControls: true )
        _transport = Transport( viewController: self, includeBandSelectButton: true )
        nc.addObserver(self, selector: #selector(MuzomaContentTableViewController.downloadingExternal(_:)), name: NSNotification.Name(rawValue: "DownloadingExternal"), object: nil)
        nc.addObserver(self, selector: #selector(MuzomaContentTableViewController.downloadedExternal(_:)), name: NSNotification.Name(rawValue: "DownloadedExternal"), object: nil)
        nc.addObserver(self, selector: #selector(MuzomaContentTableViewController.errorDownloadingExternal(_:)), name: NSNotification.Name(rawValue: "ErrorDownloadingExternal"), object: nil)
        
        nc.addObserver(self, selector: #selector(MuzomaContentTableViewController.downloadingExternalKV(_:)), name: NSNotification.Name(rawValue: "DownloadingExternalKV"), object: nil)
        nc.addObserver(self, selector: #selector(MuzomaContentTableViewController.downloadedExternalKV(_:)), name: NSNotification.Name(rawValue: "DownloadedExternalKV"), object: nil)
        nc.addObserver(self, selector: #selector(MuzomaContentTableViewController.errorDownloadingExternalKV(_:)), name: NSNotification.Name(rawValue: "ErrorDownloadingExternalKV"), object: nil)
        nc.addObserver(self, selector: #selector(MuzomaContentTableViewController.cancelDownloadExternalKV(_:)), name: NSNotification.Name(rawValue: "CancelDownload"), object: nil)
        nc.addObserver(self, selector: #selector(MuzomaContentTableViewController.docDontOverwriteExternalKV(_:)), name: NSNotification.Name(rawValue: "MuzomaDocDontOverwrite"), object: nil)
        nc.addObserver(self, selector: #selector(MuzomaContentTableViewController.docWritten(_:)), name: NSNotification.Name(rawValue: "MuzomaDocWritten"), object: nil)
        
        nc.addObserver(self, selector: #selector(MuzomaContentTableViewController.finalizeAudioStatus(_:)), name: NSNotification.Name(rawValue: "ConvertingAudio"), object: nil)
        nc.addObserver(self, selector: #selector(MuzomaContentTableViewController.finalizeAudioStatusPct(_:)), name: NSNotification.Name(rawValue: "ConvertingAudioPct"), object: nil)
        nc.addObserver(self, selector: #selector(MuzomaContentTableViewController.finalizeAudioStatus(_:)), name: NSNotification.Name(rawValue: "PaddingAudio"), object: nil)
        nc.addObserver(self, selector: #selector(MuzomaContentTableViewController.finalizeAudioStatusPct(_:)), name: NSNotification.Name(rawValue: "PaddingAudioPct"), object: nil)
        nc.addObserver(self, selector: #selector(MuzomaContentTableViewController.finalizeAudioStatus(_:)), name: NSNotification.Name(rawValue: "FinalizeAudioComplete"), object: nil)
        
        return super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        _transport?.willDeinit()
        _transport = nil
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "DownloadingExternal"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "DownloadedExternal"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "ErrorDownloadingExternal"), object: nil )
        
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "DownloadingExternalKV"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "DownloadedExternalKV"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "ErrorDownloadingExternalKV"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "CancelDownload"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "MuzomaDocDontOverwrite"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "MuzomaDocWritten"), object: nil )
        
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "ConvertingAudio"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "ConvertingAudioPct"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "PaddingAudio"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "PaddingAudioPct"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "FinalizeAudioComplete"), object: nil )
        
        if( _KVDownload != nil && _KVDownload.isDownloading() )
        {
            _KVDownload.cancel()
        }
        
        super.viewDidDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func refresh(_ sender:AnyObject)
    {
        refreshDocs()
        self.refreshControl?.endRefreshing()
    }
    
    @IBAction func segControlChanged(_ sender: AnyObject) {
        refreshDocs()
    }
    
    func refreshDocs()
    {
        globalWebView.isHidden = true
        self.remoteDocs = [Attachment]()
        self.tableView?.reloadData()
        
        self.tableView?.allowsSelection = false
        self.tableView?.allowsSelection = true
        
        globalWebView.loadHTMLString("Loading ...", baseURL: URL(string:"about:blank"))
        
        if( segControl.selectedSegmentIndex == 0 ) // demos
        {
            // replace with web view displaying KV site
            globalWebView.isHidden = true
            
            DefaultAPI.wpV2MediaGet( mimeType:"application/muz" ) { (data, error) in
                //print( "data \(data)")
                //print( "error \(error)")
                //print( "got media")
                
                if( error == nil )
                {
                    if( data != nil )
                    {
                        DispatchQueue.main.async(execute: {
                            self.remoteDocs = data!
                            self.tableView?.reloadData()
                        })
                        /*
                         for attach in (data)!
                         {
                         
                         print( "caption: \(attach.caption)" )
                         print( "published: \(attach.dateGmt?.datePretty)" )
                         print( "description: \(attach.description)" )
                         print( "" )
                         }*/
                    }
                }
                else
                {
                    Logger.log("Error getting external media \(error.debugDescription)")
                    
                    let alert = UIAlertController(title: "Download Muzoma Content", message: "Error communicating with the remote server.\nPlease retry later", preferredStyle: UIAlertController.Style.alert)
                    
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
                        //print("download file Yes")
                    }))
                    
                    alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                    self.present(alert, animated: true, completion: {})
                }
            }
        }
        else if( segControl.selectedSegmentIndex == 1 ) // karaoke version
        {
            if( _KVDownload == nil || !_KVDownload!.isDownloading() )
            {
                // replace with web view displaying KV site
                globalWebView.isHidden = false
                
                self.tableView?.reloadData() // clear download cells
                
                // start on the download page
                let htmlURL = URL(string: "https://www.karaoke-version.com/my/download.html?aff=701")
                globalWebView.loadRequest( URLRequest(url: htmlURL!) )
            }
            else // we are downloading already _KVDownload!.isDownloading()
            {
                
            }
            
            
        }
        else if( segControl.selectedSegmentIndex == 2 ) // my chord book
        {
            // replace with web view displaying site
            globalWebView.isHidden = false
            globalWebView.loadHTMLString("Coming Soon!", baseURL: URL(string:"about:blank"))
        }
        else if( segControl.selectedSegmentIndex == 3 ) // for me remote docs
        {
            globalWebView.isHidden = true
            
            let downloads = UserDownloads()
            downloads.refreshRemoteDocs()
            self.remoteDocs = downloads.remoteDocs
            self.tableView?.reloadData()
        }
    }
    
    @IBAction func addContentClicked(_ sender: AnyObject) {
        var inputTextFieldUser: UITextField?
        var inputTextFieldDownloadCode: UITextField?
        
        //Create the AlertController
        let actionSheetController: UIAlertController = UIAlertController(title: "Enter download code", message: "Please enter your user id and download code", preferredStyle: .alert)
        
        //Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            //Do some stuff
        }
        actionSheetController.addAction(cancelAction)
        
        //Create and an option action
        let nextAction: UIAlertAction = UIAlertAction(title: "OK", style: .default) { action -> Void in
            
            self.segControl.selectedSegmentIndex = 3
            
            var usrString = inputTextFieldUser?.text!
            
            // encode and log
            var codeString = ""
            for ch in inputTextFieldDownloadCode!.text!
            {
                var usrChar = usrString?.first
                
                if( usrChar == nil )
                {
                    usrChar = Character.init(" ")
                }
                
                let coderChar = ch.unicodeScalarCodePoint() - 32
                let userChar = usrChar!.unicodeScalarCodePoint() - 32
                let encoded = coderChar ^ userChar
                
                /*debug
                 let decoded = (encoded ^ userChar) + 32
                 print( "coder:\(coderChar) user:\(userChar) encoded:\(encoded) decoded:\(decoded)" )*/
                
                codeString += String(format: "%02x", encoded )
                if( usrString != nil )
                {
                    usrString!.removeFirst()
                }
            }
            
            // decode
            usrString = inputTextFieldUser?.text!
            
            // decode
            
            var decodedString = ""
            var ch1:Character! = nil
            for ch in inputTextFieldDownloadCode!.text!
            {
                if( ch1 != nil )
                {
                    let ch1code = ch1.unicodeScalarCodePoint()
                    let ch2code = ch.unicodeScalarCodePoint()
                    if(  ch1code >= 48 && ch2code >= 48 )
                    {
                        let sixteenTime = hexCharToDec(ch1code)
                        let num = hexCharToDec(ch2code)
                        if( (sixteenTime >= 0 && sixteenTime < 16) &&
                            (num >= 0 && num < 16) )
                        {
                            let code = ((sixteenTime * 16) + num)
                            var usrChar = usrString?.first
                            if( usrChar == nil )
                            {
                                usrChar = Character.init(" ")
                            }
                            let userChar = usrChar!.unicodeScalarCodePoint() - 32
                            
                            let decoded = (code ^ userChar) + 32
                            let ch2 = Character(UnicodeScalar(decoded)!)
                            decodedString += String(ch2)
                            
                            if( usrString != nil )
                            {
                                usrString!.removeFirst()
                            }
                        }
                        else
                        {
                            break;
                        }
                    }
                    else
                    {
                        break;
                    }
                    ch1 = nil
                }
                else
                {
                    ch1 = ch
                }
            }
            
            Logger.log("user: \(String(describing: inputTextFieldUser?.text)) code: (inputTextFieldDownloadCode?.text) coded: \(codeString) decoded:\(decodedString)")
            
            //print(decodedString)
            // only add valid strings
            if( !decodedString.isEmpty && decodedString.trimmingCharacters(in: CharacterSet.alphanumerics).isEmpty )
            {
                var objs = UserDefaults.standard.object(forKey: "userDownloadCodes") as! [String]?
                if( objs == nil )
                {
                    objs = [String]()
                }
                
                if( !(objs?.index(of: decodedString) > -1) )
                {
                    objs!.append(decodedString)
                    UserDefaults.standard.set(objs, forKey: "userDownloadCodes")
                    if( self.reg.communityName == nil || self.reg.communityName!.isEmpty)
                    {
                        self.reg.communityName = inputTextFieldUser?.text
                    }
                }
                else
                {
                    let alert = UIAlertController(title: "Download code already entered", message: "This code has already been used", preferredStyle: UIAlertController.Style.alert)
                    
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
                        //print("load file Yes")
                    }))
                    
                    alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                    self.present(alert, animated: true, completion: {})
                }
                
                self.refreshDocs()
            }
            else
            {
                let alert = UIAlertController(title: "Invalid download code", message: "User id or download code is not valid\nPlease try again, User Id is case sensitive/nNote there are only hex characters in the download code characters a-f and 0-9", preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
                    //print("load file Yes")
                }))
                
                alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                self.present(alert, animated: true, completion: {})
            }
        }
        actionSheetController.addAction(nextAction)
        
        //Add a text field
        actionSheetController.addTextField { textField -> Void in
            // you can use this text field
            inputTextFieldUser = textField
            inputTextFieldUser?.text = self.reg.communityName
            inputTextFieldUser?.placeholder = "user alias name"
        }
        
        actionSheetController.addTextField { textField -> Void in
            // you can use this text field
            inputTextFieldDownloadCode = textField
            inputTextFieldDownloadCode?.text = ""
            inputTextFieldDownloadCode?.placeholder = "download code"
        }
        
        //Present the AlertController
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    
    @IBAction func downloadClicked(_ sender: AnyObject) {
        let button = sender as! UIButton
        let view = button.superview!
        let cell = view.superview as! ContentCollectionViewCell
        cell.DownloadButtonPress(self)
    }
    
    
    @objc func downloadingExternal(_ notification: Notification) {
        
        if( notification.object is Downloader )
        {
            let downloader = notification.object as! Downloader
            
            // find the cell displayed and update the progress
            DispatchQueue.main.async(execute: {
                for cell in self.tableView.visibleCells
                {
                    if( cell is ContentCollectionViewCell )
                    {
                        let ccCell = cell as! ContentCollectionViewCell
                        if( ccCell._doc?.sourceUrl == downloader.url?.absoluteString )
                        {
                            ccCell.setProgress( downloader )
                            //Logger.log( "dld \(downloader.url) - \(downloader._bytesWritten) / \(downloader._totalBytesExpectedToWrite)")
                        }
                    }
                }
            })
        }
    }
    
    @objc func downloadedExternal(_ notification: Notification) {
        
        if( notification.object is Downloader )
        {
            let downloader = notification.object as! Downloader
            Logger.log( "dld \(String(describing: downloader.url)) - downloaded")
            
            // find the cell displayed and update the progress
            DispatchQueue.main.async(execute: {
                for cell in self.tableView.visibleCells
                {
                    if( cell is ContentCollectionViewCell )
                    {
                        let ccCell = cell as! ContentCollectionViewCell
                        if( ccCell._doc?.sourceUrl == downloader.url?.absoluteString )
                        {
                            ccCell.resetProgress()
                        }
                    }
                }
            })
        }
    }
    
    @objc func errorDownloadingExternal(_ notification: Notification) {
        if( notification.object is Downloader )
        {
            let downloader = notification.object as! Downloader
            Logger.log( "dld \(String(describing: downloader.url)) - error downloading")
            
            
            DispatchQueue.main.async(execute: {
                
                for cell in self.tableView.visibleCells
                {
                    if( cell is ContentCollectionViewCell )
                    {
                        let ccCell = cell as! ContentCollectionViewCell
                        if( ccCell._doc?.sourceUrl == downloader.url?.absoluteString )
                        {
                            ccCell.resetProgress()
                        }
                    }
                }
            })
        }
    }
    
    
    /* Karaoke Version Stuff*/
    
    // karaoke version web view
    @IBOutlet weak var globalWebView: UIWebView!
    var kvAlertShownOnce:Bool = false
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        //print( "should start \(request.debugDescription)" )
        var ret = true
        if( request.url?.pathExtension == "mp3" ) // single mp3 download
        {
            //let title = webView.stringByEvaluatingJavaScriptFromString("document.title")
            let addr =  webView.stringByEvaluatingJavaScript(from: "window.location.href")
            //let addrComponents = addr!.lowercaseString.trimRight( NSCharacterSet(charactersInString: "/") ).componentsSeparatedByString("/")
            let artistStr = webView.stringByEvaluatingJavaScript( from: "document.querySelector('meta[property=\"og:audio:artist\"]').content" )
            let titleStr =  webView.stringByEvaluatingJavaScript( from: "document.querySelector('meta[property=\"og:audio:title\"]').content" )
            // get tempo, key, etc
            // <span class="tempo"></span>Tempo: variable (around 79 BPM)
            // <span class="songkey"></span>In the same key as the original: G
            let tempoStrRaw =  webView.stringByEvaluatingJavaScript( from: "document.getElementsByClassName(\"tempo\")[0].parentElement.innerText" )
            let tempoStr = tempoStrRaw != nil ? tempoStrRaw?.replacingOccurrences( of: "Tempo: ", with: "" ) : ""
            let songKeyStrRaw =  webView.stringByEvaluatingJavaScript( from: "document.getElementsByClassName(\"songkey\")[0].parentElement.innerText" )
            let songKeyStr = songKeyStrRaw != nil ? songKeyStrRaw?.replacingOccurrences( of: "In the same key as the original: ", with: "" ) : ""
            
            if( addr != nil && artistStr != nil && !artistStr!.isEmpty && titleStr != nil && !titleStr!.isEmpty)
            {
                //print( "KV songId: \(songId!) prodId: \(prodId!) mixer Uri: \(downloadReqUri)")
                self._KVDownload = KVDownload( prodId: -1, songId: -1, downloadRequestURI: request.url!.absoluteString, artist: artistStr!, songTitle: titleStr!, songTempo: tempoStr!, songKey: songKeyStr! )
                
                _ = self.getKVImageFile(addr!)
                
                //let guideTrackChangeReqURL = NSURL(string: guideTrackChangeReq)
                self._KVDownload.addTrackDef( "Guide", trackMixerSourceURL: request.url! )
                
                self._KVDownload?.resetRequestIndex()
                _ = self._KVDownload?.getNextRequestURL()
                self.loadKVCell()
                self._KVDownload.setCurrentTrackAudioFileAddressURL( URL(string:request.url!.absoluteString)! )
                //self.gatherKVFiles()
            }
            ret = false
        }
        else if( request.url?.lastPathComponent == "validate.html" || request.url?.lastPathComponent == "handlebuybox.html"  )
        {
            let alert = UIAlertController(title: "Content is download only", message: "Content is download only in Muzoma.\nPurchases should be made externally through Safari.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
                
            }))
            alert.addAction(UIAlertAction(title: "Open Safari", style: .default, handler: { (action: UIAlertAction!) in
                UIApplication.shared.openURL( URL(string:"https://www.karaoke-version.com/?aff=701")! )
            }))
            
            alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            self.present(alert, animated: true, completion: {})
            
            ret = false
        } else if( request.url != nil && request.url!.host != nil && request.url!.host!.contains("google") )
        {
            ret = false
        }
        else if( request.url?.lastPathComponent == "login.html" )
        {
            if( !kvAlertShownOnce )
            {
                /*\n\nAlso, FYI we noticed that sometimes you could be prompted to log on to your KV downloads area twice, after the second time, the details should be stored in the app's browser.*/
                let alert = UIAlertController(title: "KV content is download only", message: "NOTE: KV content is restricted to KV demos and user area download only from Muzoma.\n\nPurchases must be made outside of the app, externally through Safari or other browsers.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK, Just downloads", style: .cancel, handler: { (action: UIAlertAction!) in
                    
                }))
                alert.addAction(UIAlertAction(title: "Leave Muzoma app for Safari", style: .default, handler: { (action: UIAlertAction!) in
                    UIApplication.shared.openURL( URL(string:"https://www.karaoke-version.com/?aff=701")! )
                }))
                
                alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                self.present(alert, animated: true, completion: {})
                kvAlertShownOnce = true
            }
            ret = true
        }
        
        return( ret )
    }
    
    
    func webViewDidFinishLoad(_ webView: UIWebView)
    {
        if( !webView.isLoading ) // loaded
        {
            //print( "webViewDidFinishLoad \(webView.request?.URLString) " )
            
            webView.stringByEvaluatingJavaScript(from: "document.getElementById('basketbox').hidden = true")
            webView.stringByEvaluatingJavaScript(from: "var eles = document.getElementsByClassName('addtocart'); for (var i = 0; i < eles.length; i++) { eles[i].parentElement.removeChild(eles[i]); i -= 1; }")
            webView.stringByEvaluatingJavaScript(from: "var eles = document.getElementsByClassName('song_price'); for (var i = 0; i < eles.length; i++) { eles[i].parentElement.removeChild(eles[i]); i -= 1; }")
            
            let title = webView.stringByEvaluatingJavaScript(from: "document.title")
            let addr =  webView.stringByEvaluatingJavaScript(from: "window.location.href")
            let addrComponents = addr!.lowercased().trimRight( CharacterSet(charactersIn: "/") ).components(separatedBy: "/")
            //let html = webView.stringByEvaluatingJavaScriptFromString("document.documentElement.innerHTML")
            //Logger.log("html: \(html)")
            //print( "title \(title)")
            
            if( addr != nil && title != nil )
            {
                if( addr!.lowercased().contains("/my/download.html")  ) // user's song list
                {
                    // we logged in and see the download page
                    // user now chooses the song to download
                    // we want to remove
                    // <a href="begin_download.html?id=412359&amp;famid=5" onclick="beginDownload(this);return false;">
                    //<img src="http://cdnaws.recis.io/i/img/00/62/37/45_0b9ba1.svg" width="auto" height="16"> Download                </a>
                    //
                    //var pageHTML = webView.stringByEvaluatingJavaScriptFromString("document.documentElement.innerHTML")
                    //Logger.log(pageHTML!)
                    // /*alert(anchors[i].href);*/
                    webView.stringByEvaluatingJavaScript(from: "var dldmsg='Download to Muzoma using the song link on the left in the title column';")
                    webView.stringByEvaluatingJavaScript( from: "var anchors = document.getElementsByTagName('a');for (var i = 0; i < anchors.length; i++) { if( anchors[i].href.includes('begin_download.html?') ) {  anchors[i].href = 'javascript:void(0);'; anchors[i].onclick=function(){alert(dldmsg); return(false);}; }; }" )
                    
                    //let pageHTML = webView.stringByEvaluatingJavaScriptFromString("document.documentElement.innerHTML")
                    //Logger.log(pageHTML!)
                    
                } else if( addr!.lowercased().contains("my/begin_download.html") && addr!.lowercased().contains("produced=1") )
                {
                    // we've got something to download
                }
                else if( addr!.lowercased().contains("basket.php?") ) // changed the custom track - now request download
                {
                    // web page will be blank at this point
                    //print( "basket request finished, requesting track create" )
                    
                    if( _KVDownload != nil ) // we are downloading
                    {
                        // can now request download
                        _ = pollKVFileDownload( Date() )
                    }
                }
                else if( addrComponents.count > 1 && addrComponents[addrComponents.count-1] == "custombackingtrack" ) // landed on the home page for customs
                {
                    print("custom bt home")
                }
                else if( addr!.lowercased().contains("/custombackingtrack/") || addr!.lowercased().contains("/custombackingtrack_free/")  ) // in a user's individual song - eg http://www.karaoke-version.com/custombackingtrack/ariana-grande/bang-bang.html
                {
                    // check for free songs mixer callback - is actual re-direct
                    let mixCBFn = webView.stringByEvaluatingJavaScript(from: "mixer.getMixCallback.toString()")
                    if( mixCBFn == nil || mixCBFn!.isEmpty || mixCBFn!.contains("document.location.href") )
                    {
                        
                        if(  mixCBFn == nil || mixCBFn!.isEmpty )
                        {
                            //print("empty mixer.getMixCallback")
                            // try again
                            let delay = DispatchTime.now() + Double(Int64(2.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                            DispatchQueue.main.asyncAfter(deadline: delay,execute: {
                                self.webViewDidFinishLoad(self.globalWebView)
                            })
                        }
                        else
                        {
                            //print("mixer.getMixCallback href")
                            webView.stringByEvaluatingJavaScript(from: "mixer.getMixCallback()") // create the mix
                            let delay = DispatchTime.now() + Double(Int64(2.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                            DispatchQueue.main.asyncAfter(deadline: delay,execute: {
                                // woz - goBack, but causes problems
                                // self.globalWebView.goBack()
                            })
                        }
                    }
                    else
                    {
                        webView.stringByEvaluatingJavaScript(from: "mixer.getMixCallback()") // this sets the uri for downloads - set up the data for the callback
                        
                        // ask if they want to download it
                        let alert = UIAlertController(title: "Download Karaoke Version Custom Track?", message: "Do you wish to download this song?", preferredStyle: UIAlertController.Style.alert)
                        var inputTextFieldPitchShift: UITextField?
                        
                        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                            
                            // get the required pitch shift
                            var shift = 0
                            if( inputTextFieldPitchShift != nil && inputTextFieldPitchShift!.text != nil )
                            {
                                let shiftInt = Int( inputTextFieldPitchShift!.text! )
                                if( shiftInt != nil )
                                {
                                    shift = shiftInt!
                                }
                            }
                            
                            // set up the mixer
                            let downloadReqUri = webView.stringByEvaluatingJavaScript(from: "mixer.uri") // /my/begin_download.html?id=4667537&famid=5
                            
                            // we should have a url in downloadReqUri
                            if( downloadReqUri != nil && !downloadReqUri!.isEmpty )
                            {
                                webView.stringByEvaluatingJavaScript(from: "mixer.setPrecount(\"1\");") // set up precount
                                webView.stringByEvaluatingJavaScript(from: "mixer.setPitch(\"" + String(shift) + "\");") // set pitch mixer.changePitch(52521, - 1)
                                let songIdStr = webView.stringByEvaluatingJavaScript(from: "mixer.parameters.s")// =49811
                                let prodIdStr = webView.stringByEvaluatingJavaScript(from: "mixer.parameters.prodid")// =4667537
                                
                                //print( html )
                                let artistStr = webView.stringByEvaluatingJavaScript( from: "document.querySelector('meta[property=\"og:audio:artist\"]').content" )
                                let titleStr =  webView.stringByEvaluatingJavaScript( from: "document.querySelector('meta[property=\"og:audio:title\"]').content" )
                                // get tempo, key, etc
                                // was <span class="tempo"></span>Tempo: variable (around 79 BPM)
                                // was <span class="songkey"></span>In the same key as the original: G

                                var tempoStrRaw =  webView.stringByEvaluatingJavaScript( from: "document.getElementsByClassName(\"tempo\")[0].parentElement.innerText" )
                                var tempoStr = tempoStrRaw != nil ? tempoStrRaw?.replacingOccurrences( of: "Tempo: ", with: "" ) : ""
                                var songKeyStrRaw =  webView.stringByEvaluatingJavaScript( from: "document.getElementsByClassName(\"songkey\")[0].parentElement.innerText" )
                                var songKeyStr = songKeyStrRaw != nil ? songKeyStrRaw?.replacingOccurrences( of: "In the same key as the original: ", with: "" ) : ""
                                
                                if( tempoStr == "" )
                                {
                                    // try
                                    // now <i class="song-details__icon song-details__icon-tempo"></i>
                                    tempoStrRaw =  webView.stringByEvaluatingJavaScript( from: "document.getElementsByClassName(\"song-details__icon song-details__icon-tempo\")[0].parentElement.innerText" )
                                    tempoStr = tempoStrRaw != nil ? tempoStrRaw?.replacingOccurrences( of: "Tempo: ", with: "" ) : ""
                                }
                                
                                if( songKeyStr == "" )
                                {
                                    // try
                                    // now <i class="song-details__icon song-details__icon-songkey"></i>
                                    songKeyStrRaw =  webView.stringByEvaluatingJavaScript( from: "document.getElementsByClassName(\"song-details__icon song-details__icon-songkey\")[0].parentElement.innerText" )
                                    songKeyStr = songKeyStrRaw != nil ? songKeyStrRaw?.replacingOccurrences( of: "In the same key as the original: ", with: "" ) : ""
                                }
                                
                                if( songIdStr != nil && prodIdStr != nil && !songIdStr!.isEmpty && !prodIdStr!.isEmpty && artistStr != nil && !artistStr!.isEmpty && titleStr != nil && !titleStr!.isEmpty )
                                {
                                    if( songIdStr!.trimmingCharacters(in: CharacterSet.decimalDigits).isEmpty && // digits
                                        prodIdStr!.trimmingCharacters(in: CharacterSet.decimalDigits).isEmpty
                                        )
                                    {
                                        let songId = Int(songIdStr!)
                                        let prodId = Int(prodIdStr!)
                                        if( songId != nil && prodId != nil && downloadReqUri != nil && !downloadReqUri!.isEmpty ) //all good
                                        {
                                            //print( "KV songId: \(songId!) prodId: \(prodId!) mixer Uri: \(downloadReqUri)")
                                            self._KVDownload = KVDownload( prodId: prodId!, songId: songId!, downloadRequestURI: downloadReqUri!, artist: artistStr!, songTitle: titleStr!, songTempo: tempoStr!, songKey: songKeyStr! )
                                            
                                            // get the image URL from the mp3 site
                                            _ = self.getKVImageFile(  addr! )
                                            
                                            // get the tracks of the song
                                            let jsonInfoURL = URL( string: "http://www.karaoke-version.com/i/song/i\(songId!)/0/multi.json" )
                                            let data = try? Data(contentsOf: jsonInfoURL!)
                                            let JSONObject = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers)
                                            let JSON = JSONObject as? Dictionary<String, AnyObject>
                                            
                                            // now have enough info to loop round downloading our tracks.
                                            if( JSON != nil )
                                            {
                                                let tracks = JSON!["tracks"] as? NSArray
                                                if( tracks != nil )
                                                {
                                                    // guide track with full vol - track zero
                                                    var guideMixStr = ""
                                                    var guidePanStr = ""
                                                    for trackCnt in (0 ..< tracks!.count)
                                                    {
                                                        let track = tracks![trackCnt] as AnyObject
                                                        let trackName = track["description"] as? NSString
                                                        if( trackCnt == 0 && (trackName != nil && trackName!.lowercased.contains("click")) )
                                                        {
                                                            guideMixStr += "\(trackCnt+1),0"
                                                        }
                                                        else
                                                        {
                                                            guideMixStr += "\(trackCnt+1),100"
                                                        }
                                                        guidePanStr += "\(trackCnt+1),0"
                                                        
                                                        if( trackCnt < tracks!.count - 1 )
                                                        {
                                                            guideMixStr += "."
                                                            guidePanStr += "."
                                                        }
                                                    }
                                                    
                                                    /* real
                                                     http://www.karaoke-version.com/basket.php?method=ajax&famid=5&precount=1&trackslevels=1%2C100.2%2C0.3%2C100.4%2C100.5%2C100.6%2C100.7%2C100.8%2C100.9%2C100.10%2C100.11%2C100.12%2C100.13%2C0&pannings=1%2C0.2%2C0.3%2C-100.4%2C0.5%2C0.6%2C0.7%2C0.8%2C0.9%2C0.10%2C0.11%2C0.12%2C0.13%2C0&bkac=editf&s=46509&prodid=4396159&pitch=0
                                                     muzoma's
                                                     http://www.karaoke-version.com/basket.php?method=ajax&famid=5&precount=1&trackslevels=1,100.2,100.3,100.4,100.5,100.6,100.7,100.8,100.9,100.10,100.11,100.12,100.13,100&pannings=1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,0.10,0.11,0.12,0.13,0&bkac=editf&s=46509&prodid=4396159&pitch=0
                                                     */
                                                    //webView.stringByEvaluatingJavaScriptFromString("mixer.setLevels( \"" + guideMixStr + "\")")
                                                    let guideTrackChangeReq = "http://www.karaoke-version.com/basket.php?method=ajax&famid=5&precount=1&trackslevels="
                                                        + guideMixStr + "&pannings=" + guidePanStr + "&bkac=editf&s=\(songId!)&prodid=\(prodId!)&pitch=" + String(shift)
                                                    
                                                    let guideTrackChangeReqURL = URL(string: guideTrackChangeReq)
                                                    self._KVDownload.addTrackDef( "Guide", trackMixerSourceURL: guideTrackChangeReqURL! )
                                                    
                                                    var trackIdx=0
                                                    for track in tracks!
                                                    {
                                                        let trackName = (track as AnyObject)["description"] as? NSString
                                                        if( trackName != nil )
                                                        {
                                                            // print( "Track: \(trackName!)")
                                                            // set the mixer to this track only
                                                            var mixStr = ""
                                                            var panStr = ""
                                                            for trackCnt in (0 ..< tracks!.count)
                                                            {
                                                                panStr += "\(trackCnt+1),0"
                                                                if( trackCnt == trackIdx )
                                                                {
                                                                    mixStr += "\(trackCnt+1),100"
                                                                }
                                                                else
                                                                {
                                                                    mixStr += "\(trackCnt+1),0"
                                                                }
                                                                
                                                                if( trackCnt < tracks!.count - 1 )
                                                                {
                                                                    mixStr += "."
                                                                    panStr += "."
                                                                }
                                                            }
                                                            
                                                            var trackChangeReq = ""
                                                            
                                                            if( trackIdx==0 && (trackName != nil && trackName!.lowercased.contains("click")) )
                                                            {
                                                                trackChangeReq = "http://www.karaoke-version.com/basket.php?method=ajax&famid=5&precount=1&trackslevels="
                                                                    + mixStr + "&pannings=" + panStr + "&bkac=editf&s=\(songId!)&prodid=\(prodId!)&pitch=" + String(shift)
                                                            }
                                                            else  // no pre click on the standard instruments - pad with empty sound later
                                                            {
                                                                trackChangeReq = "http://www.karaoke-version.com/basket.php?method=ajax&famid=5&precount=0&trackslevels="
                                                                    + mixStr + "&pannings=" + panStr + "&bkac=editf&s=\(songId!)&prodid=\(prodId!)&pitch=" + String(shift)
                                                            }
                                                            let trackChangeReqURL = URL(string: trackChangeReq)
                                                            self._KVDownload.addTrackDef( trackName! as String, trackMixerSourceURL: trackChangeReqURL! )
                                                        }
                                                        trackIdx += 1
                                                    }
                                                    
                                                    
                                                    // kick off the download process
                                                    let delay = DispatchTime.now() + Double(Int64(2.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                                                    DispatchQueue.main.asyncAfter(deadline: delay,execute: {
                                                        self._KVDownload?.resetRequestIndex()
                                                        self.loadKVCell()
                                                        _ = self.gatherKVFiles()
                                                    })
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }))
                        
                        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (action: UIAlertAction!) in
                            self.refreshDocs()
                        }))
                        
                        
                        alert.addTextField { textField -> Void in
                            // you can use this text field
                            inputTextFieldPitchShift = textField
                            inputTextFieldPitchShift?.text = nil
                            inputTextFieldPitchShift?.placeholder = "optional - enter a pitch shift in semitones"
                        }
                        
                        self.present(alert, animated: true, completion: nil)
                    }
                }
                else
                {
                    //print( "ignored \(addr)" )
                }
            }
        }
    }
    
    func loadKVCell()
    {
        self.globalWebView.stringByEvaluatingJavaScript(from: "document.documentElement.innerHTML=''")
        self.globalWebView.isHidden = true
        
        let top:CGPoint = CGPoint(x: 0, y: 0) // can also use CGPointZero here
        self.globalWebView.scrollView.setContentOffset(top, animated: true) // scroll to top
        
        self.tableView?.reloadData() // show progress cell
        // scroll to the download cell
        let delay = DispatchTime.now() + Double(Int64(1.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delay,execute: {
            self.tableView.scrollRectToVisible( CGRect(x: 0, y: 0, width: 1, height: 1), animated: true) // scroll to top
        })
    }
    
    @objc func downloadingExternalKV(_ notification: Notification) {
        if( notification.object is KVDownloadURL )
        {
            let downloader = notification.object as! KVDownloadURL
            
            //update the progress
            DispatchQueue.main.async(execute: {
                let dProg = (Float(downloader._totalBytesWritten) / Float(downloader._totalBytesExpectedToWrite))
                let pctProg = Int(dProg * 100)
                self.KVProgressUpdate( "\(downloader._destFileName!)", pctDone:pctProg )
            })
        }
    }
    
    @objc func downloadedExternalKV(_ notification: Notification) {
        if( notification.object is KVDownloadURL )
        {
            let downloader = notification.object as! KVDownloadURL
            Logger.log( "dld \(String(describing: downloader.url)) - downloaded")
            
            // update the progress, set next download
            DispatchQueue.main.async(execute: {
                self.KVProgressUpdate( "Got \(String(describing: downloader._destFileName))", pctDone:100 )
                _ = self.gatherKVFiles()
            })
        }
    }
    
    @objc func errorDownloadingExternalKV(_ notification: Notification) {
        if( notification.object is KVDownloadURL )
        {
            let downloader = notification.object as! KVDownloadURL
            Logger.log( "dld \(String(describing: downloader.url)) - error downloading")
            
            // update the progress
            DispatchQueue.main.async(execute: {
                self.KVErrorDownloading( "Comms err:100 downloading, please retry")
            })
        }
    }
    
    @objc func cancelDownloadExternalKV(_ notification: Notification) {
        Logger.log( "downloader cancelled")
        _lastCancelTime = Date()
        // update the progress
        DispatchQueue.main.async(execute: {
            self.KVErrorDownloading( "Download cancelled")
            self._KVDownload?.resetRequestIndex()
            // reset to show KV files
            let delay = DispatchTime.now() + Double(Int64(2.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delay,execute: {
                self.refreshDocs()
            })
        })
    }
    
    @objc func docDontOverwriteExternalKV(_ notification: Notification) {
        self._KVDownload?.cancel()
    }
    
    @objc func docWritten(_ notification: Notification) {
        // update the progress
        DispatchQueue.main.async(execute: {
            // notify docs vc
            if( self.navigationController != nil )
            {
                let viewControllers: [UIViewController] = self.navigationController!.viewControllers as [UIViewController]
                
                for vcCnt in (0..<viewControllers.count)
                {
                    // mark the top view as dirty
                    if( viewControllers[vcCnt] is DocumentsCollectionViewController )
                    {
                        //globalDocumentMapper takes care of the new doc
                        let targetVC = viewControllers[vcCnt] as! DocumentsCollectionViewController
                        targetVC.refreshDocs()
                        // can't do this every time e.g. KV loading
                        //self.navigationController?.popToRootViewController(animated: true)
                        
                        break;
                    }
                }
            }
        })
    }
    
    @objc func finalizeAudioStatus(_ notification: Notification) {
        // update the progress
        if( notification.object is String )
        {
            let status = notification.object as! String
            DispatchQueue.main.async(execute: {
                self.KVProgressUpdate( status )
            })
        }
    }
    
    @objc func finalizeAudioStatusPct(_ notification: Notification) {
        // update the progress
        if( notification.object is Float )
        {
            let pct = notification.object as! Float
            DispatchQueue.main.async(execute: {
                self.KVProgressUpdate( pct )
            })
        }
    }
    
    func getKVImageFile( _ custTrackAddr:String ) -> Bool
    {
        var done = false
        
        if( self._KVDownload != nil )
        {
            /* pick the image file from the KV mp3 page e.g
             http://www.karaoke-version.com/custombackingtrack/bruno-mars/uptown-funk.html
             http://www.karaoke-version.com/mp3-backingtrack/bruno-mars/uptown-funk.html
             <img class="song_img" itemprop="image" width="130" height="80" alt="Uptown Funk - Instrumental MP3 Karaoke - Bruno Mars" title="Uptown Funk - Instrumental MP3 Karaoke - Bruno Mars" src="http://s3.karaoke-version.com/i/img/00/52/d4/2d_acb830_lg130.jpg">
             
             <img class=\"song_img\" itemprop=\"image\" width=130 height=80 alt=\"California Gurls - Instrumental MP3 Karaoke - Katy Perry\" title=\"California Gurls - Instrumental MP3 Karaoke - Katy Perry\" src=\"http://s3.karaoke-version.com/i/img/00/52/d1/5c_55c4f1_lg130.jpg\" class=\"borderback\">\n
             */
            
            do
            {
                // get the image's html
                // free ones -  http://www.karaoke-version.com/free/traditional/house-of-the-rising-sun.html
                //              http://www.karaoke-version.com/custombackingtrack_free/traditional/house-of-the-rising-sun.html
                var imgURL:URL! = nil
                
                if(  custTrackAddr.contains("custombackingtrack_free") )
                {
                    imgURL = URL( string: custTrackAddr.replacingOccurrences(of: "custombackingtrack_free", with: "free")  )
                }
                else if( custTrackAddr.contains("custombackingtrack") )
                {
                    imgURL = URL( string: custTrackAddr.replacingOccurrences(of: "custombackingtrack", with: "mp3-backingtrack") )
                }
                else
                {
                    imgURL = URL( string: custTrackAddr )
                }
                
                let imgHtml = try NSString.init( contentsOf: imgURL!, encoding: String.Encoding.utf8.rawValue ) // start the request to get the image html
                var imgStartTagRange = imgHtml.range(of: "itemprop=\"image\"", options: NSString.CompareOptions.caseInsensitive)
                if( imgStartTagRange.length == 0 )
                {
                    imgStartTagRange = imgHtml.range(of: "class=\"song_img\"", options: NSString.CompareOptions.caseInsensitive)
                }
                
                let songImgHTML = NSString.init(string: imgHtml.substring(from: imgStartTagRange.location) )

                if( imgStartTagRange.location != NSNotFound )
                {
                    
                    let imgStr = songImgHTML as String// imgHtml.substring(with: lineRange)
                    
                    if( imgStr.lowercased().contains("src=") )
                    {
                        let fileStartIdx = (imgStr as NSString?)?.range(of: "src=").upperBound.advanced(by: 1)
                        //let fileStartIdx = NSString.CharacterView.index(imgStr.range(of: "src=")?.upperBound, offsetBy: 1)
                        if( fileStartIdx != nil )
                        {
                            let fileStrToEnd = (imgStr as NSString?)?.substring(from: fileStartIdx!) as NSString?
                            let fileStrLastQuote = fileStrToEnd?.range(of: "\"")
                            let fileSource = ((imgStr as NSString?)?.substring(from: fileStartIdx!)  as NSString?)?.substring(to: fileStrLastQuote!.lowerBound ) as NSString?

                            if( fileSource?.substring(to: 2) == "ht" ) // starts with ht maybe from the CDN
                            {
                                let actImgUrl = URL(string: String(fileSource!) )
                                if( actImgUrl != nil )
                                {
                                    Logger.log("KV image file \(actImgUrl!.absoluteString), scheme: \(String(describing: imgURL?.scheme)), host: \(String(describing: imgURL?.host)), path: \(String(describing: fileSource))")
                                    _KVDownload.setSongArtURL(actImgUrl!.absoluteString)
                                    done = true
                                } else {
                                    self.KVErrorDownloading( "KV format changed image file not found")
                                }
                            }
                            else // not from CDN must be local relative url
                            {
                                var components = URLComponents(url: imgURL, resolvingAgainstBaseURL: true)
                                components?.host = imgURL?.host
                                components?.scheme = (imgURL?.scheme)!
                                components?.path = fileSource! as String;
                                let actImgUrl = components?.url
                                if( actImgUrl != nil )
                                {
                                    Logger.log("KV image file \(actImgUrl!.absoluteString), scheme: \(String(describing: imgURL?.scheme)), host: \(String(describing: imgURL?.host)), path: \(String(describing: fileSource))")
                                    _KVDownload.setSongArtURL(actImgUrl!.absoluteString)
                                    done = true
                                } else {
                                    self.KVErrorDownloading( "KV format changed image file not found")
                                }
                            }
                        }
                    }
                }
                else
                {
                    self.KVErrorDownloading( "Comms err:300 downloading image file")
                }
            }
            catch
            {
                self.KVErrorDownloading( "Comms err:300 downloading image file")
            }
        }
        
        return( done )
    }
    
    func gatherKVFiles() -> Bool
    {
        var done = false
        
        if( self._KVDownload != nil )
        {
            let reqURL = self._KVDownload.getNextRequestURL()
            
            if( reqURL != nil )
            {
                do
                {
                    _ = try String.init(contentsOf: reqURL!) // start the request to track change, synchronous
                    
                    // can now request download
                    _ = pollKVFileDownload( Date() )
                }
                catch
                {
                    self.KVErrorDownloading( "Comms err:200 downloading, please retry")
                }
            }
            else
            {
                // all good
                done = true
                KVProgressUpdate("Completed download", pctDone: 100)
                
                // post process
                DispatchQueue.global(qos: .background).async {
                    sleep(2)
                    DispatchQueue.main.async {
                        self.KVProgressUpdate("Finalizing audio please wait...")
                    }
                    
                    self._KVDownload.finalizeAudioTracks()
                    
                    DispatchQueue.main.async {
                        for cell in self.tableView.visibleCells
                        {
                            if( cell is KVCollectionViewCell )
                            {
                                let kvCell = cell as! KVCollectionViewCell
                                kvCell.completed()
                                break;
                            }
                        }
                    }
                }
            }
        }
        
        return( done )
    }
    
    
    var _lastCancelTime:Date! = nil
    func pollKVFileDownload( _ pollTime:Date! = nil) -> Bool
    {
        var done = false
        
        if( self._KVDownload != nil && (_lastCancelTime == nil || pollTime == nil) || ( _lastCancelTime != nil && pollTime != nil && pollTime.compare(_lastCancelTime) == ComparisonResult.orderedDescending ))
        {
            let downloaderURL = URL(string: "http://www.karaoke-version.com" + _KVDownload._downloadRequestURI)
            
            do
            {
                //let downloadPageHtmlString = try String.init(contentsOf: downloaderURL!) // find the direct download link here
                let downloadPageHtmlNSString = try NSString.init( contentsOf: downloaderURL!, encoding: String.Encoding.utf8.rawValue )
                
                // check if server is still creating the track
                // might have is being generated in this response
                /* <META HTTP-EQUIV="Refresh" CONTENT="10;URL=/my/waitfor_build_multi.php?id=4396151&famid=5">
                 <div id="processing_content">
                 Your custom accompaniment track is being generated<br>*/
                if( downloadPageHtmlNSString.contains("META HTTP-EQUIV=\"Refresh\""))
                {
                    KVProgressUpdate("KV server is creating the track", pctDone: 0)
                    
                    let delay = DispatchTime.now() + Double(Int64(10.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                    let pollTime = Date()
                    DispatchQueue.main.asyncAfter(deadline: delay,execute: {
                        _ = self.pollKVFileDownload(pollTime)
                    })
                } else if( downloadPageHtmlNSString.lowercased.contains("http-equiv=\"refresh\""))
                    //wait format changed - oh great
                {
                    /*
                     <title>Generating MP3</title>
                     <meta http-equiv=\"refresh\" content=\"10;URL =/my/waitfor_build_multi.php?id =6392371&famid =5\">
                     <meta name=\"robots\" content=\"index,follow\">
                     <link rel=\"canonical\" href=\"https://www.karaoke-version.com/my/begin_download.html\">
                     <meta name=\"viewport\" content=\"width =device-width,initial-scale =1\">*/
                    KVProgressUpdate("KV server is creating the track", pctDone: 0)
                    
                    let delay = DispatchTime.now() + Double(Int64(10.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                    let pollTime = Date()
                    DispatchQueue.main.asyncAfter(deadline: delay,execute: {
                        _ = self.pollKVFileDownload(pollTime)
                    })
                }
                else // good to download
                {
                    KVProgressUpdate("KV server download ready", pctDone: 0)
                    Logger.log("KV server download ready")
                    
                    // 19/08/2018 KV changed layout again
                    /* <br>You can also click on the link below to manually begin your download:</p>\n        <a href=\"https://c14.recis.io/sl/e4ab498f1e/2e86cff859cf5299479420fba24ddec4/East_17_Stay_Another_Day(Custom_Backing_Track).mp3\" class=\"begin-download__manual-download\">\n            <img src=\"/i/gen/download_b.gif\" border=\"0\" height=\"21\" width=\"21\">\n            <span>\n                Download the file manually\n            </span>\n        </a>\n
                     
                     
                     <p>If the download doesn\'t start within 10 seconds, it may be blocked by your browser. <b><i>Look at the top of the window if your browser is not asking for permission to download the file.</i></b>\r\n<br>You can also click on the link below to manually begin your download:</p>\n        <a href=\"https://c14.recis.io/sl/e4ab498f1e/2e86cff859cf5299479420fba24ddec4/East_17_Stay_Another_Day(Custom_Backing_Track).mp3\" class=\"begin-download__manual-download\">\n            <img src=\"/i/gen/download_b.gif\" border=\"0\" height=\"21\" width=\"21\">\n            <span>\n                Download the file manually\n            </span>\n        </a>\n
                     */
                    
                    let downloadPageHtmlString = downloadPageHtmlNSString as String
                    let downloadManualEnd = downloadPageHtmlString.range(of: "Download the file manually" /* was "manually</a>"*/, options: NSString.CompareOptions.caseInsensitive)
                    
                    if( downloadManualEnd != nil && !downloadManualEnd!.isEmpty )
                    {
                        var downloadURLStr = ""
                        
                        // TODO: validate download is still working
                        
                        // truncate the string at the download text
                        //var searchStr = downloadPageHtmlString.substring( to: (downloadManualEnd?.lowerBound)! )
                        var searchStr = downloadPageHtmlString[..<downloadManualEnd!.lowerBound] //.substring( to: (downloadManualEnd?.lowerBound)! )
                        
                        // now find the last <a anchor
                        let indexOfLastAnchor = searchStr.range(of: "<a", options: .backwards)?.lowerBound
                        
                        //searchStr = searchStr.substring( from: (indexOfLastAnchor)! )
                        searchStr = searchStr[indexOfLastAnchor!...]
                        /* now we should have
                         <a href=\"https://c14.recis.io/sl/e4ab498f1e/2e86cff859cf5299479420fba24ddec4/East_17_Stay_Another_Day(Custom_Backing_Track).mp3\" class=\"begin-download__manual-download\">\n            <img src=\"/i/gen/download_b.gif\" border=\"0\" height=\"21\" width=\"21\">\n            <span>\n                Download the file manually
                         */
                        
                        // truncate from end of href
                        let indexOfHref = searchStr.range(of: "href=\"", options: .caseInsensitive)?.upperBound
                        if( indexOfHref != nil )
                        {
                            //searchStr = searchStr.substring( from: (indexOfHref)! )
                            searchStr = searchStr[indexOfHref!...]
                            
                            // truncate after url string
                            let indexOfLastQuote = searchStr.range(of: "\"", options: .caseInsensitive)?.lowerBound
                            if( indexOfLastQuote != nil )
                            {
                                //searchStr = searchStr.substring( to: (indexOfLastQuote)! )
                                searchStr = searchStr[..<indexOfLastQuote!]
                                downloadURLStr = String(searchStr)
                                Logger.log("KV download matched url \(downloadURLStr)")
                                let downloadURL = URL(string:downloadURLStr)
                                if( downloadURL != nil )
                                {
                                    self._KVDownload.setCurrentTrackAudioFileAddressURL( downloadURL! )
                                    done = true
                                }
                            }
                        }
                    }
                    
                    if( !done )
                    {
                        Logger.log("Error downloading KV file, unexpected page layout")
                        KVErrorDownloading("Error unexpected page layout\nPlease retry")
                    }
                }
            }
            catch let error as NSError
            {
                Logger.log("KV download problem \(error)")
                KVErrorDownloading("Problem downloading KV file: \(error)\nPlease retry")
            }
        }
        
        return( done )
    }
    
    func KVErrorDownloading( _ errorMsg:String )
    {
        for cell in self.tableView.visibleCells
        {
            if( cell is KVCollectionViewCell )
            {
                let kvCell = cell as! KVCollectionViewCell
                kvCell.setError(errorMsg)
            }
        }
        //print( "User error msg: \(errorMsg)")
    }
    
    func KVProgressUpdate(_ pctDone:Float)
    {
        for cell in self.tableView.visibleCells
        {
            if( cell is KVCollectionViewCell )
            {
                let kvCell = cell as! KVCollectionViewCell
                if( pctDone > -1 )
                {
                    kvCell.setProgress(pctDone)
                }
            }
        }
        //print( "User progress msg: \(msg)\npct done: \(pctDone)")
    }
    
    func KVProgressUpdate( _ msg:String, pctDone:Int = -1 )
    {
        for cell in self.tableView.visibleCells
        {
            if( cell is KVCollectionViewCell )
            {
                let kvCell = cell as! KVCollectionViewCell
                kvCell.setProgress(msg, progressPercent: pctDone)
            }
        }
        //print( "User progress msg: \(msg)\npct done: \(pctDone)")
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // return the number of rows
        var ret = 0
        if( self.segControl.selectedSegmentIndex == 0 ||
            self.segControl.selectedSegmentIndex == 3 )
        {
            ret = remoteDocs.count
        }
        else if( self.segControl.selectedSegmentIndex == 1 ) // KV might have a cell to show
        {
            if( self.globalWebView.isHidden ) // KV web is hidden, show our cell with download progress
            {
                ret = 1
            }
        }
        
        return ret
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var ret:UITableViewCell! = nil
        
        if( self.segControl.selectedSegmentIndex == 0 ||
            self.segControl.selectedSegmentIndex == 3 )
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! ContentCollectionViewCell
            let row=indexPath.row
            if( self.remoteDocs.count > row )
            {
                let doc = self.remoteDocs[row]
                cell.SetDocument(doc, vc: self, indexPath: indexPath, table: tableView)
            }
            ret = cell
        }
        else if( self.segControl.selectedSegmentIndex == 1 )
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifierKV, for: indexPath) as! KVCollectionViewCell
            cell.SetDocument(_KVDownload, vc: self, indexPath: indexPath, table: tableView)
            ret = cell
        }
        else if( self.segControl.selectedSegmentIndex == 2 )
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! ContentCollectionViewCell
            ret = cell
        }
        return ret
    }
    
    // test button
    @IBAction func butConvertPress(_ sender: AnyObject) {
        self.globalWebView.isHidden = true
        self._KVDownload = KVDownload( prodId: 1, songId: 1, downloadRequestURI: "http://www.google.com", artist: "Artist", songTitle: "Title", songTempo: "120bmp", songKey: "C" )
        self.tableView?.reloadData()
        self._KVDownload._doc = self._transport.muzomaDoc
        
        // post process
        DispatchQueue.global(qos: .background).async {
            sleep(2)
            DispatchQueue.main.async {
                self.KVProgressUpdate("Finalizing audio please wait...")
            }
            
            self._KVDownload.finalizeAudioTracks()
            
            DispatchQueue.main.async {
                for cell in self.tableView.visibleCells
                {
                    if( cell is KVCollectionViewCell )
                    {
                        let kvCell = cell as! KVCollectionViewCell
                        kvCell.completed()
                        break;
                    }
                }
            }
        }
    }
}
