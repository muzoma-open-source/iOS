//
//  Original RollingPlayerViewController.swift
//  Event Sequencer
//
//  Created by Matthew Hopkins on 05/04/2015.
//  Copyright (c) 2015 Muzoma.com. All rights reserved.
//
//
//  This is the original code that used an adapted rolling picker control to display the lyrics
//


import UIKit
import WebKit
import Foundation
import CoreFoundation

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


class RollingPlayerDocumentViewController:  UIViewController, UIPickerViewDataSource, UIPickerViewDelegate
{
    var _prevScrollToItemAtTime:TimeInterval = 0
    var _currentPrepareIdx:Int = 0
    var _currentFireIdx:Int = 0
    var muzomaDoc: MuzomaDocument?
    var lastEventTimeType: EventTimeType = EventTimeType.None
    let nc = NotificationCenter.default
    var _lyricTrackIdx = 0
    var _chordTrackIdx = 0
    var _sectionTrackIdx = 0
    var _guideTrackIdx = 0
    var _isPlayingFromSet = false
    
    // external view
    // works var externalPlayerView:ExternalPlayerView! = nil
    var externalPlayerView:WKWebView! = nil //<-- doesnt display external images must use b64
    //var externalPlayerView:UIWebView! = nil
    //@IBOutlet weak var _externalView: UIView!
    var externalWindow: UIWindow!
    
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var _navPanel: UINavigationItem!
    @IBOutlet weak var _eventPicker: UIPickerView!
    
