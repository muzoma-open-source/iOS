//
//  EditorTableViewLyricCell.swift
//  Event Sequencer
//
//  Created by Matthew Hopkins on 11/12/2015.
//  Copyright © 2015 Muzoma.com. All rights reserved.
//
//  Allows the user to set up the timing and display of a song as it plays

import UIKit

class EditorTableViewLyricCell : UITableViewCell
{
    var _parentVC:EditorLinesController?
    var _track:Int?
    
    @IBOutlet weak var editLyric: WordSelectorTextField!
    @IBOutlet weak var labTrackName: UILabel!

    @IBAction func editStart(_ sender: AnyObject) {
        _parentVC!._parentVC?._eventPicker.isUserInteractionEnabled = false
    }
    
    @IBAction func endExit(_ sender: AnyObject) {
        // needed for DONE key on keyboard
        _parentVC!.UpdateDocAndView(_track!, newData: editLyric.text!)
        _parentVC!._parentVC?._eventPicker.isUserInteractionEnabled = true
    }
    
    @IBAction func editEnded(_ sender: AnyObject) {
        //print( "edit end\(editLyric.text)")
        _parentVC!.UpdateDocAndView(_track!, newData: editLyric.text!)
        _parentVC!._parentVC?._eventPicker.isUserInteractionEnabled = true
            //editLyric.resignFirstResponder()
    }
    
    @IBAction func editChanged(_ sender: AnyObject) {
        
        if( editLyric.selectedTextRange != nil )
        {
            //print( "\(editLyric.text)" )
            
            let pos = editLyric.offset(from: editLyric.beginningOfDocument, to:editLyric.selectedTextRange!.start)
            _parentVC!.CharChange(_track!, newLength: editLyric.text!.count, newChangePos:pos, newData: editLyric.text!)
        }
        else if( editLyric.text!.count == 0 )
        {
            _parentVC!.CharChange(_track!, newLength: 0, newChangePos:0, newData:editLyric.text!)
        }
    }
}
