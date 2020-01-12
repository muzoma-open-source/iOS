//
//  MainNavViewController.swift
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

// top level navigation view controller
class MainNavViewController :  UINavigationController, UINavigationControllerDelegate
{
    // main code
    @IBOutlet weak var bottomToolbar: UIToolbar!
    
    var controllerLabel:UILabel! = nil
    
   
    fileprivate var _transport:Transport! = nil
    var transport:Transport {
        get
        {
            return _transport
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.delegate = self
    }
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        
        
        let autoHideToolbar = UserDefaults.standard.bool(forKey: "autoHideToolbar_preference")
        
        // some views we collapse the nav bar for more space
        if( autoHideToolbar &&
            (viewController.isKind( of: PlayerDocumentViewController.self) ||
             viewController.isKind( of: ViewerViewController.self ))
            )
        {
            self.hidesBarsOnSwipe = true
            self.hidesBarsWhenVerticallyCompact = true
        }
        else
        {
            self.hidesBarsOnSwipe = false
            self.hidesBarsWhenVerticallyCompact = false
        }
    }
}
