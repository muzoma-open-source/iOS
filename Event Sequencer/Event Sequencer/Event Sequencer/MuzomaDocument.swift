//
//  MuzomaDocument.swift
//  Event Sequencer
//
//  Created by Matthew Hopkins on 03/09/2015.
//  Copyright © 2015 Muzoma.com. All rights reserved.
//
//  Classes and structures used to represent a Muzoma Documnet - .muz file - this is the heart of the app in terms of data structures
//  The document represents a song and is self contained in that it can be told to playback and record its audio and also told to serialize and deserialize itself

import Foundation
import CoreFoundation
import AudioToolbox
import MediaPlayer
import AVFoundation
import MobileCoreServices
import AEXML


// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l <= r
    default:
        return !(rhs < lhs)
    }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}


enum EventTimeType : String
{
    case None = "None"
    case Prepare = "Prepare"
    case Fire = "Fire"
}

enum EventType : String
{
    case Unknown = "Unknown"
    case Line = "Line"
    case Chords = "Chords"
    case Audio = "Audio"
    case Structure = "Structure"
    case Conductor = "Conductor"
}

enum SubEventType : String
{
    case Unknown = "Unknown"
    case Word = "Word"
    case Chord = "Chord"
    case BPM = "BPM" // can be implied from bar beats
    case TimeSignature = "TimeSignature" // can be implied from bar beats
    case Bar = "Bar" // 1 of 1 2 3 4 ...
    case Beat = "Beat" // 2 of 1 2 3 4 etc
}

public enum TrackType : String
{
    case  Unknown
    
    // singletons
    case  Mixer
    case  Conductor
    case  KeySignature
    case  Structure
    
    // multiple
    case  Audio
    case  Words
    case  Chords
    case  Dynamics
    case  Midi
    case  SpokenCues
    case  Memo
    case  TAB
    case  InstrumentNotation
    case  DrumPattern
    case  Style
    case  IP
    case  Video
    case  DMXLighting
    case  AnalogueCV
    case  DigitalControl
    case  RS232
    case  Pyro
    
    static func all() -> [TrackType] {
        return [
            //TrackType.Unknown,
            TrackType.Mixer,
            TrackType.Conductor,
            TrackType.KeySignature,
            TrackType.Structure,
            
            TrackType.Audio,
            
            TrackType.Words,
            TrackType.Chords,
            TrackType.Dynamics,
            TrackType.Midi,
            TrackType.SpokenCues,
            TrackType.Memo,
            TrackType.TAB,
            TrackType.InstrumentNotation,
            TrackType.DrumPattern,
            TrackType.Style,
            TrackType.IP,
            TrackType.Video,
            TrackType.DMXLighting,
            TrackType.AnalogueCV,
            TrackType.DigitalControl,
            TrackType.RS232,
            TrackType.Pyro
        ]
    }
    
    static func purposeFor( _ trackType:TrackType ) -> [TrackPurpose] {
        var ret:[TrackPurpose] = []
        
        switch( trackType )
        {
        case TrackType.Audio:
            ret = [
                TrackPurpose.GuideAudio,
                TrackPurpose.BackingTrackAudio,
                TrackPurpose.ClickTrackAudio,
            ]
            break
            
        case TrackType.Words:
            ret = [
                TrackPurpose.MainLyrics,
                TrackPurpose.BackingLyrics,
                TrackPurpose.MaleLeadLyrics,
                TrackPurpose.FemaleLeadLyrics,
            ]
            break
            
            
        case TrackType.Chords:
            ret = [
                TrackPurpose.MainSongChords
            ]
            break
            
        default:
            ret = [
                TrackPurpose.Unknown
            ]
            break
        }
        
        return ret
    }
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .Conductor: return "Timing";
        case .KeySignature: return "Key Signature";
        case .Structure: return "Section Structure";
        case .InstrumentNotation: return "Instrument Notation";
        case .DrumPattern: return "Drum Pattern";
        default: return self.rawValue;
        }
    }
}

class TrackChange
{
    var _track:Int = -1
    var _audioTrackIdx:Int = -1
    var _volume:Float = 0
    var _specifics:AudioEventSpecifics! = nil
}

public let singletonTrackPurposes:[TrackPurpose] = [TrackPurpose.Mixer, TrackPurpose.Conductor, TrackPurpose.KeySignature, TrackPurpose.Structure, TrackPurpose.GuideAudio, TrackPurpose.ClickTrackAudio, TrackPurpose.MainLyrics, TrackPurpose.MaleLeadLyrics, TrackPurpose.FemaleLeadLyrics, TrackPurpose.MainSongChords ]

public func isSingletonTrackPurpose( _ purpose:TrackPurpose ) -> Bool
{
    return(singletonTrackPurposes.contains(purpose))
}

public enum TrackPurpose : String
{
    case Unknown
    
    // singletons
    case  Mixer
    case  Conductor
    case  KeySignature
    case  Structure
    
    case GuideAudio
    case BackingTrackAudio
    case ClickTrackAudio
    
    case MainLyrics
    case BackingLyrics
    case MaleLeadLyrics
    case FemaleLeadLyrics
    
    case TrackNotes
    case MusicalDirection
    
    case MainSongChords
    
    case GuitarTAB6String
    case BassTAB4String
    case BassTAB5String
    
    
    var description : String {
        switch self {
        // Use Internationalization, as appropriate.
        case .Conductor: return "Timing";
        case .KeySignature: return "Key Signature";
        case .Structure: return "Section Structure";
        case .GuideAudio: return "Guide Audio";
        case .BackingTrackAudio: return "Backing Track Audio";
        case .ClickTrackAudio: return "Click Track Audio";
        case .MainLyrics: return "Main Lyrics";
        case .BackingLyrics: return "Backing Lyrics";
        case .MaleLeadLyrics: return "Male Lead Lyrics";
        case .FemaleLeadLyrics: return "Female Lead Lyrics";
        case .TrackNotes: return "Track Notes";
        case .MusicalDirection: return "Musical Direction";
        case .MainSongChords: return "Main Song Chords";
        case .GuitarTAB6String: return "Guitar TAB 6 String";
        case .BassTAB4String: return "Bass TAB 4 String";
        case .BassTAB5String: return "Bass TAB 5 String";
        default: return self.rawValue;
        }
    }
}

struct MuzSubEvent {
    var _subEventType: SubEventType
    var _dataPosition: Int = 0
    var _dataLength: Int = 0
    var _offsetPrepareTime: TimeInterval? = nil
    var _offsetEventTime: TimeInterval? = nil
    var _data: String? = nil
    
    init( subEventType: SubEventType ) {
        self._subEventType = subEventType
    }
    
    init( xmlEle:AEXMLElement )
    {
        self._data = String()
        self._subEventType = SubEventType.Unknown
        deserialize( xmlEle )
    }
    
    internal func serialize()-> AEXMLElement
    {
        //let muzXMLDocAttributes = ["xmlns:xsi" : "http://www.w3.org/2001/XMLSchema-instance", "xmlns:xsd" : "http://www.w3.org/2001/XMLSchema"]
        //let body = muzXMLDoc.addChild(name: "Event")
        let ele = AEXMLElement(name: "SubEvent")//,  attributes: muzXMLDocAttributes)
        ele.addChild(name: "SubEventType", value: String(describing: _subEventType).replacingOccurrences(of: "Event_Sequencer.SubEventType.", with: ""))
        ele.addChild(name: "OffsetPrepareTime", value: String(describing: _offsetPrepareTime))
        ele.addChild(name: "OffsetEventTime", value: String(describing: _offsetEventTime))
        ele.addChild(name: "DataPosition", value: String(_dataPosition))
        ele.addChild(name: "DataLength", value: String(_dataLength))
        ele.addChild(name: "Data", value: String(describing: _data))
        return ele
    }
    
    fileprivate mutating func deserialize( _ xmlEle:AEXMLElement )
    {
        for child in xmlEle.children {
            //Logger.log(child.name)
            switch( child.name )
            {
            case "SubEventType":
                //Logger.log( "_subEventType: " + child.value! )
                _subEventType = SubEventType( rawValue: child.value! )!
                break;
                
            case "OffsetPrepareTime":
                //Logger.log( "offsetPrepareTime: " + child.value! )
                _offsetPrepareTime = TimeInterval(child.value!)
                break;
                
            case "OffsetEventTime":
                //Logger.log( "offsetEventTime: " + child.value! )
                _offsetEventTime = TimeInterval(child.value!)
                break;
                
            case "DataPosition":
                //Logger.log( "data position: " + child.value! )
                _dataPosition = Int(child.value!)!
                break;
                
            case "DataLength":
                //Logger.log( "data length: " + child.value! )
                _dataLength = Int(child.value!)!
                break;
                
            case "Data":
                //Logger.log( "data: " + child.value! )
                _data = child.value!
                break;
                
            default:
                Logger.log( "unknown MuzEvent element: " + child.name)
                break;
            }
        }
    }
}

public protocol EventSpecifics
{
    func serialize() -> AEXMLElement
    func deserialize( _ xmlEle:AEXMLElement )
}

open class AudioEventSpecifics : EventSpecifics {
    var _legacyPBChan = false
    
    var chan:Int = 1
    var volume:Float = 1.0
    var pan:Float = Float(0.0)
    var originalSourceURL:String = ""
    var favouriDevicePlayback = false
    var favourMultiChanPlayback = false
    var ignoreDownmixMultiChan  = false
    var ignoreDownmixiDevice  = false
    var downmixToMono = false
    
    // recording properties
    var recordArmed = false
    var inputChan:Int = -1
    var monitorWhileRecording = false
    var monitorInput = false
    var stereoInput = false
    
    init( xmlEle:AEXMLElement )
    {
        deserialize( xmlEle )
        if( inputChan == -1 )   // older files with no ins, default to out
        {
            inputChan = chan
        }
    }
    
    init()
    {
    }
    
    open func serialize()-> AEXMLElement
    {
        let ele = AEXMLElement(name: "AudioEventSpecifics")
        ele.addChild(name: "Chan", value: String(chan) )
        ele.addChild(name: "Volume", value: String(volume) )
        ele.addChild(name: "Pan", value: String(pan) )
        ele.addChild(name: "OriginalSourceURL", value: originalSourceURL.addingPercentEncoding(withAllowedCharacters: xmlAllowedSet) )
        ele.addChild(name: "FavouriDevicePlayback", value: favouriDevicePlayback ? "true" : "false")
        ele.addChild(name: "FavourMultiChanPlayback", value: favourMultiChanPlayback ? "true" : "false")
        ele.addChild(name: "DownmixToMono", value: downmixToMono ? "true" : "false")
        ele.addChild(name: "IgnoreDownmixMultiChan", value: ignoreDownmixMultiChan ? "true" : "false")
        ele.addChild(name: "IgnoreDownmixiDevice", value: ignoreDownmixiDevice ? "true" : "false")
        ele.addChild(name: "RecordArmed", value: recordArmed ? "true" : "false")
        ele.addChild(name: "InputChan", value: String(inputChan) )
        ele.addChild(name: "MonitorWhileRecording", value: monitorWhileRecording ? "true" : "false")
        ele.addChild(name: "MonitorInput", value: monitorInput ? "true" : "false")
        ele.addChild(name: "StereoInput", value: stereoInput ? "true" : "false")
        
        return( ele )
    }
    
    open func deserialize( _ xmlEle:AEXMLElement )
    {
        var legacyPBChan = true
        
        for child in xmlEle.children {
            //Logger.log(child.name)
            switch( child.name )
            {
            case "Chan":
                if( child.value != nil )
                {
                    //Logger.log( "Chan: " + child.value! )
                    chan = max(Int( child.value! )!,1)
                }
                break;
                
            case "Volume":
                if( child.value != nil )
                {
                    //Logger.log( "Volume: " + child.value! )
                    volume = Float( child.value! )!
                }
                break;
                
            case "Pan":
                if( child.value != nil )
                {
                    //Logger.log( "Pan: " + child.value! )
                    pan = Float( child.value! )!
                }
                break;
                
            case "OriginalSourceURL":
                if( child.value != nil )
                {
                    //Logger.log( "OriginalSourceURL: " + child.value! )
                    originalSourceURL = child.value != nil ? child.value!.removingPercentEncoding! : ""
                }
                break;
                
            case "FavouriDevicePlayback":
                if( child.value != nil )
                {
                    //Logger.log( "Chan: " + child.value! )
                    favouriDevicePlayback = child.bool!
                }
                break;
                
            case "FavourMultiChanPlayback":
                if( child.value != nil )
                {
                    legacyPBChan = false
                    //Logger.log( "Chan: " + child.value! )
                    favourMultiChanPlayback =  child.bool!
                }
                break;
                
            case "DownmixToMono":
                if( child.value != nil )
                {
                    //Logger.log( "Chan: " + child.value! )
                    downmixToMono =  child.bool!
                }
                break;
                
            case "IgnoreDownmixMultiChan":
                if( child.value != nil )
                {
                    //Logger.log( "Chan: " + child.value! )
                    ignoreDownmixMultiChan =  child.bool!
                }
                break;
                
            case "IgnoreDownmixiDevice":
                if( child.value != nil )
                {
                    //Logger.log( "Chan: " + child.value! )
                    ignoreDownmixiDevice =  child.bool!
                }
                break;
                
            case "RecordArmed":
                if( child.value != nil )
                {
                    //Logger.log( "Chan: " + child.value! )
                    recordArmed =  child.bool!
                }
                break;
                
            case "InputChan":
                if( child.value != nil )
                {
                    //Logger.log( "Chan: " + child.value! )
                    inputChan = max(Int( child.value! )!,1)
                }
                break;
                
            case "MonitorWhileRecording":
                if( child.value != nil )
                {
                    //Logger.log( "Chan: " + child.value! )
                    monitorWhileRecording =  child.bool!
                }
                break;
                
            case "MonitorInput":
                if( child.value != nil )
                {
                    //Logger.log( "Chan: " + child.value! )
                    monitorInput =  child.bool!
                }
                break;
                
            case "StereoInput":
                if( child.value != nil )
                {
                    //Logger.log( "Chan: " + child.value! )
                    stereoInput =  child.bool!
                }
                break;
                
            default:
                Logger.log( "unknown AudioEventSpecifics element: " + child.name)
                break;
            }
        }
        
        if( legacyPBChan ) // backward compatibility from 1.6 back
        {
            _legacyPBChan = true
        }
    }
}

public struct MuzEvent {
    var _eventType: EventType
    var _prepareTime: TimeInterval? = nil
    var _eventTime: TimeInterval? = nil
    var _data: String
    var _lineNumber: Int = 0
    var _subEvents: [MuzSubEvent] = []
    var _specifics: EventSpecifics? = nil
    
    init( audioEventSpecifics:AudioEventSpecifics?, data: String, lineNumber: Int ) {
        self._data = data
        self._eventType = EventType.Audio
        self._lineNumber = lineNumber
        self._specifics = audioEventSpecifics
    }
    
    init( eventType: EventType, data: String, lineNumber: Int ) {
        self._data = data
        self._eventType = eventType
        self._lineNumber = lineNumber
    }
    
    init( eventType: EventType, data: String, prepareTime: TimeInterval?, eventTime: TimeInterval?, lineNumber: Int ) {
        self._data = data
        self._eventType = eventType
        self._lineNumber = lineNumber
        self._prepareTime = prepareTime
        self._eventTime = eventTime
    }
    
    init( xmlEle:AEXMLElement )
    {
        self._data = String()
        self._eventType = EventType.Unknown
        deserialize( xmlEle )
    }
    
    internal func serialize()-> AEXMLElement
    {
        //let muzXMLDocAttributes = ["xmlns:xsi" : "http://www.w3.org/2001/XMLSchema-instance", "xmlns:xsd" : "http://www.w3.org/2001/XMLSchema"]
        //let body = muzXMLDoc.addChild(name: "Event")
        let ele = AEXMLElement(name: "Event")//,  attributes: muzXMLDocAttributes)
        ele.addChild(name: "EventType", value: String(describing: _eventType).replacingOccurrences(of: "Event_Sequencer.EventType.", with: ""))
        if( _prepareTime != nil )
        {
            ele.addChild(name: "PrepareTime", value: String(_prepareTime!))
        }
        else
        {
            ele.addChild(name: "PrepareTime", value: nil)
        }
        
        if( _eventTime != nil )
        {
            ele.addChild(name: "EventTime", value: String(_eventTime!))
        }
        else
        {
            ele.addChild(name: "EventTime", value: nil)
        }
        
        ele.addChild(name: "Data", value: String( htmlStringToEncode: String(_data) ))
        
        ele.addChild(name: "LineNumber", value: String(_lineNumber))
        
        if( _specifics != nil )
        {
            ele.addChild(_specifics!.serialize())
        }
        
        let events = ele.addChild(name: "SubEvents")
        for (_, evt) in _subEvents.enumerated() {
            events.addChild(evt.serialize())
        }
        return ele
    }
    
    fileprivate mutating func deserialize( _ xmlEle:AEXMLElement )
    {
        for child in xmlEle.children {
            //Logger.log(child.name)
            switch( child.name )
            {
            case "EventType":
                if( child.value != nil )
                {
                    //Logger.log( "_eventType: " + child.value! )
                    _eventType = EventType( rawValue: child.value! ) != nil ?EventType( rawValue: child.value! )! : EventType.Unknown
                }
                break;
                
            case "PrepareTime":
                if( child.value != nil )
                {
                    //Logger.log( "prepareTime: " + child.value! )
                    _prepareTime = TimeInterval(child.value!)
                }
                break;
                
            case "EventTime":
                if( child.value != nil )
                {
                    //Logger.log( "eventTime: " + child.value! )
                    _eventTime = TimeInterval(child.value!)
                }
                break;
                
            case "Data":
                if( child.value != nil )
                {
                    //Logger.log( "data: " + child.value! )
                    //_data = child.value!
                    //Logger.log( "data: " + child.safeValue! )
                    _data = String( htmlEncodedString: child.string )
                    //_data = child.string.removingPercentEncoding!.removingPercentEncoding!
                    /*
                    if( child.string == "Funky.mp3" )
                    {
                        print("Stop")
                    }
                    print( child.string  )*/
                }
                else
                {
                    //Logger.log( "data: nil" )
                    _data = ""
                }
                break;
                
            case "LineNumber":
                if( child.value != nil )
                {
                    //Logger.log( "line number: " + child.value! )
                    _lineNumber = Int(child.value!)!
                }
                break;
                
            case "AudioEventSpecifics":
                if( child.children.count > 0 )
                {
                    //Logger.log( "AudioEventSpecifics: " + child.children.description )
                    _specifics = AudioEventSpecifics( xmlEle: child )
                    
                }
                break;
                
            case "SubEvents":
                //Logger.log( "#_events: " + String(child.children.count) )
                _subEvents = []
                for eventEle in child.children {
                    //Logger.log(eventEle.name)
                    let newEvent:MuzSubEvent = MuzSubEvent(xmlEle: eventEle)
                    _subEvents.append(newEvent)
                }
                break;
                
            default:
                Logger.log( "unknown MuzEvent element: " + child.name)
                break;
            }
        }
    }
}

