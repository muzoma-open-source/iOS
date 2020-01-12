//
//  EditTmingViewController.swift
//  Event Sequencer
//
//  Created by Matthew Hopkins on 05/04/2015.
//  Copyright (c) 2015 Muzoma.com. All rights reserved.
//
//
//
//  UI that allows the user to set up the timing and display of a song as it plays
//

import UIKit
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

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}



class EditTmingViewController:  UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UIGestureRecognizerDelegate
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
    
    //@IBOutlet weak var overlayScrollView: UIScrollView!
    @IBOutlet weak var sectionLabel: UILabel!
    @IBOutlet weak var _navPanel: UINavigationItem!
    @IBOutlet weak var _eventPicker: UIPickerView!
    @IBOutlet weak var topToolbar: UIToolbar!
    
    var singleTapGestureEndEdit: UITapGestureRecognizer!
    var singleTapGesture: UITapGestureRecognizer!
    var doubleTapGesture: UITapGestureRecognizer!
    var longPressGesture: UILongPressGestureRecognizer!
    
    fileprivate var _transport:Transport! = nil
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // main code
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //_eventPicker.transform = CGAffineTransformMakeScale(0.5, 0.5)
        
        //print( "container view width \(self.view.frame.width), height \(self.view.frame.height)" )
        containerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height)
        containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.isHidden = true
        containerView.isUserInteractionEnabled = true
        containerView.isMultipleTouchEnabled = true
        self.view.addSubview(containerView)
        
        entryContainerView.backgroundColor = UIColor.green
        entryContainerView.isUserInteractionEnabled = true
        entryContainerView.isHidden = true
        containerView.addSubview(entryContainerView)
        
        
        singleTapGestureEndEdit = UITapGestureRecognizer(target: self, action: #selector(singleTapGestureHandlerEndEdit))
        singleTapGestureEndEdit.numberOfTapsRequired = 1
        singleTapGestureEndEdit.delegate = self
        
        singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(singleTapGestureHandler))
        singleTapGesture.numberOfTapsRequired = 1
        singleTapGesture.delegate = self
        
        doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTapGestureHandler))
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.delegate = self
        
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureHandler))
        longPressGesture.delegate = self
        
        _eventPicker.isUserInteractionEnabled = true
        _eventPicker.addGestureRecognizer(singleTapGesture)
        _eventPicker.addGestureRecognizer(doubleTapGesture)
        _eventPicker.addGestureRecognizer(longPressGesture)
        
        if( muzomaDoc!.isValid() && muzomaDoc!._activeEditTrack > -1 )
        {
            _navPanel.prompt = muzomaDoc!.getFolderName()
            _lyricTrackIdx = muzomaDoc!.getMainLyricTrackIndex()
            _chordTrackIdx = muzomaDoc!.getMainChordTrackIndex()
            _sectionTrackIdx  = muzomaDoc!.getStructureTrackIndex()
            _guideTrackIdx = muzomaDoc!.getGuideTrackIndex()
        }
        lastEventTimeType = EventTimeType.None
        updateDisplayComponents()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //print( "viewDidAppear player doc" )
        _transport = Transport( viewController: self, includeVarispeedButton: true, includeRecordTimingButton: true )
        _transport.muzomaDoc = self.muzomaDoc
        
        if( muzomaDoc!.isValid() && muzomaDoc!._activeEditTrack > -1 )
        {
            //print("playGuide is \(muzomaDoc!.getGuideTrackURL())")
            _navPanel.prompt = muzomaDoc!.getFolderName()
            _lyricTrackIdx = muzomaDoc!.getMainLyricTrackIndex()
            _chordTrackIdx = muzomaDoc!.getMainChordTrackIndex()
            _sectionTrackIdx  = muzomaDoc!.getStructureTrackIndex()
            _guideTrackIdx = muzomaDoc!.getGuideTrackIndex()
        }
        _eventPicker.reloadComponent(0)
        
        nc.addObserver(self, selector: #selector(EditTmingViewController.playerTicked(_:)), name: NSNotification.Name(rawValue: "PlayerTick"), object: nil)
        nc.addObserver(self, selector: #selector(EditTmingViewController.editEnded(_:)), name: NSNotification.Name(rawValue: "EditorEnded"), object: nil)
        nc.addObserver(self, selector: #selector(EditTmingViewController.rewindButton(_:)), name: NSNotification.Name(rawValue: "PlayerRewind"), object: nil)
        nc.addObserver(self, selector: #selector(EditTmingViewController.fastfwdButton(_:)), name: NSNotification.Name(rawValue: "PlayerFastForward"), object: nil)
        nc.addObserver(self, selector: #selector(EditTmingViewController.halfSpeedPressed(_:)), name: NSNotification.Name(rawValue: "PlayerPlayVarispeed"), object: nil)
        nc.addObserver(self, selector: #selector(EditTmingViewController.playButton(_:)), name: NSNotification.Name(rawValue: "PlayerPlay"), object: nil)
        nc.addObserver(self, selector: #selector(EditTmingViewController.recordOffButton(_:)), name: NSNotification.Name(rawValue: "RecordTimingOff"), object: nil)
        
        
        return super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "PlayerTick"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "EditorEnded"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "PlayerRewind"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "PlayerFastForward"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "PlayerPlayVarispeed"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "PlayerPlay"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "RecordTimingOff"), object: nil )
        
        _transport?.willDeinit()
        _transport = nil
        return( super.viewDidDisappear(animated) )
    }
    
    override var canBecomeFirstResponder : Bool {
        return( true )
    }
    
    /*
     private func keyCommands() -> NSArray {
     return [
     UIKeyCommand(input: UIKeyInputLeftArrow, modifierFlags: UIKeyModifierFlags.init(rawValue: 0), action: #selector(keyPress))
     ]
     }*/
    
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
        //print("up was pressed")
        
        DispatchQueue.main.async(execute: {
            if( self.inEdit )
            {
                self.editController.focusChords()
            }
            else
            {
                var currentRow = self._eventPicker.selectedRow(inComponent: 0)
                currentRow = max( 0, currentRow-1)
                self._eventPicker.selectRow( currentRow, inComponent: 0, animated: false)
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
        //print("down was pressed")
        DispatchQueue.main.async(execute: {
            if( self.inEdit )
            {
                self.editController.focusLyrics()
            }
            else
            {
                var currentRow = self._eventPicker.selectedRow(inComponent: 0)
                currentRow = min( self._eventPicker.numberOfRows(inComponent: 0)-1, currentRow+1) // zero relative
                self._eventPicker.selectRow( currentRow, inComponent: 0, animated: false)
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
        // print("left was pressed")
    }
    
    @objc func scrollRightPress() {
        // print("right was pressed")
    }
    
    @objc func returnKeyPress() {
        // print("return key was pressed")
        DispatchQueue.main.async(execute: {
            
            let currentRow = self._eventPicker.selectedRow(inComponent: 0)
            
            if( self._transport.inRecordTiming && self.muzomaDoc!.isPlaying() )
            {
                (self.muzomaDoc!._tracks[self._lyricTrackIdx]._events[currentRow])._eventTime = self.muzomaDoc!.getCurrentTime()
                self._eventPicker.view(forRow: currentRow, forComponent: 0)?.backgroundColor = UIColor.green
            }
            else
            {
                if( self.inEdit )
                {
                    self.endEdit()
                }
                else
                {
                    self.beginEdit()
                }
            }
        })
    }
    
    @IBAction func composePress(_ sender: AnyObject) {
        let importDocController = self.storyboard?.instantiateViewController(withIdentifier: "ImportTextDocumentViewController") as? ImportTextDocumentViewController
        importDocController?.importingExistingDoc = true
        importDocController?.muzomaDoc = self.muzomaDoc
        
        self.navigationController?.pushViewController(importDocController!, animated: true)
    }
    
    @IBAction func resetPress(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Reset All Timing?", message: "All timing events will be cleared", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            //print("Handle Ok logic here")
            self.muzomaDoc!.resetTiming()
            self._currentPrepareIdx = 0
            self._currentFireIdx = 0
            self._prevScrollToItemAtTime = 0
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            //print("Handle Cancel Logic here")
        }))
        self.present(alert, animated: true, completion: nil)
        //self.editorLines?.Reselect()
    }
    
    @IBAction func cancelPress(_ sender: AnyObject) {
        //self.editorLines?.Deselect()
        
        let alert = UIAlertController(title: "Undo All Edits?", message: "All changes will be reverted.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            //print("Handle Ok logic here")
            //self._eventPicker.selectRow(0, inComponent: 0, animated: false)
            self.muzomaDoc = _gFSH.loadMuzomaDoc( (self.muzomaDoc?.getDocumentURL() )!)
            self._transport.muzomaDoc = self.muzomaDoc
            
            if( self.navigationController != nil)
            {
                // pop to previous vc
                let viewControllers: [UIViewController] = self.navigationController!.viewControllers as [UIViewController]
                if( viewControllers.count >= 2 && viewControllers[viewControllers.count - 2] is PlayerDocumentViewController )
                {
                    let targetVC = viewControllers[viewControllers.count - 2] as! PlayerDocumentViewController
                    targetVC.muzomaDoc = self.muzomaDoc
                    self.navigationController!.popToViewController(targetVC, animated: true)
                }
                else
                {
                    self.navigationController!.popViewController(animated: true)
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            //print("Handle Cancel Logic here")
        }))
        self.present(alert, animated: true, completion: nil)
        //self.editorLines?.Reselect()
    }
    
    
    @IBAction func editDetailsClicked(_ sender: AnyObject) {
        
        let editDocDetails = self.storyboard?.instantiateViewController(withIdentifier: "CreateNewDocViewController") as? CreateNewDocViewController
        editDocDetails!._newDoc = self.muzomaDoc
        editDocDetails!.isUpdateExisting = true
        editDocDetails!._originalTitle = self.muzomaDoc?._title
        editDocDetails!._originalArtist = self.muzomaDoc?._artist
        self.navigationController?.pushViewController(editDocDetails!, animated: true)
        // not nav bar title - self.presentViewController(editDocDetails!, animated: true, completion: nil)
    }
    
    /*
     @IBAction func saveHit(sender: AnyObject) {
     print( "save" )
     let helper = _gFSH
     if( !helper.saveMuzomaDocLocally(muzomaDoc) )
     {
     let alert = UIAlertView()
     alert.title = "Save Error"
     alert.message = "Could not save " + muzomaDoc!.getFileName()
     alert.addButtonWithTitle("OK")
     alert.show()
     }
     }*/
    
    @objc func singleTapGestureHandlerEndEdit(_ sender: UITapGestureRecognizer) {
        //print( "Single tap EndEdit" )
        if( sender.state == .ended)
        {
            //print( "single tap" )
            if( inEdit ) // single tap outside of the edit area
            {
                let loc = sender.location(in: editController.view)
                let hit = editController.view.hitTest(loc, with: nil)
                if( hit == nil )
                {
                    endEdit()
                }
            }
        }
    }
    
    
    @objc func singleTapGestureHandler(_ sender: UITapGestureRecognizer) {
        //print( "Single tap" )
        if( sender.state == .ended)
        {
            //print( "single tap" )
            if( !inEdit && _transport.inRecordTiming && muzomaDoc!.isPlaying() )
            {
                let row = _eventPicker.selectedRow(inComponent: 0)
                muzomaDoc!._tracks[_lyricTrackIdx]._events[row]._eventTime = muzomaDoc!.getCurrentTime()
                _eventPicker.view(forRow: row, forComponent: 0)?.backgroundColor = UIColor.green
            }
        }
    }
    
    override var prefersStatusBarHidden : Bool {
        return navigationController?.isNavigationBarHidden == true
    }
    
    override var preferredStatusBarUpdateAnimation : UIStatusBarAnimation {
        return UIStatusBarAnimation.slide
    }
    
    var editController:ChordAndLyricTableViewController! = nil
    @objc func doubleTapGestureHandler(_ sender: UITapGestureRecognizer) {
        if( sender.state == .ended)
        {
            //print( "double tap" )
            beginEdit()
        }
    }
    
    var inEdit = false
    func beginEdit()
    {
        if( !_transport.inRecordTiming && !inEdit )
        {
            inEdit = true
            _eventPicker.isUserInteractionEnabled = false
            navigationController?.setNavigationBarHidden(true, animated: true)
            topToolbar.isHidden = true
            
            let row = _eventPicker.selectedRow(inComponent: 0)
            //muzomaDoc!._tracks[_lyricTrackIdx]._events[row]._eventTime = muzomaDoc!.getCurrentTime()
            let viewForRow = _eventPicker.view(forRow: row, forComponent: 0)
            viewForRow!.backgroundColor = UIColor.orange
            
            // cover the whole screen
            containerView.isHidden = false
            
            containerView.addGestureRecognizer(singleTapGestureEndEdit)
            //containerView.backgroundColor = UIColor.redColor()
            
            //print( "view for row frame x \(viewForRow!.frame.minX) y \(viewForRow!.frame.minY)" )
            let targetRect = viewForRow!.convert(viewForRow!.frame, to: containerView)
            
            // cover the line on the picker view
            entryContainerView.frame = CGRect( x: viewForRow!.frame.minX, y: targetRect.minY - 5, width: viewForRow!.frame.width, height: viewForRow!.frame.height )
            entryContainerView.isHidden = false
            
            // load the editor view controller and place it in the entry container view
            editController = self.storyboard?.instantiateViewController(withIdentifier: "ChordAndLyricTableView") as? ChordAndLyricTableViewController
            editController.muzomaDoc = self.muzomaDoc
            editController.row = row
            self.configureChildViewController( editController!, onView: entryContainerView)
        }
    }
    
    @objc func editEnded(_ notification: Notification) {
        DispatchQueue.main.async(execute: {
            self.endEdit()
        })
    }
    
    func endEdit()
    {
        if( editController != nil )
        {
            editController.endEdit()
            editController.removeFromParent()
            self.inEdit = false
            self._eventPicker.isUserInteractionEnabled = true
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            self.topToolbar.isHidden = false
            
            containerView.isHidden = true
            containerView.removeGestureRecognizer(singleTapGestureEndEdit)
            entryContainerView.isHidden = true
            editController = nil
            // get the result of the edit
            _eventPicker.reloadComponent(0)
            _ = _gFSH.saveMuzomaDocLocally(muzomaDoc)
            self._transport.muzomaDoc = muzomaDoc
        }
    }
    
    override func willMove(toParent parent: UIViewController?) {
        if( parent == nil ) {
            _ = _gFSH.saveMuzomaDocLocally(muzomaDoc)
            //print("Back Button Pressed Editor!")
            
            if( (self.navigationController?.viewControllers.count)! > 1 &&
                (self.navigationController?.viewControllers[1].isKind(of: PlayerDocumentViewController.self))! )
            {
                let player = (self.navigationController?.viewControllers[1] as! PlayerDocumentViewController)
                player.muzomaDoc = muzomaDoc
            }
        }
        super.willMove(toParent: parent)
    }
    
    override func didMove(toParent parent: UIViewController?) {
        if( parent == nil ) {
            //self.navigationController?.presentingViewController
            
            //_gFSH.saveMuzomaDocLocally(muzomaDoc)
            //print("Back Button Pressed Editor!")
        }
        
        super.didMove(toParent: parent)
    }
    
    //self.prefersStatusBarHidden() // get more real estate in an edit
    
    let containerView:UIView = UIView()
    let entryContainerView:UIView = UIView()
    
    var inLongPress=false
    @objc func longPressGestureHandler(_ sender: UITapGestureRecognizer) {
        
        if(sender.state == .ended)
        {
            if( !_transport.inRecordTiming && !inLongPress )
            {
                inLongPress = true
                //print( "long press" )
                _eventPicker.isUserInteractionEnabled = false
                //_eventPicker.hidden = true
                
                let alert = UIAlertController(title: "Line Tools", message: "", preferredStyle: UIAlertController.Style.alert )
                
                let row = _eventPicker.selectedRow(inComponent: 0)
                //let lyricEvt = muzomaDoc!._tracks[_lyricTrackIdx]._events[row]
                //let chordEvt = muzomaDoc!._tracks[_chordTrackIdx]._events[row]
                alert.addAction(UIAlertAction(title: "Edit Line", style: .default, handler: { (action: UIAlertAction!) in
                    //print("Edit Line")
                    self.inLongPress = false
                    self.beginEdit()
                }))
                
                alert.addAction(UIAlertAction(title: "Remove Line", style: .default, handler: { (action: UIAlertAction!) in
                    //print("Remove Line")
                    if( !self.muzomaDoc!.lineContainsAudioEvent(row) )
                    {
                        self.muzomaDoc!.deleteLineEvent(row)
                        self._eventPicker.reloadComponent(0)
                    }
                    else
                    {
                        // can't have two guides
                        let alert = UIAlertController(title: "Error", message: "You can't remove this event as it contains audio", preferredStyle: UIAlertController.Style.alert)
                        
                        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                            
                        }))
                        
                        alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                        
                        //self.showViewController(alert, sender: self)
                        self.present(alert, animated: true, completion: nil)
                    }
                    
                    self.inLongPress = false
                    self._eventPicker.isUserInteractionEnabled = true
                }))
                
                alert.addAction(UIAlertAction(title: "Insert Line Above", style: .default, handler: { (action: UIAlertAction!) in
                    //print("Insert Line Above")
                    
                    self.muzomaDoc!.insertLine( row )
                    var lyricEvt = self.muzomaDoc!._tracks[self._lyricTrackIdx]._events[row]
                    lyricEvt._data = "[New Line]"
                    self._eventPicker.reloadComponent(0)
                    
                    self.inLongPress = false
                    self._eventPicker.isUserInteractionEnabled = true
                }))
                
                alert.addAction(UIAlertAction(title: "Insert Line Below", style: .default, handler: { (action: UIAlertAction!) in
                    //print("Insert Line Below")
                    self.muzomaDoc!.insertLine( row+1 )
                    var lyricEvt = self.muzomaDoc!._tracks[self._lyricTrackIdx]._events[row]
                    lyricEvt._data = "[New Line]"
                    self._eventPicker.reloadComponent(0)
                    
                    self.inLongPress = false
                    self._eventPicker.isUserInteractionEnabled = true
                }))
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                    //print("Cancel")
                    self.inLongPress = false
                    self._eventPicker.isUserInteractionEnabled = true
                }))
                
                alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                self.present(alert, animated: true, completion:
                    {
                        //print( "alert shown" )
                } )
            }
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
    
    @objc func stopButton(_ sender: AnyObject) {
        //print("stop")
    }
    
    @objc func playButton(_ sender: AnyObject) {
        // print("play")
    }
    
    @objc func halfSpeedPressed(_ sender: AnyObject) {
        //print("play varispeed")
    }
    
    @objc func playerTicked(_ notification: Notification) {
        DispatchQueue.main.async(execute: {self.updateDisplayComponents()})
    }
    
    @objc func recordOffButton(_ sender: AnyObject) {
        //print("record Off")
        _ = _gFSH.saveMuzomaDocLocally(muzomaDoc)
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        let ret:CGFloat = 80.0
        return( ret )
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // picker view
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView
    {
        var lineEventView:UIView! = nil
        /*print( "main frame width \(self.view.frame.width), event view \(self._eventPicker.frame.width)" )*/
        
        let chordData = _chordTrackIdx > -1 ? muzomaDoc!._tracks[_chordTrackIdx]._events[row]._data : ""
        let lyricData = _lyricTrackIdx > -1 ? muzomaDoc!._tracks[_lyricTrackIdx]._events[row]._data : ""
        let sectionData = _sectionTrackIdx > -1 ? muzomaDoc!._tracks[_sectionTrackIdx]._events[row]._data : ""
        let guideTrackData = _guideTrackIdx > -1 ? muzomaDoc!._tracks[_guideTrackIdx]._events[row]._data : ""
        
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
            return muzomaDoc!._tracks.count > 0 ? muzomaDoc!._tracks[_lyricTrackIdx]._events.count : 0
        }
        else
        {
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return nil
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        _currentPrepareIdx = 0
        _currentFireIdx = 0
        
        // user changed the picker row
        if( _transport.inRecordTiming && muzomaDoc!.isPlaying() )
        {
            muzomaDoc!._tracks[_lyricTrackIdx]._events[row]._prepareTime = muzomaDoc!.getCurrentTime()
        }
        else if( muzomaDoc!._tracks.count > 0 && muzomaDoc!._tracks[_lyricTrackIdx]._events.count > row )
        {
            let evtTime = muzomaDoc!._tracks[_lyricTrackIdx]._events[row]._prepareTime
            
            if( evtTime > 0 )
            {
                muzomaDoc!.setCurrentTime(evtTime!)
            }
        }
    }
    
    
    var currentSectionTitle = ""
    func scrollToItemAtTime(_ currentTime:TimeInterval)
    {
        if(currentTime != _prevScrollToItemAtTime )
        {
            _prevScrollToItemAtTime = currentTime
            //let selRow = _eventPicker.selectedRowInComponent(0)
            
            var prepareIdx = 0
            var fireIdx = 0
            var updated = false
            for (n, ele) in muzomaDoc!._tracks[_lyricTrackIdx]._events.enumerated() {
                updated = false
                if( ele._prepareTime != nil && ele._prepareTime <= currentTime ) // last one in list that is less than current time and prev event was fire
                {
                    prepareIdx = n
                    updated = true
                }
                
                if( ele._eventTime != nil && ele._eventTime <= currentTime ) // event
                {
                    fireIdx = n
                    updated = true
                }
                
                let sectionEvt = muzomaDoc!._tracks[_sectionTrackIdx]._events[n]
                if(  sectionEvt._data != "" )
                {
                    currentSectionTitle = sectionEvt._data
                    //print( "section \(currentSectionTitle)" )
                }
                
                if( !updated && (ele._eventTime != nil || ele._prepareTime != nil)  )
                {
                    break;
                }
            }
            
            if( prepareIdx != _currentPrepareIdx ) //&& _currentPrepareIdx != _eventPicker.selectedRowInComponent(0) )
            {
                _eventPicker.selectRow(prepareIdx, inComponent: 0, animated: true)
                lastEventTimeType = EventTimeType.Prepare
                //print( "Prepare \(currentTime)")
                _currentPrepareIdx = prepareIdx
            }
            else if( fireIdx != _currentFireIdx  )//&& lastEventTimeType == EventTimeType.Prepare  )
            {
                _eventPicker.selectRow(fireIdx, inComponent: 0, animated: true)
                _eventPicker.view(forRow: fireIdx, forComponent: 0)?.backgroundColor = UIColor.green
                lastEventTimeType = EventTimeType.Fire
                //print( "Fire \(currentTime)")
                _currentFireIdx = fireIdx
            }
        }
    }
    
    
    var prevTime:TimeInterval = 0
    func updateDisplayComponents()
    {
        //println("update display")
        let time:TimeInterval = (self.muzomaDoc!.getCurrentTime())
        
        if( _transport != nil )
        {
            if( !_transport.inRecordTiming && !_eventPicker.isScrolling() ) //
            {
                if( time != prevTime )
                {
                    scrollToItemAtTime(time)
                    prevTime = time
                }
            }
        }
        
        self.sectionLabel.text = currentSectionTitle
    }
    
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        if( segue.destination.isKind(of: TracksTableViewController.self) )
        {
            let editor = (segue.destination as! TracksTableViewController)
            editor.muzomaDoc = muzomaDoc
        } else if( segue.destination.isKind(of: ChordPickerController.self) )
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
        } else if( segue.destination.isKind(of: PlayerDocumentViewController.self) )
        {
            let editor = (segue.destination as! PlayerDocumentViewController)
            editor.muzomaDoc = muzomaDoc
        }
    }
}

