//
//  ChordSelectorTextField.swift
//  Event Sequencer
//
//  Created by Matthew Hopkins on 11/12/2015.
//  Copyright © 2015 Muzoma.com. All rights reserved.
//
//
//  Allows the user to set up the timing and display of a song as it plays

import UIKit

class ChordSelectorTextField : UITextField, UITextFieldDelegate {
    
    // UITextField Delegates
    func textFieldDidBeginEditing(_ textField: UITextField) {
        //print("TextField did begin editing method called")
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        //print("TextField did end editing method called")
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        //print("TextField should begin editing method called")
        return true;
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        //print("TextField should clear method called")
        return true;
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        // print("TextField should snd editing method called")
        return true;
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // print("While entering the characters this method gets called")
        return true;
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        //print("TextField should return method called")
        textField.resignFirstResponder();
        return true;
    }

}
