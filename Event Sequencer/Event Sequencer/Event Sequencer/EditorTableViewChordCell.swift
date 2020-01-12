//
//  EditorTableViewChordCell.swift
//  Event Sequencer
//
//  Created by Matthew Hopkins on 11/12/2015.
//  Copyright © 2015 Muzoma.com. All rights reserved.
//
//  Allows the user to set up the timing and display of a song as it plays

import UIKit

class EditorTableViewChordCell: UITableViewCell
{
    var _parentVC:EditorLinesController?
    var _track:Int?

     @IBOutlet weak var editChord: ChordSelectorTextField!
    
    func textField(_ textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        //print("While entering the characters this method gets called")
        return true;
    }
    
    
    @IBAction func editStart(_ sender: AnyObject) {
        _parentVC!._parentVC?._eventPicker.isUserInteractionEnabled = false
    }
    
    @IBAction func endExit(_ sender: AnyObject) {
        // needed for DONE key on keyboard
        _parentVC!.UpdateDocAndView(_track!, newData: editChord.text!)
        _parentVC!._parentVC?._eventPicker.isUserInteractionEnabled = true
    }
    
    @IBAction func editEnded(_ sender: AnyObject) {
        //print( "edit end\(editChord.text)")
        
        _parentVC!.UpdateDocAndView(_track!, newData: editChord.text!)
        _parentVC!._parentVC?._eventPicker.isUserInteractionEnabled = true
        //editChord.resignFirstResponder()
    }
    
    @IBAction func editChanged(_ sender: AnyObject) {
        
        if( editChord.selectedTextRange != nil )
        {
            //print( "\(editChord.text)" )
            
            let pos = editChord.offset(from: editChord.beginningOfDocument, to:editChord.selectedTextRange!.start)

            _parentVC!.CharChange(_track!, newLength: editChord.text!.count, newChangePos:pos, newData: editChord.text!)
        }
        else if( editChord.text!.count == 0 )
        {
            _parentVC!.CharChange(_track!, newLength: 0, newChangePos:0, newData:editChord.text!)
        }
    }
    
    
    // UITextField Delegates
    func textFieldDidBeginEditing(_ textField: UITextField) {
        print("TextField did begin editing method called")
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        print("TextField did end editing method called")
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        print("TextField should begin editing method called")
        return true;
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        print("TextField should clear method called")
        return true;
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        print("TextField should snd editing method called")
        return true;
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("TextField should return method called")
        textField.resignFirstResponder();
        return true;
    }
    
    @IBOutlet weak var labTrackName: UILabel!
}
