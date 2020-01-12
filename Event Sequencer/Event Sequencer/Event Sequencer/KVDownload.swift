//
//  KVDownload.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 17/01/2017.
//  Copyright © 2017 Muzoma.com. All rights reserved.
//
//
// Bridge between muzoma document and karaoke version downloads


import Foundation


class KVTrack : NSObject
{
    var _trackIdx = -1
    var _trackName:String
    var _trackMixerSourceURL:URL
    var _trackAudioSourceURL:URL! = nil
    var _localTrackFileURL:URL! = nil
    var _kvDownloader:KVDownloadURL! = nil
    
    init( trackName:String, trackMixerSourceURL:URL, trackIndex:Int )
    {
        _trackName = trackName
        _trackMixerSourceURL = trackMixerSourceURL
        _trackIdx = trackIndex
    }
    
    func download( _ destFolder:URL, destFileName:String )
    {
        if( _trackAudioSourceURL != nil )
        {
            //print("downloading \(_trackName)")
            _kvDownloader = KVDownloadURL( yourOwnObject: self, destFolder:destFolder, destFileName:(destFileName.replacingOccurrences(of: "/", with: " ").stringByRemovingCharactersInSet(acceptableProperSet.inverted)) )
            _kvDownloader.download( _trackAudioSourceURL! )
        }
    }
    
    func cancel()
    {
        _kvDownloader?.cancel()
    }
}

class KVDownload
{
    var _doc:MuzomaDocument! = nil
    var _fs:FileSystemHelper! = _gFSH
    internal var KVTracks = [KVTrack]()
    var _nextReqIdx = -1
    var _prodId = -1
    var _songId = -1
    var _downloadRequestURI:String = ""
    var _artist:String
    var _songTitle:String
    var _songTempo:String
    var _songKey:String
 
    //private let baseURL = NSURL(string: "http://www.karaoke-version.com/?aff=701")
    //let reg = UserRegistration()
    
    init( prodId:Int, songId:Int, downloadRequestURI:String, artist:String, songTitle:String, songTempo:String, songKey:String )
    {
        _prodId = prodId
        _songId = songId
        _downloadRequestURI = downloadRequestURI
        _artist = artist
        
        _songTitle = songTitle
        _songTempo = songTempo
        _songKey = songKey
        KVTracks = [KVTrack]()
        
        // muz doc
        _doc = MuzomaDocument()
        _doc.loadEmptyDefaultSong()
        _doc._artist = _artist
        _doc._title = _songTitle
        _doc._author = _artist // make the same as the artist for now
        _doc._publisher = "Karaoke-Version.com"
        _doc._copyright = "(c) Karaoke-Version.com"
        _doc._tempo = songTempo
        _doc._key = songKey
        
        _ = _fs?.saveMuzomaDocLocally(_doc, warnOnOverwrite: true)
    }
    
    func setSongArtURL( _ songArtURLString:String )
    {
        _doc._originalArtworkURL = songArtURLString
        _doc.updateArtworkFromOriginalURL()
        _ = _fs?.saveMuzomaDocLocally(_doc, warnOnOverwrite: false)
    }
    
    func addTrackDef(_ trackName:String, trackMixerSourceURL:URL )
    {
        let track = KVTrack(trackName: trackName, trackMixerSourceURL: trackMixerSourceURL, trackIndex: KVTracks.count )
        KVTracks.append(track)
    }
    
    func setCurrentTrackAudioFileAddressURL( _ trackAudioSourceURL:URL )
    {
        let track:KVTrack! = _nextReqIdx > -1 ? KVTracks[_nextReqIdx] : nil
        if( track != nil )
        {
            track._trackAudioSourceURL = trackAudioSourceURL
            var docTrackIdx = -1
            if( _nextReqIdx == 0 )
            {
                docTrackIdx = _doc.getGuideTrackIndex()
                _doc.setOriginalURLForGuideTrack(trackAudioSourceURL)
                let specifics = _doc.getGuideTrackSpecifics() as AudioEventSpecifics?

                specifics?.chan = 1
                specifics?.inputChan = 1
                specifics?.favouriDevicePlayback = true
                specifics?.favourMultiChanPlayback = false
                specifics?.volume = 1.0
                specifics?.pan = -1.0
                specifics?.ignoreDownmixiDevice = true
                specifics?.ignoreDownmixMultiChan = false
                specifics?.downmixToMono = true
                //_doc.setDataForTrackEvent( _doc.getGuideTrackIndex(), eventIdx: 0, url: destURL )
            }
            else
            {
                if( track._trackName.lowercased().contains("click") )
                {
                    docTrackIdx = _doc.addNewTrack(track._trackName, trackType: TrackType.Audio, trackPurpose: TrackPurpose.ClickTrackAudio, eventspecifcs: nil)
                }
                else
                {
                    docTrackIdx = _doc.addNewTrack(track._trackName, trackType: TrackType.Audio, trackPurpose: TrackPurpose.BackingTrackAudio, eventspecifcs: nil)
                }
                
                let specifics = _doc?.getAudioTrackSpecifics( docTrackIdx )
                specifics?.chan = _nextReqIdx - 1
                specifics?.inputChan = _nextReqIdx - 1
                specifics?.favouriDevicePlayback = false
                specifics?.favourMultiChanPlayback = true
                specifics?.volume = 0.90
                specifics?.pan = -1.0
                specifics?.ignoreDownmixiDevice = true
                specifics?.ignoreDownmixMultiChan = false
                specifics?.downmixToMono = true
                
                //_doc.setDataForTrackEvent(<#T##trackIdx: Int##Int#>, eventIdx: <#T##Int#>, url: <#T##NSURL#>)
            }
            
            let fileName = "\(String(format: "%02d", _nextReqIdx )) \(track._trackName ).mp3".replacingOccurrences(of: "/", with: " ").stringByRemovingCharactersInSet(acceptableProperSet.inverted)
            _doc?.setDataForTrackEvent( docTrackIdx, eventIdx:0, data: fileName)
            track.download( _doc.getDocumentFolderPathURL()!, destFileName: fileName )
            _ = _fs.saveMuzomaDocLocally(_doc, warnOnOverwrite: false)
        }
    }
    