class MuzTrack {
    var _events: [MuzEvent] = []
    var _trackName: String
    var _trackType: TrackType
    var _trackPurpose: TrackPurpose
    var _defaultEventSpecifics: EventSpecifics!
    
    init( trackName: String, trackType: TrackType, trackPurpose: TrackPurpose, defaultEventSpecifics: EventSpecifics!, events: [MuzEvent] ) {
        self._trackName = trackName
        self._trackType = trackType
        self._trackPurpose = trackPurpose
        self._defaultEventSpecifics = defaultEventSpecifics
        self._events = events
    }
    
    init( xmlEle:AEXMLElement )
    {
        self._trackName = String()
        self._trackType = TrackType.Unknown
        self._trackPurpose = TrackPurpose.Unknown
        self._defaultEventSpecifics = nil
        deserialize( xmlEle )
    }
    
    internal func serialize()-> AEXMLElement
    {
        let ele = AEXMLElement(name: "Track")
        ele.addChild(name: "TrackType", value: String(describing: _trackType).replacingOccurrences(of: "Event_Sequencer.TrackType.", with: ""))
        ele.addChild(name: "TrackPurpose", value: String(describing: _trackPurpose).replacingOccurrences(of: "Event_Sequencer.TrackPurpose.", with: ""))
        ele.addChild(name: "TrackName", value: String(_trackName))
        
        if( self._defaultEventSpecifics != nil )
        {
            ele.addChild(self._defaultEventSpecifics.serialize())
        }
        
        let events = ele.addChild(name: "Events")
        for (_, evt) in _events.enumerated() {
            events.addChild(evt.serialize())
        }
        return ele
    }
    
    fileprivate func deserialize( _ xmlEle:AEXMLElement )
    {
        for child in xmlEle.children {
            //Logger.log(child.name)
            switch( child.name )
            {
            case "TrackType":
                //Logger.log( "_trackType: " + child.value! )
                _trackType = TrackType( rawValue: child.value! ) != nil ?TrackType( rawValue: child.value! )! : TrackType.Unknown
                break;
                
            case "TrackPurpose":
                //Logger.log( "_trackPurpose: " + child.value! )
                _trackPurpose = TrackPurpose( rawValue: child.value! ) != nil ?TrackPurpose( rawValue: child.value! )! : TrackPurpose.Unknown
                break;
                
            case "TrackName":
                let tn = child.value == nil ? "" : child.value!
                //Logger.log( "_trackName: " + tn )
                _trackName = tn
                break;
                
            case "AudioEventSpecifics":
                //if( _trackType == TrackType.Audio )
                //{
                let evtspec = AudioEventSpecifics( xmlEle: child )
                //Logger.log( "_eventSpecifcs chan: \(evtspec.chan)" )
                _defaultEventSpecifics = evtspec
                //}
                break;
                
            case "Events":
                //Logger.log( "#_events: " + String(child.children.count) )
                _events = []
                for eventEle in child.children {
                    //Logger.log(eventEle.name)
                    let newEvent:MuzEvent = MuzEvent(xmlEle: eventEle)
                    _events.append(newEvent)
                }
                break;
                
            default:
                Logger.log( "unknown MuzTrack element: " + child.name)
                break;
            }
        }
    }
}


open class MuzomaDocument : NSObject, AVAudioPlayerDelegate
{
    var _isSlaveForBandPlay = false
    var _isPlaceholder = false
    var _isInDeserialize = false
    var _uid: String? = nil
    var _tracks: [MuzTrack] = []
    var _chordPallet: [Chord] = []
    
    fileprivate var artist:String? = nil
    var _artist:String?
    {
        get
        {
            return artist
        }
        
        set
        {
            artist = newValue?.replacingOccurrences(of: "/", with: " ").stringByRemovingCharactersInSet(acceptableProperSet.inverted)  // fwd slash is directory character so cant use, replace with space, others just remove
        }
    }
    
    fileprivate var title:String? = nil
    var _title:String?
    {
        get
        {
            return title
        }
        
        set
        {
            title = newValue?.replacingOccurrences(of: "/", with: " ").stringByRemovingCharactersInSet(acceptableProperSet.inverted) // fwd slash is directory character so cant use, others just remove
        }
    }
    
    var _author: String? = nil
    var _copyright: String? = nil
    var _publisher: String? = nil
    var _coverArtURL: String? = nil
    var _originalArtworkURL: String? = nil
    var _key: String? = nil
    var _tempo: String? = nil
    var _timeSignature: String? = nil
    
    var _muzVersion: String? = nil
    var _muzAuthor: String? = nil
    var _muzAuthorUID: String? = nil
    var _creationDate: Date? = nil
    var _lastUpdateDate: Date? = nil
    
    var _setsOnly: Bool? = nil
    var _isBeingPlayedFromSet: Bool = false
    
    // used by editors
    var _activeEditTrack: Int = 0
    
    var _fromSetTitled: String? = nil
    var _fromSetArtist: String? = nil
    var _fromSetTrackIdx: Int? = nil
    var _fromSetTrackCount: Int? = nil
    
    
    override init()
    {
    }
    
    open func isValid() -> Bool
    {
        return( self._uid != nil )
    }
    
    open func getMainLyricTrackIndex() -> Int
    {
        var ret:Int = -1
        
        for (idx, track) in _tracks.enumerated() {
            
            if( track._trackPurpose == TrackPurpose.MainLyrics )
            {
                ret = idx
                break
            }
        }
        
        return( ret )
    }
    
    open func getMainChordTrackIndex() -> Int
    {
        var ret:Int = -1
        
        for (idx, track) in _tracks.enumerated() {
            
            if( track._trackPurpose == TrackPurpose.MainSongChords )
            {
                ret = idx
                break
            }
        }
        
        return( ret )
    }
    
    open func getGuideTrackIndex() -> Int
    {
        var ret:Int = -1
        
        for (idx, track) in _tracks.enumerated() {
            
            if( track._trackPurpose == TrackPurpose.GuideAudio )
            {
                ret = idx
                break
            }
        }
        
        return( ret )
    }
    
    open func getClickTrackIndex() -> Int
    {
        var ret:Int = -1
        
        for (idx, track) in _tracks.enumerated() {
            
            if( track._trackPurpose == TrackPurpose.ClickTrackAudio )
            {
                ret = idx
                break
            }
        }
        
        return( ret )
    }
    
    open func getStructureTrackIndex() -> Int
    {
        var ret:Int = -1
        
        for (idx, track) in _tracks.enumerated() {
            
            if( track._trackPurpose == TrackPurpose.Structure )
            {
                ret = idx
                break
            }
        }
        
        return( ret )
    }
    
    open func getBackingTrackIndexes() -> [Int]
    {
        var ret:[Int] = []
        
        for (idx, track) in _tracks.enumerated() {
            
            if( track._trackPurpose == TrackPurpose.BackingTrackAudio
                || track._trackPurpose == TrackPurpose.ClickTrackAudio )
            {
                ret.append(idx)
            }
        }
        
        return( ret )
    }
    
    open func getAudioTrackIndexes() -> [Int]
    {
        var ret:[Int] = []
        ret.append(self.getGuideTrackIndex())
        ret.append(contentsOf: self.getBackingTrackIndexes())
        return( ret )
    }
    
    open func ensureEvents()
    {
        var maxLines:Int = 1 // min is one line
        for track in _tracks
        {
            if( track._events.count > maxLines )
            {
                maxLines = track._events.count
            }
        }
        ensureEvents( maxLines )
    }
    
    open func addNewTrack( _ trackName:String, trackType:TrackType, trackPurpose:TrackPurpose,
                           eventspecifcs:EventSpecifics!) -> Int
    {
        let track:MuzTrack = MuzTrack( trackName: (trackName.replacingOccurrences(of: "/", with: " ").stringByRemovingCharactersInSet(acceptableProperSet.inverted)) /* fwd slash is directory character so cant use, others just remove*/, trackType: trackType, trackPurpose: trackPurpose, defaultEventSpecifics:eventspecifcs, events:[MuzEvent]())
        self._tracks.append(track)
        self.ensureEvents()
        return( _tracks.count - 1 )
    }
    
    open func removeTrack( _ track:Int )
    {
        self._tracks.remove(at: track)
    }
    
    open func ensureEvents( _ lineCnt:Int )
    {
        for track in _tracks  {
            
            //let lineCnt = self._activeLine + 1
            
            switch( track._trackPurpose )
            {
            case TrackPurpose.MainLyrics:
                if( track._events.count < lineCnt ) // blank line needed?
                {
                    let start = track._events.count
                    for evtIdx in ( start ..< lineCnt )
                    {
                        track._events.append(MuzEvent(eventType: EventType.Line, data: "", lineNumber: evtIdx+1))
                    }
                }
                break;
                
            case TrackPurpose.MainSongChords:
                if( track._events.count < lineCnt ) // blank line needed?
                {
                    let start = track._events.count
                    for evtIdx in ( start ..< lineCnt )
                    {
                        track._events.append(MuzEvent(eventType: EventType.Chords, data: "", lineNumber: evtIdx+1))
                    }
                }
                break;
                
            case TrackPurpose.GuideAudio,
                 TrackPurpose.BackingTrackAudio,
                 TrackPurpose.ClickTrackAudio:
                if( track._events.count < lineCnt ) // blank line needed?
                {
                    let start = track._events.count
                    for evtIdx in ( start ..< lineCnt )
                    {
                        track._events.append(MuzEvent( audioEventSpecifics: nil, data: "", lineNumber: evtIdx+1))
                    }
                }
                break;
                
            case TrackPurpose.Structure:
                if( track._events.count < lineCnt ) // blank line needed?
                {
                    let start = track._events.count
                    for evtIdx in ( start ..< lineCnt )
                    {
                        track._events.append(MuzEvent(eventType: EventType.Structure, data: "", lineNumber: evtIdx+1))
                    }
                }
                break;
                
            case TrackPurpose.Conductor:
                if( track._events.count < lineCnt ) // blank line needed?
                {
                    let start = track._events.count
                    for evtIdx in ( start ..< lineCnt )
                    {
                        track._events.append(MuzEvent(eventType: EventType.Conductor, data: "", lineNumber: evtIdx+1))
                    }
                }
                break;
                
                
            default:
                if( track._events.count < lineCnt ) // blank line needed?
                {
                    let start = track._events.count
                    for evtIdx in ( start ..< lineCnt )
                    {
                        track._events.append(MuzEvent(eventType: EventType.Line, data: "", lineNumber: evtIdx+1))
                    }
                }
                break;
            }
        }
    }
    
    open func resetTiming( _ lineMin:Int! = nil, lineMax:Int! = nil )
    {
        ensureEvents()
        
        var first = 0
        if( lineMin != nil )
        {
            first = lineMin!
        }
        
        var last = 0
        if( lineMax == nil )
        {
            last = _tracks[0]._events.count
        }
        else
        {
            last = lineMax!
        }
        
        for track in _tracks  {
            
            for evtIdx in ( first ..< last )
            {
                track._events[evtIdx]._eventTime = nil
                track._events[evtIdx]._prepareTime = nil
            }
        }
    }
    
    
    open func insertLine( _ lineCnt:Int )
    {
        for track in _tracks  {
            
            //let lineCnt = self._activeLine + 1
            
            if( track._events.count < lineCnt )
            {
                switch( track._trackPurpose )
                {
                case TrackPurpose.MainLyrics:
                    track._events.insert( MuzEvent(eventType: EventType.Line, data: "", lineNumber: lineCnt), at: lineCnt)
                    break;
                    
                case TrackPurpose.MainSongChords:
                    track._events.insert(MuzEvent(eventType: EventType.Chords, data: "", lineNumber: lineCnt),at: lineCnt)
                    break;
                    
                    /* don't insert above the guide audio */
                case TrackPurpose.GuideAudio,
                     TrackPurpose.BackingTrackAudio,
                     TrackPurpose.ClickTrackAudio:
                    track._events.insert(MuzEvent( audioEventSpecifics: nil, data: "", lineNumber: lineCnt),at: lineCnt+1)
                    break;
                    
                case TrackPurpose.Structure:
                    track._events.insert(MuzEvent(eventType: EventType.Structure, data: "", lineNumber: lineCnt),at: lineCnt)
                    break;
                    
                case TrackPurpose.Conductor:
                    track._events.insert(MuzEvent(eventType: EventType.Conductor, data: "", lineNumber: lineCnt),at: lineCnt)
                    break;
                    
                default:
                    track._events.insert(MuzEvent(eventType: EventType.Line, data: "", lineNumber: lineCnt),at: lineCnt)
                    break;
                }
            }
            else
            {
                switch( track._trackPurpose )
                {
                case TrackPurpose.MainLyrics:
                    track._events.append( MuzEvent(eventType: EventType.Line, data: "", lineNumber: lineCnt) )
                    break;
                    
                case TrackPurpose.MainSongChords:
                    track._events.append(MuzEvent(eventType: EventType.Chords, data: "", lineNumber: lineCnt) )
                    break;
                    
                    /* don't insert above the guide audio */
                case TrackPurpose.GuideAudio,
                     TrackPurpose.BackingTrackAudio,
                     TrackPurpose.ClickTrackAudio:
                    track._events.append(MuzEvent( audioEventSpecifics: nil, data: "", lineNumber: lineCnt) )
                    break;
                    
                case TrackPurpose.Structure:
                    track._events.append(MuzEvent(eventType: EventType.Structure, data: "", lineNumber: lineCnt) )
                    break;
                    
                case TrackPurpose.Conductor:
                    track._events.append(MuzEvent(eventType: EventType.Conductor, data: "", lineNumber: lineCnt) )
                    break;
                    
                default:
                    track._events.append(MuzEvent(eventType: EventType.Line, data: "", lineNumber: lineCnt) )
                    break;
                }
            }
        }
    }
    
    open func appendLyricLine( _ event:MuzEvent )
    {
        let track:Int = self.getMainLyricTrackIndex()
        //event._lineNumber
        if( track > -1 )
        {
            ensureEvents(event._lineNumber+2)
            _tracks[track]._events[event._lineNumber] = event
        }
    }
    
    open func appendChordLine( _ event:MuzEvent )
    {
        let track:Int = self.getMainChordTrackIndex()
        //event._lineNumber
        if( track > -1 )
        {
            ensureEvents(event._lineNumber+2)
            _tracks[track]._events[event._lineNumber] = event
        }
    }
    
    open func appendStructureLine( _ event:MuzEvent )
    {
        let track:Int = self.getStructureTrackIndex()
        //event._lineNumber
        if( track > -1 )
        {
            ensureEvents(event._lineNumber+2)
            _tracks[track]._events[event._lineNumber] = event
        }
    }
    
    open func appendLineEvent( _ line:Int )
    {
        ensureEvents(line+2)
    }
    
    open func lineContainsAudioEvent( _ line:Int ) -> Bool
    {
        var ret = false
        
        for (_, track) in _tracks.enumerated() {
            if( track._events.count >= line )
            {
                if( track._trackType == TrackType.Audio && !track._events[line]._data.isEmpty )
                {
                    ret = true
                    break;
                }
            }
        }
        
        return( ret )
    }
    
    open  func deleteLineEvent( _ line:Int )
    {
        for (_, track) in _tracks.enumerated() {
            if( track._events.count >= line && track._events.count > 0 )
            {
                track._events.remove(at: line)
            }
        }
        
        ensureEvents()
    }
    
    // actual
    open func getDocumentFolderPathURL() -> URL?
    {
        var ret:URL?=nil
        if(self._diskFolderFilePath != nil)
        {
            ret = self._diskFolderFilePath.deletingLastPathComponent() // deserialized from a path
        }
        else
        {
            // the default path
            ret = _gDocURL.appendingPathComponent(getFolderName(),isDirectory: true)
        }
        return( ret )
    }
    
    //correct folder
    open func getCorrectDocumentFolderPathURL() -> URL?
    {
        var ret:URL?=nil
        
        ret = _gDocURL.appendingPathComponent(getFolderName(),isDirectory: true)
        
        return( ret )
    }
    
    open func getDocumentURL() -> URL?
    {
        var ret:URL? = nil
        
        ret = getDocumentFolderPathURL()!.appendingPathComponent(getFileName())
        
        return( ret )
    }
    
    open func ensureDocumentURLExists() -> Bool
    {
        var ret:Bool = false
        ret = _gFSH.ensureFolderExists(getDocumentFolderPathURL())
        return ret
    }
    
    open func getClickTrackURL() -> URL?
    {
        var ret:URL? = nil
        
        let idx = getClickTrackIndex()
        if( idx > -1 )
        {
            if(_tracks[idx]._events.count > 0 )
            {
                let fileName = _tracks[idx]._events[0]._data
                ret = getDocumentFolderPathURL()!.appendingPathComponent(fileName)
                //Logger.log("Guide track URL is \(ret?.absoluteString)")
            }
        }
        
        return( ret )
    }
    
