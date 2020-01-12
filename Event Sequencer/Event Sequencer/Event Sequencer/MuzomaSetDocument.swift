//
//  MuzomaSetDocument.swift
//  Event Sequencer
//
//  Created by Matthew Hopkins on 03/09/2015.
//  Copyright © 2015 Muzoma.com. All rights reserved.
//
//  Represents a set of songs as a document.  The set contains links to song documents.  Has code to serialize and deserialize itself

import Foundation
import CoreFoundation
import AudioToolbox
import MediaPlayer
import AVFoundation
import CoreMIDI
import MIKMIDI
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
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}


open class MuzomaSetDocument : NSObject, AVAudioPlayerDelegate
{
    let _setURL = _gFSH.getSetsFolderURL()!
    let _docURL = _gFSH.getDocumentFolderURL()!
    let nc = NotificationCenter.default
    let info:MPNowPlayingInfoCenter! = MPNowPlayingInfoCenter.default()
    var setAutoPlayNextSong = UserDefaults.standard.bool(forKey: "setAutoPlayNextSong_preference")
    fileprivate var _muzDocs: [MuzomaDocument] = []
    
    var muzDocs : [MuzomaDocument]  {
        get {
            return _muzDocs
        }
        
        set {
            _muzDocs = newValue
        }
    }
    
    var _uid: String? = nil
    
    var _title: String? = nil
    var _artist: String? = nil
    var _author: String? = nil
    var _copyright: String? = nil
    var _publisher: String? = nil
    var _coverArtURL: String? = nil
    var _originalArtworkURL: String? = nil
    var _muzVersion: String? = nil
    var _muzAuthor: String? = nil
    var _muzAuthorUID: String? = nil
    var _creationDate: Date? = nil
    var _lastUpdateDate: Date? = nil
    
    var _loopSet:Bool = false
    
    override init()
    {
        super.init()
        nc.addObserver(self, selector: #selector(MuzomaSetDocument.refreshSettingChanges(_:)), name: UserDefaults.didChangeNotification, object: nil)
    }
    
    deinit
    {
        nc.removeObserver(self, name: UserDefaults.didChangeNotification, object: nil )
    }
    
    
    @objc func refreshSettingChanges(_ notification: Notification) {
        setAutoPlayNextSong = UserDefaults.standard.bool(forKey: "setAutoPlayNextSong_preference")
    }
    
    open func activate()
    {
        //print("set init")
        nc.addObserver(self, selector: #selector(MuzomaSetDocument.playerEnded(_:)), name: NSNotification.Name(rawValue: "SongEnded"), object: nil)
        nc.addObserver(self, selector: #selector(MuzomaSetDocument.selectSong(_:)), name: NSNotification.Name(rawValue: "SelectSong"), object: nil)
    }
    
    open func deactivate()
    {
        //print("set deinit")
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "SongEnded"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "SelectSong"), object: nil )
        self.info.nowPlayingInfo = nil
        
    }
    
    open func isValid() -> Bool
    {
        return( self._uid != nil )
    }
    
    open func addNewDoc( _ doc:MuzomaDocument )
    {
        self.muzDocs.append(doc)
    }
    
    open func getSetURL() -> URL?
    {
        var ret:URL? = nil
        
        ret = getSetFolderPathURL()!.appendingPathComponent(getFileName())
        
        return( ret )
    }
    
    open func ensureSetURLExists() -> Bool
    {
        var ret:Bool = false
        let helper = _gFSH
        ret = helper.ensureFolderExists(getSetFolderPathURL())
        return ret
    }
    
    open func getSetFolderPathURL() -> URL?
    {
        var ret:URL?=nil
        if(self._diskFolderFilePath != nil)
        {
            ret = self._diskFolderFilePath.deletingLastPathComponent() // deserialized from a path
        }
        else
        {
            // the default path
            ret = _setURL.appendingPathComponent(getFolderName(),isDirectory: true)
        }
        return( ret )
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
            ret = _docURL.appendingPathComponent("Set Placeholder.png")
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
            ret = _docURL.appendingPathComponent("Set Placeholder.png")
            //print("artwork placeholder url is \(ret?.absoluteString)")
        }
        else
        {
            ret = getSetFolderPathURL()!.appendingPathComponent(_coverArtURL!)
            //print("artwork url is \(ret?.absoluteString)")
        }
        
        return( ret )
    }
    
