//
//  EditorTableViewCell.swift
//  Event Sequencer
//
//  Created by Matthew Hopkins on 11/12/2015.
//  Copyright © 2015 Muzoma.com. All rights reserved.
//
//  Allows the user to set up the timing and display of a song as it plays

import UIKit

class EditorTableViewCell: UITableViewCell {
    @IBOutlet weak var trackIdEditor: UILabel!
    
    @IBOutlet weak var trackNameEditor: UITextField!
    
    @IBOutlet weak var trackType: UILabel!

    @IBOutlet weak var trackPurpose: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
