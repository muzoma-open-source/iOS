//
//  Globals.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 23/03/2017.
//  Copyright © 2017 Muzoma.com. All rights reserved.
//

import Foundation
import CoreFoundation
import AudioToolbox
import MediaPlayer
import AVFoundation

// shared globals - don't need to keep initializing these objects, they can be used from anywhere

let _gNC = NotificationCenter.default
let _gFSH = FileSystemHelper()
let _gDocURL = FileSystemHelper().getDocumentFolderURL()!
let _gTrackPlayerQueue:DispatchQueue = DispatchQueue( label: "trackPlayerQueue" )
let _gTimerQueue:DispatchQueue = DispatchQueue( label: "playerQueue" )
let _gMidiTimerQueue:DispatchQueue = DispatchQueue( label: "midiStatusQueue" )
let _gdocDeserializeQ:DispatchQueue = DispatchQueue( label: "docQDeserialize" )

class InitTime
{
    var _TimeInfo:mach_timebase_info = mach_timebase_info(numer: 0, denom: 0)
    
    init()
    {
        mach_timebase_info( &_TimeInfo )
    }
}

let _gInitTime = InitTime()
let _gMidi = MuzomaMidi()

