//
//  MixerMidiControl.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 19/04/2017.
//  Copyright © 2017 Muzoma.com. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices
import MIKMIDI

open class MidiValueObject
{
    var command:String = ""
    var commandIdx:Int = -1
    var midiCommand:MIKMIDICommand! = nil
    var value:Int = 0
    var trackIdx:Int = 0
}

open class MixerMidiControl : NSObject, MIKMIDIResponder, MIKMIDIMappableResponder
{
    open func midiIdentifier() -> String
    {
        return( "Mixer" )
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
            
            let commandID = command.mappingItem!.commandIdentifier
            var commandStr:String = ""
            var commandIdx:Int = -1
            if( commandID.contains("Fader") )
            {
                commandStr = "Fader"
                let commandIdxStr = NSString( string: commandID.replacingOccurrences(of: "Fader", with: "") )
                commandIdx = commandIdxStr.integerValue
            }
            
            switch commandStr {
            case "Fader":
                if( _gMidi.settings.respondToMixerFader )
                {
                    let faderValue:MidiValueObject! = MidiValueObject()
                    faderValue.command = commandStr
                    if( commandIdx == 0 ) // use  midi channel instead as from global page
                    {
                        if( command is MIKMIDIChannelVoiceCommand )
                        {
                            let voiceCmd = command as! MIKMIDIChannelVoiceCommand
                            commandIdx = Int(voiceCmd.channel)// Int(command.statusByte.subtractingReportingOverflow(UInt8(176)).partialValue)
                        }
                    }
                    faderValue.commandIdx = commandIdx
                    faderValue.midiCommand = command
                    faderValue.value = Int(command.dataByte2)
                    _gNC.post(name: Notification.Name(rawValue: "FaderControlSent"), object: faderValue)
                }
                break;
                
            default:
                Logger.log("handleMIDICommand  not implemented \(command)")
                break;
            }
        }
    }
    
    /*
     public func subresponders() -> [MIKMIDIResponder]? // Nullable for historical reasons.
     {
     
     }*/
    
    
    var _faderCommands:[String]! = nil
    var faderCommands:[String]
        {
        get
        {
            if( _faderCommands == nil )
            {
                _faderCommands = [String]()
                for faderCnt in 1 ..< 64
                {
                    _faderCommands.append( "Fader\(faderCnt)" )
                }
            }
            return( _faderCommands )
        }
    }
    
    //MIKMIDIMappableResponder
    open func commandIdentifiers() -> [String]
    {
        let commands = faderCommands
        return( commands )
    }
    
    open func midiResponderType(forCommandIdentifier commandID: String) -> MIKMIDIResponderType
    {
        var ret:MIKMIDIResponderType
        var command:String = ""
        if( commandID.contains("Fader") )
        {
            command = "Fader"
        }
        
        switch command {
            
        case "Fader":
            ret = MIKMIDIResponderType.absoluteSliderOrKnob
            break;
            
        default:
            ret = MIKMIDIResponderType.absoluteSliderOrKnob
            break;
        }
        return( ret )
    }
    
    open func illuminationState(forCommandIdentifier commandID: String) -> Bool
    {
        var ret:Bool = false
        
        /*var doc:MuzomaDocument!  = Transport.getCurrentDoc()
         
         if( doc != nil )
         {
         
         }*/
        switch commandID {
            
        default:
            ret = false
            break;
        }
        return( ret )
    }
}


