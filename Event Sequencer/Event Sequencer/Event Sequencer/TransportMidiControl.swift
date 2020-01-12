//
//  TransportMidiControl.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 19/04/2017.
//  Copyright © 2017 Muzoma.com. All rights reserved.
//

import UIKit
import Foundation
import CoreFoundation
import MediaPlayer
import AVFoundation
import MobileCoreServices
import MIKMIDI

open class TransportMidiControl : NSObject, MIKMIDIResponder, MIKMIDIMappableResponder
{
    open func midiIdentifier() -> String
    {
        return( "Transport" )
    }
    
    open func responds(to command: MIKMIDICommand) -> Bool
    {
        //Logger.log("respondsToMIDICommand: \(command.debugDescription)")
        return( true )
    }
    
    open func handle(_ command: MIKMIDICommand)
    {
        if( command.mappingItem != nil )
        {
            //Logger.log("handleMIDICommand: \(command.mappingItem!.commandIdentifier) \(command.debugDescription)")
            if( _gMidi.settings.respondToStopStart )
            {
                switch command.mappingItem!.commandIdentifier {
                case "Play":
                    _gNC.post(name: Notification.Name(rawValue: "ControlStartSent"), object: command)
                    break;
                    
                case "Stop":
                    _gNC.post(name: Notification.Name(rawValue: "ControlStopSent"), object: command)
                    break;
                    
                case "Song Select":
                    _gNC.post(name: Notification.Name(rawValue: "ControlSongSelectSent"), object: command)
                    break;

                case "Next Song":
                    _gNC.post(name: Notification.Name(rawValue: "ControlNextSongSent"), object: command)
                    break;
                    
                case "Previous Song":
                    _gNC.post(name: Notification.Name(rawValue: "ControlPreviousSongSent"), object: command)
                    break;
                    
                case "Record":
                    _gNC.post(name: Notification.Name(rawValue: "ControlRecordSent"), object: command)
                    break;
                    
                case "Rewind":
                    _gNC.post(name: Notification.Name(rawValue: "ControlRewindSent"), object: command)
                    break;
                    
                case "Fast Forward":
                    _gNC.post(name: Notification.Name(rawValue: "ControlFastForwardSent"), object: command)
                    break;
 
                default:
                    Logger.log("handleMIDICommand  not implemented \(command.mappingItem!.commandIdentifier) \(command.debugDescription)")
                    break;
                }
            }
        }
    }
    
    /*
     public func subresponders() -> [MIKMIDIResponder]? // Nullable for historical reasons.
     {
     
     }*/
    
    //MIKMIDIMappableResponder
    open func commandIdentifiers() -> [String]
    {
        return( ["Play", "Stop", "Song Select", "Record", "Rewind", "Fast Forward", "Next Song", "Previous Song" ])
    }
    
    open func midiResponderType(forCommandIdentifier commandID: String) -> MIKMIDIResponderType
    {
        var ret:MIKMIDIResponderType
        switch commandID {
            
        case "Play":
            ret = MIKMIDIResponderType.pressButton
            break;
            
        case "Stop":
            ret = MIKMIDIResponderType.pressButton
            break;
            
        case "Song Select":
            ret = MIKMIDIResponderType.absoluteSliderOrKnob
            break;
            
        case "Record":
            ret = MIKMIDIResponderType.pressButton
            break;
            
        case "Rewind":
            ret = MIKMIDIResponderType.pressButton
            break;
            
        case "Fast Forward":
            ret = MIKMIDIResponderType.pressButton
            break;
            
        case "Next Song":
            ret = MIKMIDIResponderType.pressButton
            break;
            
        case "Previous Song":
            ret = MIKMIDIResponderType.pressButton
            break;
            
        default:
            ret = MIKMIDIResponderType.pressButton
            break;
        }
        return( ret )
    }
    
    open func illuminationState(forCommandIdentifier commandID: String) -> Bool
    {
        var ret:Bool = false
        
        let doc:MuzomaDocument!  = Transport.getCurrentDoc()
        
        if( doc != nil )
        {
            switch commandID {
                
            case "Play":
                ret = doc!.isPlaying()
                break;
                
            case "Stop":
                ret = false
                break;
                
            case "Song Select":
                ret = false
                break;
                
            case "Record":
                ret = doc!._recordArmed
                break;
                
            case "Rewind":
                ret = false
                break;
                
            case "Fast Forward":
                ret = false
                break;
                
            case "Next Song":
                ret = false
                break;
                
            case "Previous Song":
                ret = false
                break;
                
            default:
                ret = false
                break;
            }
        }
        return( ret )
    }
}

