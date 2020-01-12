//
//  ChordPickerController.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 08/03/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//
//  Our UI code to allow chord picking
//

import UIKit


class ChordPickerController :  UIViewController, UIPickerViewDataSource, UIPickerViewDelegate
{
    let nc = NotificationCenter.default
    var muzomaDoc: MuzomaDocument?
    let _chordPlayer = ChordPlayer()
    fileprivate var _chord:Chord! = nil
    
    internal var chord : Chord
    {
        get
        {
            return( _chord! )
        }
    }
    
    @IBOutlet weak var _instPicker: UIPickerView!
    
    @IBAction func addClicked(_ sender: AnyObject) {
        //print( "add clicked" )
        let note = _notes[_chordPicker.selectedRow(inComponent: 0)]
        let accidental = _accidentals[_chordPicker.selectedRow(inComponent: 1)]
        let interval = _intervals[_chordPicker.selectedRow(inComponent: 2)]
        let extenstion = _extensions[_chordPicker.selectedRow(inComponent: 3)]
        let addition = _additions[_chordPicker.selectedRow(inComponent: 4)]
        let slashNote = _slashNotes[_chordPicker.selectedRow(inComponent: 5)]
        let instrument = _instruments[_instPicker.selectedRow(inComponent: 0)]

        _chord = Chord(note: note, accidental: accidental, interval: interval, extenstion: extenstion, addition: addition, slashNote: slashNote,
                        inversion: "", instrument:  instrument)
        
        muzomaDoc?._chordPallet.append(_chord)
        nc.post(name: Notification.Name(rawValue: "RefreshChordPallet"), object: nil)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelClicked(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var _chordPicker: UIPickerView!
    
    @IBAction func playChordPressed(_ sender: AnyObject) {
        _chordPlayer.playChord(
            _notes[_chordPicker.selectedRow(inComponent: 0)],
            accidental:_accidentals[_chordPicker.selectedRow(inComponent: 1)],
            interval: _intervals[_chordPicker.selectedRow(inComponent: 2)],
            extenstion: _extensions[_chordPicker.selectedRow(inComponent: 3)],
            addition: _additions[_chordPicker.selectedRow(inComponent: 4)],
            slashNote: _slashNotes[_chordPicker.selectedRow(inComponent: 5)],
            instrument: _instruments[_instPicker.selectedRow(inComponent: 0)]
        )
    }
    
    // main code
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //_chordPicker.reloadComponent(0)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Scale notes
    let _notes:[String] = [ "A", "B", "C", "D", "E", "F", "G" ]
    
    // sharp (♯), flat (♭), and natural (♮)
    let _accidentals:[String] = [ "", "♯", "♭", "♮" ]
    
    // interval
    let _intervals:[String] = [ "", "m", "sus2", "sus4", "aug" /*maj #5*/ , "dim" /*min flat 5*/]
    
    // extenstion
    let _extensions:[String] = [ "", "5", "(♯5)", "(♭5)", "6", "7", "maj7", "9", "maj9", "11", "13"]
    
    // additions
    let _additions:[String] = [ "","(add2)","(add4)","(add6)","(add9)","(add11)","(add13)",
        "(add♯9)","(add♯11)","(add♯13)",
        "(add♭9)","(add♭11)","(add♭13)"]
    
    // slashes
    let _slashNotes:[String] = [ "", "/A", "/B", "/C", "/D", "/E", "/F", "/G",
        "/A♭", "/B♭", "/C♭", "/D♭", "/E♭", "/F♭", "/G♭",
        "/A♯", "/B♯", "/C♯", "/D♯", "/E♯", "/F♯", "/G♯",
        "/A♮", "/B♮", "/C♮", "/D♮", "/E♮", "/F♮", "/G♮"
    ]
    
    let _instruments:[String] = [ "AcGuitar", "Piano" ]
    
    // picker view
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView
    {
        let pickerLabel = UILabel()
        pickerLabel.textColor = UIColor.black
        
        // pickerLabel.font = UIFont(name: pickerLabel.font.fontName, size: 15)
        pickerLabel.font = UIFont(name: "Arial MT Bold", size: 12) // In this use your custom font
        pickerLabel.textAlignment = NSTextAlignment.center
        var ret:String = ""
        if( pickerView == _instPicker)
        {
            switch( component )
            {
            case 0:
                ret = _instruments[row]
                pickerLabel.font = UIFont(name: "Arial MT Bold", size: 14) // In this use your custom font
                break
                
            default:
                ret = "?"
                break
            }
        }
        else
        {
            switch( component )
            {
            case 0:
                ret = _notes[row]
                pickerLabel.font = UIFont(name: "Arial MT Bold", size: 14) // In this use your custom font
                break
                
            case 1:
                ret = _accidentals[row]
                pickerLabel.font = UIFont(name: "Arial MT Bold", size: 14) // In this use your custom font
                break
                
            case 2:
                ret = _intervals[row]
                pickerLabel.font = UIFont(name: "Arial MT Bold", size: 12) // In this use your custom font
                break
                
            case 3:
                ret = _extensions[row]
                pickerLabel.font = UIFont(name: "Arial MT Bold", size: 12) // In this use your custom font
                break
                
            case 4:
                ret = _additions[row]
                pickerLabel.font = UIFont(name: "Arial", size: 11) // In this use your custom font
                break
                
            case 5:
                ret = _slashNotes[row]
                pickerLabel.font = UIFont(name: "Arial MT Bold", size: 14) // In this use your custom font
                break
                
            default:
                ret = "?"
                break
            }
        }
        
        pickerLabel.text = ret
        
        return pickerLabel
    }
    
    
    func numberOfComponents( in pickerView: UIPickerView ) -> Int
    {
        var ret:Int = 0
        
        if( pickerView == _instPicker)
        {
            ret=1
        }
        else
        {
            ret=6
        }
        
        return (ret)
    }
    
    func pickerView( _ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        var ret = 0
        
        if( pickerView == _instPicker)
        {
            ret = _instruments.count
        }
        else
        {
            switch( component )
            {
            case 0:
                ret = _notes.count
                break
                
            case 1:
                ret = _accidentals.count
                break
                
            case 2:
                ret = _intervals.count
                break
                
            case 3:
                ret = _extensions.count
                break
                
            case 4:
                ret = _additions.count
                break
                
            case 5:
                ret = _slashNotes.count
                break
                
            default:
                ret = _intervals.count
                break
            }
        }
        
        return( ret )
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        // user changed the picker row
    }
}