    open func getGuideTrackURL() -> URL?
    {
        var ret:URL? = nil
        
        let idx = getGuideTrackIndex()
        if( idx > -1 )
        {
            if(_tracks[idx]._events.count > 0 )
            {
                let fileName = _tracks[idx]._events[0]._data
                ret = getDocumentFolderPathURL()!.appendingPathComponent(fileName)
                //Logger.log("Guide track URL is \(ret?.absoluteString)")
            }
        }
        
        return( ret )
    }
    
    
    open func getGuideTrackRecordURL( _ fileName:String = "GuideRec.m4a" ) -> URL?
    {
        var ret:URL? = nil
        
        let idx = getGuideTrackIndex()
        if( idx > -1 )
        {
            if(_tracks[idx]._events.count > 0 )
            {
                //let fileName = "GuideRec.caf"
                if( self._diskFolderFilePath == nil ) // we haven't saved yet - new doc, need somewhere to record to!
                {
                    _ = self.ensureDocumentURLExists()
                }
                ret = getDocumentFolderPathURL()!.appendingPathComponent(fileName)
            }
        }
        
        return( ret )
    }
    
    open func getGuideTrackOriginalURL() -> URL?
    {
        var ret:URL? = nil
        
        let specifcs = getGuideTrackSpecifics()
        if( specifcs != nil )
        {
            ret = URL(fileURLWithPath: (specifcs?.originalSourceURL)!)
        }
        
        return( ret )
    }
    
    open func getClickTrackSpecifics() -> AudioEventSpecifics!
    {
        var ret:AudioEventSpecifics? = nil
        
        let idx = getClickTrackIndex()
        if( idx > -1 )
        {
            ret = getAudioTrackSpecifics(idx) // guide track should always be the first entry in the list
        }
        
        return( ret )
    }
    
    open func getGuideTrackSpecifics() -> AudioEventSpecifics!
    {
        var ret:AudioEventSpecifics? = nil
        
        let idx = getGuideTrackIndex()
        if( idx > -1 )
        {
            ret = getAudioTrackSpecifics(idx) // guide track should always be the first entry in the list
        }
        
        return( ret )
    }
    
    
    open func getBackingTrackSpecifics() -> [AudioEventSpecifics?]
    {
        var ret:[AudioEventSpecifics?] = [AudioEventSpecifics?]()
        
        let idxes = getBackingTrackIndexes()
        for idx in ( 0 ..< idxes.count )
        {
            ret.append(getAudioTrackSpecifics(idxes[idx]))
        }
        
        return( ret )
    }
    
    open func getAudioTrackSpecifics( _ track:Int, event:Int = -1 ) -> AudioEventSpecifics!
    {
        var ret:AudioEventSpecifics? = nil
        
        let idx = track
        if( idx > -1 && _tracks[idx]._trackType == TrackType.Audio )
        {
            if(_tracks[idx]._events.count == 0 )
            {
                ensureEvents()
            }
            
            if( event == -1 ) // assume the first entry in the list
            {
                ret = _tracks[idx]._events[0]._specifics as? AudioEventSpecifics
            }
            
            if( ret == nil ) // fallback on defaults
            {
                ret = _tracks[idx]._defaultEventSpecifics as? AudioEventSpecifics
            }
            
            if( ret == nil ) // no defaults, then create them
            {
                _tracks[idx]._events[0]._specifics = AudioEventSpecifics()
                ret = _tracks[idx]._events[0]._specifics as! AudioEventSpecifics?
            }
        }
        
        return( ret )
    }
    
    open func getBackingTrackURLs() -> [URL?]
    {
        var ret:[URL?] = []
        
        let idxes = getBackingTrackIndexes()
        for idx in ( 0 ..< idxes.count )
        {
            var fileName:String = ""
            if(_tracks[idxes[idx]]._events.count > 0 )
            {
                fileName = _tracks[idxes[idx]]._events[0]._data
            }
            
            if( fileName != "" )
            {
                ret.append(getDocumentFolderPathURL()!.appendingPathComponent(fileName))
                //Logger.log("Backing track URL is \(ret[idx])")
            }
            else
            {
                ret.append(getDocumentFolderPathURL()!)
            }
        }
        
        return( ret )
    }
    
    open func getBackingTrackRecordURLs(_ fileNameAddition:String = "_Rec.m4a") -> [URL?]
    {
        var ret:[URL?] = []
        
        let idxes = getBackingTrackIndexes()
        for idx in ( 0 ..< idxes.count )
        {
            //let fileName:String = "Track_"+String(idxes[idx])+"_Rec.caf"
            let fileName:String = "Track_" + String(idxes[idx]) + fileNameAddition
            if( fileName != "" )
            {
                ret.append(getDocumentFolderPathURL()!.appendingPathComponent(fileName))
                //Logger.log("Backing track URL is \(ret[idx])")
            }
        }
        
        return( ret )
    }
    
    open func setOriginalURLForGuideTrack(_ url:URL?)
    {
        let idx = getGuideTrackIndex()
        if( idx > -1 )
        {
            if(_tracks[idx]._events.count > 0 )
            {
                if( _tracks[idx]._events[0]._specifics == nil )
                {
                    _tracks[idx]._events[0]._specifics = AudioEventSpecifics()
                }
                let specifics = _tracks[idx]._events[0]._specifics as! AudioEventSpecifics
                specifics.originalSourceURL = (url?.path)!
            }
        }
    }
    
    open func updateArtwork()
    {
        let artURL = self.getArtworkURL()
        if( artURL != nil )
        {
            let data = try? Data( contentsOf: artURL! )
            if( data != nil )
            {
                let image = UIImage( data: data! )
                if( image != nil )
                {
                    _artwork = MPMediaItemArtwork( image: image! )
                }
            }
        }
    }
    
