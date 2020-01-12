//
//  EditDocumentViewController.swift
//  Event Sequencer
//
//  Created by Matthew Hopkins on 05/04/2015.
//  Copyright (c) 2015 Muzoma.com. All rights reserved.
//
//  Editor for lines in a Muzoma song
//  Allows the user to set up the timing and display of a song as it plays
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

enum EventMode
{
    case modeLines
    case modeEvents
}

class EditDocumentViewController :  UIViewController, UIPickerViewDataSource, UIPickerViewDelegate
{
    var _prevScrollToItemAtTime:TimeInterval = 0
    var _currentPrepareIdx:Int = 0
    var _currentFireIdx:Int = 0
    var editorLines: EditorLinesController?
    var eventMode:EventMode = EventMode.modeLines
    var muzomaDoc: MuzomaDocument?
    var lastEventTimeType: EventTimeType = EventTimeType.None
    let nc = NotificationCenter.default
    
    @IBOutlet weak var trackEditContainer: UIView!
    @IBOutlet weak var _navPanel: UINavigationItem!
    @IBOutlet weak var fastfwdButton: UIBarButtonItem!
    @IBOutlet weak var playButton: UIBarButtonItem!
    @IBOutlet weak var _eventPicker: UIPickerView!
    @IBOutlet weak var timeLabel: UITextField!
    @IBOutlet weak var progressTime: UIProgressView!
    @IBOutlet weak var tableContainer: UIView!
    @IBOutlet weak var butTrackLabels: UISwitch!
    @IBOutlet weak var labelMode: UITextField!
    @IBOutlet weak var butModeChange: UISwitch!
    
    fileprivate var _transport:Transport! = nil
    
    // main code
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        if( muzomaDoc!.isValid() && muzomaDoc!._activeEditTrack > -1 )
        {
            if( _navPanel != nil )
            {
                _navPanel.prompt = muzomaDoc!.getFolderName()
            }
        }
        lastEventTimeType = EventTimeType.None
        
        updateDisplayComponents()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //Logger.log(  "viewDidAppear editor doc" )
        _transport = Transport( viewController: self )
        _transport.muzomaDoc = self.muzomaDoc
        
        _eventPicker.reloadComponent(0)

        nc.addObserver(self, selector: #selector(EditDocumentViewController.playerTicked(_:)), name: NSNotification.Name(rawValue: "PlayerTick"), object: nil)
        nc.addObserver(self, selector: #selector(EditDocumentViewController.rewindButton(_:)), name: NSNotification.Name(rawValue: "PlayerRewind"), object: nil)
        nc.addObserver(self, selector: #selector(EditDocumentViewController.fastfwdButton(_:)), name: NSNotification.Name(rawValue: "PlayerFastForward"), object: nil)

        return super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "PlayerTick"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "PlayerRewind"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "PlayerFastForward"), object: nil )
        _transport?.willDeinit()
        _transport = nil
        return( super.viewDidDisappear(animated) )
    }
    
    var _trackLabelsOn:Bool = false
    @IBAction func butLabelsChange(_ sender: AnyObject) {
        _trackLabelsOn = butTrackLabels.isOn
        editorLines?.LabelVisChanged(_trackLabelsOn)
    }
    
