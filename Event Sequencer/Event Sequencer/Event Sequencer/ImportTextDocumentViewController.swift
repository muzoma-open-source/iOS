//
//  ImportTextDocumentViewController.swift
//  Event Sequencer
//
//  Created by Matthew Hopkins on 15/11/2015.
//  Copyright © 2015 Muzoma.com. All rights reserved.
//
//  Code to handle the view of text and music and format parsing between the screen, files and muzoma xml documents
//

import Foundation
import CoreFoundation
import AudioToolbox
import MediaPlayer
import AVFoundation
import UIKit
import MobileCoreServices


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


enum LineTypeColourIndex : Int
{
    case none = 255
    case lyrics = 0
    case chords = 1
    case section = 2
    case title = 3
    case artist = 4
    case author = 5
    case copyright = 6
    case publisher = 7
    case memo = 8
    case key = 9
    case tempo = 10
    case timeSig = 11
}

let LineColourArray =
    [
        UIColor.init(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0),//.redColor(),
        UIColor.init(hexString: "#00b34d"), //init(red: 0.0, green: 0.7, blue: 0.3, alpha: 1.0),//.redColor(),,
        UIColor.init(hexString: "#ff8000"), //orangeColor(),
        UIColor.init(red: 0.0, green: 0.6, blue: 0.6, alpha: 1.0),//cyanColor(),
        UIColor.init( hexString: "#0000e6" ),//red: 0.0, green: 0.0, blue: 0.901961, alpha: 1.0),//blueColor(),
        UIColor.init(red: 0.8, green: 0.6, blue: 0.8, alpha: 1.0), // grey
        UIColor.init( hexString: "#ff4d1a"), //init(red: 1.0, green: 0.3, blue: 0.1, alpha: 1.0),
        UIColor.magenta,
        UIColor.init( hexString: "#331033"), //init(red: 0.2, green: 0.7, blue: 0.2, alpha: 1.0),//grayColor(),
        UIColor.init( hexString: "#b34dcc" ), //init(red: 0.7, green: 0.3, blue: 0.8, alpha: 1.0), //lightGrayColor(),
        UIColor.init(red: 0.8, green: 0.8, blue: 0.2, alpha: 1.0),//.yellowColor(),
        UIColor.init( hexString: "#b34dff" )//init(red: 0.7, green: 0.3, blue: 1.0, alpha: 1.0)//.purpleColor()
]

class ImportTextDocumentViewController :  UIViewController, UITextViewDelegate, UIDocumentPickerDelegate, UIGestureRecognizerDelegate
{
    fileprivate var _muzomaDoc: MuzomaDocument?
    fileprivate var _originalTitle:String! = nil
    fileprivate var _originalArtist:String! = nil
    
    var muzomaDoc : MuzomaDocument?
    {
        get
        {
            return( _muzomaDoc )
        }
        
        set
        {
            _muzomaDoc = newValue
            _originalTitle =  _muzomaDoc?._title
            _originalArtist = _muzomaDoc?._artist
        }
    }
    
    var importingExistingDoc: Bool = false
    
    @IBOutlet weak var offButton: UIBarButtonItem!
    @IBOutlet weak var splitButton: UIBarButtonItem!
    @IBOutlet weak var lyricsButton: UIBarButtonItem!
    @IBOutlet weak var chordsButton: UIBarButtonItem!
    @IBOutlet weak var sectionButton: UIBarButtonItem!
    @IBOutlet weak var titleButton: UIBarButtonItem!
    @IBOutlet weak var artistButton: UIBarButtonItem!
    @IBOutlet weak var authorButton: UIBarButtonItem!
    @IBOutlet weak var copyrightButton: UIBarButtonItem!
    @IBOutlet weak var publisherButton: UIBarButtonItem!
    @IBOutlet weak var memoButton: UIBarButtonItem!
    @IBOutlet weak var keyButton: UIBarButtonItem!
    @IBOutlet weak var tempoButton: UIBarButtonItem!
    @IBOutlet weak var timeSigButton: UIBarButtonItem!
    @IBOutlet weak var _textViewContainer: UISuperTextView!
    @IBOutlet weak var lineTypeToolBar: UIToolbar!
    @IBOutlet weak var _contextToolBar: UIToolbar!
    
    fileprivate var _transport:Transport! = nil
    let _nc = NotificationCenter.default
    
