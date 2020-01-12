//
//  EditorLinesController.swift
//  Event Sequencer
//
//  Created by Matthew Hopkins on 11/12/2015.
//  Copyright © 2015 Muzoma.com. All rights reserved.
//
//  Allows the user to set up the timing and display of a song as it plays

import UIKit
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


class EditorLinesController: UITableViewController {
    
    var muzomaDoc: MuzomaDocument?
    var _parentVC:EditDocumentViewController?
    var _songLines: [MuzEvent]?
    var _activeLine: Int = 0
    var _trackLabelVisible: Bool = false
    var _deselected: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        /**** need to scroll to the position of the activated track on first load ***/
        if( _firstScroll == true )
        {
            self.tableView.setContentOffset(CGPoint(x:0,y:0), animated: true)
        }
        return super.viewDidAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        
        let ret = _deselected ? 0 : ((muzomaDoc?._tracks.count)!)
        return ret
    }
    
    //override func tabl
    
    func removeFocus()
    {
        Deselect()
        Reselect()
    }
    
    func getTableView() -> UITableView
    {
        self.tableView.sizeToFit()
        return self.tableView
    }
    
    
    var _scrollPoint:CGPoint = CGPoint(x:0, y:0)
    var _firstScroll = true
    func SetSelectedLine( _ parentVC:EditDocumentViewController, line:Int, trackLabelVisible:Bool)
    {
        self._parentVC = parentVC
        self._activeLine = line
        //print( "set selected line \(self._activeLine)" )
        self._trackLabelVisible = trackLabelVisible
        
        self.tableView.reloadData()
        if( _firstScroll == true )
        {
            /**** need to scroll to the position of the activated track on first load ***/
            self.tableView.setContentOffset(_scrollPoint, animated: true)
            _firstScroll=false
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        var ret:UITableViewCell! = nil
        let row = indexPath.row
        
        let trackType = muzomaDoc!._tracks[row]._trackType
        let trackPurpose = muzomaDoc!._tracks[row]._trackPurpose
        
        
        switch( trackType )
        {
            case TrackType.Audio:
                switch( trackPurpose )
                {
                    case TrackPurpose.GuideAudio:
                        let cell = tableView.dequeueReusableCell(withIdentifier: "EditorCellReuseGuide", for: indexPath) as! EditorTableViewGuideCell
                        cell._parentVC = self
                        cell.labTrackName.text = muzomaDoc?._tracks[indexPath.row]._trackName
                        cell.labTrackName.isHidden = !self._trackLabelVisible
                        cell._track = indexPath.row
                        cell._eventIdx = self._activeLine
                        cell.labTrackFileName.text = muzomaDoc?.getTrackFileName( cell._track!, eventIdx:cell._eventIdx! )
                        cell._audioEventSpecifics = muzomaDoc?.getGuideTrackSpecifics()
                        cell.sliderVol.value = (cell._audioEventSpecifics?.volume)!
                        cell.labChan.text = "Chan: \(String( cell._audioEventSpecifics!.chan ))"
                        cell.labTrackFileName.isHidden = false
                        ret = cell
                    break;
                    
                    case TrackPurpose.BackingTrackAudio, TrackPurpose.ClickTrackAudio :
                        let cell = tableView.dequeueReusableCell(withIdentifier: "EditorCellReuseAudio", for: indexPath) as! EditorTableViewAudioCell
                        cell._parentVC = self
                        cell.labTrackName.text = muzomaDoc?._tracks[indexPath.row]._trackName
                        cell.labTrackName.isHidden = !self._trackLabelVisible
                        cell._track = indexPath.row
                        cell._eventIdx = self._activeLine
                        cell.labTrackFileName.text = muzomaDoc?.getTrackFileName( cell._track!, eventIdx:cell._eventIdx! )
                        cell._audioEventSpecifics = muzomaDoc?.getAudioTrackSpecifics( cell._track! )
                        cell.sliderVol.value = (cell._audioEventSpecifics?.volume)!
                        cell.labChan.text = "Chan: \(String( cell._audioEventSpecifics!.chan ))"
                        cell.labTrackFileName.isHidden = false
                        ret = cell
                    break;

                
                    default:
                    break;
                }
                break;
            
                case TrackType.Words:
                    let cell = tableView.dequeueReusableCell(withIdentifier: "EditorCellReuseLyric", for: indexPath) as! EditorTableViewLyricCell
            
                    cell._parentVC = self
                    cell.labTrackName.text = muzomaDoc?._tracks[indexPath.row]._trackName
                    cell.labTrackName.isHidden = !self._trackLabelVisible
                    cell._track = indexPath.row
                    cell.editLyric.delegate = cell.editLyric
                    
                    //cell.editLyric.text = String(self._activeLine)
                    if( self._activeLine > -1  && muzomaDoc?._tracks[indexPath.row]._events.count > 0 )
                    {
                        cell.editLyric.text = muzomaDoc?._tracks[indexPath.row]._events[self._activeLine]._data
                    }
                    else
                    {
                        cell.editLyric.text = ""
                    }
                    cell.editLyric.autocorrectionType = UITextAutocorrectionType.no
                    //print( "TrackType.Words Line: \(self._activeLine) - \(cell.editLyric.text)")
                    
                    if( muzomaDoc?._activeEditTrack == indexPath.row )
                    {
                        _scrollPoint = CGPoint(x: 0, y: cell.frame.origin.y)
                        if( _firstScroll )
                        {
                            self.tableView.setContentOffset(_scrollPoint, animated: true)
                        }
                    }
                    ret = cell
                break;
            
            
                case TrackType.Chords:
                    let cell = tableView.dequeueReusableCell(withIdentifier: "EditorCellReuseChord", for: indexPath) as! EditorTableViewChordCell
            
                    cell._parentVC = self
                    cell.labTrackName.text = muzomaDoc?._tracks[indexPath.row]._trackName
                    cell.labTrackName.isHidden = !self._trackLabelVisible
                    cell._track = indexPath.row
                    cell.editChord.delegate = cell.editChord
                    if( self._activeLine > -1 && muzomaDoc?._tracks[indexPath.row]._events.count > 0 )
                    {
                        cell.editChord.text = muzomaDoc?._tracks[indexPath.row]._events[self._activeLine]._data
                    }
                    else
                    {
                        cell.editChord.text = ""
                    }
            
                    //print( "TrackType.Chords Line: \(self._activeLine) - \(cell.editChord.text)")
                    
                    if( muzomaDoc?._activeEditTrack == indexPath.row )
                    {
                        //print( "Cell: becomeFirstResponder")
                        _scrollPoint = CGPoint(x: 0, y: cell.frame.origin.y)
                    }
            
                    ret = cell
                break;
            
            
                case TrackType.Structure:
                    let cell = tableView.dequeueReusableCell(withIdentifier: "EditorCellReuseStructure", for: indexPath) as! EditorTableViewStructureCell
                    cell._parentVC = self
                    cell._track = indexPath.row
                    if( muzomaDoc?._activeEditTrack == indexPath.row )
                    {
                        _scrollPoint = CGPoint(x: 0, y: cell.frame.origin.y)
                    }
                    ret = cell
                break;
            
            
                case TrackType.Conductor:
                    let cell = tableView.dequeueReusableCell(withIdentifier: "EditorCellReuseBarBeats", for: indexPath) as! EditorTableViewBarBeatsCell
                    cell._parentVC = self
                    cell._track = indexPath.row
                    
                    if( muzomaDoc?._activeEditTrack == indexPath.row )
                    {
                        //print( "Cell: becomeFirstResponder")
                        _scrollPoint = CGPoint(x: 0, y: cell.frame.origin.y)
                    }
                    ret = cell
                break;
            
            
                default:
                break;
        }
        
        if( ret == nil )
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "EditorCellReuseLyric", for: indexPath) as! EditorTableViewLyricCell
            cell._parentVC = self
            cell._track = indexPath.row
            ret = cell
        }
        
        return ret
    }
    
    //override func tableView( tableView: UITableView
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        var ret:Bool = true
        
        if( indexPath.row > 0 )
        {
            let track = muzomaDoc?._tracks[indexPath.row]
        
            switch( track?._trackPurpose )
            {
                case TrackPurpose.Structure?:
                    ret = false
                break;
                
                case TrackPurpose.Conductor?:
                    ret = false
                break;
                
                case TrackPurpose.GuideAudio?:
                    ret = false
                break;
                
                case TrackPurpose.KeySignature?:
                    ret = false
                break;
            
                default:
                    ret = true
                break;
            }
        }
        // Return false if you do not want the specified item to be editable.
        return ret
    }
    
    
    func Deselect()
    {
        _deselected = true
        self.tableView.reloadData()
    }
    
    func Reselect()
    {
        _deselected = false
        self.tableView.reloadData()
    }
    
        
    func CharChange(_ trackIdx:Int, newLength:Int, newChangePos:Int, newData:String)
    {
    }
    
    func UpdateDocAndView(_ track:Int, newData:String)
    {
        if( self._activeLine <= (muzomaDoc?._tracks[track]._events.count)! )
        {
            muzomaDoc?._tracks[track]._events[self._activeLine]._data = newData
            self._parentVC?._eventPicker.reloadComponent(0)
        }
    }
    
    func LabelVisChanged( _ trackLabelsOn:Bool )
    {
        self._trackLabelVisible = trackLabelsOn
        self.tableView.reloadData()
    }
}
