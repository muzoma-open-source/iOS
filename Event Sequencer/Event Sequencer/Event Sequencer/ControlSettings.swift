//
//  ControlSettings.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 23/03/2017.
//  Copyright © 2017 Muzoma.com. All rights reserved.
//
//  Model that represents midi control settings
//

import Foundation
import AEXML

open class ControlSettings  {
    
    // received
    var respondToStopStart: Bool = true
    var respondToMMC: Bool = true
    var respondToLearnedControls:Bool = true
    var playLearned: String! = nil
    var stopLearned: String! = nil
    var songSelectLearned: String! = nil
    var respondToMixerFader: Bool = true
    
    // sent
    var sendStopStart: Bool = true
    var sendMMC: Bool = true
    var sendLearnedControls:Bool = true
    var sendLearnedMixerFader:Bool = true
    var controlMidiInPort: String! = nil
    var controlMidiOutPort: String! = nil
    
    init( xmlEle:AEXMLElement )
    {
        deserialize( xmlEle )
    }
    
    init()
    {
    }
    
    open func serialize()-> AEXMLElement
    {
        let ele = AEXMLElement(name: "ControlSettings")
        
        ele.addChild(name: "RespondToStopStart", value: respondToStopStart ? "true" : "false")
        ele.addChild(name: "RespondToMMC", value: respondToMMC ? "true" : "false")
        ele.addChild(name: "RespondToLearnedControls", value: respondToLearnedControls ? "true" : "false")
        ele.addChild(name: "PlayLearned", value: playLearned != nil ? playLearned.addingPercentEncoding(withAllowedCharacters: xmlAllowedSet) : nil )
        ele.addChild(name: "StopLearned", value: stopLearned != nil ?  stopLearned.addingPercentEncoding(withAllowedCharacters: xmlAllowedSet) : nil )
        ele.addChild(name: "SongSelectLearned", value: songSelectLearned != nil ? songSelectLearned.addingPercentEncoding(withAllowedCharacters: xmlAllowedSet) : nil   )
        
        ele.addChild(name: "SendStopStart", value: sendStopStart ? "true" : "false")
        ele.addChild(name: "SendMMC", value: sendMMC ? "true" : "false")
        ele.addChild(name: "SendLearnedControls", value: sendLearnedControls ? "true" : "false")
        ele.addChild(name: "SendLearnedMixerFader", value: sendLearnedMixerFader ? "true" : "false")
        
        ele.addChild(name: "ControlMidiInPort", value: controlMidiInPort != nil ? controlMidiInPort.addingPercentEncoding(withAllowedCharacters: xmlAllowedSet) : nil  )
        ele.addChild(name: "ControlMidiOutPort", value: controlMidiOutPort != nil ? controlMidiOutPort.addingPercentEncoding(withAllowedCharacters: xmlAllowedSet)  : nil )
        
        return( ele )
    }
    
    open func deserialize( _ xmlEle:AEXMLElement )
    {
        for top in xmlEle.children {
            //Logger.log(child.name)
            switch( top.name )
            {
            case "ControlSettings":

                for child in top.children {
                    //Logger.log(child.name)
                    switch( child.name )
                    {
                    case "RespondToStopStart":
                        if( child.value != nil )
                        {
                            respondToStopStart = child.bool!
                        }
                        break;
                        
                    case "RespondToMMC":
                        if( child.value != nil )
                        {
                            respondToMMC = child.bool!
                        }
                        break;
                        
                    case "RespondToLearnedControls":
                        if( child.value != nil )
                        {
                            respondToLearnedControls = child.bool!
                        }
                        break;
                        
                    case "PlayLearned":
                        if( child.value != nil )
                        {
                            playLearned = child.value != nil ? child.value!.removingPercentEncoding! : nil
                        }
                        break;
                        
                    case "StopLearned":
                        if( child.value != nil )
                        {
                            stopLearned = child.value != nil ? child.value!.removingPercentEncoding! : nil
                        }
                        break;
                        
                    case "SongSelectLearned":
                        if( child.value != nil )
                        {
                            songSelectLearned = child.value != nil ? child.value!.removingPercentEncoding! : nil
                        }
                        break;
                        
                    case "SendStopStart":
                        if( child.value != nil )
                        {
                            sendStopStart = child.bool!
                        }
                        break;
                        
                    case "SendMMC":
                        if( child.value != nil )
                        {
                            sendMMC = child.bool!
                        }
                        break;
                        
                        
                    case "SendLearnedControls":
                        if( child.value != nil )
                        {
                            sendLearnedControls = child.bool!
                        }
                        break;
                        
                    case "SendLearnedMixerFader":
                        if( child.value != nil )
                        {
                            sendLearnedMixerFader = child.bool!
                        }
                        break;
                        
                    case "ControlMidiInPort":
                        if( child.value != nil )
                        {
                            controlMidiInPort = child.value != nil ? child.value!.removingPercentEncoding! : nil
                        }
                        break;
                        
                    case "ControlMidiOutPort":
                        if( child.value != nil )
                        {
                            controlMidiOutPort = child.value != nil ? child.value!.removingPercentEncoding! : nil
                        }
                        break;
                        
                    default:
                        Logger.log( "unknown ControlSettings element: " + child.name)
                        break;
                    }
                }
                break;
                
            default:
                Logger.log( "unknown  element: " + top.name)
                break;
            }
        }
    }
}