    var _textView: UITextView!
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        if( _muzomaDoc == nil)
        {
            muzomaDoc = MuzomaDocument()
            muzomaDoc!.loadEmptyDefaultSong()
            muzomaDoc!.defaultGuideTrackRecordSettings()
        }
    }
    
    var keyboardShowing = false
    override var shouldAutorotate : Bool {
        return !self.keyboardShowing
    }
    
    // as long as you play your part (adjust content offset),
    // iOS 8 will play its part (scroll cursor to visible)
    // and we don't have to animate
    
    @objc func keyboardShow(_ n:Notification) {
        //print("kb show")
        self.navigationController?.setToolbarHidden(true, animated: true)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        self.keyboardShowing = true
    }
    
    @objc func keyboardHide(_ n:Notification) {
        //print("kb hide")
        self.navigationController?.setToolbarHidden(false, animated: true)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        self.keyboardShowing = false
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _nc.addObserver(self, selector: #selector(ImportTextDocumentViewController.refreshChordPallet(_:)), name: NSNotification.Name(rawValue: "RefreshChordPallet"), object: nil)
        _nc.addObserver(self, selector: #selector(ImportTextDocumentViewController.pasting(_:)), name: NSNotification.Name(rawValue: "SuperTVPasting"), object: nil)
        
        self._textView = _textViewContainer._textView
        self._textView.keyboardDismissMode = .interactive
        self._textView.autocorrectionType = .no
        
        lyricsButton.tintColor = LineColourArray[LineTypeColourIndex.lyrics.rawValue]
        chordsButton.tintColor = LineColourArray[LineTypeColourIndex.chords.rawValue]
        sectionButton.tintColor = LineColourArray[LineTypeColourIndex.section.rawValue]
        titleButton.tintColor = LineColourArray[LineTypeColourIndex.title.rawValue]
        artistButton.tintColor = LineColourArray[LineTypeColourIndex.artist.rawValue]
        authorButton.tintColor = LineColourArray[LineTypeColourIndex.author.rawValue]
        copyrightButton.tintColor = LineColourArray[LineTypeColourIndex.copyright.rawValue]
        publisherButton.tintColor = LineColourArray[LineTypeColourIndex.publisher.rawValue]
        memoButton.tintColor = LineColourArray[LineTypeColourIndex.memo.rawValue]
        keyButton.tintColor = LineColourArray[LineTypeColourIndex.key.rawValue]
        tempoButton.tintColor = LineColourArray[LineTypeColourIndex.tempo.rawValue]
        timeSigButton.tintColor = LineColourArray[LineTypeColourIndex.timeSig.rawValue]
        
        // Do any additional setup after loading the view, typically from a nib.
        let markSplit = UIMenuItem(title: "Split", action: #selector(ImportTextDocumentViewController.markSplit))
        let markOff = UIMenuItem(title: "Off", action: #selector(ImportTextDocumentViewController.markOff))
        let markLyric = UIMenuItem(title: "Lyric", action: #selector(ImportTextDocumentViewController.markLyric))
        let markChord = UIMenuItem(title: "Chord", action: #selector(ImportTextDocumentViewController.markChord))
        let markSection = UIMenuItem(title: "Section", action: #selector(ImportTextDocumentViewController.markSection))
        let markTitle = UIMenuItem(title: "Title", action: #selector(ImportTextDocumentViewController.markTitle))
        let markArtist = UIMenuItem(title: "Artist", action: #selector(ImportTextDocumentViewController.markArtist))
        let markAuthor = UIMenuItem(title: "Author", action: #selector(ImportTextDocumentViewController.markAuthor))
        let markCopyright = UIMenuItem(title: "Copyright", action: #selector(ImportTextDocumentViewController.markCopyright))
        let markPublisher = UIMenuItem(title: "Publisher", action: #selector(ImportTextDocumentViewController.markPublisher))
        let markMemo = UIMenuItem(title: "Memo", action: #selector(ImportTextDocumentViewController.markMemo))
        let markKey = UIMenuItem(title: "Key", action: #selector(ImportTextDocumentViewController.markKey))
        let markTempo = UIMenuItem(title: "Tempo", action: #selector(ImportTextDocumentViewController.markTempo))
        let markTimeSig = UIMenuItem(title: "TimeSig", action: #selector(ImportTextDocumentViewController.markTimeSig))
        UIMenuController.shared.menuItems=[markSplit, markOff,markLyric,markChord,markSection,markTitle,markArtist,markAuthor,markCopyright,markPublisher,markMemo,markKey,markTempo,markTimeSig]
        
        // pan chord pallet capture
        let panChord = UIPanGestureRecognizer(target:self, action:#selector(ImportTextDocumentViewController.panChord(_:)))
        panChord.maximumNumberOfTouches = 1
        panChord.minimumNumberOfTouches = 1
        panChord.delegate = self
        self._contextToolBar.addGestureRecognizer(panChord)
        
        if( importingExistingDoc )
        {
            self.addImportingSpinnerView()
            // long running, so dispatch it
            DispatchQueue.main.async(execute: {
                self.importExisting()
                self.removeImportingSpinnerView()
            })
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //print( "viewDidAppear import text doc" )
        
        _nc.addObserver(self, selector: #selector(ImportTextDocumentViewController.refreshChordPallet(_:)), name: NSNotification.Name(rawValue: "RefreshChordPallet"), object: nil)
        _nc.addObserver(self, selector: #selector(ImportTextDocumentViewController.keyboardShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        _nc.addObserver(self, selector: #selector(ImportTextDocumentViewController.keyboardHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        _nc.addObserver(self, selector: #selector(ImportTextDocumentViewController.textSelectionChanged(_:)), name: NSNotification.Name(rawValue: "SuperTVSelectionChanged"), object: nil)
        
        _transport = Transport( viewController: self, includeVarispeedButton: true, includeGuideTrackSelectButton: true, includeRecordAudioButton: true )
        _transport.muzomaDoc = self.muzomaDoc
        
        refreshChordPallet()
        return( super.viewDidAppear(animated) )
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        _nc.removeObserver( self, name: NSNotification.Name(rawValue: "RefreshChordPallet"), object: nil )
        _nc.removeObserver( self, name: NSNotification.Name(rawValue: "SuperTVPasting"), object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        _nc.removeObserver( self, name: UIResponder.keyboardWillShowNotification, object: nil )
        _nc.removeObserver( self, name: UIResponder.keyboardWillHideNotification, object: nil )
        _nc.removeObserver( self, name: NSNotification.Name(rawValue: "SuperTVSelectionChanged"), object: nil )
        
        _transport?.willDeinit()
        _transport = nil
        super.viewDidDisappear(animated)
    }
    
    func importExisting()
    {
        if( self._muzomaDoc != nil )
        {
            self._textView.attributedText = nil
            
            if( self._muzomaDoc!._title != nil )
            {
                self._textView.insertText(self._muzomaDoc!._title!)
                self.markTitle(true)
                self._textView.insertText("\n")
            }
            
            if( self._muzomaDoc!._artist != nil )
            {
                self._textView.insertText(self._muzomaDoc!._artist!)
                self.markArtist(true)
                self._textView.insertText("\n")
            }
            
            if( self._muzomaDoc!._author != nil )
            {
                self._textView.insertText(self._muzomaDoc!._author!)
                self.markAuthor(true)
                self._textView.insertText("\n")
            }
            
            if( self._muzomaDoc!._copyright != nil )
            {
                self._textView.insertText(self._muzomaDoc!._copyright!)
                self.markCopyright(true)
                self._textView.insertText("\n")
            }
            
            if( self._muzomaDoc!._key != nil )
            {
                self._textView.insertText(self._muzomaDoc!._key!)
                self.markKey(true)
                self._textView.insertText("\n")
            }
            
            if( self._muzomaDoc!._publisher != nil )
            {
                self._textView.insertText(self._muzomaDoc!._publisher!)
                self.markPublisher(true)
                self._textView.insertText("\n")
            }
            
            if( self._muzomaDoc!._timeSignature != nil )
            {
                self._textView.insertText(self._muzomaDoc!._timeSignature!)
                self.markTimeSig(true)
                self._textView.insertText("\n")
            }
            
            if( self._muzomaDoc!._tempo != nil )
            {
                self._textView.insertText(self._muzomaDoc!._tempo!)
                self.markTempo(true)
                self._textView.insertText("\n")
            }
            
            self._textView.insertText("\n")
            self.markOff()
            
            /*self._textView.insertText(" \n")
             self.markOff()
             self._textView.insertText("\n")*/
            
            let lyricIdx = self._muzomaDoc!.getMainLyricTrackIndex()
            let chordsIdx = self._muzomaDoc!.getMainChordTrackIndex()
            let structureIdx = self._muzomaDoc!.getStructureTrackIndex()
            
            let lyricEvents = _muzomaDoc!._tracks[lyricIdx]._events
            let chordEvents = _muzomaDoc!._tracks[chordsIdx]._events
            let structureEvents = _muzomaDoc!._tracks[structureIdx]._events
            
            for (idx, lyricEvt) in lyricEvents.enumerated() {
                
                let chordEvent = chordEvents[idx]
                let structureEvent = structureEvents[idx]
                
                if( !structureEvent._data.isEmpty )
                {
                    self._textView.insertText(structureEvent._data)
                    self.markSection()
                    self._textView.insertText("\n")
                }
                
                if( lyricEvt._data.count > 0 || chordEvent._data.count > 0 )
                {
                    let padCnt = max( 1, lyricEvt._data.count, chordEvent._data.count )
                    
                    if( chordEvent._data.trimmingCharacters(in: whitespaceSet) == "" &&
                        lyricEvt._data.trimmingCharacters(in: whitespaceSet) == "" )
                    {
                        let pad = "".padding(toLength: padCnt, withPad: " ", startingAt: 0)
                        self._textView.insertText(pad)
                        self.markOff()
                        self._textView.insertText("\n")
                    }
                    else
                    {
                        if( chordEvent._data.trimmingCharacters(in: whitespaceSet) == "" )
                        {
                            let pad = "".padding(toLength: padCnt, withPad: " ", startingAt: 0)
                            self._textView.insertText(pad)
                            self.markChord() //self.markOff()
                            self._textView.insertText("\n")
                        }
                        else
                        {
                            let pad = chordEvent._data.padding(toLength: padCnt, withPad: " ", startingAt: 0)
                            self._textView.insertText(pad)
                            self.markChord()
                            self._textView.insertText("\n")
                        }
                        
                        if( lyricEvt._data.trimmingCharacters(in: whitespaceSet) == "" )
                        {
                            let pad = "".padding(toLength: padCnt, withPad: " ", startingAt: 0)
                            self._textView.insertText(pad)
                            self.markLyric() // self.markOff()
                            self._textView.insertText("\n")
                        }
                        else
                        {
                            let pad = lyricEvt._data.padding(toLength: padCnt, withPad: " ", startingAt: 0)
                            self._textView.insertText(pad)
                            self.markLyric()
                            self._textView.insertText("\n")
                        }
                        
                        let pad = "".padding(toLength: padCnt, withPad: " ", startingAt: 0)
                        self._textView.insertText(pad)
                        self.markOff()
                        self._textView.insertText("\n")
                    }
                }
            }
            refreshChordPallet()
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        var ret = true
        if( identifier == "ImportClickSegue" )
        {
            self.importClicked(sender! as AnyObject)
            ret = false
        }
        return( ret )
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        
        if( segue.destination.isKind(of: CreateNewDocViewController.self) )
        {
            // should never make it here - used in conjunction with shouldPerformSegueWithIdentifier
        }
        else if( segue.destination.isKind(of: TracksTableViewController.self) )
        {
            let editor = (segue.destination as! TracksTableViewController)
            editor.muzomaDoc = _muzomaDoc
        } else if( segue.destination.isKind(of: ChordPickerController.self) )
        {
            let editor = (segue.destination as! ChordPickerController)
            editor.muzomaDoc = _muzomaDoc
        } else if( segue.destination.isKind(of: EditDocumentViewController.self) )
        {
            let editor = (segue.destination as! EditDocumentViewController)
            editor.muzomaDoc = _muzomaDoc
        } else if( segue.destination.isKind(of: EditorLinesController.self) )
        {
            let editor = (segue.destination as! EditorLinesController)
            editor.muzomaDoc = _muzomaDoc
        } else if( segue.destination.isKind(of: EditTmingViewController.self) )
        {
            let editor = (segue.destination as! EditTmingViewController)
            editor.muzomaDoc = _muzomaDoc
        }
    }
    
    let _chordPlayer = ChordPlayer()
    @objc func playChord(_ chordBut: UIBarButtonItem) {
        let chordPicked = (_muzomaDoc?._chordPallet[chordBut.tag])!
        _chordPlayer.playChord( chordPicked )
    }
    
    @objc func refreshChordPallet(_ notification: Notification)
    {
        DispatchQueue.main.async(execute: {
            self.refreshChordPallet()
        })
    }
    
    func refreshChordPallet()
    {
        // remove chords buttons
        if( _contextToolBar.items?.count > 3 )
        {
            _contextToolBar.items?.removeSubrange(3..<(_contextToolBar.items?.count)!)
        }
        
        // add chord buttons
        for (tag, chord) in (_muzomaDoc?._chordPallet.enumerated())!
        {
            let chordBut = UIBarButtonItem(title: chord.chordString, style: UIBarButtonItem.Style.plain, target: self, action:  #selector(ImportTextDocumentViewController.playChord(_:)) )
            chordBut.tag = tag
            chordBut.accessibilityIdentifier = chord.chordString
            _contextToolBar.items?.append(chordBut)
        }
    }
    
    /// must be >= 1.0
    var snapX:CGFloat = 1.0
    
    /// must be >= 1.0
    var snapY:CGFloat = 1.0
    
    /// how far to move before dragging
    var threshold:CGFloat = 1.0
    
    /// the guy we're dragging
    var selectedView:UIView?
    
    /// drag in the Y direction?
    var shouldDragY = true
    
    /// drag in the X direction?
    var shouldDragX = true
    
    @IBOutlet weak var chordTrash: UIBarButtonItem!
    
    @objc func panChord( _ rec:UIPanGestureRecognizer ) {
        
        let p:CGPoint = rec.location( in: self.view )
        var center:CGPoint = CGPoint.zero
        
        switch rec.state {
        case .began:
            //print("began")
            selectedView = view.hitTest(p, with: nil)
            
            if( selectedView != nil )
            {
                if( selectedView is UIToolbar )
                {
                    //print( "tool scroll begin" )
                }
                else if( selectedView is UIControl )
                {
                    let hitTestContextBar = _contextToolBar.hitTest(rec.location(ofTouch: 0, in: _contextToolBar), with: nil) // hit on context tool bar
                    
                    if( hitTestContextBar != nil )
                    {
                        if( !(selectedView is UISlider) )
                        {
                            // we have to scan through the chords and find the view that matches
                            var buttonItemTitle:String! = nil
                            for(_, chordItem ) in (_contextToolBar!.items?.enumerated())!
                            {
                                if(selectedView == (chordItem.value(forKey: "view") as! UIView) )
                                {
                                    buttonItemTitle = chordItem.title
                                    break;
                                }
                            }
                            
                            if( buttonItemTitle != nil && (buttonItemTitle as String) != "➕" && (buttonItemTitle as String) != "🗑" && (buttonItemTitle as String) != "↺"  )
                            {
                                self.view.bringSubviewToFront(selectedView!)
                                
                                let chordIconView = DragView( frame: CGRect(x: 85, y: 85, width: 85, height: 85) )
                                chordIconView.text = buttonItemTitle
                                chordIconView.center = (selectedView?.center)!
                                view.addSubview(chordIconView)
                                chordIconView.tag = -1
                                selectedView=chordIconView
                            }
                        }
                    }
                }
            }
            
        case .changed:
            if( selectedView is UIToolbar )
            {
                //print( "tool scroll change" )
            }
            else if(selectedView?.tag == -1 )
            {
                if let subview = selectedView {
                    center = subview.center
                    let distance = sqrt(pow((center.x - p.x), 2.0) + pow((center.y - p.y), 2.0))
                    //print("distance \(distance)")
                    
                    let type = String(describing: Swift.type(of: subview))
                    //if type == "UIToolbarTextButton" {
                    if type == "DragView" {
                        if distance > threshold {
                            if shouldDragX {
                                subview.center.x = p.x - (p.x.truncatingRemainder(dividingBy: snapX))
                            }
                            
                            if shouldDragY {
                                subview.center.y = p.y - (p.y.truncatingRemainder(dividingBy: snapY))
                            }
                        }
                    }
                }
            }
            
        case .ended:
            //print("ended")
            if( selectedView is UIToolbar )
            {
                //print( "tool scroll end" )
            }
            else
                if( selectedView?.tag == -1 )
                {
                    if let subview = selectedView {
                        let type = String(describing: Swift.type(of: subview))
                        //print( type )
                        if type == "DragView"{
                            // paste in
                            subview.removeFromSuperview()
                            let draggedView = subview as! DragView
                            
                            let chordTrashView = chordTrash.value(forKey: "view") as! UIView?
                            let targetChord = chordTrashView?.convert((chordTrashView?.frame)!, to: self.view)
                            let targetDelete = self.view.convert(subview.frame, to: self.view)
                            
                            if( targetChord?.intersects(targetDelete) )! // moved chord to delete
                            {
                                let alert = UIAlertController(title: "Remove Chord?", message: "Do you wish to remove \(draggedView.text)?", preferredStyle: UIAlertController.Style.alert)
                                
                                alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                                    //print("load file Yes")
                                    
                                    // remove chord
                                    var removeIdx = -1
                                    for (tag, chord) in (self._muzomaDoc?._chordPallet.enumerated())!
                                    {
                                        if( chord.chordString == draggedView.text )
                                        {
                                            removeIdx = tag
                                            break
                                        }
                                    }
                                    
                                    if( removeIdx > -1 )
                                    {
                                        self._muzomaDoc?._chordPallet.remove(at: removeIdx)
                                    }
                                    
                                    self.refreshChordPallet()
                                }))
                                
                                alert.addAction(UIAlertAction(title: "No", style: .default, handler: { (action: UIAlertAction!) in
                                    //print("load file No")
                                }))
                                
                                alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                                self.present(alert, animated: true, completion: {})
                            }
                            else
                            {
                                // did land in the text?
                                var targetPoint = self.view.convert( p, to: _textView )
                                
                                //print( "zooming scale: \(_textView.zoomScale)    targetPoint x : \(targetPoint.x) targetPoint y : \(targetPoint.y)"  )
                                targetPoint.x -= (43 / _textViewContainer.zoomScale)
                                targetPoint.y -= (43 / _textViewContainer.zoomScale)
                                var position:UITextPosition = _textView.closestPosition( to: targetPoint )!
                                var textRange = _textView.textRange(from: position, to: position)
                                // set selection where dropped
                                _textView.selectedTextRange = textRange
                                
                                var isChord = false
                                let lineRange = _textView.getLineRangeFromSelectedPos()
                                let lineText = self._textView.attributedText.attributedSubstring(from: lineRange)
                                if( lineText.string.count > 0 )
                                {
                                    let bgCol = lineText.attribute(NSAttributedString.Key.backgroundColor, at: 0, effectiveRange: nil)
                                    if( bgCol != nil )
                                    {
                                        let col = (bgCol as! UIColor).toHexString()
                                        if( col == LineColourArray[LineTypeColourIndex.chords.rawValue].toHexString() )
                                        {
                                            isChord = true
                                        }
                                    }
                                    
                                    if( isChord )
                                    {
                                        /*new to test for pad Line */
                                        var testPoint = self.view.convert( p, to: _textView )
                                        testPoint.x -= (43 / _textViewContainer.zoomScale)
                                        testPoint.y -= (43 / _textViewContainer.zoomScale)
                                        testPoint.x += 20
                                        
                                        var stopExtend = false
                                        var hasExtended = false
                                        var cntInsert = 0
                                        repeat
                                        {
                                            let testPosition:UITextPosition = _textView.closestPosition( to: testPoint )!
                                            if( testPosition == position && cntInsert < 80 ) // line needs extending
                                            {
                                                _textView.selectedTextRange = textRange
                                                _textView.insertText(" ")
                                                cntInsert += 1
                                                position = _textView.closestPosition( to: targetPoint )!
                                                textRange = _textView.textRange(from: position, to: position)
                                                hasExtended = true
                                            }
                                            else
                                            {
                                                if(hasExtended)
                                                {
                                                    // add space for the chord at the end of line too
                                                    _textView.selectedTextRange = textRange
                                                    _textView.insertText( "".padding(toLength: draggedView.text.count, withPad: " ", startingAt: 0))
                                                    position = _textView.closestPosition( to: targetPoint )!
                                                    textRange = _textView.textRange(from: position, to: position)
                                                }
                                                
                                                stopExtend = true
                                            }
                                        } while( !stopExtend )
                                        
                                        
                                        // insert chord over existing text
                                        let toPos = _textView.position(from: position, offset: draggedView.text.count )
                                        if( toPos != nil )
                                        {
                                            let replaceRange = _textView.textRange(from: position, to: toPos!)
                                            _textView.replace(replaceRange!, withText: draggedView.text)
                                        }
                                        else
                                        {
                                            _textView.insertText(draggedView.text)
                                        }
                                        markChord()
                                    }
                                }
                            }
                        }
                    }
            }
            selectedView = nil
            
        case .possible:
            print("possible")
        case .cancelled:
            print("cancelled")
        case .failed:
            print("failed")
        }
    }
    
    
    var gotLyricLine = false
    func addLyricLine( _ _muzDoc: MuzomaDocument!, lineNumber: Int, text: String)
    {
        let evt = MuzEvent( eventType: EventType.Line, data: text, lineNumber: lineNumber )
        _muzDoc.appendLyricLine( evt )
        gotLyricLine = false
    }
    
    var gotChordLine = false
    func addChordLine( _ _muzDoc: MuzomaDocument!, lineNumber: Int, chords: String)
    {
        let evt = MuzEvent( eventType: EventType.Chords, data: chords, lineNumber: lineNumber )
        _muzDoc.appendChordLine( evt )
        gotChordLine = false
    }
    
    func addSectionLine(_ _muzDoc: MuzomaDocument!, lineNumber: Int,  section: String)
    {
        let evt = MuzEvent( eventType: EventType.Structure, data: section, lineNumber: lineNumber )
        _muzDoc.appendStructureLine( evt )
        gotLyricLine = false
        gotChordLine = false
    }
    
    var prevChord:Chord! = nil
    @objc func textSelectionChanged(_ notification: Notification) {
        
        let wordRange = self._textView.getRangeOfNearestWordFromSelectedPos()
        if( wordRange.length > 0)
        {
            let lineText=self._textView.attributedText.attributedSubstring(from: wordRange)
            let bgCol = lineText.attribute(NSAttributedString.Key.backgroundColor, at: 0, effectiveRange: nil)
            if( bgCol != nil )
            {
                let col = (bgCol as! UIColor).toHexString()
                if( col == LineColourArray[LineTypeColourIndex.chords.rawValue].toHexString() )
                {
                    let chordTextString = lineText.string
                    //print( "Chord \(chordTextString)" )
                    let chord = Chord(chordText: chordTextString)
                    if( prevChord == nil || chord.chordString != prevChord!.chordString )
                    {
                        if( _contextToolBar.items?.count > 3 )
                        {
                            let chordPicked = (_muzomaDoc?._chordPallet[(_contextToolBar.items?[3].tag)!])!
                            chord._instrument = chordPicked._instrument
                        }
                        _chordPlayer.playChord( chord )
                        prevChord = chord
                        // reset previous chord with a timeout
                        let delay = DispatchTime.now() + Double(Int64(2.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                        DispatchQueue.main.asyncAfter(deadline: delay,execute: {
                            self.prevChord = nil
                        })
                    }
                    else
                    {
                        
                    }
                }
            }
        }
        
        //print( "word range \(wordRange)" )
    }
    
    @IBAction func importClicked(_ sender: AnyObject) {
        
        self.addImportingSpinnerView()
        
        // long running, so dispatch it
        DispatchQueue.main.async(execute: {
            
            let lineCount = self._textView.getLineCount()
            
            var title = "no title"
            var artist = "no artist"
            var author = "no author"
            
            var error = ""
            
            var songLineIdx = 0
            var lyricLine = ""
            var chordLine = ""
            
            let doc = Transport.getCurrentDoc()
            doc?.clearChordAndLyricEvents()
            
            let attrText = self._textView.attributedText
            
            // might be changing title and artist here, so directory would change
            let originalArtURL = doc?.getArtworkURL()
            let originalGuideURL = doc?.getGuideTrackURL()
            
            for lineIdx in ( 0 ..< lineCount )
            {
                let range = self._textView.getRangeForLineIndex(lineIdx)
                
                // blank line?
                let lineText = attrText?.attributedSubstring(from: range)
                let plainText = lineText?.string.trimRight(whitespaceSet)
                //print( "curr songline \(songLineIdx), line \(lineIdx) - \(lineText)" )
                
                if( (lineText?.string.isEmpty)! || plainText == "" )
                {
                    //print( "line \(lineIdx) - empty" )
                    if( self.gotLyricLine )
                    {
                        self.addLyricLine(doc, lineNumber: songLineIdx, text: lyricLine)
                    }
                    
                    if( self.gotChordLine )
                    {
                        self.addChordLine(doc, lineNumber: songLineIdx, chords: chordLine)
                    }
                    songLineIdx += 1
                }
                else if( range.length > 0)
                {
                    let bgCol = lineText?.attribute(NSAttributedString.Key.backgroundColor, at: 0, effectiveRange: nil)
                    
                    if( bgCol != nil )
                    {
                        let col = (bgCol as! UIColor).toHexString()
                        //print( "line \(lineIdx) \(bgCol?.debugDescription) \(col)" )
                        
                        switch( col )
                        {
                            
                        case LineColourArray[LineTypeColourIndex.lyrics.rawValue].toHexString():
                            //print( "line \(lineIdx) Lyrics" )
                            if( self.gotLyricLine )
                            {
                                self.addLyricLine(doc, lineNumber: songLineIdx, text: lyricLine)
                                
                                if( self.gotChordLine )
                                {
                                    self.addChordLine(doc, lineNumber: songLineIdx, chords: chordLine)
                                }
                                songLineIdx += 1
                            }
                            
                            self.gotLyricLine = true
                            lyricLine = plainText!
                            break
                        case  LineColourArray[LineTypeColourIndex.chords.rawValue].toHexString():
                            //print( "line \(lineIdx) Chords" )
                            
                            if( self.gotChordLine )
                            {
                                self.addChordLine(doc, lineNumber: songLineIdx, chords: chordLine)
                                if( self.gotLyricLine )
                                {
                                    self.addLyricLine(doc, lineNumber: songLineIdx, text: lyricLine)
                                }
                                songLineIdx += 1
                            }
                            
                            self.gotChordLine = true
                            chordLine = plainText!
                            break
                        case LineColourArray[LineTypeColourIndex.section.rawValue].toHexString():
                            //print( "line \(lineIdx) Section" )
                            if( self.gotLyricLine )
                            {
                                self.addLyricLine(doc, lineNumber: songLineIdx, text: lyricLine)
                            }
                            
                            if( self.gotChordLine )
                            {
                                self.addChordLine(doc, lineNumber: songLineIdx, chords: chordLine)
                            }
                            songLineIdx += 1
                            
                            self.addSectionLine(doc, lineNumber: songLineIdx, section: plainText!)
                            songLineIdx += 1
                            
                            break
                        case LineColourArray[LineTypeColourIndex.title.rawValue].toHexString():
                            // so we should have one or less title
                            
                            //print( "line \(lineIdx) Title" )
                            if( title == "no title" )
                            {
                                title = (plainText?.stringByRemovingCharactersInSet(acceptableProperSet.inverted))!
                                doc?._title = title
                            }
                            else
                            {
                                error = "only one title is allowed"
                                break
                            }
                            break
                        case LineColourArray[LineTypeColourIndex.artist.rawValue].toHexString():
                            // so we should have one or less artist
                            
                            //print( "line \(lineIdx) Artist" )
                            if( artist == "no artist" )
                            {
                                artist = (plainText?.stringByRemovingCharactersInSet(acceptableProperSet.inverted))!
                                doc?._artist = artist
                            }
                            else
                            {
                                error = "only one artist line is allowed"
                                break
                            }
                            break
                        case LineColourArray[LineTypeColourIndex.author.rawValue].toHexString():
                            //print( "line \(lineIdx) Author" )
                            
                            if( author == "no author" )
                            {
                                author = (plainText?.stringByRemovingCharactersInSet(acceptableProperSet.inverted))!
                                doc?._author = author
                            }
                            else
                            {
                                error = "only one author line is allowed"
                                break
                            }
                            break
                            
                        case LineColourArray[LineTypeColourIndex.copyright.rawValue].toHexString():
                            //print( "line \(lineIdx) Copyright" )
                            doc?._copyright = plainText?.stringByRemovingCharactersInSet(acceptableProperSet.inverted)
                            break
                        case LineColourArray[LineTypeColourIndex.publisher.rawValue].toHexString():
                            //print( "line \(lineIdx) Publisher" )
                            doc?._publisher = plainText?.stringByRemovingCharactersInSet(acceptableProperSet.inverted)
                            break
                        case LineColourArray[LineTypeColourIndex.memo.rawValue].toHexString():
                            //print( "line \(lineIdx) Memo" )
                            // todo - self._muzDoc._ = lineText.string
                            break
                        case LineColourArray[LineTypeColourIndex.key.rawValue].toHexString():
                            //print( "line \(lineIdx) Key" )
                            doc?._key = plainText
                            break
                        case LineColourArray[LineTypeColourIndex.tempo.rawValue].toHexString():
                            //print( "line \(lineIdx) Tempo" )
                            doc?._tempo = plainText
                            break
                        case LineColourArray[LineTypeColourIndex.timeSig.rawValue].toHexString():
                            //print( "line \(lineIdx) TimeSig" )
                            doc?._timeSignature = plainText
                            break
                            
                        default:
                            //print( "line \(lineIdx) Unknown type" )
                            break
                        }
                    }
                    else
                    {
                        //print( "line \(lineIdx) ")
                    }
                    
                    if( error != "" )
                    {
                        error = "Error at line \(lineIdx+1) - " + error
                        break
                    }
                }
            }
            
            // add the last residual lines if necessary
            if( self.gotLyricLine )
            {
                self.addLyricLine(doc, lineNumber: songLineIdx, text: lyricLine)
            }
            
            if( self.gotChordLine )
            {
                self.addChordLine(doc, lineNumber: songLineIdx, chords: chordLine)
            }
            
            self.removeImportingSpinnerView()
            
            if( error != "" )
            {
                let alert = UIAlertController(title: "Error", message: error, preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                    //print("Error importing text")
                    
                }))
                
                self.present(alert, animated: true, completion: nil)
            }
            else
            {
                // might be changing title and artist here, so directory would change
                
                doc?.setOriginalURLForArtwork(originalArtURL)
                doc?.setOriginalURLForGuideTrack(originalGuideURL)
                
                // search for to refresh unwindFromNewDocCreateClicked
                let newDocController = self.storyboard?.instantiateViewController(withIdentifier: "CreateNewDocViewController") as? CreateNewDocViewController
                newDocController!.isUpdateExisting = self.importingExistingDoc
                if( self.importingExistingDoc )
                {
                    newDocController!._originalTitle = self._originalTitle
                    newDocController!._originalArtist = self._originalArtist
                }
                newDocController!._newDoc = doc
                self.navigationController?.pushViewController(newDocController!, animated: true)
            }
        })
    }
    
    @IBAction func cancelPress(_ sender: AnyObject) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func displayFileExporter( _ src:URL )
    {
        let documentPicker: UIDocumentPickerViewController = UIDocumentPickerViewController(url: src, /*documentTypes: [kUTTypeRTF as String],*/ in: UIDocumentPickerMode.exportToService)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    @IBAction func importTextFromFile(_ sender: AnyObject) {
        displayFilePicker()
    }
    
    // shows a file picker ...
    
    func displayFilePicker()
    {
        let documentPicker: UIDocumentPickerViewController = UIDocumentPickerViewController(documentTypes: [kUTTypePlainText as String, kUTTypeRTF as String, kUTTypeRTFD as String, kUTTypeText as String, "com.Muzoma.customUTIHandler.pro"], in: UIDocumentPickerMode.import)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL)
    {
        //if( controller.documentPickerMode == UIDocumentPickerMode.exportToService )
        
        if( controller.documentPickerMode == UIDocumentPickerMode.import )
        {
            let fileExt = url.pathExtension
            if( fileExt == "pro" || fileExt == "crd" || fileExt == "cho" || fileExt == "chrpro" || fileExt == "chordpro" || fileExt == "chopro") // chord pro import
            {
                importProFromURL( url )
            }
            else if( fileExt == "txt" || fileExt == "rtf" ) // text file
            {
                importTextFromURL( url )
            }
        }
    }
    
    var boxView:UIView! = nil
    func addImportingSpinnerView() {
        // You only need to adjust this frame to move it anywhere you want
        if( boxView == nil )
        {
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
    }
    
    func removeImportingSpinnerView()
    {
        if( self.boxView != nil )
        {
            self.boxView.isHidden = true
            self.boxView.removeFromSuperview()
            boxView = nil
        }
    }
    
    @IBAction func offTypeClicked(_ sender: AnyObject) {
        self._textView.markOff()
    }
    
    
    @IBAction func splitClicked(_ sender: AnyObject) {
        self.splitLines()
    }
    
    @IBAction func lyricsTypeClicked(_ sender: AnyObject) {
        markLyric()
    }
    
    @IBAction func chordTypeClicked(_ sender: AnyObject) {
        markChord()
    }
    
    @IBAction func sectionTypeClicked(_ sender: AnyObject) {
        markSection()
    }
    
    @IBAction func titleTypeClicked(_ sender: AnyObject) {
        markTitle()
    }
    
    @IBAction func artistTypeClicked(_ sender: AnyObject) {
        markArtist()
    }
    
    @IBAction func authorTypeClicked(_ sender: AnyObject) {
        markAuthor()
    }
    
    @IBAction func copyrightTypeClicked(_ sender: AnyObject) {
        markCopyright()
    }
    
    @IBAction func publisherTypeClicked(_ sender: AnyObject) {
        markPublisher()
    }
    
    @IBAction func memoTypeClicked(_ sender: AnyObject) {
        markMemo()
    }
    
    @IBAction func keyTypeClicked(_ sender: AnyObject) {
        markKey()
    }
    
    @IBAction func tempoTypeClicked(_ sender: AnyObject) {
        markTempo()
    }
    
    @IBAction func timeSigTypeClicked(_ sender: AnyObject) {
        markTimeSig()
    }
    
    func getLineTypeFromColor( _ bgCol:UIColor ) -> LineTypeColourIndex
    {
        let col = bgCol.toHexString()
        var ret:LineTypeColourIndex = LineTypeColourIndex.none
        switch( col )
        {
        case LineColourArray[LineTypeColourIndex.lyrics.rawValue].toHexString():
            ret = .lyrics
            break;
        case LineColourArray[LineTypeColourIndex.chords.rawValue].toHexString():
            ret = .chords
            break;
        case LineColourArray[LineTypeColourIndex.section.rawValue].toHexString():
            ret = .chords
            break;
        case LineColourArray[LineTypeColourIndex.title.rawValue].toHexString():
            ret = .chords
            break;
        case LineColourArray[LineTypeColourIndex.artist.rawValue].toHexString():
            ret = .chords
            break;
        case LineColourArray[LineTypeColourIndex.copyright.rawValue].toHexString():
            ret = .chords
            break;
        case LineColourArray[LineTypeColourIndex.publisher.rawValue].toHexString():
            ret = .chords
            break;
        case LineColourArray[LineTypeColourIndex.memo.rawValue].toHexString():
            ret = .chords
            break;
        case LineColourArray[LineTypeColourIndex.key.rawValue].toHexString():
            ret = .chords
            break;
        case LineColourArray[LineTypeColourIndex.tempo.rawValue].toHexString():
            ret = .chords
            break;
        case LineColourArray[LineTypeColourIndex.timeSig.rawValue].toHexString():
            ret = .chords
            break;
        default:
            break;
        }
        return( ret )
    }
    
    internal enum markType
    {
        case off
        case lyric
        case chord
        case section
        case title
        case artist
        case copyright
        case publisher
        case memo
        case key
        case tempo
        case timeSig
    }
    
    func mark( _ backColor:UIColor, foreColor:UIColor = UIColor.white, fontSize:CGFloat = 18.0, bold:Bool = false, ignoreCursor:Bool = false )
    {
        // store the current cursor selection in the text view
        let curSel = self._textView.selectedRange
        let originalScrollPos = self._textViewContainer.contentOffset
        
        self._textView.mark( backColor, foreColor: foreColor, fontSize: fontSize, bold: bold )
        
        if( !ignoreCursor )
        {
            self._textViewContainer.setContentOffset(originalScrollPos, animated: false)
            self._textView.selectedRange = curSel
        }
    }
    
    func splitLines()
    {
        // store the current cursor selection in the text view
        let curSel = self._textView.selectedRange
        let originalScrollPos = self._textViewContainer.contentOffset
        
        let lineRangeSelected = self._textView.getLineRangeFromSelectedPos()
        let selLineNum  = self._textView.getLineNumberFromSelectedPos()
        let lineCount = self._textView.getLineCount()
        
        var prevLineRange = NSRange()
        if( selLineNum > 0 )
        {
            prevLineRange = self._textView.getRangeForLineIndex(selLineNum-1)
        }
        
        var nextLineRange = NSRange()
        if( selLineNum <= lineCount )
        {
            nextLineRange = self._textView.getRangeForLineIndex(selLineNum+1)
        }
        
        let attrText = self._textView.attributedText
        
        //print( "curr songline \(songLineIdx), line \(lineIdx) - \(lineText)" )
        
        var splitIdx = -1
        
        var lineType = LineTypeColourIndex.none
        var lineText:NSAttributedString = NSAttributedString()
        // blank line?
        if( lineRangeSelected.length > 0)
        {
            lineText = (attrText?.attributedSubstring(from: lineRangeSelected))!
            let bgCol = lineText.attribute(NSAttributedString.Key.backgroundColor, at: 0, effectiveRange: nil)
            
            if( bgCol != nil && bgCol is UIColor )
            {
                lineType = getLineTypeFromColor( bgCol as! UIColor )
            }
            splitIdx = curSel.location - lineRangeSelected.location
        }
        
        var prevLineType = LineTypeColourIndex.none
        var prevLineText:NSAttributedString = NSAttributedString()
        if( prevLineRange.length > 0)
        {
            prevLineText = (attrText?.attributedSubstring(from: prevLineRange))!
            let bgCol = prevLineText.attribute(NSAttributedString.Key.backgroundColor, at: 0, effectiveRange: nil)
            
            if( bgCol != nil && bgCol is UIColor )
            {
                prevLineType = getLineTypeFromColor( bgCol as! UIColor )
            }
        }
        
        var nextLineType = LineTypeColourIndex.none
        var nextLineText:NSAttributedString = NSAttributedString()
        if( nextLineRange.length > 0)
        {
            nextLineText = (attrText?.attributedSubstring(from: nextLineRange))!
            let bgCol = nextLineText.attribute(NSAttributedString.Key.backgroundColor, at: 0, effectiveRange: nil)
            
            if( bgCol != nil && bgCol is UIColor )
            {
                nextLineType = getLineTypeFromColor( bgCol as! UIColor )
            }
        }
        
        //print( "split index \(splitIdx) line type \(lineType), prev line type \(prevLineType), next line type \(nextLineType)")
        
        if( splitIdx > -1 && lineType != .none )
        {
            //print( "processing line.." )
            
            if( lineType == .lyrics )
            {
                // has it got chords above?
                if( prevLineType == .chords )
                {
                    let newChordLineText = prevLineText.string.trimmingCharacters( in: newLineSet )
                    let modChordLineText = NSMutableAttributedString(string: newChordLineText)
                    let rangePrev = NSMakeRange(0, modChordLineText.string.count )
                    modChordLineText.addAttribute(NSAttributedString.Key.backgroundColor, value: LineColourArray[LineTypeColourIndex.chords.rawValue], range: rangePrev )
                    modChordLineText.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white, range: rangePrev )
                    prevLineText = modChordLineText
                    
                    let newLyricText = lineText.string.trimmingCharacters( in: newLineSet )
                    let modLyricText = NSMutableAttributedString(string: newLyricText)
                    let rangeLine = NSMakeRange(0, modLyricText.string.count )
                    modLyricText.addAttribute(NSAttributedString.Key.backgroundColor, value: LineColourArray[LineTypeColourIndex.lyrics.rawValue], range: rangeLine )
                    modLyricText.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white, range: rangeLine )
                    lineText = modLyricText
                    
                    // make same length
                    let padCnt = max( prevLineText.string.count, lineText.string.count )
                    
                    if( prevLineText.string.count < padCnt ) // extend the chords
                    {
                        let pad:String = "".padding( toLength: padCnt - prevLineText.string.count, withPad: " ", startingAt: 0)
                        var newStrText = prevLineText.string
                        newStrText.append(pad)
                        let modlineText = NSMutableAttributedString(string: newStrText)
                        prevLineText = modlineText
                    }
                    else if( lineText.string.count < padCnt ) // extend the lyrics
                    {
                        let pad:String = "".padding(toLength: padCnt - lineText.string.count, withPad: " ", startingAt: 0)
                        var newStrText = lineText.string
                        newStrText.append(pad)
                        let modlineText = NSMutableAttributedString(string: newStrText)
                        lineText = modlineText
                    }
                    
                    if( splitIdx < padCnt ) // sometimes we are at the end of a line with the cursor
                    {
                        // both lines are same length now
                        // split
                        let preSplit = NSMakeRange(0, splitIdx )
                        let postSplit = NSMakeRange(splitIdx, lineText.string.count - splitIdx )
                        
                        // split into four lines, and add back the new line
                        
                        let line1 =  (prevLineText.mutableCopy() as! NSMutableAttributedString)
                        if( postSplit.length > 0 )
                        {
                            line1.deleteCharacters(in: postSplit)
                        }
                        line1.append( NSAttributedString(string: "\n") )
                        let rangeline1 = NSMakeRange(0, line1.string.count )
                        line1.addAttribute(NSAttributedString.Key.font, value: UIFont(name:"Courier", size: 18 )!, range: rangeline1 )
                        line1.addAttribute(NSAttributedString.Key.backgroundColor, value: LineColourArray[LineTypeColourIndex.chords.rawValue], range: rangeline1 )
                        line1.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white, range: rangeline1 )
                        
                        let line2 =  (lineText.mutableCopy() as! NSMutableAttributedString)
                        if( postSplit.length > 0 )
                        {
                            line2.deleteCharacters(in: postSplit)
                        }
                        line2.append( NSAttributedString(string: "\n") )
                        let rangeline2 = NSMakeRange(0, line2.string.count )
                        line2.addAttribute(NSAttributedString.Key.font, value: UIFont(name:"Courier", size: 18 )!, range: rangeline2 )
                        line2.addAttribute(NSAttributedString.Key.backgroundColor, value: LineColourArray[LineTypeColourIndex.lyrics.rawValue], range: rangeline2 )
                        line2.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white, range: rangeline2 )
                        
                        let line3 =  (prevLineText.mutableCopy() as! NSMutableAttributedString)
                        if( preSplit.length > 0 )
                        {
                            line3.deleteCharacters(in: preSplit)
                        }
                        line3.append( NSAttributedString(string: "\n") )
                        let rangeline3 = NSMakeRange(0, line3.string.count )
                        line3.addAttribute(NSAttributedString.Key.font, value: UIFont(name:"Courier", size: 18 )!, range: rangeline3 )
                        line3.addAttribute(NSAttributedString.Key.backgroundColor, value: LineColourArray[LineTypeColourIndex.chords.rawValue], range: rangeline3 )
                        line3.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white, range: rangeline3 )
                        
                        let line4 = (lineText.mutableCopy() as! NSMutableAttributedString)
                        if( preSplit.length > 0 )
                        {
                            line4.deleteCharacters(in: preSplit)
                        }
                        line4.append( NSAttributedString(string: "\n") )
                        let rangeline4 = NSMakeRange(0, line4.string.count )
                        line4.addAttribute(NSAttributedString.Key.font, value: UIFont(name:"Courier", size: 18 )!, range: rangeline4 )
                        line4.addAttribute(NSAttributedString.Key.backgroundColor, value: LineColourArray[LineTypeColourIndex.lyrics.rawValue], range: rangeline4 )
                        line4.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white, range: rangeline4 )
                        
                        // merge lines and subst into the original range
                        let originalTextMod = self._textView.attributedText.mutableCopy() as! NSMutableAttributedString
                        
                        // delete the original lines
                        let replaceStr = NSMutableAttributedString()
                        replaceStr.append( line1 )
                        replaceStr.append( line2 )
                        replaceStr.append( line3 )
                        replaceStr.append( line4 )
                        
                        let delRange = NSMakeRange(prevLineRange.location, min( prevLineRange.length + rangeLine.length + 1, originalTextMod.length ) )
                        originalTextMod.replaceCharacters(in: delRange, with: replaceStr)
                        self._textView.attributedText = originalTextMod
                        
                        //print( "line 1:\(line1.string)\nline 2:\(line2.string)\nline 3:\(line3.string)\nline 4:\(line4.string)" )
                    }
                }
            }
            else if( lineType == .chords )
            {
                if( nextLineType == .lyrics )
                {
                    let newLyricLineText = nextLineText.string.trimmingCharacters( in: newLineSet )
                    let modLyricLineText = NSMutableAttributedString(string: newLyricLineText)
                    let rangeNext = NSMakeRange(0, modLyricLineText.string.count )
                    modLyricLineText.addAttribute(NSAttributedString.Key.backgroundColor, value: LineColourArray[LineTypeColourIndex.lyrics.rawValue], range: rangeNext )
                    modLyricLineText.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white, range: rangeNext )
                    nextLineText = modLyricLineText
                    
                    let newChordText = lineText.string.trimmingCharacters( in: newLineSet )
                    let modChordText = NSMutableAttributedString(string: newChordText)
                    let rangeLine = NSMakeRange(0, modChordText.string.count )
                    modChordText.addAttribute(NSAttributedString.Key.backgroundColor, value: LineColourArray[LineTypeColourIndex.chords.rawValue], range: rangeLine )
                    modChordText.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white, range: rangeLine )
                    lineText = modChordText
                    
                    // make same length
                    let padCnt = max( nextLineText.string.count, lineText.string.count )
                    
                    if( nextLineText.string.count < padCnt ) // extend the lyrics
                    {
                        let pad:String = "".padding( toLength: padCnt - nextLineText.string.count, withPad: " ", startingAt: 0)
                        var newStrText = nextLineText.string
                        newStrText.append(pad)
                        let modlineText = NSMutableAttributedString(string: newStrText)
                        nextLineText = modlineText
                    }
                    else if( lineText.string.count < padCnt ) // extend the chords
                    {
                        let pad:String = "".padding(toLength: padCnt - lineText.string.count, withPad: " ", startingAt: 0)
                        var newStrText = lineText.string
                        newStrText.append(pad)
                        let modlineText = NSMutableAttributedString(string: newStrText)
                        lineText = modlineText
                    }
                    
                    if( splitIdx < padCnt ) // sometimes we are at the end of a line with the cursor
                    {
                        // both lines are same length now
                        // split
                        let preSplit = NSMakeRange( 0, splitIdx )
                        let postSplit = NSMakeRange(splitIdx, lineText.string.count - splitIdx )
                        
                        // split into four lines, and add back the new line
                        
                        let line1 =  (lineText.mutableCopy() as! NSMutableAttributedString)
                        if( postSplit.length > 0 )
                        {
                            line1.deleteCharacters(in: postSplit)
                        }
                        line1.append( NSAttributedString(string: "\n") )
                        let rangeline1 = NSMakeRange(0, line1.string.count )
                        line1.addAttribute(NSAttributedString.Key.font, value: UIFont(name:"Courier", size: 18 )!, range: rangeline1 )
                        line1.addAttribute(NSAttributedString.Key.backgroundColor, value: LineColourArray[LineTypeColourIndex.chords.rawValue], range: rangeline1 )
                        line1.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white, range: rangeline1 )
                        
                        let line2 =  (nextLineText.mutableCopy() as! NSMutableAttributedString)
                        if( postSplit.length > 0 )
                        {
                            line2.deleteCharacters(in: postSplit)
                        }
                        line2.append( NSAttributedString(string: "\n") )
                        let rangeline2 = NSMakeRange(0, line2.string.count )
                        line2.addAttribute(NSAttributedString.Key.font, value: UIFont(name:"Courier", size: 18 )!, range: rangeline2 )
                        line2.addAttribute(NSAttributedString.Key.backgroundColor, value: LineColourArray[LineTypeColourIndex.lyrics.rawValue], range: rangeline2 )
                        line2.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white, range: rangeline2 )
                        
                        let line3 = (lineText.mutableCopy() as! NSMutableAttributedString)
                        if( preSplit.length > 0 )
                        {
                            line3.deleteCharacters(in: preSplit)
                        }
                        line3.append( NSAttributedString(string: "\n") )
                        let rangeline3 = NSMakeRange(0, line3.string.count )
                        line3.addAttribute(NSAttributedString.Key.font, value: UIFont(name:"Courier", size: 18 )!, range: rangeline3 )
                        line3.addAttribute(NSAttributedString.Key.backgroundColor, value: LineColourArray[LineTypeColourIndex.chords.rawValue], range: rangeline3 )
                        line3.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white, range: rangeline3 )
                        
                        let line4 =  (nextLineText.mutableCopy() as! NSMutableAttributedString)
                        if( preSplit.length > 0 )
                        {
                            line4.deleteCharacters(in: preSplit)
                        }
                        line4.append( NSAttributedString(string: "\n") )
                        let rangeline4 = NSMakeRange(0, line4.string.count )
                        line4.addAttribute(NSAttributedString.Key.font, value: UIFont(name:"Courier", size: 18 )!, range: rangeline4 )
                        line4.addAttribute(NSAttributedString.Key.backgroundColor, value: LineColourArray[LineTypeColourIndex.lyrics.rawValue], range: rangeline4 )
                        line4.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white, range: rangeline4 )
                        
                        // merge lines and subst into the original range
                        let originalTextMod = self._textView.attributedText.mutableCopy() as! NSMutableAttributedString
                        
                        // delete the original lines
                        let replaceStr = NSMutableAttributedString()
                        replaceStr.append( line1 )
                        replaceStr.append( line2 )
                        replaceStr.append( line3 )
                        replaceStr.append( line4 )
                        
                        let delRange = NSMakeRange(lineRangeSelected.location, min( nextLineRange.length + lineRangeSelected.length, originalTextMod.length ) )
                        originalTextMod.replaceCharacters(in: delRange, with: replaceStr)
                        self._textView.attributedText = originalTextMod
                        
                        //print( "line 1:\(line1.string)\nline 2:\(line2.string)\nline 3:\(line3.string)\nline 4:\(line4.string)" )
                    }
                }
            }
            
            self._textView.selectedRange = curSel
            self._textViewContainer.contentOffset = originalScrollPos
            self._textViewContainer.resizeTextView()
        }
    }
    
    @objc func markSplit()
    {
        self.splitLines()
    }
    
    @objc func markOff()
    {
        _textView.markOff()
    }
    
    @objc func markLyric( _ ignoreCursor:Bool = false )
    {
        self.mark( LineColourArray[LineTypeColourIndex.lyrics.rawValue], fontSize: 18.0, bold: false, ignoreCursor:ignoreCursor )
    }
    
    @objc func markChord( _ ignoreCursor:Bool = false )
    {
        self.mark( LineColourArray[LineTypeColourIndex.chords.rawValue], fontSize: 18.0, bold: false, ignoreCursor:ignoreCursor )
    }
    
    @objc func markSection( _ ignoreCursor:Bool = false )
    {
        self.mark( LineColourArray[LineTypeColourIndex.section.rawValue], fontSize: 20.0, bold: true, ignoreCursor:ignoreCursor  )
    }
    
    @objc func markTitle( _ ignoreCursor:Bool = false )
    {
        self.mark( LineColourArray[LineTypeColourIndex.title.rawValue], fontSize: 24.0, bold: true, ignoreCursor:ignoreCursor )
    }
    
    @objc func markArtist( _ ignoreCursor:Bool = false )
    {
        self.mark( LineColourArray[LineTypeColourIndex.artist.rawValue], fontSize: 22.0, bold: true, ignoreCursor:ignoreCursor  )
    }
    
    @objc func markAuthor( _ ignoreCursor:Bool = false )
    {
        self.mark( LineColourArray[LineTypeColourIndex.author.rawValue], fontSize: 22.0, bold: true, ignoreCursor:ignoreCursor   )
    }
    
    @objc func markCopyright( _ ignoreCursor:Bool = false )
    {
        self.mark( LineColourArray[LineTypeColourIndex.copyright.rawValue], fontSize: 20.0, bold: false, ignoreCursor:ignoreCursor )
    }
    
    @objc func markPublisher( _ ignoreCursor:Bool = false )
    {
        self.mark( LineColourArray[LineTypeColourIndex.publisher.rawValue], fontSize: 20.0, bold: false, ignoreCursor:ignoreCursor  )
    }
    
    @objc func markMemo( _ ignoreCursor:Bool = false )
    {
        self.mark( LineColourArray[LineTypeColourIndex.memo.rawValue], fontSize: 18.0, bold: false, ignoreCursor:ignoreCursor  )
    }
    
    @objc func markKey( _ ignoreCursor:Bool = false )
    {
        self.mark( LineColourArray[LineTypeColourIndex.key.rawValue], fontSize: 20.0, bold: false, ignoreCursor:ignoreCursor   )
    }
    
    @objc func markTempo( _ ignoreCursor:Bool = false )
    {
        self.mark( LineColourArray[LineTypeColourIndex.tempo.rawValue], fontSize: 20.0, bold: false, ignoreCursor:ignoreCursor   )
    }
    
    @objc func markTimeSig( _ ignoreCursor:Bool = false )
    {
        self.mark( LineColourArray[LineTypeColourIndex.timeSig.rawValue], fontSize: 20.0, bold: false, ignoreCursor:ignoreCursor   )
    }
    
    func importProFromURL( _ url:URL )
    {
        let fileName = url.lastPathComponent
        let fileExt = url.pathExtension
        
        self._textView?.text = "importing the chord pro file \(fileName), please wait..."
        self._textView?.setNeedsDisplay()
        self.addImportingSpinnerView()
        
        // long running, so dispatch it
        DispatchQueue.main.async(execute: {
            
            if( url.isFileURL )
            {
                do
                {
                    var atStr:NSMutableAttributedString = self._textView.attributedText.mutableCopy() as! NSMutableAttributedString
                    
                    // reset the text view
                    self.clearView()
                    
                    if(  fileExt == "txt" || fileExt == "pro" || fileExt == "crd" || fileExt == "cho" || fileExt == "chrpro" || fileExt == "chordpro" || fileExt == "chopro")
                    {
                        let proString = try String.init(contentsOf: url)
                        Logger.log("got pro string:\n \(proString)")
                        // get an array of lines
                        var lineIdx = 0
                        proString.enumerateLines{ (line, stop) -> () in
                            
                            
                            var cleanLine = line.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                            //print(cleanLine)
                            
                            if( !cleanLine.hasPrefix("#") ) // ignore comment
                            {
                                if( cleanLine.hasPrefix("{") && cleanLine.hasSuffix("}") ) // pro directive coming
                                {
                                    cleanLine.remove(at: cleanLine.index(before: cleanLine.endIndex)) // clear the last }
                                    
                                    /*{title: title string} ({t:string})
                                     Specifies the title of the song. The title is used to sort the songs in the user interface. It appears at the top of the song, centered, and may be repeated if the song overflows onto a new column.*/
                                    if( cleanLine.hasPrefix("{title:") ||  cleanLine.hasPrefix("{t:") )
                                    {
                                        let titleStr = cleanLine.replacingOccurrences(of: "{title:", with: "").replacingOccurrences(of: "{t:", with: "")
                                        
                                        atStr = self._textView.attributedText.mutableCopy() as! NSMutableAttributedString
                                        let x = NSAttributedString(string: titleStr)
                                        atStr.append(x)
                                        atStr.append(newLineUAttStr)
                                        self._textView.attributedText = atStr
                                        _ = self._textView.setSelectedLine(lineIdx)
                                        self.markTitle(true)
                                        lineIdx += 1
                                    } else
                                        /*{subtitle: subtitle string} ({su:string})
                                         Specifies a subtitle for the song. This string will be printed just below the title string.
                                         */
                                        if( cleanLine.hasPrefix("{subtitle:") || cleanLine.hasPrefix("{su:") || cleanLine.hasPrefix("{st:") )
                                        {
                                            let subTitleStr = cleanLine.replacingOccurrences(of: "{subtitle:", with: "").replacingOccurrences(of: "{su:", with: "")
                                                .replacingOccurrences(of: "{st:", with: "")
                                            
                                            atStr = self._textView.attributedText.mutableCopy() as! NSMutableAttributedString
                                            atStr.append(NSAttributedString(string: subTitleStr))
                                            atStr.append(newLineUAttStr)
                                            self._textView.attributedText = atStr
                                            _ = self._textView.setSelectedLine(lineIdx)
                                            self.markArtist(true)
                                            lineIdx += 1
                                        } else
                                            /*{comment: string} ({c:string})
                                             Prints the string following the colon as a comment.*/
                                            if(cleanLine.hasPrefix("{comment:") || cleanLine.hasPrefix("{c:") )
                                            {
                                                let commentStr = cleanLine.replacingOccurrences(of: "{comment:", with: "").replacingOccurrences(of: "{c:", with: "")
                                                
                                                atStr = self._textView.attributedText.mutableCopy() as! NSMutableAttributedString
                                                atStr.append(NSAttributedString(string: commentStr))
                                                atStr.append(newLineUAttStr)
                                                self._textView.attributedText = atStr
                                                _ = self._textView.setSelectedLine(lineIdx)
                                                let lowerstr = commentStr.lowercased()
                                                if( lowerstr.contains("auth") ) // author?
                                                {
                                                    self.markAuthor(true)
                                                }
                                                else if( lowerstr.contains("copyright") || lowerstr.contains("(c)") || lowerstr.contains("©") ) // copyright?
                                                {
                                                    self.markCopyright(true)
                                                }
                                                else if( lowerstr.contains("publish") ) // publisher?
                                                {
                                                    self.markPublisher(true)
                                                }
                                                else
                                                {
                                                    self.markMemo(true)
                                                }
                                                lineIdx += 1
                                            } else
                                                /*{guitar_comment: string} ({gc:string})
                                                 Prints the string following the colon as a comment. This comment will only be printed if chords are also printed; it should be used for comments to performers, or for other notes that are unneccessary for lyrics-only song sheets (or projection).*/
                                                if(cleanLine.hasPrefix("{guitar_comment:") || cleanLine.hasPrefix("{gc:") )
                                                {
                                                    let commentStr = cleanLine.replacingOccurrences(of: "{guitar_comment:", with: "").replacingOccurrences(of: "{gc:", with: "")
                                                    
                                                    atStr = self._textView.attributedText.mutableCopy() as! NSMutableAttributedString
                                                    atStr.append(NSAttributedString(string: commentStr))
                                                    atStr.append(newLineUAttStr)
                                                    self._textView.attributedText = atStr
                                                    _ = self._textView.setSelectedLine(lineIdx)
                                                    self.markMemo(true)
                                                    lineIdx += 1
                                                    
                                                } else
                                                    /* {key: xyz} ({k:xyz})
                                                     Key the chart is written in; xyz is a valid key; transposition will apply.
                                                     Note: this is a Songsheet Generator extension to the standard syntax.*/
                                                    if(cleanLine.hasPrefix("{key:") || cleanLine.hasPrefix("{k:") )
                                                    {
                                                        let keyStr = cleanLine.replacingOccurrences(of: "{key:", with: "").replacingOccurrences(of: "{k:", with: "")
                                                        
                                                        atStr = self._textView.attributedText.mutableCopy() as! NSMutableAttributedString
                                                        atStr.append(NSAttributedString(string: keyStr))
                                                        atStr.append(newLineUAttStr)
                                                        self._textView.attributedText = atStr
                                                        _ = self._textView.setSelectedLine(lineIdx)
                                                        self.markKey(true)
                                                        lineIdx += 1
                                                    } else
                                                        /* {start_of_part: xyz} ({sop:xyz})
                                                         indicates the start of a specific part of the song, for example “Verse 1″ or “Bridge”. Like the {start_of_chorus} directive, all lines until {end_of_part} will be indented.
                                                         Additional parameters
                                                         Additional parameters can be supplied to indicate whether the part is only for guitar, how many times it is directly repeated, and if it should use chords from a previously defined part.
                                                         
                                                         Examples:
                                                         
                                                         {sop:Verse 1}
                                                         Indicates the start of Verse 1 without any additional parameters
                                                         
                                                         {sop:Intro guitar_only}
                                                         Causes the part only to be displayed if chords are being displayed
                                                         
                                                         {sop:Bridge repeat 4x}
                                                         Causes the Bridge’s title to be displayed as “Bridge 4x”; in a future GuitarTapp release will also be used for autoscroll timing
                                                         
                                                         {sop:Verse 2 chords_like Verse 1}
                                                         Causes Verse 2′s chords to be automatically filled in using Verse 1′s chords
                                                         
                                                         {sop:Solo guitar_only chords_like Intro repeat 2x}
                                                         Causes the solo only to be displayed when chords are being displayed, the chords defined in the Intro part to be used, and the Solo’s title to be displayed as “Solo 2x”
                                                         
                                                         */
                                                        if(cleanLine.hasPrefix("{start_of_part:") || cleanLine.hasPrefix("{sop:") )
                                                        {
                                                            let partStr = cleanLine.replacingOccurrences(of: "{start_of_part:", with: "").replacingOccurrences(of: "{sop:", with: "")
                                                            
                                                            atStr = self._textView.attributedText.mutableCopy() as! NSMutableAttributedString
                                                            // insert empty line above section
                                                            atStr.append(newLineUAttStr)
                                                            lineIdx += 1
                                                            
                                                            atStr.append(NSAttributedString(string: partStr))
                                                            atStr.append(newLineUAttStr)
                                                            self._textView.attributedText = atStr
                                                            _ = self._textView.setSelectedLine(lineIdx)
                                                            self.markSection(true)
                                                            lineIdx += 1
                                                        } else
                                                            /* {start_of_chorus: xyz} ({soc: xyz})
                                                             */
                                                            if(cleanLine.hasPrefix("{start_of_chorus:") || cleanLine.hasPrefix("{soc:") )
                                                            {
                                                                let partStr = cleanLine.replacingOccurrences(of: "{start_of_chorus:", with: "").replacingOccurrences(of: "{soc:", with: "")
                                                                
                                                                atStr = self._textView.attributedText.mutableCopy() as! NSMutableAttributedString
                                                                
                                                                // insert empty line above section
                                                                atStr.append(newLineUAttStr)
                                                                lineIdx += 1
                                                                atStr.append(NSAttributedString(string: partStr.count > 1 ? partStr : "Chorus"))
                                                                atStr.append(newLineUAttStr)
                                                                self._textView.attributedText = atStr
                                                                _ = self._textView.setSelectedLine(lineIdx)
                                                                self.markSection(true)
                                                                lineIdx += 1
                                                            } else
                                                                /* {define: <chord>..
                                                                 base-fret <base>..
                                                                 frets <Low-E> <A> <D>..
                                                                 <G> <B> <E>}
                                                                 
                                                                 Defines a chord, its diagram will be shown underneith the song’s title. A little confusing about this ChordPro directive is the base-fret: for open chords it’s 1, not 0 as one might expect. Fret number 1 for a string indicates the base-fret is played, allowing for barre-chords with open strings being defined.
                                                                 Examples:
                                                                 Open Am chord:
                                                                 {define:Am base-fret..
                                                                 1 frets x 0 2 2 1 0}
                                                                 Barre F:
                                                                 {define:F base-fret 1..
                                                                 frets 1 3 3 2 1 1}
                                                                 Barre D/A:
                                                                 {define:D/A base-fret..
                                                                 5 frets 1 1 3 3 3 1}
                                                                 C#sus with open strings:
                                                                 {define:C#sus base-fret..
                                                                 4 frets x 1 3 3 0 0}
                                                                 
                                                                 */
                                                                if(cleanLine.hasPrefix("{define:")  )
                                                                {
                                                                    //let chordStr = cleanLine.stringByReplacingOccurrencesOfString("{define:", withString: "")
                                                                    
                                                                    /*
                                                                     atStr = self._textView.attributedText.mutableCopy() as! NSMutableAttributedString
                                                                     atStr.appendAttributedString(NSAttributedString(string: partStr.characters.count > 1 ? partStr : "Chorus"))
                                                                     atStr.appendAttributedString(self.newLineUAttStr)
                                                                     self._textView.attributedText = atStr
                                                                     self.setSelectedLine(lineIdx)
                                                                     self.markSection(true)
                                                                     lineIdx += 1*/
                                                                } else
                                                                    /* {tempo: xyz}
                                                                     Defines the song tempo in bpm. A tempo sign will be drawn at this particular location.
                                                                     */
                                                                    if(cleanLine.hasPrefix("{tempo:") )
                                                                    {
                                                                        let inlineStr = cleanLine.replacingOccurrences(of: "{tempo:", with: "")
                                                                        
                                                                        atStr = self._textView.attributedText.mutableCopy() as! NSMutableAttributedString
                                                                        atStr.append(NSAttributedString(string: inlineStr))
                                                                        atStr.append(newLineUAttStr)
                                                                        self._textView.attributedText = atStr
                                                                        _ = self._textView.setSelectedLine(lineIdx)
                                                                        self.markTempo(true)
                                                                        lineIdx += 1
                                                                    } else
                                                                        /* {time: xyz}
                                                                         Defines the song’s time signature, like 3/4 or 6/8. The signature will be displayed using traditional notation.
                                                                         */
                                                                        if(cleanLine.hasPrefix("{time:") )
                                                                        {
                                                                            let inlineStr = cleanLine.replacingOccurrences(of: "{time:", with: "")
                                                                            
                                                                            atStr = self._textView.attributedText.mutableCopy() as! NSMutableAttributedString
                                                                            atStr.append(NSAttributedString(string: inlineStr))
                                                                            atStr.append(newLineUAttStr)
                                                                            self._textView.attributedText = atStr
                                                                            _ = self._textView.setSelectedLine(lineIdx)
                                                                            self.markTimeSig(true)
                                                                            lineIdx += 1
                                                                            
                                                                        } else
                                                                            /* {inline: xyz}
                                                                             */
                                                                            if(cleanLine.hasPrefix("{inline:") )
                                                                            {
                                                                                let inlineStr = cleanLine.replacingOccurrences(of: "{inline:", with: "")
                                                                                
                                                                                atStr = self._textView.attributedText.mutableCopy() as! NSMutableAttributedString
                                                                                atStr.append(NSAttributedString(string: inlineStr))
                                                                                atStr.append(newLineUAttStr)
                                                                                self._textView.attributedText = atStr
                                                                                _ = self._textView.setSelectedLine(lineIdx)
                                                                                self.markLyric(true)
                                                                                lineIdx += 1
                                    }
                                    
                                    
                                    /* the following are ignored for muzoma imports at the moment ...
                                     
                                     
                                     {start_of_tab} ({sot})
                                     Indicates the start of a guitar tab section. The text will be formatted in a fixed-width font until the end_of_tab directive appears. This can be useful for creating a tab drawing with ASCII text. Guitar tab sections will only be printed if chords are also printed.
                                     {end_of_tab} ({eot})
                                     Marks the end of the guitar tab section.
                                     
                                     {new_song} ({ns})
                                     Marks the beginning of a new song. Although this directive will work with the Songsheet Generator program, its use is not recommended, since only the first song in any song file will show up in the "Songs available" list.
                                     {new_page} ({np})
                                     This directive will cause a "cell break" in the Two and Four Discrete Cells per Page printing modes, and a column break in the Two Flowing Columns printing mode. It will cause a physical page break otherwise. It has no effect in the Text and HTML File output destinations.
                                     {new_physical_page} ({npp})
                                     This directive will always force a physical page break. It has no effect in the Text and HTML File output destinations.
                                     {column_break} ({colb})
                                     This directive will force a column break in the Flowing Columns printing modes, which amounts to a physical page break in the One Flowing Column printing mode. It has no effect in the Discrete Cells printing modes, and no effect in the Text and HTML File output destinations.
                                     {data_abc: xyz} ({d_abc:xyz})
                                     Data key and value; abc is the key, xyz is its value.
                                     Note: this is a Songsheet Generator extension to the standard syntax.
                                     {footer: xyz} ({f:xyz})
                                     Footer override for the current song.
                                     Note: this is a Songsheet Generator extension to the standard syntax.
                                     */
                                }
                                else // chord and text content e.g. [C](Why ah ah ah ah[C/B] ah ah ah ah ah [Am]ah) [F] x2
                                {
                                    let lower = cleanLine.lowercased()
                                    // not part of the spec but try to detect the sections
                                    if( lower.count < 10 &&
                                        (
                                            lower.contains( "chorus" )
                                                || lower.contains( "verse" )
                                                || lower.contains( "bridge" )
                                                || lower.contains( "middle" )
                                                || lower.contains( "intro" )
                                                || lower.contains( "break" )
                                                || lower.contains( "outro" )
                                                || lower.contains( "solo" )
                                                || lower.contains( "hook" )
                                                || lower.contains( "reprise" )
                                                || lower.contains( "refrain" )
                                                || lower.contains( "theme" )
                                                || lower.contains( "riff" )
                                                || lower.contains( "motif" )
                                                || lower.contains( "link" )
                                                || lower.contains( "coda" )
                                        ))
                                    {
                                        atStr = self._textView.attributedText.mutableCopy() as! NSMutableAttributedString
                                        // insert empty line above section
                                        atStr.append(newLineUAttStr)
                                        lineIdx += 1
                                        
                                        cleanLine = cleanLine.trimmingCharacters(in: colonSet)
                                        atStr.append(NSAttributedString(string: cleanLine))
                                        atStr.append(newLineUAttStr)
                                        self._textView.attributedText = atStr
                                        _ = self._textView.setSelectedLine(lineIdx)
                                        self.markSection(true)
                                        lineIdx += 1
                                    }
                                    else
                                    {
                                        let sepChordsChars = cleanLine
                                        var inChord = false
                                        var chord = ""
                                        var lyric = ""
                                        var chordSpaceAdj = 1
                                        
                                        for (_, character) in sepChordsChars.enumerated()
                                        {
                                            if( character == "[" )
                                            {
                                                inChord = true
                                            } else if( character == "]" )
                                            {
                                                inChord = false
                                                chordSpaceAdj += 1
                                                chord += " "
                                            } else if( inChord )
                                            {
                                                chord.append( character )
                                                chordSpaceAdj += 1
                                            }
                                            else
                                            {
                                                lyric.append( character )
                                                chordSpaceAdj -= 1
                                                if( chordSpaceAdj < 1 )
                                                {
                                                    chord += " "
                                                    chordSpaceAdj = 1
                                                }
                                            }
                                        }
                                        
                                        //print(lineIdx)
                                        
                                        // make chord and lyric lines the same length
                                        if( lyric.count > chord.count)
                                        {
                                            chord = chord.padding(toLength: lyric.count, withPad: " ", startingAt: 0)
                                        } else if( chord.count > lyric.count)
                                        {
                                            lyric = lyric.padding(toLength: chord.count, withPad: " ", startingAt: 0)
                                        }
                                        
                                        // make string 200 chars long max
                                        let lyricStrings = lyric.split( 200 )
                                        let chordStrings = chord.split( 200 )
                                        
                                        for(idx, chordStr ) in chordStrings.enumerated()
                                        {
                                            atStr = self._textView.attributedText.mutableCopy() as! NSMutableAttributedString
                                            atStr.append(NSAttributedString(string: chordStr))
                                            atStr.append(newLineUAttStr)
                                            self._textView.attributedText = atStr
                                            _ = self._textView.setSelectedLine(lineIdx)
                                            self.markChord(true)
                                            lineIdx += 1
                                            
                                            
                                            let lyricStr = lyricStrings[idx]
                                            atStr = self._textView.attributedText.mutableCopy() as! NSMutableAttributedString
                                            atStr.append(NSAttributedString(string: lyricStr))
                                            atStr.append(newLineUAttStr)
                                            self._textView.attributedText = atStr
                                            _ = self._textView.setSelectedLine(lineIdx)
                                            self.markLyric(true)
                                            lineIdx += 1
                                        }
                                    }
                                }
                            }
                            else
                            {
                                // just a comment / memo
                                cleanLine.remove(at: cleanLine.startIndex)
                                cleanLine = cleanLine.trimmingCharacters(in: whitespaceSet)
                                atStr = self._textView.attributedText.mutableCopy() as! NSMutableAttributedString
                                atStr.append(NSAttributedString(string: cleanLine))
                                atStr.append(newLineUAttStr)
                                self._textView.attributedText = atStr
                                _ = self._textView.setSelectedLine(lineIdx)
                                self.markMemo(true)
                                lineIdx += 1
                            }
                        }
                    }
                    
                    //self._textViewContainer?.resizeTextView()
                    self.removeImportingSpinnerView()
                    
                    try _gFSH.removeItem(at: url)
                    Logger.log("\(#function)  \(#file) Deleted \(url.absoluteString)")
                }
                catch  let error as NSError {
                    self.removeImportingSpinnerView()
                    
                    Logger.log( "Importing text file error \(error.localizedDescription)" )
                    
                    let alert = UIAlertController(title: "Error", message: "File could not be imported \(error.localizedDescription)", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                        print("Error importing text file")
                    }))
                    
                    self.present(alert, animated: true, completion: nil)
                    do
                    {
                        try _gFSH.removeItem(at: url)
                        Logger.log("\(#function)  \(#file) Deleted \(url.absoluteString)")
                    } catch let error as NSError {
                        Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                    }
                }
                
                if( self._textView != nil )
                {
                    self._textView.becomeFirstResponder()
                    let newFont = UIFont(name: "Courier" , size: 18)
                    self._textView.font = newFont
                    self._textView.textAlignment = NSTextAlignment.left
                    self._textView.backgroundColor = UIColor.black
                    self._textView.textColor = UIColor.white
                    self._textView.selectEndOfDoc()
                }
                self._textViewContainer?.resizeTextView()
            }
        })
    }
    
    
    func stripKnownPrefixes( _ text:String ) -> String
    {
        var ret = text.replacingOccurrences(of: "title: ", with: "")
        ret = ret.replacingOccurrences(of: "artist: ", with: "")
        ret = ret.replacingOccurrences(of: "author: ", with: "")
        ret = ret.replacingOccurrences(of: "copyright: ", with: "")
        ret = ret.replacingOccurrences(of: "tempo: ", with: "")
        ret = ret.replacingOccurrences(of: "time signature: ", with: "")
        ret = ret.replacingOccurrences(of: "key: ", with: "")
        
        return( ret )
    }
    
    
    func importTextFromURL( _ url:URL )
    {
        let fileName = url.lastPathComponent //url.pathComponents![((url.pathComponents?.count)!-1)].lowercaseString
        let fileType = url.pathExtension //components[components.count-1]
        
        self.addImportingSpinnerView()
        self._textView?.text = "importing the file \(fileName), please wait..."
        self._textView?.setNeedsDisplay()
        
        // long running, so dispatch it
        DispatchQueue.main.async(execute: {
            var dontProcess = false
            
            if( url.isFileURL )
            {
                do
                {
                    if( fileType == "txt")
                    {
                        let plainString = try String.init(contentsOf: url)
                        
                        if( plainString.localizedCaseInsensitiveContains( "# chordpro") || plainString.localizedCaseInsensitiveContains( "#chordpro") )
                        {
                            dontProcess = true
                            self.importProFromURL( url )
                        }
                        else
                        {
                            self._textView.text = plainString
                        }
                    }
                    else if( fileType == "rtf")
                    {
                        let attributedString = try NSAttributedString(url: url, options: convertToNSAttributedStringDocumentReadingOptionKeyDictionary([convertFromNSAttributedStringDocumentAttributeKey(NSAttributedString.DocumentAttributeKey.documentType):convertFromNSAttributedStringDocumentType(NSAttributedString.DocumentType.rtf)]), documentAttributes:nil )
                        self._textView.attributedText = attributedString
                    }
                    else if( fileType == "rtfd")
                    {
                        let attributedString = try NSAttributedString(url: url, options: convertToNSAttributedStringDocumentReadingOptionKeyDictionary([convertFromNSAttributedStringDocumentAttributeKey(NSAttributedString.DocumentAttributeKey.documentType):convertFromNSAttributedStringDocumentType(NSAttributedString.DocumentType.rtfd)]), documentAttributes: nil)
                        self._textView.attributedText = attributedString
                    }
                    else if( fileType == "htm" || fileType == "html" )
                    {
                        let attributedString = try NSAttributedString(url: url, options: convertToNSAttributedStringDocumentReadingOptionKeyDictionary([convertFromNSAttributedStringDocumentAttributeKey(NSAttributedString.DocumentAttributeKey.documentType):convertFromNSAttributedStringDocumentType(NSAttributedString.DocumentType.html)]), documentAttributes: nil)
                        self._textView.attributedText = attributedString
                    }
                    else
                    {
                        let plainString = try String.init(contentsOf: url)
                        self._textView.text = plainString
                    }
                    
                    //print( "text: \(self._textView.text)" )
                    
                    // remove the formatting
                    if( !dontProcess )
                    {
                        let plainText = self._textView.text
                        self.clearView()
                        self._textView.text = plainText
                    }
                }
                catch let error as NSError {
                    Logger.log("\(#function)  \(#file)  \(error.localizedDescription)")
                    
                    let alert = UIAlertController(title: "Error", message: "File could not be imported \(error.localizedDescription)", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                        print("Error importing text file")
                        
                    }))
                    
                    self.present(alert, animated: true, completion: nil)
                }
                
                if( !dontProcess )
                {
                    var titleDetected:Bool = false
                    var authorDetected:Bool = false
                    var artistDetected:Bool = false
                    var copyrightDetected:Bool = false
                    var publisherDetected:Bool = false
                    var keyDetected:Bool = false
                    var timeSigDetected:Bool = false
                    var tempoDetected:Bool = false
                    
                    var songContentDetected:Bool = false
                    
                    
                    let lineCnt = self._textView.getLineCount()
                    for lineIdx in ( 0 ..< lineCnt )
                    {
                        let text = self._textView.setSelectedLine(lineIdx, returnContent: true)
                        // detect the content
                        
                        var contentTypeDetected:Bool = false
                        if( text != nil )
                        {
                            let lower = text!.lowercased()
                            // could be a section?
                            if( lower.count < 10 )
                            {
                                if( lower.contains( "chorus" )
                                    || lower.contains( "verse" )
                                    || lower.contains( "bridge" )
                                    || lower.contains( "middle" )
                                    || lower.contains( "intro" )
                                    || lower.contains( "break" )
                                    || lower.contains( "outro" )
                                    || lower.contains( "solo" )
                                    || lower.contains( "hook" )
                                    || lower.contains( "reprise" )
                                    || lower.contains( "refrain" )
                                    || lower.contains( "theme" )
                                    || lower.contains( "riff" )
                                    || lower.contains( "motif" )
                                    || lower.contains( "link" )
                                    || lower.contains( "coda" )
                                    )
                                {
                                    self.markSection(true)
                                    contentTypeDetected = true
                                    songContentDetected = true
                                }
                            }
                            
                            let stripText = text!.trimmingCharacters(in: whitespaceSet)
                            if( stripText.isEmpty )
                            {
                                self.markMemo(true)
                                contentTypeDetected=true
                            }
                            
                            if( !contentTypeDetected )
                            {
                                if( !stripText.isEmpty && stripText.trimmingCharacters(in: chordSet) == "")
                                {
                                    self.markChord(true)
                                    contentTypeDetected = true
                                    songContentDetected = true
                                }
                            }
                            
                            // check for title
                            if( !contentTypeDetected && !songContentDetected && !titleDetected && text!.lowercased().contains( "title" ) )
                            {
                                self.markTitle(true)
                                titleDetected = true
                                contentTypeDetected = true
                                if( text!.lowercased().contains( "title" ) )
                                {
                                    let range = self._textView.getRangeOfString( "title" )
                                    let mutTxt = self._textView.attributedText.mutableCopy() as! NSMutableAttributedString
                                    mutTxt.deleteCharacters(in: range)
                                    self._textView.attributedText = mutTxt
                                }
                            }
                            
                            // check for artist
                            if( !contentTypeDetected && !songContentDetected && !artistDetected && ( text!.lowercased().contains( "artist" ) || text!.lowercased().contains( "band" ) ) )
                            {
                                self.markArtist(true)
                                artistDetected = true
                                contentTypeDetected = true
                                if( text!.lowercased().contains( "artist" ) )
                                {
                                    let range = self._textView.getRangeOfString( "artist" )
                                    let mutTxt = self._textView.attributedText.mutableCopy() as! NSMutableAttributedString
                                    mutTxt.deleteCharacters(in: range)
                                    self._textView.attributedText = mutTxt
                                }
                                
                                if( text!.lowercased().contains( "band" ) )
                                {
                                    let range = self._textView.getRangeOfString( "band" )
                                    let mutTxt = self._textView.attributedText.mutableCopy() as! NSMutableAttributedString
                                    mutTxt.deleteCharacters(in: range)
                                    self._textView.attributedText = mutTxt
                                }
                            }
                            
                            // check for author
                            if( !contentTypeDetected && !songContentDetected && !authorDetected && ( text!.lowercased().contains( "by" ) || text!.lowercased().contains( "written" ) ||
                                text!.lowercased().contains( "compose" ) ||
                                text!.lowercased().contains( "author" )) )
                            {
                                self.markAuthor(true)
                                authorDetected = true
                                contentTypeDetected = true
                                
                                if( text!.lowercased().contains( "author" ) )
                                {
                                    let range = self._textView.getRangeOfString( "author" )
                                    let mutTxt = self._textView.attributedText.mutableCopy() as! NSMutableAttributedString
                                    mutTxt.deleteCharacters(in: range)
                                    self._textView.attributedText = mutTxt
                                }
                            }
                            
                            // check for copyright
                            if( !contentTypeDetected && !songContentDetected && !copyrightDetected && (
                                text!.lowercased().contains( "right" ) ||
                                    text!.lowercased().contains( "(c)" ) ) )
                            {
                                self.markCopyright(true)
                                copyrightDetected = true
                                contentTypeDetected = true
                                
                                if( text!.lowercased().contains( "copyright" ) )
                                {
                                    let range = self._textView.getRangeOfString( "copyright" )
                                    let mutTxt = self._textView.attributedText.mutableCopy() as! NSMutableAttributedString
                                    mutTxt.deleteCharacters(in: range)
                                    self._textView.attributedText = mutTxt
                                }
                            }
                            
                            // check for publisher
                            if( !contentTypeDetected && !songContentDetected && !publisherDetected && (
                                text!.lowercased().contains( "publish" ) ||
                                    text!.lowercased().contains( "ltd" ) ||
                                    text!.lowercased().contains( "inc" )
                                ) )
                            {
                                self.markPublisher(true)
                                publisherDetected = true
                                contentTypeDetected = true
                                
                                if( text!.lowercased().contains( "publisher" ) )
                                {
                                    let range = self._textView.getRangeOfString( "publisher" )
                                    let mutTxt = self._textView.attributedText.mutableCopy() as! NSMutableAttributedString
                                    mutTxt.deleteCharacters(in: range)
                                    self._textView.attributedText = mutTxt
                                }
                            }
                            
                            // check for BPM
                            if( !contentTypeDetected && !songContentDetected && !tempoDetected && (
                                text!.lowercased().contains( "bpm" ) ||
                                    text!.lowercased().contains( "beat" ) ||
                                    text!.lowercased().contains( "tempo" )
                                ) )
                            {
                                self.markTempo(true)
                                tempoDetected = true
                                contentTypeDetected = true
                                
                                if( text!.lowercased().contains( "tempo" ) )
                                {
                                    let range = self._textView.getRangeOfString( "tempo" )
                                    let mutTxt = self._textView.attributedText.mutableCopy() as! NSMutableAttributedString
                                    mutTxt.deleteCharacters(in: range)
                                    self._textView.attributedText = mutTxt
                                }
                            }
                            
                            // check for key
                            if( !contentTypeDetected && !songContentDetected && !keyDetected && (
                                text!.lowercased().contains( "key" ) ||
                                    text!.lowercased().contains( "major" ) ||
                                    text!.lowercased().contains( "minor" )
                                ) )
                            {
                                self.markKey(true)
                                keyDetected = true
                                contentTypeDetected = true
                                
                                if( text!.lowercased().contains( "key" ) )
                                {
                                    let range = self._textView.getRangeOfString( "key" )
                                    let mutTxt = self._textView.attributedText.mutableCopy() as! NSMutableAttributedString
                                    mutTxt.deleteCharacters(in: range)
                                    self._textView.attributedText = mutTxt
                                }
                            }
                            
                            // check for timesig
                            if( !contentTypeDetected && !songContentDetected && !timeSigDetected && (
                                text!.lowercased().contains( "time" ) ||
                                    text!.lowercased().contains( "2/4" ) ||
                                    text!.lowercased().contains( "3/4" ) ||
                                    text!.lowercased().contains( "4/4" ) ||
                                    text!.lowercased().contains( "12/8" ) ||
                                    text!.lowercased().contains( "7/8" ) ||
                                    text!.lowercased().contains( "6/8" )) )
                            {
                                self.markTimeSig(true)
                                timeSigDetected = true
                                contentTypeDetected = true
                                
                                if( text!.lowercased().contains( "time signature" ) )
                                {
                                    let range = self._textView.getRangeOfString( "time signature" )
                                    let mutTxt = self._textView.attributedText.mutableCopy() as! NSMutableAttributedString
                                    mutTxt.deleteCharacters(in: range)
                                    self._textView.attributedText = mutTxt
                                }
                            }
                            
                            // assume the first line is the title, if nothing else got it
                            if( !contentTypeDetected && !songContentDetected && !titleDetected )
                            {
                                self.markTitle(true)
                                titleDetected = true
                                contentTypeDetected = true
                            }
                            
                            // assume the second line is the artist, if nothing else got it
                            if( !contentTypeDetected && !songContentDetected && !artistDetected )
                            {
                                self.markArtist(true)
                                artistDetected = true
                                contentTypeDetected = true
                            }
                            
                            if( !contentTypeDetected && (text!.lowercased().contains( "created: " ) ||
                                text!.lowercased().contains( "last updated: " )))
                            {
                                self.markMemo(true)
                                contentTypeDetected = true
                            }
                            
                            if( !contentTypeDetected )
                            {
                                self.markLyric(true)
                            }
                        }
                        else
                        {
                            self._textView.markOff()
                        }
                    }
                }
            }
            
            if( !dontProcess )
            {
                self.removeImportingSpinnerView()
                
                if( self._textView != nil )
                {
                    self._textView.becomeFirstResponder()
                    let newFont = UIFont(name: "Courier" , size: 18)
                    self._textView.font = newFont
                    self._textView.textAlignment = NSTextAlignment.left
                    self._textView.backgroundColor = UIColor.black
                    self._textView.textColor = UIColor.white
                    self._textView.selectEndOfDoc()
                }
                self._textViewContainer.resizeTextView()
            }
        })
    }
    
    @IBOutlet weak var scrollToolbar: ExtUISlider!
    let maxScroll:CGFloat = 2048.0
    @IBAction func scrollToolbarsChanged(_ sender: AnyObject) {
        let pos = max( ((scrollToolbar.value * (Float)(maxScroll)) * -1), (Float)((maxScroll-self.view.frame.maxX) * -1) )
        print("pos: " + String(pos) )

        self._contextToolBar.frame = CGRect(x: CGFloat(pos), y: self._contextToolBar.frame.minY, width: maxScroll, height: self._contextToolBar.frame.height)
        self.lineTypeToolBar.frame = CGRect(x: CGFloat(pos), y: self.lineTypeToolBar.frame.minY, width: maxScroll, height: self.lineTypeToolBar.frame.height)
    }
    
    func clearView()
    {
        self._textView.attributedText = NSAttributedString(string: " ")
        self._textView.text = " "
        self._textView.font = nil
        self._textView.textColor = nil
        self.markOff()
        self._textView.attributedText = NSAttributedString(string: "")
        self._textView.text = ""
        let newFont = UIFont(name: "Courier" , size: 18)
        self._textView.font = newFont
        self._textView.textAlignment = NSTextAlignment.left
        self._textView.backgroundColor = UIColor.black
        self._textView.textColor = UIColor.white
    }
    
    
    @IBAction func clearDoc(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Clear the document?", message: "The document will be cleared", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            self.clearView()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            //print("Handle Cancel Logic here")
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func pasting(_ notification: Notification)
    {
        let text = notification.object
        
        if( text is NSAttributedString )
        {
            DispatchQueue.main.async(execute: { // attributed text
                var range = self._textView.selectedRange
                let attribText:NSMutableAttributedString = NSMutableAttributedString(attributedString: self._textView.attributedText)
                attribText.fixAttributes(in: range)
                let aString = text as! NSAttributedString
                attribText.insert(aString, at: range.location)
                attribText.fixAttributes(in: range)
                self._textView.attributedText = attribText
                range.length = aString.length
                self._textView.selectedRange = range
            })
        }
        else if( text is String )
        {
            DispatchQueue.main.async(execute: { // plain text
                var originalRange = self._textView.selectedRange
                var range = self._textView.selectedRange
                let attribText:NSMutableAttributedString = NSMutableAttributedString(attributedString: self._textView.attributedText)
                attribText.fixAttributes(in: range)
                
                let textString = text as! String
                let nsText = textString as NSString
                let textRange = NSMakeRange(0, nsText.length)
                nsText.enumerateSubstrings(in: textRange, options: NSString.EnumerationOptions(), using: { // split lines up
                    (substring,_,range2, _) in  // use the enclosing range with the line feed
                    
                    var str = substring
                    if( str == nil || str!.isEmpty )
                    {
                        str = ""
                    }
                    str = str! + "\n"
                    
                    let aString = NSAttributedString(string: str!).mutableCopy() as! NSMutableAttributedString
                    let rangeStr:NSRange = NSMakeRange(0, aString.length)
                    
                    // detect chords or lyrics
                    if( substring == nil || substring!.trimmingCharacters(in: whitespaceSet) == "" )
                    {
                        // don't attribute
                    }
                    else if( substring!.trimmingCharacters(in: chordSet) == "")
                    {
                        aString.addAttribute(NSAttributedString.Key.backgroundColor, value: LineColourArray[LineTypeColourIndex.chords.rawValue], range: rangeStr )
                    }
                    else
                    {
                        aString.addAttribute(NSAttributedString.Key.backgroundColor, value: LineColourArray[LineTypeColourIndex.lyrics.rawValue], range: rangeStr )
                    }
                    
                    aString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white, range: rangeStr )
                    aString.addAttribute(NSAttributedString.Key.font, value: UIFont(name:"Courier", size: 18 )!, range: rangeStr )
                    range.length = aString.length
                    attribText.insert(aString as NSAttributedString, at: range.location)
                    self._textView.attributedText = attribText
                    range.location = range.location.advanced(by: range2.length)
                })
                
                originalRange.location = originalRange.location.advanced(by: nsText.length) // move cursor to end
                self._textView.selectedRange = originalRange
            })
        }
    }
    
    @IBAction func refreshChordsFromDoc(_ sender: AnyObject) {
        let attrText = self._textView.attributedText
        let numLines = self._textView.getLineCount()
        
        for lineIdx in( 0 ..< numLines )
        {
            let range = self._textView.getRangeForLineIndex(lineIdx)
            // blank line?
            let lineText = attrText?.attributedSubstring(from: range)
            let plainText = lineText?.string.trimRight(whitespaceSet)
            var instrument:String! = nil
            if( _contextToolBar.items?.count > 3 )
            {
                let chordPicked = (_muzomaDoc?._chordPallet[(_contextToolBar.items?[3].tag)!])!
                instrument = chordPicked._instrument
            }
            
            if( range.length > 0)
            {
                let bgCol = lineText?.attribute(NSAttributedString.Key.backgroundColor, at: 0, effectiveRange: nil)
                
                if( bgCol != nil )
                {
                    let col = (bgCol as! UIColor).toHexString()
                    
                    
                    switch( col )
                    {
                    case LineColourArray[LineTypeColourIndex.chords.rawValue].toHexString():
                        let chords = plainText?.components(separatedBy: whitespaceSet)
                        for chord in chords!{
                            if( !chord.isEmpty )
                            {
                                let foundChord = Chord(chordText: chord)
                                if( !foundChord.chordString.isEmpty )
                                {
                                    if( instrument != nil )
                                    {
                                        foundChord._instrument = instrument
                                    }
                                    
                                    let foundIdx = _muzomaDoc?._chordPallet.index(where: { (Chord) -> Bool in
                                        return( foundChord.chordString == Chord.chordString )
                                    })
                                    
                                    if( foundIdx < 0 )
                                    {
                                        _muzomaDoc?._chordPallet.append(foundChord)
                                    }
                                }
                            }
                        }
                        
                        
                        break;
                        
                    default:
                        break;
                    }
                }
            }
        }
        
        refreshChordPallet()
    }
}



// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToNSAttributedStringDocumentReadingOptionKeyDictionary(_ input: [String: Any]) -> [NSAttributedString.DocumentReadingOptionKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.DocumentReadingOptionKey(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringDocumentAttributeKey(_ input: NSAttributedString.DocumentAttributeKey) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringDocumentType(_ input: NSAttributedString.DocumentType) -> String {
	return input.rawValue
}