    open func updateArtworkFromOriginalURL()
    {
        let artURL:URL! = self._originalArtworkURL != nil ? URL( string: self._originalArtworkURL! ) : nil
        if( artURL != nil )
        {
            let data = try? Data( contentsOf: artURL! )
            if( data != nil )
            {
                let image = UIImage( data: data! )
                if( image != nil )
                {
                    _artwork = MPMediaItemArtwork( image: image! )
                    
                    // save to doc folder
                    let saveArtURL = self.getDocumentFolderPathURL()?.appendingPathComponent( self.getFolderName() + "." + artURL!.pathExtension )
                    
                    if( _gFSH.fileExists(saveArtURL!) ) // file exists?
                    {
                        // remove the old file
                        do
                        {
                            try _gFSH.removeItem(at: saveArtURL!)
                            Logger.log("\(#function)  \(#file) Deleted \(saveArtURL!.absoluteString)")
                        } catch let error as NSError {
                            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                        }
                    }
                    
                    // copy the new one
                    do
                    {
                        let jpg = image!.jpegData(compressionQuality: 100)
                        try jpg?.write(to: saveArtURL!, options: .atomicWrite)
                        //try fileManager.copyItemAtURL( artURL!, toURL: saveArtURL!)
                        self._coverArtURL = saveArtURL?.lastPathComponent
                    }
                    catch let error as NSError {
                        Logger.log("\(#function)  \(#file)  \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    open func setOriginalURLForArtwork(_ url:URL?)
    {
        _originalArtworkURL = (url?.path)!
    }
    
    open func getOriginalArtworkURL() -> URL?
    {
        var ret:URL? = nil
        
        //print( "Original art \(self._originalArtworkURL)" )
        
        if( _originalArtworkURL == nil || _originalArtworkURL!.isEmpty )
        {
            ret = _gDocURL.appendingPathComponent("Song Placeholder.png")
        }
        else
        {
            let urlStr = self._originalArtworkURL?.replacingOccurrences(of: "file://", with: "").removingPercentEncoding
            ret = URL( fileURLWithPath: urlStr!, isDirectory: false).absoluteURL
        }
        
        
        return( ret )
    }
    
    open func getArtworkURL() -> URL?
    {
        var ret:URL? = nil
        
        if( _coverArtURL == nil || _coverArtURL!.isEmpty )
        {
            ret = _gDocURL.appendingPathComponent("Song Placeholder.png")
            //print("artwork placeholder url is \(ret?.absoluteString)")
        }
        else
        {
            ret = getDocumentFolderPathURL()!.appendingPathComponent(_coverArtURL!)
            //print("artwork url is \(ret?.absoluteString)")
        }
        
        return( ret )
    }
    
    fileprivate static var _placeholderArtwork:MPMediaItemArtwork! = nil
    open var placeholderArtwork:MPMediaItemArtwork!
        {
        get
        {
            if( MuzomaDocument._placeholderArtwork == nil )
            {
                let data = try? Data( contentsOf: _gDocURL.appendingPathComponent("Song Placeholder.png") )
                if( data != nil )
                {
                    let image = UIImage( data: data! )
                    if( image != nil )
                    {
                        MuzomaDocument._placeholderArtwork = MPMediaItemArtwork( image: image! )
                    }
                }
            }
            return(MuzomaDocument._placeholderArtwork)
        }
    }
    
    fileprivate static var _loadingPlaceholderArtwork:MPMediaItemArtwork! = nil
    open var loadingPlaceholderArtwork:MPMediaItemArtwork!
        {
        get
        {
            if( MuzomaDocument._loadingPlaceholderArtwork == nil )
            {
                let data = try? Data( contentsOf: _gDocURL.appendingPathComponent("Placeholder load.gif") )
                if( data != nil )
                {
                    let image = UIImage( data: data! )
                    if( image != nil )
                    {
                        MuzomaDocument._loadingPlaceholderArtwork = MPMediaItemArtwork( image: image! )
                    }
                }
            }
            return(MuzomaDocument._loadingPlaceholderArtwork)
        }
    }
    
    open func getFileName() -> String
    {
        let prefix = _artist == nil ? "" : _artist!
        let suffix = _title == nil ? "" : _title!
        return( prefix + " - " + suffix + ".muz.xml")
    }
    
    open func getFolderName() -> String
    {
        let prefix = _artist == nil ? "" : _artist!
        let suffix = _title == nil ? "" : _title!
        return( prefix + " - " + suffix )
    }
    
    fileprivate var _diskFolderFilePath:URL! = nil
    open var diskFolderFilePath : URL!
        {
        get {
            if( _diskFolderFilePath == nil )
            {
                _diskFolderFilePath = self.getDocumentFolderPathURL()!.appendingPathComponent( getFileName() )
            }
            return _diskFolderFilePath
        }
        
        set {
            _diskFolderFilePath = newValue
        }
    }
    
    var diskFolderFilePathString:String{
        get{
            let componentsCount = self.diskFolderFilePath!.pathComponents.count
            let components = self.diskFolderFilePath!.pathComponents
            let path = components[componentsCount-2] + "/" + components[componentsCount-1]
            return( path )
        }
    }
    
    open func getMuzZipFileName() -> String
    {
        let prefix = _artist == nil ? "" : _artist!
        let suffix = _title == nil ? "" : _title!
        return( prefix + " - " + suffix + ".muz" )
    }
    
    open func getAudioZipFileName() -> String
    {
        let prefix = _artist == nil ? "" : _artist!
        let suffix = _title == nil ? "" : _title!
        return( prefix + " - " + suffix + ".zip" )
    }
    
    open func clearChordAndLyricEvents()
    {
        (_tracks[self.getMainChordTrackIndex()]._events).removeAll()
        (_tracks[self.getStructureTrackIndex()]._events).removeAll()
        (_tracks[self.getMainLyricTrackIndex()]._events).removeAll()
    }
    
    open func loadEmptyDefaultSong()
    {
        _uid = UUID().uuidString
        let reg = UserRegistration()
        _title = "Song 1"
        _artist = reg.artist ?? "Artist"
        _author = reg.author ?? "Author"
        _copyright = reg.copyright ?? "(c) " + Date().datePretty
        _publisher = reg.publisher ?? "Publisher"
        _coverArtURL = ""
        _muzVersion = Version.DocVersion
        _muzAuthor = reg.communityName ?? "My Name"
        _muzAuthorUID = reg.userId ?? ""
        _creationDate = Date()
        _lastUpdateDate = Date()
        _key = nil
        _tempo = nil
        _timeSignature = nil
        _chordPallet = [Chord]()
        
        _tracks = [
            
            MuzTrack(trackName: "Structure", trackType: TrackType.Structure, trackPurpose: TrackPurpose.Structure, defaultEventSpecifics:nil,
                     events: [
                        //MuzEvent( eventType: EventType.Structure, data: "Count In", lineNumber: 0 )
                ]),
            /*
             MuzTrack(trackName: "Conductor", trackType: TrackType.Conductor, trackPurpose: TrackPurpose.Conductor, defaultEventSpecifics:nil,
             events: [
             MuzEvent( eventType: EventType.Conductor, data: "|", lineNumber: 0 )
             ]),
             */
            MuzTrack(trackName: "Guide Audio", trackType: TrackType.Audio, trackPurpose: TrackPurpose.GuideAudio, defaultEventSpecifics:nil,
                     events: [
                        // MuzEvent( audioEventSpecifics: AudioEventSpecifics(), data: "", lineNumber: 0 )
                ]),
            
            MuzTrack(trackName: "Chords", trackType: TrackType.Chords, trackPurpose: TrackPurpose.MainSongChords, defaultEventSpecifics:nil,
                     events: [
                        // MuzEvent( eventType: EventType.Chords, data: "n.c.", lineNumber: 0 )
                ]),
            
            MuzTrack(trackName: "Lyrics", trackType: TrackType.Words, trackPurpose: TrackPurpose.MainLyrics, defaultEventSpecifics:nil,
                     
                     events: [
                        /* MuzEvent( eventType: EventType.Line, data: "1   2   3   4", lineNumber: 0 ),
                         MuzEvent( eventType: EventType.Line, data: "A new song line 1", lineNumber: 1 ),
                         MuzEvent( eventType: EventType.Line, data: "A new song line 2", lineNumber: 2 ),*/
                ])]
        ensureEvents()
    }
    
    open func defaultGuideTrackRecordSettings()
    {
        let guideSpecifics = self.getGuideTrackSpecifics()
        guideSpecifics?.chan = 1
        guideSpecifics?.favouriDevicePlayback = true
        guideSpecifics?.favourMultiChanPlayback = true
        guideSpecifics?.inputChan = 1
        guideSpecifics?.recordArmed = true
    }
    
    open func setDataForTrackEvent( _ trackIdx:Int, eventIdx:Int, url:URL )
    {
        if( self._tracks[trackIdx]._events.count <= eventIdx )
        {
            ensureEvents()
        }
        
        if( !url.path.isEmpty )
        {
            self._tracks[trackIdx]._events[eventIdx]._data = url.lastPathComponent // just the file name
        } else {
            self._tracks[trackIdx]._events[eventIdx]._data = ""
        }
    }
    
    open func setDataForTrackEvent( _ trackIdx:Int, eventIdx:Int, data:String! )
    {
        if( self._tracks[trackIdx]._events.count <= eventIdx )
        {
            ensureEvents()
        }
        
        if( data != nil )
        {
            self._tracks[trackIdx]._events[eventIdx]._data = data! // just the string
        } else {
            self._tracks[trackIdx]._events[eventIdx]._data = ""
        }
    }
    
    open func getTrackDataAsURL( _ trackIdx:Int, eventIdx:Int ) -> URL?
    {
        var ret:URL? = nil
        
        if( self._tracks[trackIdx]._events.count <= eventIdx )
        {
            ensureEvents()
        }
        
        let fileName = self._tracks[trackIdx]._events[eventIdx]._data
        if(fileName != "")
        {
            ret = self.getDocumentFolderPathURL()!.appendingPathComponent(fileName)
        }
        
        return( ret )
    }
    
    open func getTrackFileName( _ trackIdx:Int, eventIdx:Int ) -> String
    {
        var ret = ""
        
        if( self._tracks[trackIdx]._events.count <= eventIdx )
        {
            ensureEvents()
        }
        
        let fileName = self._tracks[trackIdx]._events[eventIdx]._data
        if(fileName != "")
        {
            let url = URL(fileURLWithPath: fileName)
            ret = url.lastPathComponent
        }
        
        return( ret )
    }
    
    open func removeTrackFile( _ trackIdx:Int, eventIdx:Int ) -> Bool
    {
        var ret = false
        
        let fileURL = getTrackDataAsURL( trackIdx, eventIdx: eventIdx )
        
        if( fileURL != nil && _gFSH.fileExists( fileURL ) )
        {
            do
            {
                try _gFSH.removeItem(at: fileURL!)
                Logger.log("\(#function)  \(#file) Deleted \(fileURL!.absoluteString)")
                self.setDataForTrackEvent(trackIdx, eventIdx: 0, url: URL(string: "about:blank")!)
                ret = true
            } catch let error as NSError {
                Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                
            }
        }
        
        return( ret )
    }
    
    open func getAudioEventSpecifics( _ trackIdx:Int, eventIdx:Int ) -> AudioEventSpecifics?
    {
        if( self._tracks[trackIdx]._events.count <= eventIdx )
        {
            ensureEvents()
        }
        
        let specifics = self._tracks[trackIdx]._events[eventIdx]._specifics

        return( specifics as! AudioEventSpecifics? )
    }
    
    open func toggleRecordArm( _ recordOn:Bool = false ) -> Bool
    {
        var done = true
        self.stop()
        
        for track in self.getBackingTrackIndexes()
        {
            let specifics =  self.getAudioTrackSpecifics(track)
            if( specifics != nil )
            {
                specifics?.recordArmed = recordOn
                done = true
            }
        }
        
        
        let specifics = self.getAudioTrackSpecifics(self.getGuideTrackIndex())
        if( specifics != nil )
        {
            specifics?.recordArmed = recordOn
            done = true
        }
        
        return( done )
    }
    
    
    open func enableDisableiDeviceOnAllTracks( _ leaveGuide:Bool = false, enable:Bool ) -> Bool
    {
        var done = true
        self.stop()
        
        for track in self.getBackingTrackIndexes()
        {
            let specifics =  self.getAudioTrackSpecifics(track)
            if( specifics != nil )
            {
                specifics?.favouriDevicePlayback = enable
                done = true
            }
        }
        
        if( !leaveGuide )
        {
            let specifics =  self.getAudioTrackSpecifics(self.getGuideTrackIndex())
            if( specifics != nil )
            {
                specifics?.favouriDevicePlayback = enable
                done = true
            }
        }
        
        return( done )
    }
    
    open func enableDisableMultiChanOnAllTracks( _ leaveGuide:Bool = false, enable:Bool  ) -> Bool
    {
        var done = true
        self.stop()
        
        for track in self.getBackingTrackIndexes()
        {
            let specifics =  self.getAudioTrackSpecifics(track)
            if( specifics != nil )
            {
                specifics?.favourMultiChanPlayback = enable
                done = true
            }
        }
        
        if( !leaveGuide )
        {
            let specifics =  self.getAudioTrackSpecifics(self.getGuideTrackIndex())
            if( specifics != nil )
            {
                specifics?.favourMultiChanPlayback = enable
                done = true
            }
        }
        
        return( done )
    }
    
    open func downMixMonoAllTracks( _ leaveGuide:Bool = false, on:Bool = true ) -> Bool
    {
        var done = true
        self.stop()
        
        for track in self.getBackingTrackIndexes()
        {
            let specifics =  self.getAudioTrackSpecifics(track)
            if( specifics != nil )
            {
                specifics?.downmixToMono = on
                specifics?.pan = on == true ? -1.0 : 0.0
                specifics?.ignoreDownmixMultiChan = false
                specifics?.ignoreDownmixiDevice = true
                done = true
            }
        }
        
        if( !leaveGuide )
        {
            let specifics =  self.getAudioTrackSpecifics(self.getGuideTrackIndex())
            if( specifics != nil )
            {
                specifics?.downmixToMono = on
                specifics?.pan = 0.0
                specifics?.ignoreDownmixMultiChan = false
                specifics?.ignoreDownmixiDevice = false
                done = true
            }
        }
        
        return( done )
    }
    
    open func serialize() -> String
    {
        ensureEvents()
        self._originalArtworkURL = self.getArtworkURL()?.absoluteString // update this before sending on
        
        let muzXMLDoc = AEXMLDocument()
        let muzXMLDocAttributes = ["xmlns:xsi" : "http://www.w3.org/2001/XMLSchema-instance", "xmlns:xsd" : "http://www.w3.org/2001/XMLSchema"]
        let body = muzXMLDoc.addChild(name: "Muzoma", attributes: muzXMLDocAttributes)
        
        let header = body.addChild(name: "Header")
        header.addChild(name: "UID", value: _uid != nil ? String(_uid!) : nil )
        
        header.addChild(name: "Title", value: _title != nil ? String(_title!).addingPercentEncoding(withAllowedCharacters: xmlAllowedSet) : nil )
        header.addChild(name: "Artist", value: _artist != nil ? String(_artist!).addingPercentEncoding(withAllowedCharacters: xmlAllowedSet) : nil )
        header.addChild(name: "Author", value: _author != nil ? String(_author!).addingPercentEncoding(withAllowedCharacters: xmlAllowedSet) : nil )
        
        header.addChild(name: "Copyright", value: _copyright != nil ? String(_copyright!).addingPercentEncoding(withAllowedCharacters: xmlAllowedSet) : nil )
        header.addChild(name: "Publisher", value: _publisher != nil ? String(_publisher!).addingPercentEncoding(withAllowedCharacters: xmlAllowedSet) : nil )
        header.addChild(name: "CoverArt", value: _coverArtURL != nil ? String(_coverArtURL!).addingPercentEncoding(withAllowedCharacters: xmlAllowedSet) : nil )
        header.addChild(name: "OriginalArtworkURL", value: _originalArtworkURL != nil ? String(_originalArtworkURL!).addingPercentEncoding(withAllowedCharacters: xmlAllowedSet) : nil )
        header.addChild(name: "Key", value: _key != nil ? String(_key!).addingPercentEncoding(withAllowedCharacters: xmlAllowedSet) : nil )
        header.addChild(name: "Tempo", value: _tempo != nil ? String(_tempo!).addingPercentEncoding(withAllowedCharacters: xmlAllowedSet) : nil )
        header.addChild(name: "TimeSignature", value: _timeSignature != nil ? String(_timeSignature!).addingPercentEncoding(withAllowedCharacters: xmlAllowedSet) : nil )
        
        header.addChild(name: "MuzVersion", value: _muzVersion != nil ? String(_muzVersion!) : nil )
        header.addChild(name: "MuzAuthor", value: _muzAuthor != nil ? String(_muzAuthor!).addingPercentEncoding(withAllowedCharacters: xmlAllowedSet) : nil )
        header.addChild(name: "MuzAuthorUID", value: _muzAuthorUID != nil ? String(_muzAuthorUID!) : nil )
        
        header.addChild(name: "CreationDate", value: _creationDate != nil ? String(_creationDate!.formatted) : nil )
        header.addChild(name: "LastUpdateDate", value: _lastUpdateDate != nil ? String(_lastUpdateDate!.formatted) : nil )
        
        header.addChild(name: "SetsOnly", value: _setsOnly != nil ? String(_setsOnly!) : nil )
        
        let chords = body.addChild(name: "ChordPallet")
        for (_, chord) in _chordPallet.enumerated() {
            chords.addChild(chord.serialize())
        }
        
        let tracks = body.addChild(name: "Tracks")
        for (_, track) in _tracks.enumerated() {
            tracks.addChild(track.serialize())
        }
        
        return(muzXMLDoc.xml)
    }
    
    open func serializeSetData( _ setDoc:AEXMLElement ) -> AEXMLElement
    {
        let ret = setDoc
        
        ret.addChild(name: "DocFolderName", value: String(self.getFolderName()).addingPercentEncoding(withAllowedCharacters: xmlAllowedSet) )
        ret.addChild(name: "DocFileName", value: String(self.getFileName()).addingPercentEncoding(withAllowedCharacters: xmlAllowedSet) )
        ret.addChild(name: "DiskFolderFilePath", value: String(self.diskFolderFilePathString).addingPercentEncoding(withAllowedCharacters: xmlAllowedSet) )
        return( ret )
    }
    
    open func loadPlaceholder( _ srcURL: URL ) {
        
        _isPlaceholder = true
        _uid = UUID().uuidString
        
        let artistDashTitle = srcURL.lastPathComponent
        if( !artistDashTitle.isEmpty )
        {
            /*
            let startFindDash = artistDashTitle.range(of: " - ")?.lowerBound
            let endFindDash = artistDashTitle.range(of: " - ")?.upperBound
            _artist = artistDashTitle.substring(to: startFindDash!)
            _title = artistDashTitle.substring(from: endFindDash!)
            */
            
            let components = artistDashTitle.components(separatedBy: " - ")
            if( components.count > 0 )
            {
                _artist = components[0]
            }
            else
            {
                _artist = ""
            }
            
            if( components.count > 1 )
            {
                _title = components[1]
            }
            else
            {
                _title = ""
            }
            
            let extRange = _title?.range(of: ".muz.xml")
            if( extRange != nil )
            {
                _title?.removeSubrange(extRange!)
            }
        }
        else
        {
            _artist =  "Artist"
            _author =  "Author"
        }
        self.diskFolderFilePath = srcURL
        //let reg = UserRegistration()
        //_title = "Song 1"
        
        //_artwork = self.placeholderArtwork
        _artwork = self.loadingPlaceholderArtwork
        
        _copyright =  "(c) " + Date().datePretty
        _publisher = "Publisher"
        _coverArtURL = getArtworkURL()?.absoluteString
        _muzVersion = Version.DocVersion
        _muzAuthor = "My Name"
        _muzAuthorUID =  ""
        _creationDate = Date()
        _lastUpdateDate = Date()
        _key = nil
        _tempo = nil
        _timeSignature = nil
        _chordPallet = [Chord]()
        
        _tracks = [
            
            MuzTrack(trackName: "Structure", trackType: TrackType.Structure, trackPurpose: TrackPurpose.Structure, defaultEventSpecifics:nil,
                     events: [
                ]),
            MuzTrack(trackName: "Guide Audio", trackType: TrackType.Audio, trackPurpose: TrackPurpose.GuideAudio, defaultEventSpecifics:nil,
                     events: [
                ]),
            
            MuzTrack(trackName: "Chords", trackType: TrackType.Chords, trackPurpose: TrackPurpose.MainSongChords, defaultEventSpecifics:nil,
                     events: [
                ]),
            
            MuzTrack(trackName: "Lyrics", trackType: TrackType.Words, trackPurpose: TrackPurpose.MainLyrics, defaultEventSpecifics:nil,
                     events: [
                ])]
        ensureEvents()
    }
    
    open func deserialize( _ srcURL: URL ) {
        _isInDeserialize = true
        do
        {
            let docContents = try NSString( contentsOf: srcURL, encoding: String.Encoding.utf8.rawValue)
            self.deserialize(docContents as String, srcURL: srcURL)
        }
        catch let error as NSError
        {
            Logger.log( "error \(error.localizedDescription)" )
        }
    }
    
    open func deserialize( _ xmlContent: String, srcURL: URL  )
    {
        _isInDeserialize = true
        //let muzXMLDoc = AEXMLDocument(xmlData:xmlContent)
        //self._loadedFromSourceURL = srcURL
        diskFolderFilePath = srcURL
        
        //if let data = xmlContent.data(using: String.Encoding.utf8) {
        
        // works only if data is successfully parsed
        // otherwise Logger.log(s information about error with parsing
        //var error: NSError?
        
        var xmlParserOptions = AEXMLOptions();
        xmlParserOptions.parserSettings.shouldTrimWhitespace = false;
        let xmlDoc = try? AEXMLDocument(xml: xmlContent, encoding: String.Encoding.utf8, options: xmlParserOptions)
        
        if xmlDoc != nil {
            
            // Logger.log(s the same XML structure as original
            // Logger.log(xmlDoc.xmlString)
            
            for child in (xmlDoc?.root.children)! {
                //Logger.log(child.name)
                switch( child.name )
                {
                case "Header":
                    //Logger.log( "UID: " + child["UID"].value! )
                    _uid = child["UID"].name != "AEXMLError" ? child["UID"].value == nil ? "" : child["UID"].value! : ""
                    if( child["Title"].value != nil )
                    {
                        _title = child["Title"].name != "AEXMLError" ? child["Title"].value?.removingPercentEncoding : ""
                        _artist = child["Artist"].name != "AEXMLError" ? child["Artist"].value?.removingPercentEncoding : ""
                        _author = child["Author"].name != "AEXMLError" ? child["Author"].value?.removingPercentEncoding : ""
                        _copyright = child["Copyright"].name != "AEXMLError" ? child["Copyright"].value?.removingPercentEncoding : ""
                        _publisher = child["Publisher"].name != "AEXMLError" ? child["Publisher"].value?.removingPercentEncoding : ""
                        _coverArtURL = child["CoverArt"].name != "AEXMLError" ? child["CoverArt"].value?.removingPercentEncoding : ""
                        _originalArtworkURL = child["OriginalArtworkURL"].name != "AEXMLError" ? child["OriginalArtworkURL"].value?.removingPercentEncoding : ""
                        _key = child["Key"].name != "AEXMLError" ? child["Key"].value?.removingPercentEncoding : ""
                        _tempo = child["Tempo"].name != "AEXMLError" ? child["Tempo"].value?.removingPercentEncoding : ""
                        _timeSignature = child["TimeSignature"].name != "AEXMLError" ? child["TimeSignature"].value?.removingPercentEncoding : ""
                        _muzVersion =  child["MuzVersion"].name != "AEXMLError" ? child["MuzVersion"].value : ""
                        _muzAuthor = child["MuzAuthor"].name != "AEXMLError" ? child["MuzAuthor"].value?.removingPercentEncoding : ""
                        _muzAuthorUID = child["MuzAuthorUID"].name != "AEXMLError" ? child["MuzAuthorUID"].value : ""
                        _creationDate = child["CreationDate"].name != "AEXMLError" && child["CreationDate"].value != nil ? Date( dateString: child["CreationDate"].value! ) : nil
                        _lastUpdateDate = child["LastUpdateDate"].name != "AEXMLError" && child["LastUpdateDate"].value != nil ? Date( dateString: child["LastUpdateDate"].value! ) : nil
                        _setsOnly = child["SetsOnly"].name != "AEXMLError" && child["SetsOnly"].value != nil ? child["SetsOnly"].value == "true" ? true : false : false
                        
                        _chordPallet = []
                        
                        if( child["ChordPallet"].name != "AEXMLError" && child["ChordPallet"].value != nil )
                        {
                            for ele in child["ChordPallet"].children {
                                //Logger.log(ele.name)
                                let newChord:Chord = Chord(xmlEle: ele)
                                _chordPallet.append(newChord)
                            }
                        }
                    }
                    break;
                    
                case "Tracks":
                    _tracks = []
                    for trackEle in child.children {
                        //Logger.log(trackEle.name)
                        let newTrack:MuzTrack = MuzTrack(xmlEle: trackEle)
                        if( newTrack._trackPurpose == .GuideAudio )
                        {
                            var evtSpecifics:AudioEventSpecifics? = nil
                            if( newTrack._events.count > 0 )
                            {
                                evtSpecifics = newTrack._events[0]._specifics as! AudioEventSpecifics?
                                if( evtSpecifics != nil && evtSpecifics!._legacyPBChan )
                                {
                                    evtSpecifics!.favouriDevicePlayback = true
                                    evtSpecifics!.favourMultiChanPlayback = false
                                    if( evtSpecifics!.volume == 0.0 )
                                    {
                                        evtSpecifics!.volume = 1.0
                                    }
                                }
                            }
                        }
                        else if( newTrack._trackPurpose == .BackingTrackAudio || newTrack._trackPurpose == .ClickTrackAudio )
                        {
                            var evtSpecifics:AudioEventSpecifics? = nil
                            if( newTrack._events.count > 0 )
                            {
                                evtSpecifics = newTrack._events[0]._specifics as! AudioEventSpecifics?
                                if( evtSpecifics != nil && evtSpecifics!._legacyPBChan )
                                {
                                    evtSpecifics!.favouriDevicePlayback = false
                                    evtSpecifics!.favourMultiChanPlayback = true
                                }
                            }
                        }
                        _tracks.append(newTrack)
                    }
                    break;
                    
                case "ChordPallet":
                    _chordPallet = []
                    for chordEle in child.children {
                        //Logger.log(trackEle.name)
                        let newChord:Chord = Chord(xmlEle: chordEle)
                        _chordPallet.append(newChord)
                    }
                    break;
                    
                    
                default:
                    Logger.log( "invalid element in xml: " + child.name )
                    break;
                }
            }
            ensureEvents()
            _activeEditTrack = getMainLyricTrackIndex()
            
            updateArtwork()
        } else {
            Logger.log("Error deserializing document")
        }
        //}
        _isInDeserialize = false
        _isPlaceholder = false
    }
    
    
    /*Text*/
    func getTXT() -> String
    {
        var txtOut = ""
        
        // title
        if( self._title != nil )
        {
            txtOut += "title: " + (self._title)!
            txtOut += "\r\n"
        }
        
        if( self._artist  != nil )
        {
            // artist
            txtOut += "artist: " + (self._artist)!
            txtOut += "\r\n"
        }
        
        if( self._author != nil )
        {
            // author
            txtOut += "author: " + (self._author)!
            txtOut += "\r\n"
        }
        
        if( self._copyright != nil )
        {
            // right hand details
            if(_copyright != nil )
            {
                txtOut += "copyright: " + (self._copyright)!
                txtOut += "\r\n"
            }
        }
        
        if( self._publisher != nil )
        {
            txtOut += "publisher: " + (self._publisher)!
            txtOut += "\r\n"
        }
        
        if( self._creationDate != nil)
        {
            txtOut += "created: " + (self._creationDate!.datePretty)
            txtOut += "\r\n"
        }
        
        if( self._lastUpdateDate != nil )
        {
            txtOut += "last updated: " + (self._lastUpdateDate!.datePretty)
            txtOut += "\r\n"
        }
        // other optional
        if( self._tempo != nil && !(self._tempo?.isEmpty)! )
        {
            // Tempo
            txtOut += "tempo: " + (self._tempo)!
            txtOut += "\r\n"
        }
        
        if( self._timeSignature != nil && !(self._timeSignature?.isEmpty)! )
        {
            // Time Signature
            txtOut += "time signature: " + (self._timeSignature)!
            txtOut += "\r\n"
        }
        
        if( self._key != nil && !(self._key?.isEmpty)! )
        {
            // Key
            txtOut += "key: " + (self._key)!
            txtOut += "\r\n"
        }
        
        txtOut += "\r\n"
        txtOut += "\r\n"
        
        // chords
        let pal=self._chordPallet
        if( pal.count > 0 )
        {
            txtOut += "chords used: "
            
            // add chord buttons
            for (_, chord) in (self._chordPallet.enumerated())
            {
                txtOut +=  chord.chordString + "   "
            }
        }
        txtOut += "\r\n"
        
        // main song body
        let lyricIdx = self.getMainLyricTrackIndex()
        let chordsIdx = self.getMainChordTrackIndex()
        let structureIdx = self.getStructureTrackIndex()
        
        let lyricEvents = self._tracks[lyricIdx]._events
        let chordEvents = self._tracks[chordsIdx]._events
        let structureEvents = self._tracks[structureIdx]._events
        
        var justDoneText = false
        for (idx, lyricEvt) in lyricEvents.enumerated() {
            let chordEvent = chordEvents[idx]
            let structureEvent = structureEvents[idx]
            
            if( !structureEvent._data.isEmpty )
            {
                txtOut += "\(structureEvent._data)"
                txtOut += "\r\n"
            }
            
            let padCnt = max( 1, lyricEvt._data.count, chordEvent._data.count )
            
            if( chordEvent._data.trimmingCharacters(in: whitespaceSet) == "" &&
                lyricEvt._data.trimmingCharacters(in: whitespaceSet) == "" )
            {
                let pad = "".padding(toLength: padCnt, withPad: " ", startingAt: 0)
                if( justDoneText )
                {
                    txtOut += "\(pad)"
                    txtOut += "\r\n"
                    justDoneText = false
                }
            }
            else
            {
                if( chordEvent._data.trimmingCharacters(in: whitespaceSet) == "" )
                {
                    let pad = "".padding(toLength: padCnt, withPad: " ", startingAt: 0)
                    txtOut += "\(pad)"
                    txtOut += "\r\n"
                }
                else
                {
                    let pad = chordEvent._data.padding(toLength: padCnt, withPad: " ", startingAt: 0)
                    txtOut += "\(pad)"
                    txtOut += "\r\n"
                }
                
                if( lyricEvt._data.trimmingCharacters(in: whitespaceSet) == "" )
                {
                    let pad = "".padding(toLength: padCnt, withPad: " ", startingAt: 0)
                    txtOut += "\(pad)"
                    txtOut += "\r\n"
                }
                else
                {
                    let pad = lyricEvt._data.padding(toLength: padCnt, withPad: " ", startingAt: 0)
                    txtOut += "\(pad)"
                    txtOut += "\r\n"
                }
                
                let pad = "".padding(toLength: padCnt, withPad: " ", startingAt: 0)
                txtOut += "\(pad)"
                txtOut += "\r\n"
                justDoneText = true
            }
        }
        
        return( txtOut )
    }
    
    /*Chord Pro*/
    func getPRO() -> String
    {
        var proOut = "#Muzoma Export - " + self.getFolderName()
        proOut += "\r\n"
        
        // title
        if( self._title != nil )
        {
            proOut += "{title:" + (self._title)! + "}"
            proOut += "\r\n"
        }
        
        // artist
        if( self._artist != nil )
        {
            proOut += "{subtitle:" + (self._artist)! + "}"
            proOut += "\r\n"
        }
        
        // author
        if( self._author != nil )
        {
            proOut += "{comment:author - " + (self._author)! + "}"
            proOut += "\r\n"
        }
        
        if( self._copyright != nil )
        {
            proOut += "{comment:copyright - " + (self._copyright)! + "}"
            proOut += "\r\n"
        }
        
        if( self._publisher != nil )
        {
            proOut += "{comment:publisher - " + (self._publisher)! + "}"
            proOut += "\r\n"
        }
        
        if( self._creationDate != nil )
        {
            proOut += "{comment:created - " + (self._creationDate!.datePretty)  + "}"
            proOut += "\r\n"
        }
        
        if( self._lastUpdateDate != nil )
        {
            proOut += "{comment:last updated - " + (self._lastUpdateDate!.datePretty) + "}"
            proOut += "\r\n"
        }
        
        // other optional
        if( self._tempo != nil && !(self._tempo?.isEmpty)! )
        {
            // Tempo
            proOut += "{{tempo:" + (self._tempo)!  + "}"
            proOut += "\r\n"
        }
        
        if( self._timeSignature != nil && !(self._timeSignature?.isEmpty)! )
        {
            // Time Signature
            proOut += "{time:" + (self._timeSignature)!  + "}"
            proOut += "\r\n"
        }
        
        if( self._key != nil && !(self._key?.isEmpty)! )
        {
            // Key
            proOut += "{key:" + (self._key)!  + "}"
            proOut += "\r\n"
        }
        
        
        proOut += "\r\n"
        
        // chords
        let pal=self._chordPallet
        if( pal.count > 0 )
        {
            proOut += "{comment: chords used: "
            
            // add chord buttons
            for (_, chord) in (self._chordPallet.enumerated())
            {
                proOut +=  chord.chordString + "   "
            }
            proOut += "}"
        }
        
        proOut += "\r\n"
        proOut += "\r\n"
        
        // main song body
        let lyricIdx = self.getMainLyricTrackIndex()
        let chordsIdx = self.getMainChordTrackIndex()
        let structureIdx = self.getStructureTrackIndex()
        
        let lyricEvents = self._tracks[lyricIdx]._events
        let chordEvents = self._tracks[chordsIdx]._events
        let structureEvents = self._tracks[structureIdx]._events
        
        var justDoneText = false
        for (idx, lyricEvt) in lyricEvents.enumerated() {
            let chordEvent = chordEvents[idx]
            let structureEvent = structureEvents[idx]
            
            if( !structureEvent._data.isEmpty )
            {
                /* if( structureEvent._data.lowercaseString.containsString("cho") )
                 {
                 proOut += "{start_of_chorus:\(structureEvent._data)}"
                 proOut += "\r\n"
                 }
                 else*/
                
                proOut += "{start_of_part:\(structureEvent._data)}"
                proOut += "\r\n"
            }
            
            let padCnt = max( 1, lyricEvt._data.count, chordEvent._data.count )
            
            if( chordEvent._data.trimmingCharacters(in: whitespaceSet) == "" &&
                lyricEvt._data.trimmingCharacters(in: whitespaceSet) == "" )
            {
                let pad = "".padding(toLength: padCnt, withPad: " ", startingAt: 0)
                if( justDoneText )
                {
                    proOut += "\(pad)"
                    proOut += "\r\n"
                    justDoneText = false
                }
            }
            else
            {
                var chordLine = ""
                var lyricLine = ""
                
                if( chordEvent._data.trimmingCharacters(in: whitespaceSet) == "" )
                {
                    let pad = "".padding(toLength: padCnt, withPad: " ", startingAt: 0)
                    chordLine += "\(pad)"
                    chordLine += "\r\n"
                }
                else
                {
                    let pad = chordEvent._data.padding(toLength: padCnt, withPad: " ", startingAt: 0)
                    chordLine += "\(pad)"
                    chordLine += "\r\n"
                }
                
                if( lyricEvt._data.trimmingCharacters(in: whitespaceSet) == "" )
                {
                    let pad = "".padding(toLength: padCnt, withPad: " ", startingAt: 0)
                    lyricLine += "\(pad)"
                    lyricLine += "\r\n"
                }
                else
                {
                    let pad = lyricEvt._data.padding(toLength: padCnt, withPad: " ", startingAt: 0)
                    lyricLine += "\(pad)"
                    lyricLine += "\r\n"
                }
                
                /*
                 let pad = "".stringByPaddingToLength(padCnt, withString: " ", startingAtIndex: 0)
                 proOut += "\(pad)"
                 proOut += "\r\n"
                 */
                
                
                lyricLine = lyricLine.trimmingCharacters(in: newLineSet)
                chordLine = chordLine.trimmingCharacters(in: newLineSet)
                
                var lyricPointer = lyricLine.startIndex
                var chordPointer = chordLine.startIndex
                
                var proFmt = ""
                var complete = false
                var lChar = lyricLine[lyricPointer]
                var cChar = chordLine[chordPointer]
                repeat
                {
                    //whitespaceSet.characterIsMember(lChar) &&  whitespaceSet.characterIsMember(cChar)  )
                    
                    if( lyricPointer >= lyricLine.endIndex && chordPointer >= chordLine.endIndex )
                    {
                        complete = true
                    }
                    if( cChar == Character(" ") &&  lChar == Character(" ") )// both spaces, add an output space
                    {
                        proFmt += " "
                        if(  lyricPointer < lyricLine.endIndex )
                        {
                            lyricPointer = lyricLine.index(lyricPointer, offsetBy: 1)
                        }
                        
                        if( chordPointer < chordLine.endIndex )
                        {
                            chordPointer = chordLine.index(chordPointer, offsetBy: 1)
                        }
                    }
                    else if( cChar == Character(" ") ) // no chords, use lyrics
                    {
                        proFmt += String(lChar)
                        if(  lyricPointer < lyricLine.endIndex )
                        {
                            lyricPointer = lyricLine.index(lyricPointer, offsetBy: 1)
                        }
                        else
                        {
                            lChar = " "
                        }
                        
                        if( chordPointer < chordLine.endIndex )
                        {
                            chordPointer = chordLine.index(chordPointer, offsetBy: 1)
                        }
                        else
                        {
                            cChar = " "
                        }
                    } else if( cChar != Character(" ") ) // insert chord
                    {
                        var chordComplete = false
                        proFmt += "["
                        var lyricSave = ""
                        repeat
                        {
                            proFmt += String(cChar) // add chord root
                            
                            chordPointer = chordLine.index(chordPointer, offsetBy: 1)
                            if( chordPointer < chordLine.endIndex )
                            {
                                cChar = chordLine[chordPointer]
                            }
                            else
                            {
                                cChar = " "
                            }
                            
                            
                            if( cChar == Character(" ") ) // are we done
                            {
                                chordComplete = true
                            }
                            
                            lyricSave += String(lChar) // match the lyrics
                            
                            lyricPointer = lyricLine.index(lyricPointer, offsetBy: 1)
                            if(  lyricPointer < lyricLine.endIndex )
                            {
                                lChar = lyricLine[lyricPointer]
                            }
                            else
                            {
                                lChar = " "
                            }
                            
                        } while !chordComplete
                        
                        proFmt += "]" // end the chord
                        proFmt += lyricSave // add the missing lyric text
                    }
                    
                    if( lyricPointer < lyricLine.endIndex )
                    {
                        lChar = lyricLine[lyricPointer]
                    }
                    else
                    {
                        lChar = " "
                    }
                    
                    if( chordPointer < chordLine.endIndex )
                    {
                        cChar = chordLine[chordPointer]
                    }
                    else
                    {
                        cChar = " "
                    }
                } while !complete
                
                proOut += proFmt
                proOut += "\r\n"
                
                justDoneText = true
            }
        }
        
        return( proOut )
    }
    
    /*HTML*/
    func getHTML( _ forPDF:Bool = false, ignoreZoom:Bool, ignoreColourScheme:Bool, isAirPlay:Bool ) -> String
    {
        var cs = ""
        
        if( !ignoreColourScheme)
        {
            cs = UserDefaults.standard.object(forKey: "playerColorScheme_preference") as! String
        }
        
        var htmlOut = "<html>\r\n"
        htmlOut += "<head>\r\n"
        htmlOut += "<title>\(self.getFileName())</title>\r\n"
        
        
        
        // stylesheet mods for 10.3 issue
        /*
         //htmlOut += "<link rel='stylesheet' href='Muzoma.css'>"
         if( !forPDF )
         {
         //htmlOut += "<meta name='viewport' content='user-scalable=yes, width=device-width' />"
         }
         */
        
        let cssURL = Bundle.main.url( forResource: "Muzoma"+cs, withExtension: "css")
        if( cssURL != nil )
        {
            do
            {
                
                var cssString = "<style type=\"text/css\">"
                try cssString = cssString + String( contentsOf: cssURL! )
                cssString = cssString + "</style>"
                htmlOut += cssString
                /*
                 let cssData = NSData(contentsOfURL: cssURL!)
                 let base64CSSString = cssData?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
                 if( base64CSSString != nil )
                 {
                 //htmlOut += "<link rel='stylesheet' href='data:text/javascript;base64," + base64CSSString! + "'></link>\r\n" // works pre 10.3
                 //htmlOut += "<link rel='stylesheet' href='Muzoma\(cs).css'>" // doesn't work
                 
                 
                 }*/
            }
            catch
            {
                
            }
        }
        
        if( !ignoreZoom )
        {
            if( !isAirPlay )
            {
                htmlOut += "<meta name=\"viewport\" content=\"width=device-width, initial-scale=\(UserDefaults.standard.object(forKey: "playerZoomLevel_preference")!)\">"
            }
        }
        
        if( isAirPlay )
        {
            htmlOut += "<meta name=\"viewport\" content=\"width=device-width, initial-scale=\(UserDefaults.standard.object(forKey: "airplayZoomLevel_preference")!)\">"
        }
        htmlOut += "<meta charset='utf-8' />\r\n"
        
        //htmlOut += "<script src='Muzoma.js' type='text/javascript'></script>"
        let jsURL = Bundle.main.url( forResource: "Muzoma", withExtension: "js")
        let jsData = try? Data(contentsOf: jsURL!)
        let base64JSString = jsData?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        if( base64JSString != nil )
        {
            htmlOut += "<script src='data:text/javascript;base64," + base64JSString! + "'></script>\r\n"
        }
        
        
        htmlOut += "</head>\r\n"
        
        htmlOut += "<body>\r\n"
        htmlOut += "<main>\r\n"
        
        if( forPDF )
        {
            htmlOut += "<div id='headingsAndPic' style='height:800px; width:100%;'>\r\n"// background: orange'>"
            htmlOut += "<div id='footerDetails' style='height:80px; width:100%;'>\r\n" // background: yellow
            htmlOut += "<table style='width:100%; height: 80px'>\r\n"
            htmlOut += "<tr>\r\n"
            htmlOut += "<td>\r\n"
            
            // left hand details
            htmlOut += "<H5 align='left'>\r\n"
            // other optional
            if( self._tempo != nil && !(self._tempo?.isEmpty)! )
            {
                // Tempo
                htmlOut += "<div>Tempo: " + (self._tempo)! + " </div>\r\n"
            }
            
            if( self._timeSignature != nil && !(self._timeSignature?.isEmpty)! )
            {
                // Time Signature
                htmlOut += "<div>Time Signature: " + (self._timeSignature)! + "</div>\r\n"
            }
            
            if( self._key != nil && !(self._key?.isEmpty)! )
            {
                // Key
                htmlOut += "<div>Key: " + (self._key)! + "</div>\r\n"
            }
            htmlOut += "</H5>\r\n"
            
            htmlOut += "</td>\r\n"
            htmlOut += "<td>\r\n"
            
            // right hand details
            htmlOut += "<H5 align='right' >\r\n"
            if( self._copyright != nil )
            {
                htmlOut += "<div>copyright: " + (self._copyright)! + "</div>\r\n"
            }
            
            if( self._publisher != nil )
            {
                htmlOut += "<div>publisher: " + (self._publisher)!  + "</div>\r\n"
            }
            
            if( self._creationDate != nil )
            {
                htmlOut += "<div>created: " + (self._creationDate!.datePretty)  + "</div>\r\n"
            }
            
            if( self._lastUpdateDate != nil )
            {
                htmlOut += "<div>last updated: " + (self._lastUpdateDate!.datePretty) + "</div>\r\n"
            }
            htmlOut += "</H5>\r\n"
            
            htmlOut += "</td>\r\n"
            htmlOut += "<tr>\r\n"
            htmlOut += "</table>\r\n"
            htmlOut += "</div>\r\n"
            
            // title
            if( _title != nil )
            {
                htmlOut += "<H1 style='font-size: 52px;'>" + (self._title)! + "</H1>\r\n"
            }
            
            // artist
            if( _artist != nil )
            {
                htmlOut += "<H2 style='font-size: 44px;'>" + (self._artist)! + "</H2>\r\n"
            }
            
            // author
            if( _author != nil )
            {
                htmlOut += "<H3 style='font-size: 40px;' class='author'>" + (self._author)! + "</H3>\r\n"
            }
            htmlOut += "<div style='height:400px; width:100%; overflow: hidden;'>\r\n" // background: red;
            htmlOut += "<center>\r\n"
            let plainData = try? Data(contentsOf: (self.getArtworkURL())!)
            if( plainData != nil  )
            {
                let base64ImgString = plainData!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                htmlOut += "<img style='height:400px; width:400px; ' src='data:image/png;base64," + base64ImgString + "' alt='Cover Art' />\r\n"
            }
            //htmlOut += "<img style='height:400px; width:400px; ' src='" + (self.getArtworkURL()?.absoluteString)! + "'>"
            htmlOut += "</center>\r\n"
            htmlOut += "</div>\r\n"
            
            htmlOut += "<div style='' class='pagebreak'> </div>\r\n"
        }
        else
        {
            let plainData = try? Data(contentsOf: (self.getArtworkURL())!)
            if( plainData != nil )
            {
                let base64ImgString = plainData!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                htmlOut += "<img align='right' height='150' width='150' src='data:image/png;base64," + base64ImgString + "' alt='Cover Art' />\r\n"
            }
            else
            {
                Logger.log( "No artwork! \(String(describing: self.getArtworkURL()))" )
            }
            //htmlOut += "<img align='right' height='150' width='150' src='" + (self.getArtworkURL()?.absoluteString)! + "'>"
            // title
            if( self._title != nil )
            {
                
                htmlOut += "<H1 id='title'>" + (self._title)! + "</H1>\r\n"
            }
            // artist
            if( self._artist != nil )
            {
                htmlOut += "<H2>" + (self._artist)! + "</H2>\r\n"
            }
            // author
            if( self._author != nil )
            {
                htmlOut += "<H3 class='author'>" + (self._author)! + "</H3>\r\n"
            }
            // right hand details
            htmlOut += "<H4 align='right' >\r\n"
            if( self._copyright != nil )
            {
                htmlOut += "copyright: " + (self._copyright)! + " <br>\r\n" //+ "</H4>"
            }
            if( self._publisher != nil )
            {
                htmlOut += "publisher: " + (self._publisher)!  + " <br>\r\n"  //+ "</H4>"
            }
            if(self._creationDate != nil )
            {
                htmlOut += "created: " + (self._creationDate!.datePretty)  + " <br>\r\n"  //+ "</H4>"
            }
            if(self._lastUpdateDate != nil )
            {
                htmlOut += "last updated: " + (self._lastUpdateDate!.datePretty) + "</H4>\r\n"
            }
            // other optional
            if( self._tempo != nil && !(self._tempo?.isEmpty)! )
            {
                // Tempo
                htmlOut += "<H3>Tempo: " + (self._tempo)! + "</H3>\r\n"
            }
            
            if( self._timeSignature != nil && !(self._timeSignature?.isEmpty)! )
            {
                // Time Signature
                htmlOut += "<H3>Time Signature: " + (self._timeSignature)! + "</H3>\r\n"
            }
            
            if( self._key != nil && !(self._key?.isEmpty)! )
            {
                // Key
                htmlOut += "<H3>Key: " + (self._key)! + "</H3>\r\n"
            }
            
            htmlOut += "<div class='pagebreak'> </div>\r\n"
        }
        
        // chords
        let pal=self._chordPallet
        if( pal.count > 0 )
        {
            htmlOut += "<H3>Chords<BR>"
            // add chord buttons
            for (_, chord) in (self._chordPallet.enumerated())
            {
                htmlOut += "<B class='chords'><nobr>" + chord.chordString + "</nobr></B>&nbsp;&nbsp;&nbsp;&nbsp;"
            }
            
            htmlOut += "</H3>"
        }
        htmlOut += "<br>"
        
        // main song body
        let lyricIdx = self.getMainLyricTrackIndex()
        let chordsIdx = self.getMainChordTrackIndex()
        let structureIdx = self.getStructureTrackIndex()
        
        if( lyricIdx > -1 && chordsIdx > -1 && structureIdx > -1 )
        {
            let lyricEvents = self._tracks[lyricIdx]._events
            let chordEvents = self._tracks[chordsIdx]._events
            let structureEvents = self._tracks[structureIdx]._events
            
            //htmlOut += "<pre>\r\n"
            var inArticle = false
            var justDoneText = false
            for (idx, lyricEvt) in lyricEvents.enumerated() {
                let chordEvent = chordEvents[idx]
                let structureEvent = structureEvents[idx]
                
                if( !structureEvent._data.isEmpty )
                {
                    if( inArticle )
                    {
                        htmlOut += "</article>\r\n"
                        inArticle = false
                    }
                    htmlOut += "<article>"
                    inArticle = true
                    htmlOut += "<H3>\(structureEvent._data)</H3>\r\n"
                }
                
                let padCnt = max( 1, lyricEvt._data.count, chordEvent._data.count )
                
                if( chordEvent._data.trimmingCharacters(in: whitespaceSet) == "" &&
                    lyricEvt._data.trimmingCharacters(in: whitespaceSet) == "" )
                {
                    let pad = "".padding(toLength: padCnt, withPad: " ", startingAt: 0)
                    if( justDoneText )
                    {
                        htmlOut += "<div><pre>\(pad)<br></pre></div>\r\n"
                        justDoneText = false
                    }
                }
                else
                {
                    if( chordEvent._data.trimmingCharacters(in: whitespaceSet) == "" )
                    {
                        let pad = "".padding(toLength: padCnt, withPad: " ", startingAt: 0)
                        htmlOut += "<div class='chords' id='chord"+String(idx)+"'><pre>\(pad)</pre></div>\r\n"
                    }
                    else
                    {
                        let pad = chordEvent._data.padding(toLength: padCnt, withPad: " ", startingAt: 0)
                        htmlOut += "<div class='chords' id='chord"+String(idx)+"'><pre>\(pad)</pre></div>\r\n"
                    }
                    
                    if( lyricEvt._data.trimmingCharacters(in: whitespaceSet) == "" )
                    {
                        let pad = "".padding(toLength: padCnt, withPad: " ", startingAt: 0)
                        htmlOut += "<div class='lyrics' id='lyric"+String(idx)+"'><pre>\(pad)<br></pre></div>\r\n"
                    }
                    else
                    {
                        let pad = lyricEvt._data.padding(toLength: padCnt, withPad: " ", startingAt: 0)
                        htmlOut += "<div class='lyrics' id='lyric"+String(idx)+"'><pre>\(pad)</pre></div>\r\n"
                    }
                    
                    let pad = "".padding(toLength: padCnt, withPad: " ", startingAt: 0)
                    htmlOut += "<pre>\(pad)<br></pre>\r\n"
                    justDoneText = true
                }
            }
            
            if( inArticle )
            {
                htmlOut += "</article>\r\n"
            }
            //htmlOut += "</pre>\r\n"
        }
        htmlOut += "</main>\r\n"
        
        //htmlOut += "<img src='data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA AAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO 9TXL0Y4OHwAAAABJRU5ErkJggg==' alt='Red dot' />"
        htmlOut += "</body>\r\n</html>\r\n"
        
        return( htmlOut )
    }
    
    
    /************
     audio & timing
     *************/
    var finiteTimer:RepeatingTimer! = nil
    var _prevEventAtTime:TimeInterval = 0
    var _lyricTrackIdx = -1
    var _sectionTrackIdx = -1
    var _currentPrepareIdx = 0
    var _currentFireIdx = 0
    var currentSectionTitle = ""
    var prevSectionTitle = ""
    var prevTm:TimeInterval = 0
    var lastEventTimeType = EventTimeType.None
    var schedTime:UInt64 = 0
    var songStartMSecsUpTime:UInt64 = 0
    var playTime:AVAudioTime = AVAudioTime()
    var duration:TimeInterval = 0
    var _speed:Float = 1.0
    var _startOffsetInterval:TimeInterval = 0
    var _artwork:MPMediaItemArtwork! = nil
    var _stoppedTime:TimeInterval = 0
    var _stoppedDuration:TimeInterval = 0
    var notifiedEnd = false
    var _mc:MultiChannelAudio! = nil
    static let _appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    fileprivate func startTick()
    {
        if( finiteTimer != nil )
        {
            stopTick()
        }
        
        _lyricTrackIdx = self.getMainLyricTrackIndex()
        _sectionTrackIdx = self.getStructureTrackIndex()
        
        self.prevTm = -5.0
        
        finiteTimer = RepeatingTimer(timeInterval: 0.050, queue: _gTimerQueue)
        finiteTimer.eventHandler =
            {
                _gNC.post(name: Notification.Name(rawValue: "PlayerTick"), object: self)
        }
        finiteTimer.start()
        
        _gNC.addObserver(self, selector: #selector(MuzomaDocument.playerTicked(_:)), name: NSNotification.Name(rawValue: "PlayerTick"), object: nil)
    }
    
    fileprivate func stopTick()
    {
        if( finiteTimer != nil )
        {
            finiteTimer.pause()
            finiteTimer.invalidate()
            finiteTimer = nil
            prevTm = -5.0
            
            _gNC.removeObserver(self, name: NSNotification.Name(rawValue: "PlayerTick"), object: nil )
        }
    }
    
    @objc func playerTicked(_ notification: Notification) {
        DispatchQueue.main.async(execute: {self.tick()})
    }
    
    func fillMediaInfo( _ tm:TimeInterval! = nil, stopping:Bool = false)
    {
        // fill media info for shut display
        let songInfo: [String:AnyObject]
        
        if( _fromSetTitled != nil && _fromSetArtist != nil )
        {
            songInfo =
                
                [
                    MPMediaItemPropertyTitle: (self._title == nil ? "" : self._title)! as AnyObject,
                    MPMediaItemPropertyArtist: (self._artist == nil ? "" : self._artist)! as AnyObject,
                    MPMediaItemPropertyComposer: (self._author == nil ? "" : self._author)! as AnyObject,
                    MPNowPlayingInfoPropertyElapsedPlaybackTime: tm == nil ? 0.0 as AnyObject : tm! as AnyObject,
                    
                    MPNowPlayingInfoPropertyPlaybackRate: stopping ? 0.0 as AnyObject : _speed as AnyObject,
                    MPMediaItemPropertyPlaybackDuration: self.getDuration() as AnyObject,
                    MPMediaItemPropertyArtwork: self._artwork as AnyObject,
                    MPMediaItemPropertyAlbumTitle: _fromSetTitled! as AnyObject,
                    MPMediaItemPropertyAlbumArtist: _fromSetArtist! as AnyObject,
                    MPMediaItemPropertyIsCompilation: true as AnyObject,
                    MPMediaItemPropertyAlbumTrackNumber: _fromSetTrackIdx! as AnyObject,
                    MPMediaItemPropertyAlbumTrackCount: _fromSetTrackCount! as AnyObject,
                    MPNowPlayingInfoPropertyPlaybackQueueIndex: _fromSetTrackIdx! as AnyObject,
                    MPNowPlayingInfoPropertyPlaybackQueueCount: _fromSetTrackCount! as AnyObject,
                    MPMediaItemPropertyReleaseDate: (self._lastUpdateDate?.formatted)! as AnyObject
            ]
        }
        else if( self._artwork != nil )
        {
            songInfo =
                
                [
                    MPMediaItemPropertyTitle: (self._title == nil ? "" : self._title)! as AnyObject,
                    MPMediaItemPropertyArtist: (self._artist == nil ? "" : self._artist)!  as AnyObject,
                    MPMediaItemPropertyComposer: (self._author == nil ? "" : self._author)!  as AnyObject,
                    MPNowPlayingInfoPropertyElapsedPlaybackTime: tm == nil ? 0.0 as AnyObject : tm! as AnyObject,
                    MPNowPlayingInfoPropertyPlaybackRate: stopping ? 0.0 as AnyObject : _speed as AnyObject,
                    MPMediaItemPropertyPlaybackDuration: self.getDuration() as AnyObject,
                    MPMediaItemPropertyArtwork: self._artwork as AnyObject,
                    MPMediaItemPropertyReleaseDate: (self._lastUpdateDate?.formatted)! as AnyObject
            ]
        }
        else
        {
            songInfo =
                
                [
                    MPMediaItemPropertyTitle: (self._title == nil ? "" : self._title)! as AnyObject,
                    MPMediaItemPropertyArtist: (self._artist == nil ? "" : self._artist)! as AnyObject,
                    MPMediaItemPropertyComposer: (self._author == nil ? "" : self._author)! as AnyObject,
                    MPNowPlayingInfoPropertyElapsedPlaybackTime: tm == nil ? 0.0 as AnyObject : tm! as AnyObject,
                    MPNowPlayingInfoPropertyPlaybackRate: stopping ? 0.0 as AnyObject : _speed as AnyObject,
                    MPMediaItemPropertyPlaybackDuration: self.getDuration() as AnyObject,
                    MPMediaItemPropertyReleaseDate: (self._lastUpdateDate?.formatted)! as AnyObject
            ]
        }
        
        let info:MPNowPlayingInfoCenter! = MPNowPlayingInfoCenter.default()
        
        info.nowPlayingInfo = songInfo
    }
    
    func tick()
    {
        let tm = self.getCurrentTime()
        calcEventAtTime(tm)
        
        if( tm > duration && !notifiedEnd )
        {
            self.notifiedEnd = true
            _gNC.post(name: Notification.Name(rawValue: "SongEnded"), object: self)
        }
        
        if( prevTm.distance(to: tm) > 5.0 )
        {
            prevTm = tm
            self.fillMediaInfo( tm )
        }
    }
    
    // setup for slave playback
    func prepareForSlaving()
    {
        _lyricTrackIdx = self.getMainLyricTrackIndex()
        _sectionTrackIdx = self.getStructureTrackIndex()
        _prevEventAtTime = 0
        _currentPrepareIdx = 0
        _currentFireIdx = 0
        currentSectionTitle = ""
        prevSectionTitle = ""
        lastEventTimeType = EventTimeType.None
    }
    
    func calcEventAtTime(_ currentTime:TimeInterval)
    {
        if( currentTime != _prevEventAtTime && _lyricTrackIdx > -1 && _sectionTrackIdx > -1 )
        {
            _prevEventAtTime = currentTime
            var prepareIdx = 0
            var fireIdx = 0
            
            var updated = false
            for (n, ele) in self._tracks[_lyricTrackIdx]._events.enumerated() {
                updated = false
                if( ele._prepareTime != nil && ele._prepareTime <= currentTime ) // last one in list that is less than current time and prev event was fire
                {
                    prepareIdx = n
                    updated = true
                }
                
                if( ele._eventTime != nil && ele._eventTime <= currentTime ) // event
                {
                    fireIdx = n
                    updated = true
                }
                
                let sectionEvt = self._tracks[_sectionTrackIdx]._events[n]
                if(  sectionEvt._data != "" )
                {
                    currentSectionTitle = sectionEvt._data
                }
                
                if( !updated && (ele._eventTime != nil || ele._prepareTime != nil)  )
                {
                    break;
                }
            }
            
            if( currentSectionTitle != prevSectionTitle )
            {
                prevSectionTitle = currentSectionTitle
                _gNC.post(name: Notification.Name(rawValue: "SectionChanged"), object: self)
            }
            
            if( prepareIdx != _currentPrepareIdx ) //&& _currentPrepareIdx != _eventPicker.selectedRowInComponent(0) )
            {
                lastEventTimeType = EventTimeType.Prepare
                Logger.log( "Prepare \(currentTime)")
                _currentPrepareIdx = prepareIdx
                _gNC.post(name: Notification.Name(rawValue: "PrepareEventIndexChanged"), object: self)
            }
            else if( fireIdx != _currentFireIdx  )//&& lastEventTimeType == EventTimeType.Prepare  )
            {
                lastEventTimeType = EventTimeType.Fire
                Logger.log( "Fire \(currentTime)")
                _currentFireIdx = fireIdx
                _gNC.post(name: Notification.Name(rawValue: "FireEventIndexChanged"), object: self)
            }
        }
    }
    
    func playReversed( _ player:AVAudioPlayerNode!, songFile:AVAudioFile!, trackSpecifics:AudioEventSpecifics! )
    {
        if( trackSpecifics.volume > 0 ) // only play if audible!
        {
            let nowTime = self.getCurrentTime()
            
            if( player.volume > 0 )
            {
                let revBuff = self.getReverseBuffer( nowTime, songFile: songFile, trackSpecifics: trackSpecifics, player: player )
                if( revBuff != nil )
                {
                    //print( "Schedule rev \(trackSpecifics.chan)")
                    player?.scheduleBuffer(revBuff!, completionHandler:
                        {
                            self.playReversed(player, songFile: songFile, trackSpecifics: trackSpecifics)
                    })
                }
            }
        }
    }
    
    func getReverseBuffer( _ atTime:TimeInterval, songFile:AVAudioFile!, trackSpecifics:AudioEventSpecifics!, player:AVAudioPlayerNode! ) -> AVAudioPCMBuffer!
    {
        var ret:AVAudioPCMBuffer! = nil
        let startOffset = Int64(atTime * songFile.processingFormat.sampleRate)
        
        if( startOffset > 0 ) // got something to play?
        {
            //print inBuffer.audioBufferList.memory
            let frameCount:AVAudioFrameCount = AVAudioFrameCount(startOffset)
            let buffLen:AVAudioFrameCount = min( frameCount, 200000 )
            let inBuffer = AVAudioPCMBuffer( pcmFormat: songFile.processingFormat, frameCapacity: buffLen )
            let outBuffer = AVAudioPCMBuffer( pcmFormat: songFile.processingFormat, frameCapacity: buffLen )
            
            //print( "file chans \(songFile.processingFormat.channelCount.toIntMax())")
            //print( "main mix chans \(player?.engine?.mainMixerNode.outputFormatForBus(0).channelCount)" )
            //print( "main mix outs \(player.engine?.mainMixerNode.numberOfOutputs)" )
            
            songFile.framePosition = startOffset - Int64(buffLen)
            do
            {
                try songFile.read(into: inBuffer!, frameCount: buffLen)
                var readIdx = Int(inBuffer!.frameLength)
                var writeIdx =  0
                //let chanCnt = guideTrackSongFile.fileFormat.channelCount
                repeat
                {
                    let fl = inBuffer!.floatChannelData?.pointee[readIdx]
                    //print ( fl )
                    /* copy  outBuffer.floatChannelData.memory[readIdx] = fl*/
                    // reverse
                    outBuffer!.floatChannelData?.pointee[writeIdx] = fl!
                    writeIdx += 1
                    readIdx -= 1
                } while( readIdx > -1  )
                outBuffer!.frameLength = inBuffer!.frameLength
                ret = outBuffer
            }
            catch
            {
            }
            
            //ret = inBuffer // doesn't quite make sense but needed otherwise playback is only in one side of headphones
            
            if( trackSpecifics.downmixToMono == true ||
                player.engine?.outputNode.outputFormat(forBus: 0) != songFile.processingFormat )  // need this otherwise we crash!
            {
                
                let conv = AVAudioConverter(from: outBuffer!.format, to: player.outputFormat(forBus: 0) )
                conv!.downmix = true
                let convBuff =  AVAudioPCMBuffer( pcmFormat: player.outputFormat(forBus: 0), frameCapacity: buffLen )
                convBuff!.frameLength = outBuffer!.frameLength // remember to set this otherwise we fail on iOS10!
                do
                {
                    try conv!.convert(to: convBuff!, from: outBuffer!)
                    ret = convBuff
                } catch let error as NSError {
                    Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                    ret = nil
                }
            }
        }
        return(ret)
    }
    
    func setGuideTrackVolume( _ volume:Float )
    {
        let gtSpecifics = getGuideTrackSpecifics()
        if( gtSpecifics != nil )
        {
            gtSpecifics?.volume = volume
            let _track = getGuideTrackIndex()
            setTrackVolume( _track, volume: volume )
        }
    }
    
    func setTrackPan( _ _track:Int, pan:Float )
    {
        let specifics = getAudioTrackSpecifics( _track )
        if( specifics != nil )
        {
            specifics?.pan = pan
            if( _mc != nil )
            {
                let audioTrack = _mc.getAudioIndexFromTrackIndex( _track )
                if( audioTrack > -1 )
                {
                    _mc._audioTracks[audioTrack]?._player?.pan = pan
                }
            }
        }
    }
    
    let _appDelegate = UIApplication.shared.delegate as! AppDelegate
    func setTrackVolume( _ track:Int, volume:Float )
    {
        let specifics = getAudioTrackSpecifics( track )
        if( specifics != nil )
        {
            specifics?.volume = volume
            
            if( _mc != nil )
            {
                let audioTrack = _mc.getAudioIndexFromTrackIndex( track )
                if( audioTrack > -1 )
                {
                    if( _appDelegate.isPlayingOnMC && (specifics?.favourMultiChanPlayback)! )
                    {
                        _mc._audioTracks[audioTrack]?._player?.volume = volume
                    }
                    else if( !_appDelegate.isPlayingOnMC && (specifics?.favouriDevicePlayback)! )
                    {
                        _mc._audioTracks[audioTrack]?._player?.volume = volume
                    }
                    else
                    {
                        _mc._audioTracks[audioTrack]?._player?.volume = 0
                    }
                }
            }
            
            let idxs = self.getAudioTrackIndexes()
            let trackIdx = idxs.index(of: track)
            if( trackIdx != nil )
            {
                let trackChange = TrackChange()
                trackChange._track = track
                trackChange._audioTrackIdx = trackIdx!
                trackChange._volume = volume
                trackChange._specifics = specifics
                _gNC.post(name: Notification.Name(rawValue: "TrackVolumeSet"), object: trackChange)
            }
        }
    }
    
    func setIncludeOnMC( _ _track:Int, include:Bool  )
    {
        let specifics = getAudioTrackSpecifics( _track )
        
        if( specifics != nil )
        {
            specifics?.favourMultiChanPlayback = include
            setTrackVolume( _track, volume:(specifics?.volume)! )
        }
    }
    
    func setIncludeOnNonMC( _ _track:Int, include:Bool  )
    {
        let specifics = getAudioTrackSpecifics( _track )
        
        if( specifics != nil )
        {
            specifics?.favouriDevicePlayback = include
            setTrackVolume( _track, volume:(specifics?.volume)! )
        }
    }
    
    func setIgnoreDownMixMC( _ _track:Int, ignore:Bool  )
    {
        let specifics = getAudioTrackSpecifics( _track )
        
        if( specifics != nil )
        {
            specifics?.ignoreDownmixMultiChan = ignore
        }
    }
    
    func setIgnoreDownMixiDevice( _ _track:Int, ignore:Bool  )
    {
        let specifics = getAudioTrackSpecifics( _track )
        
        if( specifics != nil )
        {
            specifics?.ignoreDownmixiDevice = ignore
        }
    }
    
    func setRecordArmed( _ _track:Int, armed:Bool  )
    {
        let specifics = getAudioTrackSpecifics( _track )
        
        if( specifics != nil )
        {
            specifics?.recordArmed = armed
        }
    }
    
    var inputChan:Int = 1
    func setMonitorWhileRecording( _ _track:Int, monitorWhileRecording:Bool  )
    {
        let specifics = getAudioTrackSpecifics( _track )
        
        if( specifics != nil )
        {
            specifics?.monitorWhileRecording = monitorWhileRecording
        }
    }
    
    func setMonitorInput( _ _track:Int, monitorInput:Bool  )
    {
        let specifics = getAudioTrackSpecifics( _track )
        
        if( specifics != nil )
        {
            specifics?.monitorInput = monitorInput
        }
    }
    
    func setStereoInput( _ _track:Int, stereoInput:Bool  )
    {
        let specifics = getAudioTrackSpecifics( _track )
        
        if( specifics != nil )
        {
            specifics?.stereoInput = stereoInput
        }
    }
    
    func setInputChan( _ _track:Int, inputChan:Int )
    {
        let specifics = getAudioTrackSpecifics( _track )
        if( specifics != nil )
        {
            specifics?.inputChan = inputChan
        }
    }
    
    func isPlaying() -> Bool
    {
        let ret = _mc != nil && _mc!.isPlaying
        return( ret )
    }
    
    var _slaveTime:TimeInterval = 0
    func setCurrentTime( _ newTime: TimeInterval )
    {
        if( _isSlaveForBandPlay )
        {
            _slaveTime = newTime
            //let tm = self.getCurrentTime()
            calcEventAtTime(_slaveTime)
        }
        else
        {
            if( isPlaying() )
            {
                play(_speed, offsetTime:newTime )
            }
            else
            {
                _stoppedTime = newTime
                _gNC.post(name: Notification.Name(rawValue: "PlayerTick"), object: self)
            }
        }
    }
    
    func getCurrentTime() -> TimeInterval
    {
        var ret: TimeInterval
        if( _isSlaveForBandPlay )
        {
            ret = _slaveTime
        }
        else
        {
            //TODO: 20191128 crash here when rewind - Simultaneous accesses to 0x7fb561dc3e80, but modification requires exclusive access
            if(_mc != nil && _mc!.isPlaying)
            {
                // song time is done in absolute time
                let curTime = mach_absolute_time()
                let MSUpTime = (curTime * UInt64(_gInitTime._TimeInfo.numer) / UInt64(_gInitTime._TimeInfo.denom)) / 1_000_000
                
                var songTime:UInt64=0
                if( _speed >= 0 )
                {
                    songTime = UInt64(((Float)(MSUpTime-songStartMSecsUpTime) * _speed))
                    songTime = songTime + (UInt64)(_startOffsetInterval * 1000)
                }
                else
                {
                    songTime = UInt64(((Float)(MSUpTime-songStartMSecsUpTime) * abs(_speed)))
                    let rewtime =  ((Float)(_startOffsetInterval * 1000) -  Float(songTime))
                    if( rewtime <= 0 && !notifiedEnd )
                    {
                        DispatchQueue.main.async(execute: {
                            if( !self.notifiedEnd )
                            {
                                self.notifiedEnd = true
                                _gNC.post(name: Notification.Name(rawValue: "SongEnded"), object: self)
                            }
                        } )
                        
                    }
                    songTime = UInt64(max(0,rewtime))
                }
                
                //Logger.log(  "play time millisecs \(songTime)")
                
                // adjust to play speed
                let adjSongTime = ((Float(songTime)/1000))
                ret = TimeInterval( adjSongTime )
            }
            else
            {
                ret = _stoppedTime
            }
        }
        
        return ret
    }
    
    func getDuration() -> TimeInterval
    {
        var ret: TimeInterval
        
        if(_mc != nil && _mc!.isPlaying)
        {
            //let adjDuration = (Float(duration) * (1/_speed))
            //ret = NSTimeInterval( adjDuration )
            ret = duration
        }
        else
        {
            ret = _stoppedDuration
        }
        
        return ret
    }
    
    func getProgress() -> Float
    {
        var ret: Float = 0
        
        if( getDuration() != 0 )
        {
            ret = Float((getCurrentTime())/(getDuration()))
        }
        
        return ret
    }
    
    func rewind()
    {
        if( isPlaying() )
        {
            stop()
            play( -5.0, offsetTime:getCurrentTime() )
        }
        else
        {
            var targetTime = getCurrentTime()
            targetTime = targetTime.advanced(by: -10.0)
            if( targetTime < 0 )
            {
                targetTime = 0
            }
            setCurrentTime(targetTime)
        }
        _gNC.post(name: Notification.Name(rawValue: "PlayerRewind"), object: self)
    }
    
    func fastFwd()
    {
        if( isPlaying() )
        {
            stop()
            play( 5.0, offsetTime:getCurrentTime() )
        }
        else
        {
            var targetTime = getCurrentTime()
            let duration = getDuration()
            targetTime = targetTime.advanced(by: 10.0)
            if( targetTime > duration)
            {
                targetTime = duration
            }
            setCurrentTime(targetTime)
        }
        _gNC.post(name: Notification.Name(rawValue: "PlayerFastForward"), object: self)
    }
    
    func stop( _ dontNotifyStop:Bool = false, sendMidi:Bool = true, waitForCleanup:Bool = false )
    {
        stopTick() // do this first
        if( isPlaying() )
        {
            self._stoppedTime = self.getCurrentTime()
            self._stoppedDuration = self.getDuration()
            self.fillMediaInfo(self._stoppedTime, stopping: true)
            let recordedTracks = self._mc?.stop( waitForCleanup )
            
            // update the urls for the tracks
            if( recordedTracks?.count > 0 )
            {
                _gNC.post(name: Notification.Name(rawValue: "StatusUpdate"), object: String("Saving \(String(describing: recordedTracks?.count)) tracks please wait..."))
                for recTrack in recordedTracks!
                {
                    let recTrackIdx = recTrack?._originalRecordedTrackIdx
                    if( recTrackIdx > -1 )
                    {
                        self.setDataForTrackEvent(recTrackIdx!, eventIdx: 0, url: (recTrack?._recordedFileURL)!)
                    }
                }
            }
            
            _gNC.post(name: Notification.Name(rawValue: "PlayerTick"), object: self)
            if(!dontNotifyStop)
            {
                _gNC.post(name: Notification.Name(rawValue: "PlayerStop"), object: self)
                if( sendMidi )
                {
                    _gNC.post(name: Notification.Name(rawValue: "PlayerStopSendMidi"), object: self)
                }
            }
            
            // kill the engine
            _ = self._mc?.stop(waitForCleanup)
            self._mc = nil
        }
        else // second press
        {
            self._stoppedTime = 0
            self._stoppedDuration = self.getDuration()
            _gNC.post(name: Notification.Name(rawValue: "PlayerTick"), object: self)
            if( !dontNotifyStop )
            {
                _gNC.post(name: Notification.Name(rawValue: "PlayerStop"), object: self)
                if( sendMidi )
                {
                    _gNC.post(name: Notification.Name(rawValue: "PlayerStopSendMidi"), object: self)
                }
            }
        }
    }
    
    func pause()
    {
        self.stop()
    }
    
    // setup audio
    func setupMultiChan()
    {
        if( _mc == nil)
        {
            let guideTrackIdx = self.getGuideTrackIndex()
            let backingTrackIdxs = self.getBackingTrackIndexes()
            
            _mc = MultiChannelAudio( guideTrackIdx:guideTrackIdx, backingTrackIdxs: backingTrackIdxs )
        }
    }
    
    
    func play( _ speed:Float = 1.0, offsetTime:TimeInterval = 0, withRecord:Bool = false )
    {
        notifiedEnd = false
        
        if( isPlaying() && speed != self._speed )
        {
            stop()
        }
        
        if( !isPlaying() || !(isPlaying() && speed == self._speed) ) // ignore a second request
        {
            let prefBitDepth = UserDefaults.standard.integer(forKey: "bitDepth_preference")
            let audioPlayersGroupService:DispatchGroup = DispatchGroup()
            setupMultiChan()
            
            var atTime:TimeInterval = offsetTime
            if( atTime == 0 && self._stoppedTime != 0 )
            {
                atTime = self._stoppedTime
            }
            self._startOffsetInterval = atTime
            
            let guideTrackSpecifics = self.getGuideTrackSpecifics()
            if( guideTrackSpecifics != nil )
            {
                // get the urls we are going to play or record
                let guideTrack:URL! = guideTrackSpecifics!.recordArmed && withRecord ? self.getGuideTrackRecordURL() : self.getGuideTrackURL()
                // _mc.recordMode = self._recordArmed
                
                audioPlayersGroupService.enter()
                _gTrackPlayerQueue.async(execute: {
                    if( guideTrack != nil && self._mc?._audioTracks.count > 0 )
                    {
                        do
                        {
                            var guideTrackSongFile:AVAudioFile! = nil
                            let track = self._mc._audioTracks[0]
                            track?._existingPlaybackURL = self.getGuideTrackURL()
                            let guideplayer = track?._player
                            
                            if( !((guideTrackSpecifics?.recordArmed)! && withRecord == true) )
                            {
                                guideTrackSongFile = try AVAudioFile( forReading: guideTrack! )
                            }
                            else // create our recording file
                            {
                                let inChanCount:Int = Int( track!._engine.inputNode.inputFormat(forBus: 0).channelCount ) // num of input chans avail
                                let startChan = (((guideTrackSpecifics?.inputChan)!-1) % inChanCount) // starting chan given specified rec chan - zero relative
                                let songFileChanCount:Int = min( (guideTrackSpecifics!.stereoInput ? 2 : 1), inChanCount > 1 ? 2 : 1, inChanCount-startChan  )
                                
                                //let fileFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.PCMFormatFloat32, sampleRate:44100, channels: UInt32(songFileChanCount), interleaved: true)
                                //guideTrackSongFile = try AVAudioFile(forWriting: guideTrack!, settings: fileFormat.settings)
                                
                                let recordSettings:[String : AnyObject] = [AVFormatIDKey : NSNumber(value: kAudioFormatMPEG4AAC as UInt32), AVNumberOfChannelsKey : NSNumber(value: UInt32(songFileChanCount) as UInt32), AVSampleRateKey : NSNumber(value: AVAudioSession.sharedInstance().sampleRate as Double), AVLinearPCMBitDepthKey:  NSNumber(value: UInt32(prefBitDepth) as UInt32),
                                                                           AVEncoderAudioQualityKey:  NSNumber(value: UInt32(AVAudioQuality.max.rawValue) as UInt32) ]
                                
                                guideTrackSongFile = try AVAudioFile(forWriting: guideTrack!, settings: recordSettings)
                            }
                            
                            var dontPlay = false
                            if( self._appDelegate.isPlayingOnMC && (guideTrackSpecifics?.favourMultiChanPlayback)! )
                            {
                                guideplayer?.volume = (guideTrackSpecifics?.volume)!
                            }
                            else if( !self._appDelegate.isPlayingOnMC && (guideTrackSpecifics?.favouriDevicePlayback)! )
                            {
                                guideplayer?.volume = (guideTrackSpecifics?.volume)!
                            }
                            else
                            {
                                guideplayer?.volume = 0
                                dontPlay = true
                            }
                            
                            if( !dontPlay || ((guideTrackSpecifics?.recordArmed)! && withRecord == true) )
                            {
                                track?.primeTrack((guideTrackSpecifics?.chan)!, songFile:guideTrackSongFile, requestMonoDownMix: (guideTrackSpecifics?.downmixToMono)!, ignoreDownmixOnMultiChan: (guideTrackSpecifics?.ignoreDownmixMultiChan)!,
                                                  ignoreDownmixiDevice: (guideTrackSpecifics?.ignoreDownmixiDevice)!,
                                                  speed: speed, songStartOffset: self._startOffsetInterval, withRecord: withRecord, trackArmed: (guideTrackSpecifics?.recordArmed)!, recordChan: (guideTrackSpecifics?.inputChan)!, stereoInput: (guideTrackSpecifics?.stereoInput)!, monitor:(guideTrackSpecifics?.monitorInput)!, monitorWhileRecording: (guideTrackSpecifics?.monitorWhileRecording)! )
                                
                                if( guideTrackSongFile != nil && !((guideTrackSpecifics?.recordArmed)! && withRecord == true) )
                                {
                                    self.duration = Double((guideTrackSongFile.length) / (Int64)(guideTrackSongFile.processingFormat.sampleRate))// - atTime
                                    //Logger.log( "guideTrackSongFile.length \(guideTrackSongFile.length) guideTrackSongFile.processingFormat.sampleRate \(guideTrackSongFile.processingFormat.sampleRate)" )
                                    
                                    guideplayer?.pan = 0.001 // we have to do this before setting the actual value for some strange reason!
                                    guideplayer?.pan = (guideTrackSpecifics?.pan)!
                                    
                                    if( speed >= 0 )
                                    {
                                        if( atTime == 0 )
                                        {
                                            guideplayer?.scheduleFile(guideTrackSongFile, at:nil, completionHandler:nil)
                                        }
                                        else
                                        {
                                            let startOffset = Int64(atTime * guideTrackSongFile.processingFormat.sampleRate)
                                            //Logger.log( "startOffset \(startOffset)")
                                            if( guideTrackSongFile.length > startOffset )
                                            {
                                                guideplayer?.scheduleSegment(guideTrackSongFile, startingFrame: startOffset, frameCount: UInt32(guideTrackSongFile.length - startOffset), at: nil, completionHandler:nil)
                                            }
                                        }
                                    }
                                    else // playing in reverse
                                    {
                                        if( guideTrackSongFile.processingFormat.commonFormat == .pcmFormatFloat32 )
                                        {
                                            if( atTime > 0 ) // got something to play?
                                            {
                                                self.playReversed( guideplayer, songFile: guideTrackSongFile, trackSpecifics: guideTrackSpecifics )
                                            }
                                        }
                                    }
                                }
                            }
                        } catch let error as NSError
                        {
                            Logger.log( "guide track error \(error.localizedDescription)" )
                        }
                    }
                    audioPlayersGroupService.leave()
                })
            }
            
            
            // backing tracks could in theory have different sample rate to the guide track
            let backingURLs = self.getBackingTrackURLs()
            let backingRecordURLs = self.getBackingTrackRecordURLs()
            let backingSpecifics = self.getBackingTrackSpecifics()
            
            for (idx, track) in backingURLs.enumerated()
            {
                audioPlayersGroupService.enter()
                _gTrackPlayerQueue.async(execute: {
                    do
                    {
                        let specifics = backingSpecifics[idx]
                        let audioTrack = self._mc._audioTracks[idx+1]
                        audioTrack?._existingPlaybackURL = track
                        var trackSongFile:AVAudioFile! = nil
                        
                        if( !((specifics?.recordArmed)! && withRecord == true) )
                        {
                            trackSongFile = try AVAudioFile( forReading: track! )
                        }
                        else
                        {
                            let trackRec = backingRecordURLs[idx]
                            
                            let inChanCount:Int = Int( audioTrack!._engine.inputNode.inputFormat(forBus: 0).channelCount ) // num of input chans avail
                            let startChan = (((specifics?.inputChan)!-1) % inChanCount) // starting chan given specified rec chan - zero relative
                            let songFileChanCount:Int = min( (specifics!.stereoInput ? 2 : 1), inChanCount > 1 ? 2 : 1, inChanCount-startChan  )
                            /*
                             let fileFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.PCMFormatFloat32, sampleRate:44100, channels: UInt32(songFileChanCount), interleaved: true)
                             trackSongFile = try AVAudioFile(forWriting: trackRec!, settings: fileFormat.settings)
                             */
                            
                            let recordSettings:[String : AnyObject] = [AVFormatIDKey : NSNumber(value: kAudioFormatMPEG4AAC as UInt32), AVNumberOfChannelsKey : NSNumber(value: UInt32(songFileChanCount) as UInt32), AVSampleRateKey : NSNumber(value: AVAudioSession.sharedInstance().sampleRate as Double), AVEncoderAudioQualityKey:  NSNumber(value: UInt32(AVAudioQuality.max.rawValue) as UInt32) ]
                            trackSongFile = try AVAudioFile(forWriting: trackRec!, settings: recordSettings)
                        }
                        
                        if( self.duration == 0 ) // use first BT as reference clock if guide track not used
                        {
                            self.duration = Double((trackSongFile.length) / (Int64)(trackSongFile.processingFormat.sampleRate))
                        }
                        
                        let player = audioTrack?._player
                        var dontPlay = false
                        if( self._appDelegate.isPlayingOnMC && (specifics?.favourMultiChanPlayback)! )
                        {
                            player?.volume = (specifics?.volume)!
                        }
                        else if( !self._appDelegate.isPlayingOnMC && (specifics?.favouriDevicePlayback)! )
                        {
                            player?.volume = (specifics?.volume)!
                        }
                        else
                        {
                            player?.volume = 0
                            dontPlay = true
                        }
                        
                        if( !dontPlay || ((specifics?.recordArmed)! && withRecord == true) )
                        {
                            audioTrack?.primeTrack( (specifics?.chan)!, songFile: trackSongFile, requestMonoDownMix: (specifics?.downmixToMono)!, ignoreDownmixOnMultiChan: (specifics?.ignoreDownmixMultiChan)!, ignoreDownmixiDevice: (specifics?.ignoreDownmixiDevice)!, speed: speed, songStartOffset: self._startOffsetInterval, withRecord: withRecord, trackArmed: (specifics?.recordArmed)!, recordChan: (specifics?.inputChan)!, stereoInput: (specifics?.stereoInput)!, monitor: (specifics?.monitorInput)!, monitorWhileRecording: (specifics?.monitorWhileRecording)!  )
                            
                            if( trackSongFile != nil && !((specifics?.recordArmed)! && withRecord == true) )
                            {
                                player?.pan = 0.001 // we have to do this before setting the actual value for some strange reason!
                                player?.pan =  (backingSpecifics[idx]?.pan)!
                                
                                if( speed >= 0 )
                                {
                                    if( atTime == 0 )
                                    {
                                        player?.scheduleFile(trackSongFile, at:nil, completionHandler:nil)
                                    }
                                    else
                                    {
                                        let startOffset:Int64 = Int64(atTime * trackSongFile.processingFormat.sampleRate)
                                        if( trackSongFile.length > startOffset )
                                        {
                                            player?.scheduleSegment(trackSongFile, startingFrame: startOffset, frameCount: UInt32(trackSongFile.length - startOffset), at: nil, completionHandler:nil)
                                        }
                                    }
                                }
                                else
                                {
                                    if( trackSongFile.processingFormat.commonFormat == .pcmFormatFloat32 )
                                    {
                                        if( atTime > 0 ) // got something to play?
                                        {
                                            self.playReversed( player, songFile: trackSongFile, trackSpecifics: backingSpecifics[idx] )
                                        }
                                    }
                                }
                            }
                        }
                    }
                    catch let error as NSError
                    {
                        Logger.log( "error \(error.localizedDescription)" )
                    }
                    audioPlayersGroupService.leave()
                })
            }
            
            Logger.log( "Waiting for track sync group" )
            // allow all the player start-up threads to complete and join together to sync them in playback
            _ = audioPlayersGroupService.wait(timeout: DispatchTime.distantFuture)
            Logger.log( "tracks sync group done" )
            
            let startUpTimeBuff = 30 // should really get from global vars
            var curTime = mach_absolute_time()
            //Logger.log(  "play curTime \(curTime)")
            
            self.songStartMSecsUpTime = (curTime * UInt64(_gInitTime._TimeInfo.numer) / UInt64(_gInitTime._TimeInfo.denom)) / 1_000_000
            //Logger.log(  "play up time millisecs \(songStartMSecsUpTime)")
            
            let timeToStart = UInt64( startUpTimeBuff * _mc._audioTracks.count ) // x (startUpTimeBuff) ms per player, plus one to pad
            self.schedTime = ((((self.songStartMSecsUpTime + timeToStart) * 1000000) * UInt64(_gInitTime._TimeInfo.denom)) / UInt64(_gInitTime._TimeInfo.numer))
            self.playTime = AVAudioTime( hostTime: self.schedTime )
            
            //guideplayer.playerTimeForNodeTime(<#T##nodeTime: AVAudioTime##AVAudioTime#>)
            //guideplayer.nodeTimeForPlayerTime(<#T##playerTime: AVAudioTime##AVAudioTime#>)
            
            Logger.log( "calling play at time" )
            self._mc.playAtTime(self.playTime, withRecord: withRecord)
            
            self._speed = speed
            
            if( speed == 1.0 )
            {
                _gNC.post(name: Notification.Name(rawValue: "PlayerPlay"), object: self)
            }
            else
            {
                _gNC.post(name: Notification.Name(rawValue: "PlayerPlayVarispeed"), object: self)
            }
            
            curTime = mach_absolute_time()
            let timeNow = (curTime * UInt64(_gInitTime._TimeInfo.numer) / UInt64(_gInitTime._TimeInfo.denom)) / 1_000_000
            Logger.log( "done play at time \(self.songStartMSecsUpTime + timeToStart) time now: \(timeNow)")
            self.startTick()
        }
    }
    
    var _recordArmed = false
    func armRecord()
    {
        _recordArmed = true
        if( self.isPlaying() )
        {
            self.stop()
            self.play( withRecord: _recordArmed )
        }
    }
    
    func dearmRecord()
    {
        _recordArmed = false
        if( self.isPlaying() )
        {
            self.stop()
            self.play( withRecord: _recordArmed )
        }
    }
    
    func copyTrackAudioToWavs(withGuideAudio:Bool) -> [URL?]
    {
        let audioUtils:AudioUtils = AudioUtils()
        var btIdxs = self.getBackingTrackIndexes()
        let guideTrackIdx = self.getGuideTrackIndex()
        let clickTrackIdx = self.getClickTrackIndex()
        if( withGuideAudio == true )
        {
            btIdxs.append(guideTrackIdx)
        }
        if( clickTrackIdx > -1 )
        {
            btIdxs.append(clickTrackIdx)
        }
        
        var audioURLs = self.getBackingTrackURLs()
        let guideURL = self.getGuideTrackURL()
        if( withGuideAudio == true )
        {
            audioURLs.append(guideURL)
        }
        if( clickTrackIdx > -1 )
        {
            let clickURL = self.getClickTrackURL()
            audioURLs.append(clickURL)
        }
        
        var specifics = self.getBackingTrackSpecifics()
        let guideSpecifics = self.getGuideTrackSpecifics()
        if( withGuideAudio == true )
        {
            specifics.append(guideSpecifics)
        }
        if( clickTrackIdx > -1 )
        {
            let clickSpecifics = self.getClickTrackSpecifics()
            specifics.append(clickSpecifics)
        }
        
        
        var lstOutputURLs = [URL?]()
        
        // convert all to .wav and split stereo to two mono, keep list with channel assignments
        // remix to channel assignments, with
        var btIdx = 0
        for url in audioURLs
        {
            /*
             _gNC.post(name: Notification.Name(rawValue: "ConvertingAudio"), object: "Converting audio \(btIdx+1) of \(audioURLs.count)")
             _gNC.post(name: Notification.Name(rawValue: "ConvertingAudioPct"), object: Float( Float(btIdx+1) / Float(audioURLs.count) ) )*/

            let track = self._tracks[btIdxs[btIdx]]
            let name = "\(track._trackName)_\(String.init(format: "%02d", specifics[btIdx]!.chan))"
            let newURL = audioUtils.toWav(url!, outName: name)//, monoDownMix: specifics[btIdx]!.downmixToMono)
            Logger.log( "Converting \(url!.debugDescription) to wav" )
            _gNC.post(name: Notification.Name(rawValue: "ConvertingAudio"), object: "Converting audio track \(name)")
            
            Logger.log( "New file created: \(newURL.debugDescription) " )
            if( newURL != nil )
            {
                let OutputLFileName = "\(track._trackName)L_\(String.init(format: "%02d", specifics[btIdx]!.chan)).wav"
                let OutputRFileName = "\(track._trackName)R_\(String.init(format: "%02d", specifics[btIdx]!.chan+1)).wav"
                
                let outputURLl = (newURL!.deletingLastPathComponent().appendingPathComponent(OutputLFileName) as NSURL).filePathURL
                let outputURLr = (newURL!.deletingLastPathComponent().appendingPathComponent(OutputRFileName) as NSURL).filePathURL
                
                if( audioUtils.splitStereo( newURL!, outputURLl: outputURLl!, outputURLr: outputURLr! ) )
                {
                    Logger.log( "Split stereo" )
                    // remove stereo file
                    try? _gFSH.removeItem(at: newURL!)
                    
                    // if we wanted to mix to mono, then combine L and R wavs
                    if( specifics[btIdx]!.downmixToMono )
                    {
                        let OutputMonoFileName = "\(track._trackName)M_\(String.init(format: "%02d", specifics[btIdx]!.chan)).wav"
                        let outputURLMono = (newURL!.deletingLastPathComponent().appendingPathComponent(OutputMonoFileName) as NSURL).filePathURL
                        if( audioUtils.mixWavs(outputURLMono!, urlWav1: outputURLl!, volume1: 0.73, urlWav2: outputURLr!, volume2: 0.73, synchronous: true) )
                        {
                            Logger.log( "Mono downmix" )
                            // remove L R files
                            try? _gFSH.removeItem(at: outputURLl!)
                            try? _gFSH.removeItem(at: outputURLr!)
                            
                            // add mono file to the master list for downmixing
                            lstOutputURLs.append(outputURLMono)
                        }
                        else
                        {
                            
                            
                        }
                    }
                    else
                    {
                        // add stereo files to the master list for downmixing
                        lstOutputURLs.append(outputURLl)
                        lstOutputURLs.append(outputURLr)
                    }
                }
                else
                {
                    // add mono file to the master list for downmixing
                    lstOutputURLs.append(newURL)
                }
            }

            btIdx += 1
        }
        
        
        // process output lists in case of down mixes for duplicate channels
        var lstEachChan = [URL?]()
        for chanCnt in 1...32
        {
            let thisCount = String.init(format: "%02d", chanCnt)
            for matchURL in lstOutputURLs
            {
                let fileName = matchURL!.deletingPathExtension().lastPathComponent // no .wav
                //let chan = fileName.substring(from: fileName.index(fileName.endIndex, offsetBy: -2))
                let chan = fileName[fileName.index(fileName.endIndex, offsetBy: -2)...]
                if( thisCount == chan) // matched channel
                {
                    lstEachChan.append(matchURL!)
                }
            }
            
            // need to merge these chans
            if( lstEachChan.count > 1 )
            {
                Logger.log( "Merging audio for channel \(thisCount)" )
                _gNC.post(name: Notification.Name(rawValue: "ConvertingAudio"), object: "Merging audio for channel \(thisCount)")
                
                let volProportion:Float = ((1.0 / (Float)(lstEachChan.count)) - 0.05)
                
                var accumulatorWavURL:URL! = lstEachChan[0]?.deletingLastPathComponent().appendingPathComponent("Chan\(chanCnt).wav")
                var tempOutURL:URL! = lstEachChan[0]?.deletingLastPathComponent().appendingPathComponent("Chan\(chanCnt)Part\(0).wav")
                let firstTemp:URL = tempOutURL!
                for mergeIdx in 0..<lstEachChan.count
                {
                    let mergeURL=lstEachChan[mergeIdx]
                    // multiply volProportion by actual vol in mixer
                    _ = audioUtils.mixWavs(tempOutURL, urlWav1: accumulatorWavURL, volume1: 1.0, urlWav2: mergeURL!, volume2: volProportion, synchronous: true)
                    try? _gFSH.removeItem(at: accumulatorWavURL!) // remove the accumulator now its used
                    accumulatorWavURL = tempOutURL
                    tempOutURL = lstEachChan[0]?.deletingLastPathComponent().appendingPathComponent("MergeParts1-\(mergeIdx+2)OnChan_\(thisCount).wav")
                }
                
                // remove temp files
                try? _gFSH.removeItem(at: firstTemp)
                for mergeIdx in 0..<lstEachChan.count
                {
                    let mergeURL=lstEachChan[mergeIdx]
                    let originalListIdx = lstOutputURLs.index(of: mergeURL)
                    lstOutputURLs.remove(at: originalListIdx!)
                    try? _gFSH.removeItem(at: mergeURL!) // remove the original input files we first made
                }
                
                // tempOutURL is what we keep
                lstOutputURLs.append(accumulatorWavURL)
            }
            
            // do our thing then reset list
            lstEachChan.removeAll()
        }
        
        // now we have what we need in lstOutputURLs
        return(lstOutputURLs)
    }
    
    func copyTrackAudioToClipboard( _ track:Int )
    {
        let originalTrack = self.getTrackDataAsURL(track, eventIdx: 0 )
        
        if( originalTrack != nil )
        {
            let ext = originalTrack!.pathExtension
            /*
             let name = self.muzomaDoc?._tracks[self._track!]._trackName
             let trackFileName = "track \(self._track!+1) - \(name!)." + ext!
             */
            
            let pasteBoard = UIPasteboard.general
            pasteBoard.items.removeAll()
            var items: [[String : AnyObject]] =  [[String : AnyObject]]()
            
            var type:CFString = "" as CFString
            switch(ext)
            {
            case "wav": type = kUTTypeWaveformAudio
            break;
            case "m4a": type = kUTTypeMPEG4Audio
            break;
            case "mp3": type = kUTTypeMP3
            break;
            case "caf": type = kUTTypeAudioInterchangeFileFormat
            break;
                
            default:
                type = "" as CFString
                break;
            }
            
            let data = try? Data.init(contentsOf: originalTrack!)
            if( data != nil )
            {
                Logger.log("added \(originalTrack!.lastPathComponent)")
                items.append([type as String:data! as AnyObject, kUTTypeURL as String:originalTrack! as AnyObject])
            }
            
            if(items.count > 0 )
            {
                pasteBoard.addItems(items)
            }
        }
    }
    
    func copyTrackAudioToAudioShare( _ track:Int )
    {
        let ashare = AudioShare()
        let originalTrack = self.getTrackDataAsURL(track, eventIdx: 0 )
        
        if( originalTrack != nil )
        {
            let name = self._tracks[track]._trackName
            let ext = originalTrack!.pathExtension
            let trackFileName = "track \(track+1) - \(name)." + ext
            let data = try? Data.init(contentsOf: originalTrack!)
            if( data != nil )
            {
                Logger.log("added \(trackFileName) to audio share")
                ashare.addSound(from: data!, withName: trackFileName )
            }
        }
    }
    
    func pasteTrackAudioFromClipboard( _ track:Int ) -> String!
    {
        var ret:String! = nil
        let pasteBoard = UIPasteboard.general
        Logger.log( "paste board items \(pasteBoard.numberOfItems)" )
        let audioTypeStr = NSString(utf8String: kUTTypeAudio as String)
        
        let typeArray:NSArray!  = NSArray.init(array: [audioTypeStr!])
        let set:IndexSet! = pasteBoard.itemSet(withPasteboardTypes: typeArray as [AnyObject] as! [String])
        
        if( set != nil && set.count > 0 )
        {
            let audItems:NSArray! = pasteBoard.data(forPasteboardType: audioTypeStr! as String, inItemSet: set)! as NSArray
            Logger.log("paste board audio items \(audItems.count)" )
            
            var count = 0
            for item in audItems
            {
                let name = self._tracks[track]._trackName
                let prefTrackName = "track \(track) - " + name.stringByRemovingCharactersInSet(acceptableProperSet.inverted)
                let tempURLStr = try? NSTemporaryDirectory().asURL().absoluteString
                if( tempURLStr != nil )
                {
                    let tempfile = NSURL( fileURLWithPath: tempURLStr! ).appendingPathComponent("\(prefTrackName)")
                    do
                    {
                        if( item is NSData )
                        {
                            ret = ""
                            try (item as! NSData).write(to: tempfile!, options: .atomicWrite)
                            //var filePtr:UnsafeMutablePointer<AudioFileID> = nil
                            var af:AudioFileID? = nil
                            let audioFileErr = AudioFileOpenURL(tempfile! as CFURL, .readPermission, 0, &af )
                            if( audioFileErr == 0 )
                            {
                                var typeID:AudioFileTypeID = 0
                                var size:UInt32 = 4// sizeof(typeID)
                                AudioFileGetProperty( af!, kAudioFilePropertyFileFormat, &size, &typeID)
                                AudioFileClose(af!)
                                var ext = ""
                                switch(typeID)
                                {
                                case kAudioFileAIFFType: ext = "aiff"
                                break;
                                case kAudioFileAIFCType: ext = "aifc"
                                break;
                                case kAudioFileWAVEType: ext = "wav"
                                break;
                                case kAudioFileSoundDesigner2Type: ext = "sd2"
                                break;
                                case kAudioFileNextType: ext = "nxt"
                                break;
                                case kAudioFileMP3Type: ext = "mp3"
                                break;
                                case kAudioFileMP2Type: ext = "mp2"
                                break;
                                case kAudioFileMP1Type: ext = "mp1"
                                break;
                                case kAudioFileAC3Type: ext = "ac3"
                                break;
                                case kAudioFileAAC_ADTSType: ext = "adts"
                                break;
                                case kAudioFileMPEG4Type: ext = "mp4"
                                break;
                                case kAudioFileM4AType: ext = "m4a"
                                break;
                                case kAudioFileCAFType: ext = "caf"
                                break;
                                case kAudioFile3GPType: ext = "3gp"
                                break;
                                case kAudioFile3GP2Type: ext = "3gp2"
                                break;
                                case kAudioFileAMRType: ext = "amr"
                                break;
                                default:
                                    ext = ""
                                    break;
                                }
                                
                                if( ext != "" )
                                {
                                    let existing = self.getTrackDataAsURL(track, eventIdx: 0)
                                    if( _gFSH.fileExists(existing) ) // clear the old one
                                    {
                                        do
                                        {
                                            try _gFSH.removeItem(at: existing!)
                                            Logger.log("\(#function)  \(#file) Deleted \(existing!.absoluteString)")
                                        } catch let error as NSError {
                                            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                                        }
                                    }
                                    
                                    let fileWithCorrectExtension = tempfile?.appendingPathExtension(ext)
                                    let documentFolderFileWithCorrectExtension = self.getDocumentFolderPathURL()!.appendingPathComponent(fileWithCorrectExtension!.lastPathComponent)
                                    if( _gFSH.fileExists(documentFolderFileWithCorrectExtension) )
                                    {
                                        do
                                        {
                                            try _gFSH.removeItem(at: documentFolderFileWithCorrectExtension)
                                            Logger.log("\(#function)  \(#file) Deleted \(documentFolderFileWithCorrectExtension.absoluteString)")
                                        } catch let error as NSError {
                                            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                                        }
                                    }
                                    try _gFSH.moveItem(at: tempfile!, to: documentFolderFileWithCorrectExtension)
                                    Logger.log("File saved \(documentFolderFileWithCorrectExtension)")
                                    self.setDataForTrackEvent(track, eventIdx: 0, url: documentFolderFileWithCorrectExtension)
                                    ret = documentFolderFileWithCorrectExtension.lastPathComponent
                                    break;
                                }
                            }
                            else
                            {
                                if( _gFSH.fileExists(tempfile) ) // clear the old one
                                {
                                    do
                                    {
                                        try _gFSH.removeItem(at: tempfile!)
                                        Logger.log("\(#function)  \(#file) Deleted \(String(describing: tempfile?.absoluteString))")
                                    } catch let error as NSError {
                                        Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                                    }
                                }
                            }
                        }
                    } catch let error as NSError {
                        Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                    }
                }
                count += 1
            }
        }
        return(ret)
    }
    
    
    open func removeAllAudio( _ leaveGuide:Bool = false ) -> Bool
    {
        var done = true
        self.stop()
        
        for track in self.getBackingTrackIndexes()
        {
            done =  self.removeTrackFile(track, eventIdx: 0 ) == true && done
        }
        
        if( !leaveGuide )
        {
            done =  self.removeTrackFile(self.getGuideTrackIndex(), eventIdx: 0 ) == true && done
        }
        
        return( done )
    }
}



