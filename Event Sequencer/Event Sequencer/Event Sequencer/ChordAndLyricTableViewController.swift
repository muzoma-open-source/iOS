//
//  ChordAndLyricTableViewController.swift
//  Event Sequencer
//
//  Created by Matthew Hopkins on 11/12/2015.
//  Copyright © 2015 Muzoma.com. All rights reserved.
//

import UIKit

class ChordAndLyricTableViewController: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var chordEditor: ChordSelectorTextField!
    @IBOutlet weak var lyricEditor: WordSelectorTextField!
    
    let nc = NotificationCenter.default
    var muzomaDoc: MuzomaDocument?
    var row = 0
    var _lyricTrackIdx = 0
    var _chordTrackIdx = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _lyricTrackIdx = muzomaDoc!.getMainLyricTrackIndex()
        _chordTrackIdx = muzomaDoc!.getMainChordTrackIndex()
        let lyricEvt = muzomaDoc!._tracks[_lyricTrackIdx]._events[row]
        let chordEvt = muzomaDoc!._tracks[_chordTrackIdx]._events[row]
        chordEditor.text = chordEvt._data
        lyricEditor.text = lyricEvt._data

        lyricEditor.becomeFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func endEdit()
    {
        self.view.endEditing(true)
        muzomaDoc!._tracks[_lyricTrackIdx]._events[row]._data = lyricEditor.text!
        muzomaDoc!._tracks[_chordTrackIdx]._events[row]._data = chordEditor.text!
        self.chordEditor.resignFirstResponder()
        self.lyricEditor.resignFirstResponder()
        self.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        endEdit()
        self.nc.post(name: Notification.Name(rawValue: "EditorEnded"), object: self)
        return false
    }
    
    func focusChords()
    {
        chordEditor.becomeFirstResponder()
    }
    
    func focusLyrics()
    {
        lyricEditor.becomeFirstResponder()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var ret = true
        
        // TODO 2-3
        if( string == ". " /*&& range != textField.selectedTextRange?.end */) // filter out auto full stop
        {
            ret = false
        }
        return(ret)
    }
    
    var prevChord:Chord! = nil
    let _chordPlayer = ChordPlayer()
    
    func playChord()
    {
        let wordRange = chordEditor.getRangeOfNearestWordFromSelectedPos()
        
        if( wordRange.length > 0)
        {
            let nsTxt = chordEditor.text! as NSString
            let lineText = nsTxt.substring(with: wordRange).trimmingCharacters(in: whitespaceSet)
            //print( "loc: \(wordRange.location) len: \(wordRange.length) text:\(lineText)" )
            
            let chord = Chord(chordText: lineText)
            if( prevChord == nil || chord.chordString != prevChord!.chordString )
            {
                _chordPlayer.playChord( chord )
                prevChord = chord
                // reset previous chord with a timeout
                let delay = DispatchTime.now() + Double(Int64(1.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: delay,execute: {
                    self.prevChord = nil
                })
            }
        }
    }
    
    @IBAction func chordEditChange(_ sender: AnyObject, forEvent event: UIEvent) {
         //print( "Chord edit changed" )
        playChord()
    }
    
    @IBAction func chordValueChanged(_ sender: AnyObject, forEvent event: UIEvent) {
        //print( "Chord value changed" )
    }
    
    @IBAction func touchDownChordText(_ sender: ChordSelectorTextField) {
        //print( "touch down")
        playChord()
    }
    
    @IBAction func touchDragChordText(_ sender: AnyObject, forEvent event: UIEvent) {
        //print( "touch drag")
        
    }

    @IBAction func touchDragChord(_ sender: AnyObject, forEvent event: UIEvent) {
        //print( "touch drag ins")
        //playChord()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 2
    }
    
    func getTableView() -> UITableView
    {
        return self.tableView
    }
}
