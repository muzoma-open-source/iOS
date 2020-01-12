//
//  MuzomaMidi.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 23/03/2017.
//  Copyright © 2017 Muzoma.com. All rights reserved.
//

import Foundation
import CoreFoundation
import CoreMIDI
import MIKMIDI

struct MidiIOState : OptionSet {
    var rawValue: Int
    
    static let None         = MidiIOState(rawValue: 0)
    static let MidiInRx     = MidiIOState(rawValue: 1 << 0)
    static let MidiOutTx    = MidiIOState(rawValue: 1 << 1)
    static let MidiInOutRxTx  = MidiIOState(rawValue: 1 << 0 + 1 << 1)
}

class ObservableMidiIOState : NSObject
{
    var midiIOState:MidiIOState! = nil
    init( state:MidiIOState )
    {
        midiIOState = state
    }
}


extension MIKMIDICommandType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .noteOff: return "Note off command"
        case .noteOn : return "Note on command"
        case .polyphonicKeyPressure : return "Polyphonic key pressure command"
        case .controlChange : return "Control change command"
        case .programChange : return "Program change command"
        case .channelPressure : return "Channel pressure command"
        case .pitchWheelChange : return "Pitch wheel change command"
        case .systemMessage : return "System message command"
        case .systemExclusive : return "System message command"
        case .systemTimecodeQuarterFrame : return "System timecode command"
        case .systemSongPositionPointer : return "System song position pointer command"
        case .systemSongSelect: return "System song select command"
        case .systemTuneRequest : return "System tune request command"
        case .systemTimingClock : return "System timing clock command"
        case .systemStartSequence : return "System start sequence command"
        case .systemContinueSequence : return "System continue sequence command"
        case .systemStopSequence : return "System stop sequence command"
        case .systemKeepAlive : return "System keep alive message"
        }
    }
}

open class MuzomaMidi {
    fileprivate var _midiTimer:RepeatingTimer! = nil
    fileprivate var _midiState:MidiIOState = MidiIOState.None
    fileprivate var _previousMidiState:MidiIOState = MidiIOState.None
    
    var deviceManager:MIKMIDIDeviceManager! = MIKMIDIDeviceManager.shared
    
    fileprivate var _settings:ControlSettings! = _gFSH.getControlSettings()
    fileprivate var _transportControl:TransportMidiControl! = TransportMidiControl()
    fileprivate var _mixerControl:MixerMidiControl! = MixerMidiControl()
    
    
    var transportControl:TransportMidiControl!
    {
        get
        {
            return( _transportControl )
        }
    }
    
    var mixerControl:MixerMidiControl!
    {
        get
        {
            return( _mixerControl )
        }
    }
    
    var settings:ControlSettings!
    {
        get
        {
            return( _settings )
        }
    }
    
    fileprivate var _mappingPath:URL! = _gFSH.getMappingFolderURL()!
    var mappingPath:URL!
    {
        get
        {
            return _mappingPath
        }
    }
    
    var mappingFileURL:URL!
    {
        get
        {
            return( self.mappingPath?.appendingPathComponent( _learningMappingResponder.midiIdentifier() + "." + self._learningCommandIdentifier + ".xml") )
            
        }
    }
    
    func getMappingFileURL( _ midiIdentifier:String, commandIdentifier:String ) -> URL!
    {
        return( self.mappingPath?.appendingPathComponent( midiIdentifier + "." + commandIdentifier + ".xml") )
        
    }
    
    func loadMappings()
    {
        do
        {
            let files = try _gFSH.contentsOfDirectory( at: mappingPath,
                                                       includingPropertiesForKeys: [URLResourceKey.isDirectoryKey, URLResourceKey.isReadableKey, URLResourceKey.contentModificationDateKey],
                                                       options: FileManager.DirectoryEnumerationOptions()) as [URL]
            for file in files {
                let midiMapping = try MIKMIDIMapping(fileAt: file, error: ())
                MIKMIDIMappingManager.shared().addUserMappingsObject(midiMapping)
            }
        } catch let error as NSError {
            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
        }
    }
    
