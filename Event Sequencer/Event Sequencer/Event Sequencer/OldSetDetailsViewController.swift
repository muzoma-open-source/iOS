//
//  SetDetailsViewController.swift
//  Event Sequencer
//
//  Created by Matthew Hopkins on 15/11/2015.
//  Copyright © 2015 Muzoma.com. All rights reserved.
//

import UIKit
import MediaPlayer
import AVFoundation

import Foundation
import CoreFoundation
import CoreMIDI


class OldSetDetailsViewController:  UIViewController
{
    // main code
    @IBAction func CancelPress(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil )
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        //pickerView.viewForRow(<#row: Int#>, forComponent: <#Int#>)
    }
}

