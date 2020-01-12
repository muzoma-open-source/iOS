//
//  ExternalPlayerView.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 13/05/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//

import UIKit

class ExternalPlayerView: UIView {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    @IBOutlet weak var prevChords: UITextField!
    
    @IBOutlet weak var prevLyrics: UITextField!
    
    @IBOutlet weak var currentChords: UITextField!
    
    @IBOutlet weak var currentLyrics: UITextField!
    
    @IBOutlet weak var nextChords: UITextField!
    
    @IBOutlet weak var nextLyrics: UITextField!
}
