//
//  Logging.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 14/08/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//

import Foundation
import UIKit

class Logger  {
    static let doLog = UserDefaults.standard.bool(forKey: "debugLogging_preference")
    static func log( _ inStr : String ) {
        // NSLog(<#T##format: String##String#>, <#T##args: CVarArgType...##CVarArgType#>)
        if( doLog )
        {
            NSLog( "%@", inStr )
            print( inStr )
        }
    }
}