    open func getFileName() -> String
    {
        let prefix = _artist == nil ? "" : _artist!
        let suffix = _title == nil ? "" : _title!
        return( prefix + " - " + suffix + ".set.xml")
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
                _diskFolderFilePath = self.getSetFolderPathURL()!.appendingPathComponent( getFolderName() )
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
    
    open func addDocs( _ docs:[MuzomaDocument] )
    {
        if( docs.count > 0 )
        {
            self.muzDocs.append(contentsOf: docs)
        }
    }
    
    open func loadEmptyDefaultSet()
    {
        _uid = UUID().uuidString
        let reg = UserRegistration()
        _title = "Set 1"
        _artist = reg.artist ?? "Artist"
        _author = reg.author ?? "Author"
        _copyright = reg.copyright ?? "(c) " + Date().datePretty
        _publisher = reg.publisher
        _coverArtURL = ""
        _muzVersion = Version.DocVersion
        _muzAuthor = reg.communityName ?? "My Name"
        _muzAuthorUID = reg.userId ?? ""
        _creationDate = Date()
        _lastUpdateDate = Date()
    }
    
    open func serialize() -> String
    {
        let muzXMLDoc = AEXMLDocument()
        let muzXMLDocAttributes = ["xmlns:xsi" : "http://www.w3.org/2001/XMLSchema-instance", "xmlns:xsd" : "http://www.w3.org/2001/XMLSchema"]
        let body = muzXMLDoc.addChild(name: "MuzomaSet", attributes: muzXMLDocAttributes)
        
        let header = body.addChild(name: "Header")
        header.addChild(name: "UID", value: _uid != nil ? String(_uid!) : nil )
        
        header.addChild(name: "DiskFolderFilePath", value: self.diskFolderFilePathString )
        
        header.addChild(name: "Title", value: _title != nil ? String(_title!).addingPercentEncoding(withAllowedCharacters: xmlAllowedSet) : nil )
        header.addChild(name: "Artist", value: _artist != nil ? String(_artist!).addingPercentEncoding(withAllowedCharacters: xmlAllowedSet) : nil )
        header.addChild(name: "Author", value: _author != nil ? String(_author!).addingPercentEncoding(withAllowedCharacters: xmlAllowedSet) : nil )
        header.addChild(name: "Copyright", value: _copyright != nil ? String(_copyright!).addingPercentEncoding(withAllowedCharacters: xmlAllowedSet) : nil )
        header.addChild(name: "Publisher", value: _publisher != nil ? String(_publisher!).addingPercentEncoding(withAllowedCharacters: xmlAllowedSet) : nil )
        header.addChild(name: "CoverArt", value: _coverArtURL != nil ? String(_coverArtURL!).addingPercentEncoding(withAllowedCharacters: xmlAllowedSet) : nil )
        header.addChild(name: "OriginalArtworkURL", value: _originalArtworkURL != nil ? String(_originalArtworkURL!).addingPercentEncoding(withAllowedCharacters: xmlAllowedSet) : nil )
        
        header.addChild(name: "MuzVersion", value: _muzVersion != nil ? String(_muzVersion!) : nil )
        header.addChild(name: "MuzAuthor", value: _muzAuthor != nil ? String(_muzAuthor!) : nil )
        header.addChild(name: "MuzAuthorUID", value: _muzAuthorUID != nil ? String(_muzAuthorUID!) : nil )
        
        header.addChild(name: "CreationDate", value: _creationDate != nil ? String(_creationDate!.formatted) : nil )
        header.addChild(name: "LastUpdateDate", value: _lastUpdateDate != nil ? String(_lastUpdateDate!.formatted) : nil )
        
        let docs = body.addChild(name: "Docs")
        
        for (_, doc) in muzDocs.enumerated() {
            let docEle = docs.addChild(name: "Doc")
            _ = doc.serializeSetData(docEle)
        }
        
        //print( "set xml \(muzXMLDoc.xmlString)")
        
        return(muzXMLDoc.xml)
    }
    
    open func deserialize( _ srcURL: URL ) {
        do
        {
            let docContents = try NSString( contentsOf: srcURL, encoding: String.Encoding.utf8.rawValue)
            self.deserialize(docContents as String, srcURL: srcURL)
        }
        catch let error as NSError
        {
            print ( "error \(error.localizedDescription)" )
        }
    }
    
    open func deserialize( _ xmlContent: String, srcURL: URL  )
    {
        //let muzXMLDoc = AEXMLDocument(xmlData:xmlContent)
        diskFolderFilePath = srcURL
        
        //if let data = xmlContent.data(using: String.Encoding.utf8) {
        
        // works only if data is successfully parsed
        // otherwise prints information about error with parsing
        
        
        // prints the same XML structure as original
        // print(xmlDoc.xmlString)
        var xmlParserOptions = AEXMLOptions();
        xmlParserOptions.parserSettings.shouldTrimWhitespace = false;
        let xmlDoc = try? AEXMLDocument(xml: xmlContent, encoding: String.Encoding.utf8, options: xmlParserOptions)
        
        if xmlDoc != nil {
            
            for child in (xmlDoc?.root.children)! {
                print(child.name)
                switch( child.name )
                {
                case "Header":
                    _uid = child["UID"].name != "AEXMLError" ? child["UID"].value == nil ? "" : child["UID"].value! : ""
                    
                    _title = child["Title"].name != "AEXMLError" ? child["Title"].value?.removingPercentEncoding : ""
                    _artist = child["Artist"].name != "AEXMLError" ? child["Artist"].value?.removingPercentEncoding : ""
                    _author = child["Author"].name != "AEXMLError" ? child["Author"].value?.removingPercentEncoding : ""
                    
                    
                    //print( "UID: \(_uid)" )
                    if( _uid != "" )
                    {
                        _copyright = child["Copyright"].name != "AEXMLError" ? child["Copyright"].value?.removingPercentEncoding : ""
                        _publisher = child["Publisher"].name != "AEXMLError" ? child["Publisher"].value?.removingPercentEncoding : ""
                        _coverArtURL = child["CoverArt"].name != "AEXMLError" ? child["CoverArt"].value?.removingPercentEncoding : ""
                        _originalArtworkURL = child["OriginalArtworkURL"].name != "AEXMLError" ? child["OriginalArtworkURL"].value?.removingPercentEncoding : ""
                        
                        _muzVersion = child["MuzVersion"].name != "AEXMLError" ? child["MuzVersion"].value == nil ? "" : child["MuzVersion"].value! : ""
                        _muzAuthor = child["MuzAuthor"].name != "AEXMLError" ? child["MuzAuthor"].value == nil ? "" : child["MuzAuthor"].value! : ""
                        _muzAuthorUID = child["MuzAuthorUID"].name != "AEXMLError" ? child["MuzAuthorUID"].value == nil ? "" : child["MuzAuthorUID"].value! : ""
                        _creationDate = child["CreationDate"].name != "AEXMLError" ? Date( dateString: child["CreationDate"].value! ) : nil
                        _lastUpdateDate = child["LastUpdateDate"].name != "AEXMLError" ? Date( dateString: child["LastUpdateDate"].value! ) : nil
                    }
                    break;
                    
                case "Docs":
                    for docChild in child.children {
                        //print(child.name)
                        switch( docChild.name )
                        {
                        case "Doc":
                            
                            /*let docFolder = docChild["DocFolderName"].name != "AEXMLError" ? docChild["DocFolderName"].value! : ""
                             let docFile = docChild["DocFileName"].name != "AEXMLError" ? docChild["DocFileName"].value! : ""*/
                            let docPhysicalLocation = docChild["DiskFolderFilePath"].name != "AEXMLError" ? docChild["DiskFolderFilePath"].value?.removingPercentEncoding : ""
                            
                            if( docPhysicalLocation != nil && !docPhysicalLocation!.isEmpty )
                            {
                                let docPhysicalLocationURL = _docURL.appendingPathComponent(docPhysicalLocation!)
                                
                                let doc = globalDocumentMapper.getDocFromPhysicalLocation(docPhysicalLocationURL)
                                if( doc != nil && doc!.isValid() )
                                {
                                    self.muzDocs.append(doc!)
                                    //print( "set doc: \(doc!._title)" )
                                }
                                else
                                {
                                    //print( "set member: \(docPhysicalLocationURL.absoluteString) not found")
                                }
                            }
                            else
                            {
                                //print( "docPhysicalLocation not found")
                            }
                            break;
                        default:
                            break;
                        }
                    }
                    
                    
                    break;
                    
                default:
                    //print( "invalid element in xml: " + child.name )
                    break;
                }
            }
            
        }
    }
    
    //var currentDoc:MuzomaDocument! = nil
    
    // sets
    @objc func selectSong(_ notification: Notification) {
        if( notification.object != nil && notification.object is MIKMIDICommand)
        {
            let current = Transport.getCurrentDoc()
            if( current != nil && current!.isPlaying() )
            {
                current!.stop()
                current!.setCurrentTime(0)
            }
            
            var songIdx = 0
            let mikObj = notification.object as! MIKMIDICommand?
            if( mikObj?.commandType == MIKMIDICommandType.systemSongSelect )
            {
                let msg = notification.object as! MIKMIDISystemMessageCommand?
                songIdx = Int(msg!.dataByte1)
                Logger.log("song select \(msg!.debugDescription)")
            }
            else if( mikObj is MIKMIDIChannelVoiceCommand )
            {
                let msg = mikObj as! MIKMIDIChannelVoiceCommand?
                songIdx = Int(msg!.dataByte2)
                Logger.log("song select \(msg!.debugDescription)")
            }
            
            if( self.muzDocs.count > songIdx )
            {
                let muzomaDoc = self.muzDocs[songIdx]
                muzomaDoc._fromSetArtist = (self._artist == nil ? "" : self._artist)!
                muzomaDoc._fromSetTitled = (self._title == nil ? "" : self._title)!
                muzomaDoc._fromSetTrackIdx = self.muzDocs.index(of: muzomaDoc)
                muzomaDoc._fromSetTrackCount = self.muzDocs.count
                muzomaDoc._isBeingPlayedFromSet = true
                self.nc.post(name: Notification.Name(rawValue: "SetSelectedSong"), object: muzomaDoc)
            }
        }
    }
    
    @objc func playerEnded(_ notification: Notification) {
        //print( "Player ended" )
        let playerDoc = notification.object as? MuzomaDocument
        if( playerDoc != nil && playerDoc!._isBeingPlayedFromSet ) // currently playing and playing from a set?
        {
            if( playerDoc?._speed < 0 )
            {
                //seekPrevious( playerDoc )
                // dont need to seek backwards in the set
            }
            else
            {
                _ = seekNext( playerDoc )
            }
        }
    }
    
    
    func seekNext( _ currentlyPlayingDoc:MuzomaDocument!, honourWasPlayingOnly:Bool = false ) -> MuzomaDocument?
    {
        var ret = currentlyPlayingDoc
        let playerDoc = currentlyPlayingDoc
        let wasPlaying = playerDoc?.isPlaying() ?? false
        playerDoc?.stop()
        playerDoc?.setCurrentTime(0)
        
        let currentIdx = self.muzDocs.index( of: playerDoc! )
        if( currentIdx != nil && currentIdx < (self.muzDocs.count - 1)  ) // one of ours?
        {   // next doc
            let muzomaDoc = self.muzDocs[currentIdx!+1]
            muzomaDoc.stop(true)
            muzomaDoc.setCurrentTime(0)
            muzomaDoc._fromSetArtist = (self._artist == nil ? "" : self._artist)!
            muzomaDoc._fromSetTitled = (self._title == nil ? "" : self._title)!
            muzomaDoc._fromSetTrackIdx = self.muzDocs.index(of: muzomaDoc)
            muzomaDoc._fromSetTrackCount = self.muzDocs.count
            muzomaDoc._isBeingPlayedFromSet = true
            
            //if( wasPlaying ?? false || (setAutoPlayNextSong && !honourWasPlayingOnly) )
            if( (wasPlaying && honourWasPlayingOnly) || (wasPlaying && setAutoPlayNextSong))
            {
                muzomaDoc.play()
            }
            else
            {
                muzomaDoc.fillMediaInfo(stopping:true) // update display for remote control
            }
            
            self.nc.post(name: Notification.Name(rawValue: "SetSelectNextSong"), object: muzomaDoc)
            ret = muzomaDoc
        }
        else if( currentIdx == (self.muzDocs.count - 1) && _loopSet == true && self.muzDocs.count > 0 )
        {
            // fisrt doc
            let muzomaDoc = self.muzDocs[0]
            muzomaDoc.stop(true)
            muzomaDoc.setCurrentTime(0)
            muzomaDoc._fromSetArtist = (self._artist == nil ? "" : self._artist)!
            muzomaDoc._fromSetTitled = (self._title == nil ? "" : self._title)!
            muzomaDoc._fromSetTrackIdx = self.muzDocs.index(of: muzomaDoc)
            muzomaDoc._fromSetTrackCount = self.muzDocs.count
            muzomaDoc._isBeingPlayedFromSet = true
            if( (wasPlaying && honourWasPlayingOnly) || (wasPlaying && setAutoPlayNextSong))
            {
                muzomaDoc.play()
            }
            else
            {
                muzomaDoc.fillMediaInfo(stopping:true) // update display for remote control
            }
            
            self.nc.post(name: Notification.Name(rawValue: "SetSelectNextSong"), object: muzomaDoc)
            ret = muzomaDoc
        }
        else // end of set
        {
            //print( "Set ended" )
            self.nc.post(name: Notification.Name(rawValue: "SetEnded"), object: self)
        }
        
        return( ret )
    }
    
    func seekPrevious( _ currentlyPlayingDoc:MuzomaDocument!, honourWasPlayingOnly:Bool = false ) -> MuzomaDocument?
    {
        var ret = currentlyPlayingDoc
        let playerDoc = currentlyPlayingDoc
        let wasPlaying = playerDoc?.isPlaying() ?? false
        playerDoc?.stop()
        playerDoc?.setCurrentTime(0)
        
        let currentIdx = self.muzDocs.index( of: playerDoc! )
        if( currentIdx != nil && currentIdx > 0   )
        {   // next doc
            let muzomaDoc = self.muzDocs[currentIdx!-1]
            muzomaDoc.stop(true)
            muzomaDoc.setCurrentTime(0)
            muzomaDoc._fromSetArtist = (self._artist == nil ? "" : self._artist)!
            muzomaDoc._fromSetTitled = (self._title == nil ? "" : self._title)!
            muzomaDoc._fromSetTrackIdx = self.muzDocs.index(of: muzomaDoc)
            muzomaDoc._fromSetTrackCount = self.muzDocs.count
            muzomaDoc._isBeingPlayedFromSet = true
            
            //if( wasPlaying ?? false || (setAutoPlayNextSong && !honourWasPlayingOnly) )
            if( (wasPlaying && honourWasPlayingOnly) || (wasPlaying && setAutoPlayNextSong))
            {
                muzomaDoc.play()
            }
            else
            {
                muzomaDoc.fillMediaInfo(stopping:true) // update display for remote control
            }
            self.nc.post(name: Notification.Name(rawValue: "SetSelectPreviousSong"), object: muzomaDoc)
            ret = muzomaDoc
        }
        else // end of set
        {
            //print( "Set ended" )
            self.nc.post(name: Notification.Name(rawValue: "SetEnded"), object: self)
        }
        
        //self.currentDoc = ret
        return( ret )
    }
}