    fileprivate let nc = NotificationCenter.default
    
    func finalizeAudioTracks()
    {
        let fs = _gFSH

        // test audio pad function
        let audioUtils:AudioUtils = AudioUtils()
        var btIdxs = _doc?.getBackingTrackIndexes()
        let guideTrackIdx = _doc?.getGuideTrackIndex()
        btIdxs?.append(guideTrackIdx!)
        
        var guideURL = _doc?.getGuideTrackURL()
        var audioURLs = _doc?.getBackingTrackURLs()
        audioURLs?.append(guideURL)
        
        // convert all to .M4A if not already
        var btIdx = 0
        for url in audioURLs!
        {
            if( url?.pathExtension != "m4a" )
            {
                nc.post(name: Notification.Name(rawValue: "ConvertingAudio"), object: "Converting audio \(btIdx+1) of \(audioURLs!.count)")
                nc.post(name: Notification.Name(rawValue: "ConvertingAudioPct"), object: Float( Float(btIdx+1) / Float(audioURLs!.count) ) )
                Logger.log( "Converting \(String(describing: url?.debugDescription)) to m4a" )
                let newURL = audioUtils.toM4a(url!, synchronous: true)
                Logger.log( "New file created: \(String(describing: newURL?.debugDescription)) " )
                if( newURL != nil )
                {
                    //self.muzomaDoc?._tracks[btIdxs![btIdx]]._events[0]._data
                    _doc?._tracks[btIdxs![btIdx]]._events[0]._data = newURL!.lastPathComponent
                    _ = fs.saveMuzomaDocLocally(_doc) // save as we go
                }
            }
            btIdx += 1
        }
        
        // get the new urls
        guideURL = _doc?.getGuideTrackURL()
        audioURLs = _doc?.getBackingTrackURLs()
        btIdx = 0
        for audioUrl in audioURLs!
        {
            nc.post(name: Notification.Name(rawValue: "PaddingAudio"), object: "Padding audio \(btIdx+1) of \(audioURLs!.count)")
            nc.post(name: Notification.Name(rawValue: "PaddingAudioPct"), object: Float( Float(btIdx+1) / Float(audioURLs!.count) ) )
            Logger.log( "Padding file: \(String(describing: audioUrl?.debugDescription))" )
            let newURL = audioUtils.pad( guideURL!, audio2In: audioUrl!, synchronous: true )
            if( newURL != nil )
            {
                if( audioUrl!.absoluteString != newURL?.absoluteString ) // new one different, delete old one
                {
                    do
                    {
                        try fs.removeItem(at: audioUrl!)
                        Logger.log("\(#function)  \(#file) Deleted \(audioUrl!.absoluteString)")
                    } catch let error as NSError {
                        Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                    }
                }
                
                //self.muzomaDoc?._tracks[btIdxs![btIdx]]._events[0]._data
                _doc?._tracks[btIdxs![btIdx]]._events[0]._data = newURL!.lastPathComponent
                _ = fs.saveMuzomaDocLocally(_doc) // save as we go
            }
            btIdx += 1
        }
        
        nc.post(name: Notification.Name(rawValue: "FinalizeAudioComplete"), object: "Finalize audio complete")
    }

    
    func getNextRequestURL() -> URL!
    {
        _nextReqIdx += 1
        var ret:URL! = nil
        
        if( _nextReqIdx < KVTracks.count )
        {
            ret = KVTracks[_nextReqIdx]._trackMixerSourceURL
        }
        
        return( ret )
    }

    func downloadTracks()
    {
        var idx = 0
        for track in KVTracks
        {
            if( idx == 0 )
            {
                let fileName = "\(String(format: "%02x", _nextReqIdx )) \(track._trackName).mp3".replacingOccurrences(of: "/", with: " ").stringByRemovingCharactersInSet(acceptableProperSet.inverted)
                track.download(_doc.getDocumentFolderPathURL()!, destFileName: fileName)
            }
            idx += 1
        }
    }
    
    func cancel()
    {
        NotificationCenter.default.post(name: Notification.Name(rawValue: "CancelDownload"), object: self)
        for track in KVTracks
        {
            track.cancel()
        }
        resetRequestIndex()
    }
    
    func resetRequestIndex()
    {
        _nextReqIdx = -1
    }
    
    
    func isDownloading() -> Bool
    {
       return( _nextReqIdx > -1 )
    }
}