    var boxView:UIView! = nil
    let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffect.Style.light))
    var oldBGColor:UIColor! = nil
    
    fileprivate var _transport:Transport! = nil
    
    // main code
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        //_eventPicker.transform = CGAffineTransformMakeScale(0.5, 0.5)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //print( "viewDidAppear player doc" )
        _transport = Transport( viewController: self, includeVarispeedButton: false,  includeRecordTimingButton: false, isSetPlayer: _isPlayingFromSet )
        _transport.muzomaDoc = self.muzomaDoc
        
        registerForScreenNotifications()
        docChanged()
        setupAirPlay()
        
        //nc.addObserver(self, selector: #selector(PlayerDocumentViewController.playerTicked(_:)), name: "PlayerTick", object: nil)
        nc.addObserver(self, selector: #selector(PlayerDocumentViewController.sectionChanged(_:)), name: NSNotification.Name(rawValue: "SectionChanged"), object: nil)
        nc.addObserver(self, selector: #selector(PlayerDocumentViewController.prepareEventIndexChanged(_:)), name: NSNotification.Name(rawValue: "PrepareEventIndexChanged"), object: nil)
        nc.addObserver(self, selector: #selector(PlayerDocumentViewController.fireEventIndexChanged(_:)), name: NSNotification.Name(rawValue: "FireEventIndexChanged"), object: nil)
        
        nc.addObserver(self, selector: #selector(PlayerDocumentViewController.rewindButton(_:)), name: NSNotification.Name(rawValue: "PlayerRewind"), object: nil)
        nc.addObserver(self, selector: #selector(PlayerDocumentViewController.fastfwdButton(_:)), name: NSNotification.Name(rawValue: "PlayerFastForward"), object: nil)
        nc.addObserver(self, selector: #selector(PlayerDocumentViewController.setSelectNextSong(_:)), name: NSNotification.Name(rawValue: "SetSelectNextSong"), object: nil)
        nc.addObserver(self, selector: #selector(PlayerDocumentViewController.setSelectPreviousSong(_:)), name: NSNotification.Name(rawValue: "SetSelectPreviousSong"), object: nil)
        nc.addObserver(self, selector: #selector(PlayerDocumentViewController.setSelectedSong(_:)), name: NSNotification.Name(rawValue: "SetSelectedSong"), object: nil)
        
        return super.viewDidAppear(animated)
    }
    
    func docChanged()
    {
        self.editButton.isEnabled = true
        self.muzomaDoc = _transport.muzomaDoc // update our version of the doc
        
        if( muzomaDoc != nil && muzomaDoc!.isValid() && muzomaDoc!._activeEditTrack > -1 )
        {
            //print("playGuide is \(muzomaDoc!.getGuideTrackURL())")
            _navPanel.prompt = muzomaDoc!.getFolderName()
            _lyricTrackIdx = muzomaDoc!.getMainLyricTrackIndex()
            _chordTrackIdx = muzomaDoc!.getMainChordTrackIndex()
            
            if( self.muzomaDoc!._isSlaveForBandPlay )
            {
                self.editButton.isEnabled = false
            }
            
            _prevScrollToItemAtTime = 0
            _currentFireIdx = 0
            _currentPrepareIdx = 0
            
            deInitializeExternalScreen()
            setupAirPlay()
        }
        
        lastEventTimeType = EventTimeType.None
        _eventPicker?.reloadComponent(0)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "SectionChanged"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "PrepareEventIndexChanged"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "FireEventIndexChanged"), object: nil )
        
        //nc.removeObserver( self, name: NSNotification.Name(rawValue: "PlayerTick"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "PlayerRewind"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "PlayerFastForward"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "SetSelectNextSong"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "SetSelectPreviousSong"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "SetSelectedSong"), object: nil )
        
        // external screen
        nc.removeObserver( self, name: UIScreen.didConnectNotification, object: nil )
        nc.removeObserver( self, name: UIScreen.didDisconnectNotification, object: nil )
        nc.removeObserver( self, name: UIDevice.orientationDidChangeNotification, object: nil )
        
        _transport?.willDeinit()
        _transport = nil
        return( super.viewDidDisappear(animated) )
    }
    
    func registerForScreenNotifications(){
        nc.addObserver(self, selector: #selector(PlayerDocumentViewController.handleScreenDidConnectNotification(_:)), name: UIScreen.didConnectNotification, object: nil)
        nc.addObserver(self, selector: #selector(PlayerDocumentViewController.handleScreenDidDisconnectNotification(_:)), name: UIScreen.didDisconnectNotification, object: nil)
        nc.addObserver(self, selector: #selector(PlayerDocumentViewController.rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    @IBOutlet weak var airplayButton: UIBarButtonItem!
    var airPlayAttemptOn = UserDefaults.standard.bool(forKey: "airPlayOnByDefault_preference")
    @IBAction func airPlayClicked(_ sender: AnyObject) {
        airPlayAttemptOn = !airPlayAttemptOn
        
        if( airPlayAttemptOn )
        {
            setupAirPlay()
        }
        else
        {
            airplayButton.tintColor = nil
            deInitializeExternalScreen()
        }
    }
    
    func setupAirPlay()
    {
        if( airPlayAttemptOn )
        {
            DispatchQueue.main.async(execute: {
                self.airplayButton.tintColor = UIColor.red
            })
            
            if( UIScreen.screens.count > 1 ) {
                //find the second screen (the 'as! UIScreen' is not needed in Xcode 7 and above)
                DispatchQueue.main.async(execute: {
                    self.airplayButton.tintColor = UIColor.orange
                })
                
                let secondScreen = UIScreen.screens[1]
                let airPlayOK = initializeExternalScreen(secondScreen)
                if( airPlayOK )
                {
                    DispatchQueue.main.async(execute: {
                        self.airplayButton.tintColor = UIColor.green
                    })
                }
            }
        }
    }
    
    @objc func handleScreenDidConnectNotification(_ aNotification: Notification) {
        //print( "Screen connected!" )
        if( airPlayAttemptOn )
        {
            if let screen = aNotification.object as? UIScreen {
                let airPlayOK = self.initializeExternalScreen(screen)
                if( airPlayOK )
                {
                    DispatchQueue.main.async(execute: {
                        self.airplayButton.tintColor = UIColor.green
                    })
                }
            }
        }
    }
    
    @objc func handleScreenDidDisconnectNotification(_ aNotification: Notification) {
        //print( "Screen disconnected!" )
        deInitializeExternalScreen()
        
        if( airPlayAttemptOn )
        {
            DispatchQueue.main.async(execute: {
                self.airplayButton.tintColor = UIColor.red
            })
        }
        else
        {
            DispatchQueue.main.async(execute: {
                self.airplayButton.tintColor = nil
            })
        }
    }
    

    // Initialize an external screen
    func initializeExternalScreen(_ externalScreen: UIScreen) -> Bool {
        var ret = false
        //print( "Screens \(UIScreen.screens().count)" )
        if( UIScreen.screens.count > 1 ) {
            
            // Create a new window sized to the external screen's bounds
            self.externalWindow = UIWindow(frame: externalScreen.bounds)
            
            // Assign the screen object to the screen property of the new window
            self.externalWindow.screen = externalScreen;
            
            externalPlayerView = WKWebView(frame: externalScreen.bounds)
            //externalPlayerView = UIWebView(frame: externalScreen.bounds)
            externalPlayerView.loadHTMLString((self.muzomaDoc?.getHTML(false, ignoreZoom: true, ignoreColourScheme: false, isAirPlay: true))!, baseURL: self.muzomaDoc?.getDocumentFolderPathURL() )
            externalPlayerView.isUserInteractionEnabled = false
            //let result = externalPlayerView.stringByEvaluatingJavaScriptFromString("document.getElementById('head').innerText")
            self.externalWindow.addSubview(externalPlayerView)
            
            // Make the window visible
            self.externalWindow.makeKeyAndVisible()
            ret = true
        }
        
        return( ret )
    }
    
    func deInitializeExternalScreen()
    {
        if self.externalWindow != nil {
            self.externalPlayerView.removeFromSuperview()
            self.externalWindow.removeFromSuperview()
            
            self.externalWindow.isHidden = true
            self.externalWindow = nil
            self.externalPlayerView = nil
        }
    }
    
    @objc func rewindButton(_ sender: AnyObject) {
        //print("rewind")
        _prevScrollToItemAtTime = 0
        _currentFireIdx = 0
        _currentPrepareIdx = 0
    }
    
    @objc func fastfwdButton(_ sender: AnyObject) {
        //print("fast fwd")
        _prevScrollToItemAtTime = 0
        _currentFireIdx = 0
        _currentPrepareIdx = 0
    }
    
    @objc func setSelectNextSong(_ notification: Notification)
    {
        let newDoc = notification.object as! MuzomaDocument
        self.muzomaDoc = newDoc
        self._transport.muzomaDoc = newDoc
        docChanged()
    }
    
    @objc func setSelectPreviousSong(_ notification: Notification)
    {
        let newDoc = notification.object as! MuzomaDocument
        self.muzomaDoc = newDoc
        self._transport.muzomaDoc = newDoc
        docChanged()
    }
    
    func addSpinnerView() {
        oldBGColor = self.view.backgroundColor
        self.view.backgroundColor = UIColor.clear
        
        //always fill the view
        blurEffectView.frame = self.view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.view.addSubview(blurEffectView) //if you have more UIViews, use an insertSubview API to place it where needed
        // You only need to adjust this frame to move it anywhere you want
        self.boxView = UIView(frame: CGRect(x: view.frame.midX - 90, y: view.frame.midY - 25, width: 180, height: 50))
        self.boxView.isHidden = false
        self.boxView.backgroundColor = UIColor.white
        self.boxView.alpha = 0.8
        self.boxView.layer.cornerRadius = 10
        
        //Here the spinnier is initialized
        let activityView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
        activityView.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        activityView.startAnimating()
        
        let textLabel = UILabel(frame: CGRect(x: 60, y: 0, width: 200, height: 50))
        textLabel.textColor = UIColor.gray
        textLabel.text = "Working..."
        
        self.boxView.addSubview(activityView)
        self.boxView.addSubview(textLabel)
        
        view.addSubview(self.boxView)
    }
    
    func removeSpinnerView()
    {
        self.boxView.isHidden = true
        self.boxView.removeFromSuperview()
        self.view.backgroundColor =  oldBGColor
        blurEffectView.removeFromSuperview()
    }
    
    @IBAction func ShareActionPress(_ sender: UIBarButtonItem) {
        let textToShare:String = (self.muzomaDoc?.getFolderName())!
        
        addSpinnerView()
        
        let delay = DispatchTime.now() + Double(Int64(0.2 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delay,execute: {
            if let zip = _gFSH.getMuzZip( self.muzomaDoc )
            {
                let objectsToShare = [textToShare, zip] as [Any]
                let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                
                activityVC.popoverPresentationController?.barButtonItem = sender
                
                activityVC.excludedActivityTypes = []//UIActivityTypeCopyToPasteboard,UIActivityTypeAirDrop,UIActivityTypeAddToReadingList,UIActivityTypeAssignToContact,UIActivityTypePostToTencentWeibo,UIActivityTypePostToVimeo,UIActivityTypePrint,UIActivityTypeSaveToCameraRoll,UIActivityTypePostToWeibo]
                
                activityVC.completionWithItemsHandler = {
                    (activity, success, items, error) in
                    Logger.log("Activity: \(String(describing: activity)) Success: \(success) Items: \(String(describing: items)) Error: \(String(describing: error))")
                    do
                    {
                        try _gFSH.removeItem(at: zip)
                        Logger.log("\(#function)  \(#file) Deleted \(zip.absoluteString)")
                    }
                    catch let error as NSError {
                        Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                    }
                }
                
                self.present(activityVC, animated: true, completion: nil)
            }
            self.removeSpinnerView()
        })
    }

    @objc func rotated()
    {
        if(UIDevice.current.orientation.isLandscape)
        {
            //print("landscape")
        }
        
        if(UIDevice.current.orientation.isPortrait)
        {
            //print("Portrait")
        }
    }
    
    @objc func sectionChanged(_ notification: Notification) {
        //print( "Section Changed " )
        DispatchQueue.main.async(execute: {
            //self.sectionLabel.text = self.muzomaDoc!.currentSectionTitle
        })
    }
    
    @objc func prepareEventIndexChanged(_ notification: Notification) {
        //print( "Prepare Event" )
        
        mirrorToSecondDisplay( self.muzomaDoc!._currentPrepareIdx, colour: false )
        
        DispatchQueue.main.async(execute: {
            self._eventPicker.selectRow( self.muzomaDoc!._currentPrepareIdx, inComponent: 0, animated: true)
        })
    }
    
    @objc func fireEventIndexChanged(_ notification: Notification) {
        //print( "Fire Event" )
        
        mirrorToSecondDisplay( self.muzomaDoc!._currentFireIdx, colour: true )

        DispatchQueue.main.async(execute: {
            self._eventPicker.selectRow( self.muzomaDoc!._currentFireIdx, inComponent: 0, animated: true)
            self._eventPicker.view( forRow: self.muzomaDoc!._currentFireIdx, forComponent: 0)?.backgroundColor = UIColor.green
        })
    }
    
    func mirrorToSecondDisplay( _ eventIndex:Int, colour:Bool )
    {
        // 2nd display
        if( externalPlayerView != nil )
        {
            externalPlayerView.evaluateJavaScript( "gotoLine( \(String(eventIndex)), true)" ) { (result, error) in
                if error == nil {
                    //print(result)
                }
                else
                {
                   // print(error)
                }
            }
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        //pickerView.viewForRow(<#row: Int#>, forComponent: <#Int#>)
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return( 80.0 )
    }
    
    /*
     func pickerView(pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
     //print( "width \(self.view.frame.width)")
     return( self.view.frame.width )
     }
     */
    
    // picker view
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView
    {
        var lineEventView:UIView! = nil
        /*print( "main frame width \(self.view.frame.width), event view \(self._eventPicker.frame.width)" )*/
        
        let chordData = row < muzomaDoc!._tracks[_chordTrackIdx]._events.count ? muzomaDoc!._tracks[_chordTrackIdx]._events[row]._data : ""
        let lyricData = row < muzomaDoc!._tracks[_lyricTrackIdx]._events.count ? muzomaDoc!._tracks[_lyricTrackIdx]._events[row]._data : ""
        let sectionData = row < muzomaDoc!._tracks[_sectionTrackIdx]._events.count ? muzomaDoc!._tracks[_sectionTrackIdx]._events[row]._data : ""
        let guideTrackData = row < muzomaDoc!._tracks[_guideTrackIdx]._events.count ? muzomaDoc!._tracks[_guideTrackIdx]._events[row]._data : ""
        
        if(guideTrackData != "" )
        {
            let lab=UILabel( frame: CGRect(x: 0, y: 0, width: self.view.frame.width / 1.1, height: 70) )
            lab.text = guideTrackData
            lineEventView = lab
        } else if( sectionData != "" )
        {
            //lineEventView = LineEventView.loadFromNib()
            let lab=UILabel( frame: CGRect(x: 0, y: 0, width: self.view.frame.width / 1.1, height: 70) )
            lab.text = sectionData
            lineEventView = lab
        }
        else
        {
            let newLineEventView = LineEventView.loadFromNib()
            newLineEventView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width / 1.1, height: 70)
            newLineEventView.chordText!.text = chordData
            newLineEventView.lyricText!.text = lyricData
            lineEventView = newLineEventView
        }
        
        return lineEventView
    }
    
    func numberOfComponents( in pickerView: UIPickerView ) -> Int
    {
        return(1)
    }
    
    func pickerView( _ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        if( component == 0 )
        {
            if( muzomaDoc != nil )
            {
                return muzomaDoc!._tracks.count > 0 ? muzomaDoc!._tracks[_lyricTrackIdx]._events.count : 0
            }
            else
            {
                return 0
            }
        }
        else
        {
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return nil
        
        /*
         if( component == 0 )
         {
         return muzomaDoc!._tracks.count > 0 ? muzomaDoc!._tracks[_lyricTrackIdx]._events[row]._data : ""
         }
         else
         {
         return nil
         }*/
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        _currentPrepareIdx = 0
        _currentFireIdx = 0
        
        if( muzomaDoc!._tracks.count > 0 && muzomaDoc!._tracks[_lyricTrackIdx]._events.count > row )
        {
            // 2nd display
            self.mirrorToSecondDisplay( row, colour: false )
            
            let evtTime = muzomaDoc!._tracks[_lyricTrackIdx]._events[row]._prepareTime
            //secondDisplay( row )
            
            if( evtTime > 0 )
            {
                muzomaDoc!.setCurrentTime(evtTime!)
            }
        }
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        if( segue.destination.isKind(of: ChordPickerController.self) )
        {
            let editor = (segue.destination as! ChordPickerController)
            editor.muzomaDoc = muzomaDoc
        } else if( segue.destination.isKind(of: EditDocumentViewController.self) )
        {
            let editor = (segue.destination as! EditDocumentViewController)
            editor.muzomaDoc = muzomaDoc
        } else if( segue.destination.isKind(of: EditorLinesController.self) )
        {
            let editor = (segue.destination as! EditorLinesController)
            editor.muzomaDoc = muzomaDoc
        } else if( segue.destination.isKind(of: EditTmingViewController.self) )
        {
            let editor = (segue.destination as! EditTmingViewController)
            editor.muzomaDoc = muzomaDoc
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        var ret = true
        if( identifier == "EditSegue" )
        {
            let pro = MuzomaProducts.store.isProductPurchased( "MuzomaProducer" )
            //pro = true
            if(!pro)
            {
                ret = false
                
                let alert = UIAlertController(title: "Editor Feature", message: "Please upgrade to the Producer version to use this feature", preferredStyle: UIAlertController.Style.alert )
                
                //let row = _eventPicker.selectedRowInComponent(0)
                //let lyricEvt = muzomaDoc!._tracks[_lyricTrackIdx]._events[row]
                //let chordEvt = muzomaDoc!._tracks[_chordTrackIdx]._events[row]
                let iap = UIAlertAction(title: "In app purchases", style: .default, handler: { (action: UIAlertAction!) in
                    print("IAP")
                    let iapVC = self.storyboard?.instantiateViewController(withIdentifier: "IAPTableViewController") as? IAPTableViewController
                    self.navigationController?.pushViewController(iapVC!, animated: true)
                })
                
                
                alert.addAction(iap)
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                    print("Cancel")
                    //self.nc.postNotificationName("RefreshDocsView", object: nil)
                }))
                
                alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                self.present(alert, animated: true, completion:
                    {
                        //print( "iap alert shown" )
                } )
            }
            
            
        }
        return( ret )
    }

    
    override var keyCommands: [UIKeyCommand]? {
            return [ // these will steal the keys from other controls so take care!
                /* UIKeyCommand(input: UIKeyInputLeftArrow, modifierFlags: UIKeyModifierFlags.init(rawValue: 0), action:  #selector(scrollLeftPress), discoverabilityTitle: "Left"),
                 UIKeyCommand(input: UIKeyInputRightArrow, modifierFlags: UIKeyModifierFlags.init(rawValue: 0), action:  #selector(scrollRightPress), discoverabilityTitle: "Right"),*/
                UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: UIKeyModifierFlags.init(rawValue: 0), action:  #selector(scrollUpPress), discoverabilityTitle: "Up"),
                UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: UIKeyModifierFlags.init(rawValue: 0), action:  #selector(scrollDownPress), discoverabilityTitle: "Down"),
                UIKeyCommand(input: "\r", modifierFlags: UIKeyModifierFlags.init(rawValue: 0), action:  #selector(returnKeyPress), discoverabilityTitle: "Enter")
            ]
    }
    
    @objc func scrollUpPress() {
        print("up was pressed")
        
        DispatchQueue.main.async(execute: {
            if( !self.muzomaDoc!.isPlaying() )
            {
                var currentRow = self._eventPicker.selectedRow(inComponent: 0)
                currentRow = max( 0, currentRow-1)

                self._eventPicker.selectRow( currentRow, inComponent: 0, animated: false)
                // 2nd display
                self.mirrorToSecondDisplay( currentRow, colour: false )

                if( self._transport.inRecordTiming && self.muzomaDoc!.isPlaying() )
                {
                    (self.muzomaDoc!._tracks[self._lyricTrackIdx]._events[currentRow])._prepareTime = self.muzomaDoc!.getCurrentTime()
                }
                else
                {
                    self.pickerView(self._eventPicker, didSelectRow: currentRow, inComponent: 0)
                }
            }
        })
    }
    
    @objc func scrollDownPress() {
        print("down was pressed")
        DispatchQueue.main.async(execute: {
            if( !self.muzomaDoc!.isPlaying() )
            {
                var currentRow = self._eventPicker.selectedRow(inComponent: 0)
                currentRow = min( self._eventPicker.numberOfRows(inComponent: 0)-1, currentRow+1) // zero relative

                self._eventPicker.selectRow( currentRow, inComponent: 0, animated: false)
                // 2nd display
                self.mirrorToSecondDisplay( currentRow, colour: false )
                
                if( self._transport.inRecordTiming && self.muzomaDoc!.isPlaying() )
                {
                    (self.muzomaDoc!._tracks[self._lyricTrackIdx]._events[currentRow])._prepareTime = self.muzomaDoc!.getCurrentTime()
                }
                else
                {
                    self.pickerView(self._eventPicker, didSelectRow: currentRow, inComponent: 0)
                }
            }
        })
    }
    
    @objc func scrollLeftPress() {
        print("left was pressed")
    }
    
    @objc func scrollRightPress() {
        print("right was pressed")
    }
    
    @objc func returnKeyPress() {
        print("return key was pressed")
        DispatchQueue.main.async(execute: {
            
        })
    }
}