    @IBAction func butCancelPress(_ sender: AnyObject) {

        self.editorLines?.Deselect()
        
        let alert = UIAlertController(title: "Undo All Edits?", message: "All changes will be reverted.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                //Logger.log( "Handle Ok logic here")
                self._eventPicker.selectRow(0, inComponent: 0, animated: false)
                self.muzomaDoc = _gFSH.loadMuzomaDoc( (self.muzomaDoc?.getDocumentURL() )!)
                self.viewDidLoad()
                self._eventPicker.reloadComponent(0)
                self.editorLines?.muzomaDoc = self.muzomaDoc
                self.editorLines?.SetSelectedLine(self, line: 0, trackLabelVisible: self._trackLabelsOn)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                //Logger.log( "Handle Cancel Logic here")
        }))
        self.present(alert, animated: true, completion: nil)
        self.editorLines?.Reselect()
    }
    
    @IBAction func butModeChange(_ sender: AnyObject) {
        if( butModeChange.isOn )
        {
            labelMode.text = "Lines"
            eventMode = EventMode.modeLines
        }
        else
        {
            labelMode.text = "Events"
            eventMode = EventMode.modeEvents
        }
    }
    
    @IBAction func newEventButton(_ sender: AnyObject){
        Logger.log("new event at \(String(describing: editorLines?._activeLine))")
        
        // drop focus if in editor
        editorLines?.removeFocus()
        muzomaDoc!.appendLineEvent((editorLines?._activeLine)!)
        _eventPicker.reloadComponent(0)
        editorLines?.SetSelectedLine(self, line: (editorLines?._activeLine)!+1, trackLabelVisible: self._trackLabelsOn)
        self._eventPicker.selectRow((editorLines?._activeLine)!, inComponent: 0, animated: true)
    }
    
    @IBAction func deleteEventButton(_ sender: AnyObject) {
        Logger.log( "delete event")
        
        muzomaDoc!.deleteLineEvent((editorLines?._activeLine)!)
        
        _eventPicker.reloadComponent(0)
        editorLines?.SetSelectedLine(self, line: (editorLines?._activeLine)!, trackLabelVisible: self._trackLabelsOn)
        self._eventPicker.selectRow((editorLines?._activeLine)!, inComponent: 0, animated: true)
    }
    
    @objc func rewindButton(_ sender: AnyObject) {
        Logger.log( "rewind")
        _prevScrollToItemAtTime = 0
        _currentFireIdx = 0
        _currentPrepareIdx = 0
    }
    
    @objc func stopButton(_ sender: AnyObject) {
        Logger.log( "stop")
        _prevScrollToItemAtTime = 0
        _currentFireIdx = 0
        _currentPrepareIdx = 0
        
        _eventPicker.selectRow(0, inComponent: 0, animated: true)
    }
    
    @objc func playButton(_ sender: AnyObject) {
        Logger.log( "play")
    }
    
    @objc func pauseButton(_ sender: AnyObject) {
        Logger.log( "pause")
    }
    
    @objc func fastfwdButton(_ sender: AnyObject) {
        Logger.log( "fast fwd")
        _prevScrollToItemAtTime = 0
        _currentFireIdx = 0
        _currentPrepareIdx = 0
    }
    
    @IBAction func prepareButton(_ sender: AnyObject) {
        Logger.log( "prepare guide time is \(self.muzomaDoc!.getCurrentTime())")
        prepareButton()
    }
    
    @IBAction func fireButton(_ sender: AnyObject) {
        Logger.log( "fire guide time is \(self.muzomaDoc!.getCurrentTime())")
        fireButton()
    }
    
    @objc func playerTicked(_ notification: Notification) {
        DispatchQueue.main.async(execute: {self.updateDisplayComponents()})
    }

    // picker view
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView
    {
        let pickerLabel = UILabel()
        
        if( pickerView.selectedRow(inComponent: 0) == row)
        {
            switch( lastEventTimeType )
            {
                case EventTimeType.Prepare:
                    pickerLabel.textColor = UIColor.red
                break
                
                case EventTimeType.Fire:
                    pickerLabel.textColor = UIColor.green
                break
                
                default:
                    pickerLabel.textColor = UIColor.black
                break;
            }
            
        }else{
            pickerLabel.textColor = UIColor.black
        }
        
        pickerLabel.text = muzomaDoc!._tracks[muzomaDoc!._activeEditTrack]._events[row]._data
        // pickerLabel.font = UIFont(name: pickerLabel.font.fontName, size: 15)
        pickerLabel.font = UIFont(name: "Arial-BoldMT", size: 10) // In this use your custom font
        pickerLabel.textAlignment = NSTextAlignment.left
        
        return pickerLabel
    }
   
    func numberOfComponents( in pickerView: UIPickerView ) -> Int
    {
        return(1)
    }
    
    func pickerView( _ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        return muzomaDoc!._tracks.count > 0 ? muzomaDoc!._tracks[muzomaDoc!._activeEditTrack]._events.count : 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if( muzomaDoc!._tracks.count > 0 && component == 0 )
        {
           return muzomaDoc!._tracks[muzomaDoc!._activeEditTrack]._events[row]._data
        }
        else
        {
            return nil
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        // user changed the picker row
        if( muzomaDoc!._tracks[muzomaDoc!._activeEditTrack]._events.count > row )
        {
            let evtTime = muzomaDoc!._tracks[muzomaDoc!._activeEditTrack]._events[row]._prepareTime
        
            if( evtTime > 0 )
            {
                muzomaDoc!.setCurrentTime(evtTime!)
            }
        
            editorLines?.SetSelectedLine(self, line: row, trackLabelVisible: self._trackLabelsOn)
        }
    }
    
    
    func scrollToItemAtTime(_ currentTime:TimeInterval)
    {
        if(currentTime != _prevScrollToItemAtTime )
        {
            _prevScrollToItemAtTime = currentTime
            
            for (n, ele) in muzomaDoc!._tracks[muzomaDoc!._activeEditTrack]._events.enumerated() {
                if( /*n > 0 &&*/ele._prepareTime != nil && ele._prepareTime <= currentTime && _currentFireIdx == _eventPicker.selectedRow(inComponent: 0)) // last one in list that is less than current time and prev event was fire
                {
                    _currentPrepareIdx = n
                } else if( ele._eventTime != nil && ele._eventTime <= currentTime) // event
                {
                    _currentFireIdx = n
                }
                else if( ele._prepareTime != nil && ele._eventTime != nil )
                {
                    break;
                }
            }
            
            if( _currentPrepareIdx > _currentFireIdx && _currentPrepareIdx != _eventPicker.selectedRow(inComponent: 0) )
            {
                _eventPicker.selectRow(_currentPrepareIdx, inComponent: 0, animated: true)
                lastEventTimeType = EventTimeType.Prepare
                //Logger.log(  "Prepare \(currentTime)")
            }
            else if( _currentFireIdx == _currentPrepareIdx && lastEventTimeType == EventTimeType.Prepare  )
            {
                _eventPicker.selectRow(_currentFireIdx, inComponent: 0, animated: true)
                lastEventTimeType = EventTimeType.Fire
                //Logger.log(  "Fire \(currentTime)")
            }
        }
    }

    func updateDisplayComponents()
    {
        //println("update display")
        
        if( self.muzomaDoc!.isPlaying() )
        {
            let time:TimeInterval = (self.muzomaDoc!.getCurrentTime())
            scrollToItemAtTime(time)
        }
        else
        {
            /*timeLabel.text = "--:--:--"
            progressTime.progress = 0;*/
        }
    }
    
    func prepareButton()
    {
        if( self.muzomaDoc!.isPlaying())
        {
            let nextIdx = _eventPicker.selectedRow(inComponent: 0) + 1
            if( muzomaDoc!._tracks[muzomaDoc!._activeEditTrack]._events.count > nextIdx )
            {
                _eventPicker.selectRow(nextIdx, inComponent:0, animated: true)
                muzomaDoc!._tracks[muzomaDoc!._activeEditTrack]._events[nextIdx]._prepareTime = TimeInterval((self.muzomaDoc!.getCurrentTime()))
                _eventPicker.reloadComponent(0)
                lastEventTimeType = EventTimeType.Prepare
            }
        }
    }
    
    func fireButton()
    {
        if( self.muzomaDoc!.isPlaying())
        {
            let idx = _eventPicker.selectedRow(inComponent: 0)
            if( muzomaDoc!._tracks[muzomaDoc!._activeEditTrack]._events.count > idx )
            {
                muzomaDoc!._tracks[muzomaDoc!._activeEditTrack]._events[idx]._eventTime = TimeInterval((self.muzomaDoc!.getCurrentTime()))
                _eventPicker.reloadComponent(0)
                lastEventTimeType = EventTimeType.Fire
            }
        }
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
        }
    }

    override func willMove(toParent parent: UIViewController?) {
        if( parent == nil ) {
            _ = _gFSH.saveMuzomaDocLocally(muzomaDoc)
            //Logger.log( "Back Button Pressed Editor!")
        }
        
        super.willMove(toParent: parent)
    }
}