    func removeMapping( _ midiIdentifier:String, commandIdentifier:String )
    {
        //remove the in memory mappings
        for mapping in MIKMIDIMappingManager.shared().userMappings
        {
            if( commandIdentifier == "Faders" )
            {
                for faderIdx in 0 ..< 64
                {
                    let faderStr = "Fader\(faderIdx)"
                    let items = mapping.mappingItems(forCommandIdentifier: faderStr, responderWithIdentifier: midiIdentifier)
                    if( items.count > 0 )
                    {
                        mapping.removeMappingItems(items)
                    }
                    
                    // now remove the file
                    let url = getMappingFileURL( midiIdentifier, commandIdentifier: faderStr)
                    if( url != nil )
                    {
                        do
                        {
                            try _gFSH.removeItem(at: url!)
                            Logger.log("\(#function)  \(#file) Deleted \(url!.absoluteString)")
                        } catch let error as NSError {
                            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                        }
                    }
                }
            }
            else
            {
                let items = mapping.mappingItems(forCommandIdentifier: commandIdentifier, responderWithIdentifier: midiIdentifier)
                if( items.count > 0 )
                {
                    mapping.removeMappingItems(items)
                }
                
                // now remove the file
                let url = getMappingFileURL( midiIdentifier, commandIdentifier: commandIdentifier)
                if( url != nil )
                {
                    do
                    {
                        try _gFSH.removeItem(at: url!)
                        Logger.log("\(#function)  \(#file) Deleted \(url!.absoluteString)")
                    } catch let error as NSError {
                        Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    var _observableMidiState:MidiIOState = .None
    var observableMidiState:ObservableMidiIOState
    {
        get
        {
            return( ObservableMidiIOState( state: _observableMidiState ) )
        }
        
        set
        {
            _observableMidiState = newValue.midiIOState
        }
    }
    
    func midiStatusCheck()
    {
        // grab the current state
        let currentState = self._midiState
        
        // flipped in this cycle? /*currentState != .None &&*/
        if( _previousMidiState != currentState )
        {
            //Logger.log("Midi state \(currentState.rawValue)")
            _observableMidiState = currentState
            _gNC.post(name: Notification.Name(rawValue: "MidiStateChange"), object: observableMidiState)
        }
        
        _previousMidiState = currentState
        self._midiState = .None
    }
    
    init()
    {
        setupVirtualMIKMidi()
        //midiSetupChanged()
        loadMappings()
        
        _midiTimer = RepeatingTimer( timeInterval: TimeInterval(0.250))
        _midiTimer.start()
        _midiTimer.eventHandler =
            {
                self.midiStatusCheck()
        }
        
        /*MIKMIDIDeviceManager posts these notifications: MIKMIDIDeviceWasAddedNotification, MIKMIDIDeviceWasRemovedNotification, MIKMIDIVirtualEndpointWasAddedNotification, MIKMIDIVirtualEndpointWasRemovedNotification.*/
        _gNC.addObserver(self, selector: #selector(MuzomaMidi._midiSetupChanged(_:)), name: NSNotification.Name(rawValue: "MIKMIDIDeviceWasAddedNotification"), object: nil)
        _gNC.addObserver(self, selector: #selector(MuzomaMidi._midiSetupChanged(_:)), name: NSNotification.Name(rawValue: "MIKMIDIDeviceWasRemovedNotification"), object: nil)
        _gNC.addObserver(self, selector: #selector(MuzomaMidi._midiSetupChanged(_:)), name: NSNotification.Name(rawValue: "MIKMIDIVirtualEndpointWasAddedNotification"), object: nil)
        _gNC.addObserver(self, selector: #selector(MuzomaMidi._midiSetupChanged(_:)), name: NSNotification.Name(rawValue: "MIKMIDIVirtualEndpointWasRemovedNotification"), object: nil)
        
        _gNC.addObserver(self, selector: #selector(MuzomaMidi.playerPlayed(_:)), name: NSNotification.Name(rawValue: "PlayerPlay"), object: nil)
        _gNC.addObserver(self, selector: #selector(MuzomaMidi.playerPlayVarispeed(_:)), name: NSNotification.Name(rawValue: "PlayerPlayVarispeed"), object: nil)
        _gNC.addObserver(self, selector: #selector(MuzomaMidi.playerStopped(_:)), name: NSNotification.Name(rawValue: "PlayerStopSendMidi"), object: nil)
        _gNC.addObserver(self, selector: #selector(MuzomaMidi.playerEnded(_:)), name: NSNotification.Name(rawValue: "SongEnded"), object: nil)
        _gNC.addObserver(self, selector: #selector(MuzomaMidi.playerFastForward(_:)), name: NSNotification.Name(rawValue: "PlayerFastForward"), object: nil)
        _gNC.addObserver(self, selector: #selector(MuzomaMidi.playerRewind(_:)), name: NSNotification.Name(rawValue: "PlayerRewind"), object: nil)
        
        _gNC.addObserver(self, selector: #selector(MuzomaMidi.trackVolumeSet(_:)), name: NSNotification.Name(rawValue: "TrackVolumeSet"), object: nil)
        
        _gNC.addObserver(self, selector: #selector(MuzomaMidi.setSelectNext(_:)), name: NSNotification.Name(rawValue: "SetSelectNextSong"), object: nil)
        _gNC.addObserver(self, selector: #selector(MuzomaMidi.setSelectPrevious(_:)), name: NSNotification.Name(rawValue: "SetSelectPreviousSong"), object: nil)
        _gNC.addObserver(self, selector: #selector(MuzomaMidi.setSelectSong(_:)), name: NSNotification.Name(rawValue: "SetSelectSong"), object: nil)
    }
    
    deinit
    {
        _gNC.removeObserver( self, name: NSNotification.Name(rawValue: "MIKMIDIDeviceWasAddedNotification"), object: nil )
        _gNC.removeObserver( self, name: NSNotification.Name(rawValue: "MIKMIDIDeviceWasRemovedNotification"), object: nil )
        _gNC.removeObserver( self, name: NSNotification.Name(rawValue: "MIKMIDIVirtualEndpointWasAddedNotification"), object: nil )
        _gNC.removeObserver( self, name: NSNotification.Name(rawValue: "MIKMIDIVirtualEndpointWasRemovedNotification"), object: nil )
        
        _gNC.removeObserver(self, name: NSNotification.Name(rawValue: "PlayerPlay"), object: nil)
        _gNC.removeObserver(self, name: NSNotification.Name(rawValue: "PlayerPlayVarispeed"), object: nil)
        _gNC.removeObserver(self, name: NSNotification.Name(rawValue: "PlayerStop"), object: nil)
        _gNC.removeObserver(self, name: NSNotification.Name(rawValue: "SongEnded"), object: nil)
        _gNC.removeObserver(self, name: NSNotification.Name(rawValue: "PlayerFastForward"), object: nil)
        _gNC.removeObserver(self, name: NSNotification.Name(rawValue: "PlayerRewind"), object: nil)
        
        _gNC.removeObserver(self, name: NSNotification.Name(rawValue: "TrackVolumeSet"), object: nil)
        _gNC.removeObserver(self, name: NSNotification.Name(rawValue: "SetSelectSong"), object: nil)
        
        if( _midiTimer != nil )
        {
            _midiTimer.pause()
            _midiTimer.invalidate()
            _midiTimer = nil
        }
    }
    
    @objc func _midiSetupChanged(_ notification: Notification) {
        DispatchQueue.main.async(execute: {
            self.midiSetupChanged()
        })
    }
    
    var inEp:MIKMIDIEndpoint! = nil
    var outEp:MIKMIDIEndpoint! = nil
    func midiSetupChanged()
    {
        if( inEp == nil || inEp.displayName != _settings.controlMidiInPort )
        {
            inEp = selectMidiInByName( _settings.controlMidiInPort )
        }
        
        if( outEp == nil || outEp.displayName != _settings.controlMidiOutPort )
        {
            outEp = selectMidiOutByName( _settings.controlMidiOutPort )
        }
    }
    
    func getVirtualDevice() -> MIKMIDIDevice!
    {
        var epArray = [MIKMIDIEndpoint]()
        let outeps = self.getActiveMidiOutEndpoints()
        for endPoint in outeps
        {
            epArray.append(endPoint!)
        }
        let ineps = self.getActiveMidiInEndpoints()
        for endPoint in ineps
        {
            epArray.append(endPoint!)
        }
        
        let vd = MIKMIDIDevice(virtualEndpoints:epArray)
        
        return( vd )
    }
    
    fileprivate var _inLearn:Bool = false
    
    var inLearn:Bool
    {
        get
        {
            return( _inLearn )
        }
    }
    
    var _mapGen:MIKMIDIMappingGenerator! = nil
    var _learningMappingResponder:MIKMIDIMappableResponder! = nil
    var _learningCommandIdentifier:String! = nil
    
    func startMidiLearn( _ mappingResponder:MIKMIDIMappableResponder!, commandIdentifier:String )
    {
        if( _inLearn )
        {
            self.cancelMidiLearn()
        }
        
        _inLearn = true
        _learningMappingResponder = mappingResponder
        _learningCommandIdentifier = commandIdentifier
    }
    
    func clearExisting( _ mappingResponder:MIKMIDIMappableResponder!, commandIdentifier:String )
    {
        if( _inLearn )
        {
            self.cancelMidiLearn()
        }
        
        self.removeMapping(mappingResponder.midiIdentifier(), commandIdentifier: commandIdentifier)
    }
    
    func cancelMidiLearn()
    {
        _inLearn = false
        _mapGen = nil
        _learningMappingResponder = nil
        _learningCommandIdentifier = nil
    }
    
    func saveMappingItem( _ mappingItem:MIKMIDIMappingItem! )
    {
        let mapping:MIKMIDIMapping! = MIKMIDIMapping()
        mapping.controllerName = "Muzoma.MidiControl." + mappingItem.midiResponderIdentifier //_learningMappingResponder.MIDIIdentifier()
        mapping.name = "Muzoma.MidiControl." + mappingItem.commandIdentifier //self._learningCommandIdentifier
        mapping!.addItemsObject(mappingItem)
        
        MIKMIDIMappingManager.shared().addUserMappingsObject(mapping) // doesn't save to disk on iOS
        do
        {
            //Logger.log(mapping.debugDescription)
            //try mapping.writeToFileAtURL( getMappingFileURL( _learningMappingResponder.MIDIIdentifier(), commandIdentifier: self._learningCommandIdentifier) )
            try mapping.writeToFile( at: getMappingFileURL( mappingItem.midiResponderIdentifier, commandIdentifier: mappingItem.commandIdentifier) )
        }
        catch let error as NSError
        {
            Logger.log( "error \(error.localizedDescription)" )
        }
    }
    
    func getMappingItems( _ responderIdentifier:String, commandIdentifier:String ) -> [MIKMIDIMappingItem?]
    {
        var ret:[MIKMIDIMappingItem?] = [MIKMIDIMappingItem?]()
        
        for mapping in MIKMIDIMappingManager.shared().userMappings
        {
            let items = mapping.mappingItems(forCommandIdentifier: commandIdentifier, responderWithIdentifier: responderIdentifier)
            for item in items
            {
                ret.append(item)
            }
        }
        
        return( ret )
    }
    
    func getMidiCmds( _ responderIdentifier:String, commandIdentifier:String, value:Int = 127 ) -> [MIKMIDICommand?]
    {
        var ret:[MIKMIDICommand?] = [MIKMIDICommand?]()
        
        let items = getMappingItems( responderIdentifier, commandIdentifier: commandIdentifier )
        
        for item in items
        {
            var cmd:MIKMIDICommand! = nil//(forCommandType: item.commandType)
            if( item != nil )
            {
                switch( item!.commandType as MIKMIDICommandType )
                {
                case .noteOn:
                    let mcmd = MIKMutableMIDINoteOnCommand()
                    mcmd.channel = UInt8((item?.channel)!)
                    mcmd.note = (item?.controlNumber)!
                    if(  item?.additionalAttributes?["Byte2"] != nil )
                    {
                        let valStr:NSString! = item!.additionalAttributes!["Byte2"] as! NSString?
                        mcmd.velocity = UInt(valStr!.integerValue)
                    }
                    else
                    {
                        mcmd.velocity = UInt(value)
                    }
                    cmd = mcmd
                    break;
                    
                case .noteOff:
                    let mcmd = MIKMutableMIDINoteOffCommand()
                    mcmd.channel = UInt8((item?.channel)!)
                    mcmd.note = (item?.controlNumber)!
                    mcmd.velocity = 0
                    cmd = mcmd
                    break;
                    
                case .controlChange:
                    let mcmd = MIKMutableMIDIControlChangeCommand()
                    mcmd.channel = UInt8((item?.channel)!)
                    mcmd.controllerNumber = (item?.controlNumber)!
                    if(  item?.additionalAttributes?["Byte2"] != nil )
                    {
                        let valStr:NSString? = item!.additionalAttributes!["Byte2"] as! NSString?
                        mcmd.controllerValue = UInt(valStr!.integerValue)
                    }
                    else
                    {
                        mcmd.controllerValue = UInt(value)
                    }
                    
                    cmd = mcmd
                    break;
                    
                default:
                    break;
                }
            }
            
            if( cmd != nil )
            {
                ret.append(cmd)
            }
        }
        
        return( ret )
    }
    
    fileprivate func processMidiCommands( _ endpoint:MIKMIDIEndpoint, arrCmds:[MIKMIDICommand] )
    {
        if( _inLearn )
        {
            for cmd in arrCmds
            {
                if( cmd is MIKMIDISystemMessageCommand )
                {
                    // not supported here yet
                    
                }
                else
                {
                    Logger.log( "Learing midi input: \(cmd.debugDescription)" )
                    
                    let mappingItem:MIKMIDIMappingItem = MIKMIDIMappingItem( midiResponderIdentifier: self._learningMappingResponder.midiIdentifier(), andCommandIdentifier: self._learningCommandIdentifier )
                    
                    if( cmd is MIKMIDIChannelVoiceCommand )
                    {
                        let voiceCmd = cmd as! MIKMIDIChannelVoiceCommand
                        mappingItem.channel = Int(voiceCmd.channel)
                    }
                    else
                    {
                        mappingItem.channel = 0
                    }
                    
                    mappingItem.commandType = cmd.commandType
                    mappingItem.controlNumber = UInt(cmd.dataByte1)
                    mappingItem.additionalAttributes = [AnyHashable: Any]()
                    mappingItem.additionalAttributes!["Byte2"] = String("\(cmd.dataByte2)")
                    mappingItem.interactionType = self._learningMappingResponder.midiResponderType(forCommandIdentifier: self._learningCommandIdentifier) //.PressButton
                    
                    _gNC.post(name: Notification.Name(rawValue: "MidiMappingLearned"), object: mappingItem)
                    _inLearn = false
                    break;
                }
            }
        }
        else
        {
            let mappings = MIKMIDIMappingManager.shared().userMappings
            
            for var cmd in arrCmds
            {
                //Logger.log( "midi input: \(cmd.debugDescription)" )
                
                if( cmd.commandType == MIKMIDICommandType.systemExclusive )
                {
                    // convert sys ex command
                    let sysExCmd = cmd as! MIKMIDISystemExclusiveCommand
                    
                    // is it MMC
                    if(self._settings.respondToMMC)
                    {
                        if( sysExCmd.manufacturerID == 0x7f ) // Real-time
                        {
                            if( sysExCmd.sysexData.count > 1 && sysExCmd.sysexData[0] == 0x06 ) // MMC
                            {
                                let cmd:MMCCommand = MMCCommand(rawValue: sysExCmd.sysexData[1])!
                                switch cmd
                                {
                                    case MMCCommand.Stop:
                                        _gNC.post(name: Notification.Name(rawValue: "MMCStopSent"), object: cmd)
                                        break;
                                    
                                    case MMCCommand.Play:
                                         _gNC.post(name: Notification.Name(rawValue: "MMCStartSent"), object: cmd)
                                        break;
                                    
                                    case MMCCommand.Pause:
                                         _gNC.post(name: Notification.Name(rawValue: "MMCPauseSent"), object: cmd)
                                        break;
                                    
                                    case MMCCommand.Rewind:
                                         _gNC.post(name: Notification.Name(rawValue: "MMCRewindSent"), object: cmd)
                                        break;
                                    
                                    case MMCCommand.FastForward:
                                         _gNC.post(name: Notification.Name(rawValue: "MMCFastForwardSent"), object: cmd)
                                        break;
                                    
                                    case MMCCommand.RecordStrobe:
                                         _gNC.post(name: Notification.Name(rawValue: "MMCRecordStrobeSent"), object: cmd)
                                        break;
                                    
                                    case MMCCommand.RecordExit:
                                        _gNC.post(name: Notification.Name(rawValue: "MMCRecordExitSent"), object: cmd)
                                        break;
                                    
                                    case MMCCommand.RecordPause:
                                        _gNC.post(name: Notification.Name(rawValue: "MMCRecordPauseSent"), object: cmd)
                                        break;
                                    
                                    default:
                                        break;
                                }
                            }
                        }
                    }
                }
                else if( cmd.commandType.rawValue >= 240 /*MIKMIDICommandType.SystemMessage*/ )
                {
                    if( cmd.statusByte == UInt8(MIKMIDICommandType.systemKeepAlive.rawValue) ||
                        cmd.statusByte == UInt8(MIKMIDICommandType.systemTimecodeQuarterFrame.rawValue) ||
                        cmd.statusByte == UInt8(MIKMIDICommandType.systemTimingClock.rawValue) ||
                        cmd.statusByte == UInt8(MIKMIDICommandType.systemTuneRequest.rawValue) ||
                        cmd.statusByte == UInt8(MIKMIDICommandType.systemSongPositionPointer.rawValue) )
                    {
                        // ignore these for the minute
                    }
                    else
                    {
                        _midiState.rawValue =  _midiState.rawValue | MidiIOState.MidiInRx.rawValue
                        
                        // select a song in the playlist
                        if( cmd.statusByte == UInt8(MIKMIDICommandType.systemSongSelect.rawValue) )
                        {
                            Logger.log("virt src: \(String(describing: endpoint.displayName)) Song select")
                            if( self._settings.respondToStopStart )
                            {
                                _gNC.post(name: Notification.Name(rawValue: "ControlSongSelectSent"), object: cmd)
                            }
                        }
                        else
                        {
                            // System Real-Time Messages ? start, stop, continue
                            //if( cmd.data[0])
                            //Logger.log( "s=\(cmd.statusByte) 1=\(cmd.dataByte1) 2=\(cmd.dataByte2)" )
                            if( cmd.statusByte == UInt8(MIKMIDICommandType.systemStartSequence.rawValue) )
                            {
                                Logger.log("virt src: \(String(describing: endpoint.displayName)) Start seq")
                                if( self._settings.respondToStopStart )
                                {
                                    _gNC.post(name: Notification.Name(rawValue: "ControlStartSent"), object: cmd)
                                }
                            }
                            else if( cmd.statusByte == UInt8(MIKMIDICommandType.systemStopSequence.rawValue) )
                            {
                                Logger.log("virt src: \(String(describing: endpoint.displayName))  Stop seq")
                                if( self._settings.respondToStopStart )
                                {
                                    _gNC.post(name: Notification.Name(rawValue: "ControlStopSent"), object: cmd)
                                }
                            }
                            else  if( cmd.statusByte == UInt8(MIKMIDICommandType.systemContinueSequence.rawValue) )
                            {
                                Logger.log("virt src: \(String(describing: endpoint.displayName))  Continue seq")
                                if( self._settings.respondToStopStart )
                                {
                                    _gNC.post(name: Notification.Name(rawValue: "ControlContinueSent"), object: cmd)
                                }
                            }
                        }
                    }
                }
                else if( settings.respondToLearnedControls || settings.respondToMixerFader ) // only need the logic if we are a responder
                {
                    for mapping in mappings
                    {
                        for mappingItem in mapping.mappingItems
                        {
                            _midiState.rawValue =  _midiState.rawValue | MidiIOState.MidiInRx.rawValue
                            
                            if(cmd is MIKMIDIChannelVoiceCommand)
                            {
                                let voiceCmd = cmd as! MIKMIDIChannelVoiceCommand
                                if( cmd is MIKMIDINoteOnCommand)
                                {
                                    // convert note on with zero velocity to note off
                                    let noteOnCmd = cmd as! MIKMIDINoteOnCommand
                                    if(noteOnCmd.velocity == 0)
                                    {
                                        cmd = MIKMIDINoteOffCommand(note: noteOnCmd.note, velocity: 0, channel: noteOnCmd.channel, midiTimeStamp: noteOnCmd.midiTimestamp)
                                    }
                                }
                                
                                if( (cmd.commandType.rawValue == mappingItem.commandType.rawValue && voiceCmd.channel == UInt8(mappingItem.channel) && voiceCmd.dataByte1 == UInt8(mappingItem.controlNumber)) ||
                                    (mappingItem.commandIdentifier=="Mix Fader" && (cmd.commandType.rawValue == mappingItem.commandType.rawValue && voiceCmd.dataByte1 == UInt8(mappingItem.controlNumber))))
                                {
                                    let b2 = mappingItem.additionalAttributes?["Byte2"]
                                    if( mappingItem.additionalAttributes == nil || b2 == nil || b2 as! String == String(voiceCmd.value) )
                                    {
                                        var responder:MIKMIDIResponder! = nil
                                        switch mappingItem.midiResponderIdentifier
                                        {
                                        case "Transport":
                                            if( mappingItem.commandIdentifier == "Mix Fader" )// can be here for global mixer fader control on midi page
                                            {
                                                responder = settings.respondToMixerFader ? _gMidi.mixerControl : nil
                                            }
                                            else
                                            {
                                                responder = settings.respondToLearnedControls ? _gMidi.transportControl : nil
                                            }
                                            break;
                                            
                                        case "Mixer":
                                            responder = settings.respondToMixerFader ? _gMidi.mixerControl : nil
                                            break;
                                        default:
                                            break;
                                        }
                                        
                                        if( responder != nil )
                                        {
                                            cmd.mappingItem = mappingItem
                                            if( responder.responds(to: cmd) )
                                            {
                                                responder.handle(cmd)
                                                break;
                                            }
                                        }
                                    }
                                }
                            }
                            else if( cmd.commandType.rawValue == mappingItem.commandType.rawValue )
                            {
                                cmd.mappingItem = mappingItem
                                
                                var responder:MIKMIDIResponder! = nil
                                switch mappingItem.midiResponderIdentifier
                                {
                                case "Transport":
                                    responder = _gMidi.transportControl
                                    break;
                                    
                                case "Mixer":
                                    responder = _gMidi.mixerControl
                                    break;
                                default:
                                    break;
                                }
                                
                                if( responder != nil )
                                {
                                    cmd.mappingItem = mappingItem
                                    if( responder.responds(to: cmd) )
                                    {
                                        responder.handle(cmd)
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    var mikMidiControlClientDestVirtEndpoint:MIKMIDIClientDestinationEndpoint! = nil
    var mikMidiControlClientSourceVirtEndpoint:MIKMIDIClientSourceEndpoint! = nil
    func setupVirtualMIKMidi()
    {
        mikMidiControlClientDestVirtEndpoint =  MIKMIDIClientDestinationEndpoint.init(name: "Muzoma.MidiControl") { (endpoint, arrCmds) in
            //Logger.log("Muzoma.MidiControl rx")
            //Logger.log("virt src: \(endpoint.displayName)")
            self.processMidiCommands( endpoint, arrCmds: arrCmds )
        }
        
        let err:NSErrorPointer = nil
        mikMidiControlClientSourceVirtEndpoint =  MIKMIDIClientSourceEndpoint.init(name: "Muzoma.MidiControl", error: err)
    }
    
    var activeMidiInName:String!
    {
        get
        {
            return( _settings?.controlMidiInPort )
        }
    }
    
    var activeMidiOutName:String!
    {
        get
        {
            return( _settings?.controlMidiOutPort )
        }
    }
    
    
    func selectMidiInByName( _ midiIn:String! ) -> MIKMIDIEndpoint!
    {
        var ep:MIKMIDIEndpoint! = nil
        
        if(  midiIn == nil || midiIn == "No additional midi port")
        {
            _settings.controlMidiInPort = "No additional midi port"
            _ = _gFSH.saveControlSettings(_settings)
            ep = nil
        }
        else
        {
            let devices = getMidiDeviceIns()
            var deviceIdx = 0
            for device in devices
            {
                if( device?.displayName == midiIn )
                {
                    _settings.controlMidiInPort = midiIn
                    self.connectControlMidiIn(device)
                    _ = _gFSH.saveControlSettings(_settings)
                    ep = device
                    break;
                }
                deviceIdx = deviceIdx + 1
            }
        }
        return( ep )
    }
    
    func selectMidiOutByName( _ midiOut:String! ) -> MIKMIDIEndpoint!
    {
        var ep:MIKMIDIEndpoint! = nil
        
        if( midiOut == nil || midiOut == "No additional midi port")
        {
            _settings.controlMidiOutPort = "No additional midi port"
            _ = _gFSH.saveControlSettings(_settings)
            ep = nil
        }
        else
        {
            let devices = getMidiDeviceOuts()
            var deviceIdx = 0
            for device in devices
            {
                if( device?.displayName == midiOut )
                {
                    _settings.controlMidiOutPort = midiOut
                    self.connectControlMidiOut(device)
                    _ = _gFSH.saveControlSettings(_settings)
                    ep = device
                    break;
                }
                deviceIdx = deviceIdx + 1
            }
        }
        
        return( ep )
    }
    
    func getMidiDeviceIns() -> [MIKMIDISourceEndpoint?]
    {
        var midiIdx = 0
        var allDevices:[MIKMIDISourceEndpoint?] = [MIKMIDISourceEndpoint?]()
        
        for src in deviceManager.virtualSources
        {
            if( src.displayName != "Muzoma.MidiControl")
            {
                //Logger.log( "device: \(device.displayName) src: \(src.displayName)" )
                allDevices.append(src)
                midiIdx += 1
            }
        }
        
        return( allDevices )
    }
    
    var mikMidiControlDestEndpoint:MIKMIDIDestinationEndpoint! = nil
    var mikMidiControlSourceEndpoint:MIKMIDIClientSourceEndpoint! = nil
    var mikMidiControlDestEndpointToken:AnyObject! = nil
    var mikMidiControlSourceEndpointToken:AnyObject! = nil
    
    func connectControlMidiIn( _ device:MIKMIDISourceEndpoint! )
    {
        // disconnect existing
        if( mikMidiControlSourceEndpointToken != nil)
        {
            // disconnect
            deviceManager.disconnectConnection(forToken: mikMidiControlSourceEndpointToken)
            mikMidiControlSourceEndpoint = nil
            mikMidiControlSourceEndpointToken = nil
        }
        
        // make connection
        if( device != nil )
        {
            do
            {
                mikMidiControlSourceEndpointToken = try deviceManager.connectInput(device) { (endpoint, arrCmds:[MIKMIDICommand]) in
                self.processMidiCommands( endpoint, arrCmds: arrCmds )
            } as AnyObject
            }
            catch let error as NSError
            {
                Logger.log( "error \(error.localizedDescription)" )
            }
        }
    }
    
    func connectControlMidiOut( _ device:MIKMIDIDestinationEndpoint! )
    {
        // disconnect existing
        if( mikMidiControlDestEndpointToken != nil)
        {
            // disconnect
            deviceManager.disconnectConnection(forToken: mikMidiControlDestEndpointToken)
            mikMidiControlDestEndpoint = nil
            mikMidiControlDestEndpointToken = nil
        }
        
        // make connection
        /*if( device != nil )
         {
         do
         {
         
         }
         catch let error as NSError
         {
         Logger.log( "error \(error.localizedDescription)" )
         }
         }*/
    }
    
    
    func getActiveMidiOutEndpoints() -> [MIKMIDIEndpoint?]
    {
        var endpoints = [MIKMIDIEndpoint?]()
        
        if( mikMidiControlClientSourceVirtEndpoint != nil )
        {
            endpoints.append(mikMidiControlClientSourceVirtEndpoint)
        }
        
        let midiOut = self.selectMidiOutByName( _settings.controlMidiOutPort )
        if( midiOut != nil )
        {
            endpoints.append(midiOut)
        }
        
        return( endpoints )
    }
    
    func getActiveMidiInEndpoints() -> [MIKMIDIEndpoint?]
    {
        var endpoints = [MIKMIDIEndpoint?]()
        
        if( mikMidiControlClientDestVirtEndpoint != nil )
        {
            endpoints.append(mikMidiControlClientDestVirtEndpoint)
        }
        
        let midiIn = self.selectMidiInByName( _settings.controlMidiInPort )
        if( midiIn != nil )
        {
            endpoints.append(midiIn)
        }
        
        return( endpoints )
    }
    
    func getMidiDeviceOuts() -> [MIKMIDIDestinationEndpoint?]
    {
        var midiIdx = 0
        var allDevices:[MIKMIDIDestinationEndpoint?] = [MIKMIDIDestinationEndpoint?]()
        
        for dest in deviceManager.virtualDestinations
        {
            if( dest.displayName != "Muzoma.MidiControl")
            {
                allDevices.append(dest)
                midiIdx += 1
            }
            
        }
        return( allDevices )
    }
    
    func sendMidiCommands( _ cmds:[MIKMIDICommand] )
    {
        for endpoint in getActiveMidiOutEndpoints()
        {
            do
            {
                if( endpoint is MIKMIDIClientSourceEndpoint? )
                {
                    try (endpoint as! MIKMIDIClientSourceEndpoint?)?.send(cmds)
                    //Logger.log( "dest: \(endpoint.name) \(endpoint.debugDescription) " )
                }
                else if( endpoint is MIKMIDIDestinationEndpoint? )
                {
                    //(endpoint as! MIKMIDIDestinationEndpoint!).scheduleMIDICommands(cmds)
                    try deviceManager.send(cmds, to: ((endpoint as! MIKMIDIDestinationEndpoint?)!))
                    //Logger.log( "dest: \(endpoint.name) \(endpoint.debugDescription) " )
                }
            }
            catch let error as NSError
            {
                Logger.log( "midi error \(error.localizedDescription)" )
            }
        }
        
        _midiState.rawValue =  _midiState.rawValue | MidiIOState.MidiOutTx.rawValue
    }
    
    @objc func playerPlayed(_ notification: Notification) {
        //Logger.log("midi: playerPlayed")
        
        /* NEWNEWNEW
         do
         {
         let url = NSBundle.mainBundle().URLForResource( "BB", withExtension: "kar")
         var seq = try MIKMIDISequence(fileAtURL: url!)
         var seqr = MIKMIDISequencer(sequence: seq)
         seqr.createSynthsIfNeeded = true
         seqr.startPlayback()
         
         }
         catch let error as NSError
         {
         Logger.log( "midi play error \(error.localizedDescription)" )
         }
         */
        
        
        if( self.settings.sendStopStart )
        {
            var cmds = [MIKMIDICommand]()
            
            // start sequencer message
            let cmd = MIKMutableMIDISystemMessageCommand();
            cmd.commandType = MIKMIDICommandType.systemStartSequence
            var dataBytes: [UInt8] = [UInt8(MIKMIDICommandType.systemStartSequence.rawValue)]
            let data = NSData(bytes: &dataBytes, length: MemoryLayout<UInt8>.size)
            cmd.data = data as Data?
            cmds.append(cmd)
            sendMidiCommands(cmds)
        }
        
        if( self.settings.sendMMC )
        {
            var cmds = [MIKMIDICommand]()
            let cmd = getMMCCommand(command: MMCCommand.Play) // play
            cmds.append(cmd)
            sendMidiCommands(cmds)
        }
        
        if( self.settings.sendLearnedControls )
        {
            var cmds = [MIKMIDICommand]()
            let midiCmds = self.getMidiCmds( "Transport", commandIdentifier: "Play" )
            if( midiCmds.count > 0 )
            {
                for cmd in midiCmds
                {
                    cmds.append(cmd!)
                }
                sendMidiCommands(cmds)
            }
        }
    }
    
    @objc func playerStopped(_ notification: Notification) {
        //Logger.log("midi: playerStopped")
        if( self.settings.sendStopStart )
        {
            var cmds = [MIKMIDICommand]()
            let cmd = MIKMutableMIDISystemMessageCommand()
            cmd.commandType = MIKMIDICommandType.systemStopSequence
            var dataBytes: [UInt8] = [UInt8(MIKMIDICommandType.systemStopSequence.rawValue)]
            let data = NSData(bytes: &dataBytes, length: MemoryLayout<UInt8>.size)
            cmd.data = data as Data?
            cmds.append(cmd)
            sendMidiCommands(cmds)
        }
        
        if( self.settings.sendMMC )
        {
            var cmds = [MIKMIDICommand]()
            let cmd = getMMCCommand(command: MMCCommand.Stop)
            cmds.append(cmd)
            sendMidiCommands(cmds)
        }
        
        if( self.settings.sendLearnedControls )
        {
            var cmds = [MIKMIDICommand]()
            let midiCmds = self.getMidiCmds( "Transport", commandIdentifier: "Stop" )
            if( midiCmds.count > 0 )
            {
                for cmd in midiCmds
                {
                    cmds.append(cmd!)
                }
                sendMidiCommands(cmds)
            }
        }
    }
    
    @objc func playerFastForward(_ notification: Notification) {
        
        if( self.settings.sendLearnedControls )
        {
            var cmds = [MIKMIDICommand]()
            let midiCmds = self.getMidiCmds( "Transport", commandIdentifier: "Fast Forward" )
            if( midiCmds.count > 0 )
            {
                Logger.log("midi: playerFastForward")
                for cmd in midiCmds
                {
                    cmds.append(cmd!)
                }
                sendMidiCommands(cmds)
            }
        }
        
        if( self.settings.sendMMC )
        {
            var cmds = [MIKMIDICommand]()
            let cmd = getMMCCommand(command: MMCCommand.FastForward)
            cmds.append(cmd)
            sendMidiCommands(cmds)
        }
    }
    
    @objc func playerRewind(_ notification: Notification) {
        
        if( self.settings.sendLearnedControls )
        {
            var cmds = [MIKMIDICommand]()
            let midiCmds = self.getMidiCmds( "Transport", commandIdentifier: "Rewind" )
            if( midiCmds.count > 0 )
            {
                Logger.log("midi: playerRewind")
                for cmd in midiCmds
                {
                    cmds.append(cmd!)
                }
                sendMidiCommands(cmds)
            }
        }
        
        if( self.settings.sendMMC )
        {
            var cmds = [MIKMIDICommand]()
            let cmd = getMMCCommand(command: MMCCommand.Rewind)
            cmds.append(cmd)
            sendMidiCommands(cmds)
        }
    }
    
    @objc func playerPlayVarispeed(_ notification: Notification) {
        
        if( self.settings.sendLearnedControls )
        {
            var cmds = [MIKMIDICommand]()
            let midiCmds = self.getMidiCmds( "Transport", commandIdentifier: "Play" )
            if( midiCmds.count > 0 )
            {
                Logger.log("midi: playerPlayVarispeed")
                
                for cmd in midiCmds
                {
                    cmds.append(cmd!)
                }
                sendMidiCommands(cmds)
            }
        }
        
        /*
        F0 7F <Device0ID> 06 47 <length=03> <sh> <sm> <sl> F7
        Note: sh, sm and sl are defined as Standard Speed in the MIDI 1.0 Recommended Practice RP-013.
        sh = Nominal Integer part of speed value: 0 g sss ppp
        g = sign (1 = reverse)
        sss = shift left count (see below)
        ppp = most significant bits of integer multiple of play-speed
        sm = MSB of nominal fractional part of speed value: 0 qqqqqqq
        sl = LSB of nominal fractional part of speed value: 0 rrrrrrr
        Speed values per shift left count:
        BINARY REPRESENTATION USABLE RANGES (DECIMAL)
        Integer multiple Fractional part Integer Fractional
        sss of play speed of play speed range resolution
        000 ppp - qqqqqqqrrrrrrr 0-7 1/16384
        001 pppq - qqqqqqrrrrrrr 0-15 1/8192
        010 pppqq - qqqqqrrrrrrr 0-31 1/4096
        011 pppqqq - qqqqrrrrrrr 0-63 1/2048
        100 pppqqqq - qqqrrrrrrr 0-127 1/1024
        101 pppqqqqq - qqrrrrrrr 0-255 1/512
        110 pppqqqqqq - qrrrrrrr 0-511 1/256
        111 pppqqqqqqq - rrrrrrr 0-1023 1/128
        if( self.settings.sendMMC )
        {
            var cmds = [MIKMIDICommand]()
            let cmd = getMMCCommand(command: MMCCommand.Shuttle)
            cmds.append(cmd)
            sendMidiCommands(cmds)
        }*/
    }
    
    // sets
    @objc func playerEnded(_ notification: Notification) {
        
        if( self.settings.sendLearnedControls )
        {
            var cmds = [MIKMIDICommand]()
            let midiCmds = self.getMidiCmds( "Transport", commandIdentifier: "Stop" )
            if( midiCmds.count > 0 )
            {
                Logger.log("midi: playerEnded")
                
                for cmd in midiCmds
                {
                    cmds.append(cmd!)
                }
                sendMidiCommands(cmds)
            }
        }
    }
    
    @objc func setSelectPrevious(_ notification: Notification) {
        
        if( notification.object is MuzomaDocument )
        {
            Logger.log("midi: setSelectPrevious")
            
            let doc = notification.object as! MuzomaDocument?
            
            if( self.settings.sendLearnedControls )
            {
                var cmds = [MIKMIDICommand]()
                let midiCmds = self.getMidiCmds( "Transport", commandIdentifier: "Previous Song" )
                if( midiCmds.count > 0 )
                {
                    Logger.log("midi user: setSelectPrevious  \(doc!._fromSetTrackIdx!)")
                    
                    for cmd in midiCmds
                    {
                        cmds.append(cmd!)
                    }
                    sendMidiCommands(cmds)
                }
            }
        }
    }
    
    @objc func setSelectNext(_ notification: Notification) {
        
        if( notification.object is MuzomaDocument )
        {
            Logger.log("midi: setSelectNext")
            
            let doc = notification.object as! MuzomaDocument?
            
            if( self.settings.sendLearnedControls )
            {
                var cmds = [MIKMIDICommand]()
                let midiCmds = self.getMidiCmds( "Transport", commandIdentifier: "Next Song" )
                if( midiCmds.count > 0 )
                {
                    Logger.log("midi user: setSelectNext  \(doc!._fromSetTrackIdx!)")
                    
                    for cmd in midiCmds
                    {
                        cmds.append(cmd!)
                    }
                    sendMidiCommands(cmds)
                }
            }
        }
    }
    
    @objc func setSelectSong(_ notification: Notification) {
        
        if( notification.object is MuzomaDocument )
        {
            let doc = notification.object as! MuzomaDocument?
            if( self.settings.sendStopStart )
            {
                Logger.log("midi sys: setSelectSong \(doc!._fromSetTrackIdx!)")
                var cmds = [MIKMIDICommand]()
                let selCmd = MIKMutableMIDISystemMessageCommand()//for: MIKMIDICommandType.systemSongSelect
                selCmd.commandType = MIKMIDICommandType.systemSongSelect
                // have to do this
                var dataBytes: [UInt8] = [UInt8(MIKMIDICommandType.systemSongSelect.rawValue), UInt8(doc!._fromSetTrackIdx!)]
                //woz let data = NSData(bytes: &dataBytes, length: sizeof(UInt8)/* * 2*/)
                //converter //let data = NSData(bytes: UnsafePointer<UInt8>(&dataBytes), count: sizeof(UInt8)/* * 2*/)
                let data = NSData(bytes: &dataBytes, length: MemoryLayout<UInt8>.size * 2/* * 2*/)
                selCmd.data = data as Data?
                
                cmds.append(selCmd)
                sendMidiCommands(cmds)
            }
            
            if( self.settings.sendLearnedControls )
            {
                var cmds = [MIKMIDICommand]()
                let midiCmds = self.getMidiCmds( "Transport", commandIdentifier: "Song Select", value: doc!._fromSetTrackIdx!  )
                if( midiCmds.count > 0 )
                {
                    Logger.log("midi user: setSelectSong  \(doc!._fromSetTrackIdx!)")
                    
                    for cmd in midiCmds
                    {
                        cmds.append(cmd!)
                    }
                    sendMidiCommands(cmds)
                }
            }
        }
    }
    
    
    // mixer
    @objc func trackVolumeSet(_ notification: Notification) {
        //Logger.log("midi: trackVolumeSet")
        
        if( self.settings.sendLearnedControls )
        {
            if( notification.object is TrackChange )
            {
                let trackChange = notification.object as! TrackChange?
                
                var cmds = [MIKMIDICommand]()
                let midiCmds = self.getMidiCmds( "Mixer", commandIdentifier:"Fader\(trackChange?._audioTrackIdx ?? 0)", value: Int((trackChange?._volume)! * 127.0) )
                if( midiCmds.count > 0 )
                {
                    for cmd in midiCmds
                    {
                        cmds.append(cmd!)
                    }
                    sendMidiCommands(cmds)
                }
            }
        }
    }
    
    
    enum MMCCommand : UInt8
    {
        case Stop=0x01
        case Play=0x02
        case DeferredPlay=0x03 // (play after no longer busy)
        case FastForward=0x04
        case Rewind=0x05
        case RecordStrobe=0x06//  (AKA [[Punch in/out|Punch In]])
        case RecordExit=0x07 // (AKA [[Punch out (music)|Punch out]])
        case RecordPause=0x08 //
        case Pause=0x09 // (pause playback)
        case Eject=0x0A // (disengage media container from MMC device)
        case Chase=0x0B //
        case MMCReset=0x0D  // (to default/startup state)
        case Write=0x40 // (AKA Record Ready, AKA Arm Tracks) parameters: <length1> 4F <length2> <track-bitmap-bytes>
        case Goto=0x44  //(AKA Locate) parameters: <length>=06 01 <hours> <minutes> <seconds> <frames> <subframes>
        case Shuttle=0x47
    }
    
    // get a midi machine command
    func getMMCCommand( command: MMCCommand ) -> MIKMutableMIDISystemExclusiveCommand
    {
        /*
         An MMC message is either an MMC command (Sub-ID#1=06) or an MMC response (Sub-ID#1=07). As a SysEx message it is formatted (all numbers hexadecimal):
         
         F0 7F <Device-ID> <06|07> [<Sub-ID#2> [<parameters>]] F7
         Device-ID: MMC device's ID#; value 00-7F (7F = all devices); AKA "channel number"
         Sub-ID#1: 06 = command
         Sub-ID#2:
         01 Stop
         02 Play
         03 Deferred Play (play after no longer busy)
         04 Fast Forward
         05 Rewind
         06 Record Strobe (AKA [[Punch in/out|Punch In]])
         07 Record Exit (AKA [[Punch out (music)|Punch out]])
         08 Record Pause
         09 Pause (pause playback)
         0A Eject (disengage media container from MMC device)
         0B Chase
         0D MMC Reset (to default/startup state)
         40 Write (AKA Record Ready, AKA Arm Tracks)
         parameters: <length1> 4F <length2> <track-bitmap-bytes>
         44 Goto (AKA Locate)
         parameters: <length>=06 01 <hours> <minutes> <seconds> <frames> <subframes>
         47 Shuttle
         parameters: <length>=03 <sh> <sm> <sl> (MIDI Standard Speed codes)
         Sub-ID#1: 07 = response
         Sub-ID#2: response state
         parameters: values detailing response state
         */
        
        
        // 02 Play MMC
        // F0 7F <Device-ID> <06|07> [<Sub-ID#2> [<parameters>]] F7
        let cmd1 = MIKMutableMIDISystemExclusiveCommand();
        cmd1.commandType = MIKMIDICommandType.systemExclusive
        cmd1.manufacturerID = 0x7f
        cmd1.sysexChannel = 0x7f
        cmd1.sysexData = Data([UInt8(0x06),command.rawValue]);
        return( cmd1 )
    }
}

