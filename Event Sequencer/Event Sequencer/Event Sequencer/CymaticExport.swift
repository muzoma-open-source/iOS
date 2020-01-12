//
//  CymaticExport.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 05/09/2018.
//  Copyright © 2018 Muzoma.com. All rights reserved.
//
//  Support for Cymatic's LP16 live player
//  Allows the export of Muzoma songs and sets to be used standalone on the LP16 device
//

import Foundation
import AEXML

class CymaticExport
{
    var _setDocument:MuzomaSetDocument! = nil
    
    init( setDocument:MuzomaSetDocument! )
    {
        _setDocument = setDocument
    }
    
    // main function, produce xml in the Cymatic format
    func exportLP16Audio( withGuideAudio:Bool )
    {
        _gNC.post(name: Notification.Name(rawValue: "ConvertingAudio"), object: "Exporting set to Cymatic folder...")
        
        var cymaticLP16Folder = _gFSH.getDocumentFolderURL()
        cymaticLP16Folder?.appendPathComponent("Cymatic/Recording")
        _ = _gFSH.ensureFolderExists(cymaticLP16Folder)
        
        var cymaticLP16PlaylistsFolder = _gFSH.getDocumentFolderURL()
        cymaticLP16PlaylistsFolder?.appendPathComponent("Cymatic/Recording/#PLAYLISTS")
        _ = _gFSH.ensureFolderExists(cymaticLP16PlaylistsFolder)
        
        
        var songIdx = 0;
        DispatchQueue.global(qos: .utility).async(execute: {
            // keep track of the playlist for xml output
            let playlistDoc = AEXMLDocument()
            //let playlistDocAttributes  = ["xmlns:xsi" : "http://www.w3.org/2001/XMLSchema-instance", "xmlns:xsd" : "http://www.w3.org/2001/XMLSchema"]
            let body = playlistDoc.addChild(name: "playlist")
            
            /*let version =         */body.addChild(name: "version", value: "1.0")
            /*let timestamp =       */body.addChild(name: "timestamp", value: "1536335854123")
            /*let creator =         */body.addChild(name: "creator", value: "Muzoma App")
            /*let playlistname =    */body.addChild(name: "playlistname", value: self._setDocument._title)
            /*let targetDevice =    */body.addChild(name: "target_device", value: "LP-16")
            
            self._setDocument.muzDocs.forEach { (doc) in
                songIdx += 1
                let setTrackName = "\(String.init(format: "%02d", songIdx)) \(doc._title!) (\(doc._artist!))"
                _gNC.post(name: Notification.Name(rawValue: "ConvertingAudio"), object: "Exporting  \(setTrackName)")
                let docFolder = cymaticLP16Folder?.appendingPathComponent( setTrackName, isDirectory: true )
                _ = _gFSH.ensureFolderExists(docFolder)
                
                let lstURLS = doc.copyTrackAudioToWavs(withGuideAudio: withGuideAudio)
                
                let duration = AudioUtils().getDurationInSeconds(audio: lstURLS as! [URL])
                let songXML = body.addChild(name: "song")
                songXML.addChild(name: "name", value: setTrackName)
                songXML.addChild(name: "location", value: "")
                songXML.addChild(name: "duration", value: "\(String.init(format: "%.003f", duration))")
                let pauseMode = songXML.addChild(name: "pause_mode", value: "")
                pauseMode.addChild(name: "mode", value: "wait_for_button_press")
                pauseMode.addChild(name: "time", value: "0")
                
                
                // keep track of the playlist for xml output
                let songDoc = AEXMLDocument()
                //let playlistDocAttributes  = ["xmlns:xsi" : "http://www.w3.org/2001/XMLSchema-instance", "xmlns:xsd" : "http://www.w3.org/2001/XMLSchema"]
                let songBody = songDoc.addChild(name: "song_settings")
                songBody.addChild(name: "version", value: "2.0")
                songBody.addChild(name: "timestamp", value: "1536329723352")
                songBody.addChild(name: "creator", value: "Muzoma App" )
                songBody.addChild(name: "target_device", value: "LP-16" )
                songBody.addChild(name: "song_name", value: setTrackName )
                songBody.addChild(name: "validationcode", value: "cf1f00a02ff8bb24e9bf539f7c69ec1c" )
                songBody.addChild(name: "playback_type", value: "multitrack" )
                songBody.addChild(name: "channel_count", value: String(lstURLS.count) )
                songBody.addChild(name: "sampling_rate", value: "44100" )
                songBody.addChild(name: "resolution", value: "16" )
                let outputLevels = songBody.addChild(name: "output_level")
                let monitorPans = songBody.addChild(name: "monitor_pan" )
                let channelMutes = songBody.addChild(name: "channel_mute" )
                let guideIdx = doc.getGuideTrackIndex()
                
                for moveURL in lstURLS
                {
                    let fileNameChan = moveURL!.deletingPathExtension().lastPathComponent
                    //let fileNameChanNumber = fileNameChan.substring(from: fileNameChan.index(fileNameChan.endIndex, offsetBy: -2))
                    let fileNameChanNumber = fileNameChan[fileNameChan.index(fileNameChan.endIndex, offsetBy: -2)...]
                    //let mono = fileNameChan.substring(from: fileNameChan.index(fileNameChan.endIndex, offsetBy: -4)).first == "M"
                    let mono = fileNameChan[fileNameChan.index(fileNameChan.endIndex, offsetBy: -4)...].first == "M"
                    let merge = fileNameChan.starts(with: "Merge")
                    //let left = fileNameChan.substring(from: fileNameChan.index(fileNameChan.endIndex, offsetBy: -4)).first == "L"
                    let left = fileNameChan[fileNameChan.index(fileNameChan.endIndex, offsetBy: -4)...].first == "L"
                    //let right = fileNameChan.substring(from: fileNameChan.index(fileNameChan.endIndex, offsetBy: -4)).first == "R"
                    let right = fileNameChan[fileNameChan.index(fileNameChan.endIndex, offsetBy: -4)...].first == "R"
                    let chanNumber = String(Int(fileNameChanNumber)!)
                    
                    let idxs = doc.getAudioTrackIndexes()
                    var setChan = false
                    for idx in idxs
                    {
                        if( !withGuideAudio && guideIdx==idx ) // don't match guide
                        {
                            // could alert here
                        }
                        else
                        {
                            let specifics = doc.getAudioTrackSpecifics(idx)
                            if( specifics?.chan == Int(fileNameChanNumber) )
                            {
                                var logVol = specifics!.volume == 1.0 ? 1.0 : log2((specifics!.volume * 100)+1) // convert the volume scale
                                if( logVol != 1.0 )
                                {
                                    logVol = ((6.643 - logVol) * -10)
                                }
                                outputLevels.addChild(name: "chan", value: (String.init(format: "%.003f", logVol)), attributes: ["id":chanNumber] )
                                
                                let ignorePan = specifics!.ignoreDownmixiDevice
                                if( merge )
                                {
                                    monitorPans.addChild(name: "chan", value: "0", attributes: ["id":chanNumber]  )
                                }
                                else if( right )
                                {
                                    monitorPans.addChild(name: "chan", value: "127", attributes: ["id":chanNumber]  )
                                }
                                else if( left )
                                {
                                    monitorPans.addChild(name: "chan", value: "-127", attributes: ["id":chanNumber]  )
                                }
                                else if( !ignorePan && mono ) // pans enabled in mixer so mirror this
                                {
                                    monitorPans.addChild(name: "chan", value: (String.init(format: "%1.0f", (specifics!.pan * 127))), attributes: ["id":chanNumber]  )
                                }
                                else
                                {
                                    monitorPans.addChild(name: "chan", value: "0", attributes: ["id":chanNumber]  )
                                }
                                
                                setChan = true
                                break;
                            }
                        }
                    }
                    
                    if( !setChan ) // must be a stereo track
                    {
                        for idx in idxs
                        {
                            if( !withGuideAudio && guideIdx==idx ) // don't match guide
                            {
                                
                            }
                            else
                            {
                                let specifics = doc.getAudioTrackSpecifics(idx)
                                if( specifics!.chan+1 == Int(fileNameChanNumber) )
                                {
                                    var logVol = specifics!.volume == 1.0 ? 1.0 : log2((specifics!.volume * 100)+1) // convert the volume scale
                                    if( logVol != 1.0 )
                                    {
                                        logVol = ((6.643 - logVol) * -10)
                                    }
                                    outputLevels.addChild(name: "chan", value: (String.init(format: "%.003f", logVol)), attributes: ["id":chanNumber] )
                                    if( merge )
                                    {
                                        monitorPans.addChild(name: "chan", value: "0", attributes: ["id":chanNumber]  )
                                    }
                                    else if( right )
                                    {
                                        monitorPans.addChild(name: "chan", value: "127", attributes: ["id":chanNumber]  )
                                    }
                                    else if( left )
                                    {
                                        monitorPans.addChild(name: "chan", value: "-127", attributes: ["id":chanNumber]  )
                                    }
                                    else
                                    {
                                        monitorPans.addChild(name: "chan", value: "127" , attributes: ["id":chanNumber]  ) // must be right hand of pair
                                    }
                                    setChan = true
                                    break;
                                }
                            }
                        }
                    }
                    
                    if( !setChan )
                    {
                        outputLevels.addChild(name: "chan", value: "-64.4", attributes: ["id":chanNumber] )
                        monitorPans.addChild(name: "chan", value: "0", attributes: ["id":chanNumber]  )
                    }
                    channelMutes.addChild(name: "chan", value: "0", attributes: ["id":chanNumber]  )
                    
                    try? _gFSH.moveItem(at: moveURL!, to: docFolder!.appendingPathComponent(moveURL!.lastPathComponent))
                }
                
                // write our song out
                do{
                    let outFile = docFolder!.appendingPathComponent("song.set")
                    try songDoc.xml.write(to: outFile, atomically: true, encoding: String.Encoding.utf8)
                } catch let error as NSError {
                    Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                }
            }
            
            // write our playlist out
            do{
                let outFile = cymaticLP16PlaylistsFolder!.appendingPathComponent(self._setDocument._title! + ".play")
                try playlistDoc.xml.write(to: outFile, atomically: true, encoding: String.Encoding.utf8)
            } catch let error as NSError {
                Logger.log("\(#function) \(#file) \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async(execute: {
                let keyWind = UIApplication.shared.keyWindow!
                let callingVC = keyWind.visibleViewController
                
                let alertProcessing = UIAlertController(title: "Export Complete", message: "The export to LP16 completed\nCopy the files from the Cymatic folder in the Files app and then delete them.", preferredStyle: UIAlertController.Style.alert)
                
                alertProcessing.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
                    //print("overwrite file No")
                }))
                
                alertProcessing.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                callingVC?.queuePopup(alertProcessing, animated: true, completion: nil)
            })
        })
    }
    
    // helper to create the structure
    func createCymaticFolderStructure()
    {
        if( _setDocument != nil )
        {
            DispatchQueue.main.async(execute: {
                let keyWind = UIApplication.shared.keyWindow!
                let callingVC = keyWind.visibleViewController
                
                let alertProcessing = UIAlertController(title: "Export to Cymatic", message: "This task will run through the set converting audio to .wav files and place them in the Cymatic folder.  It will take some time and you will be notified when it has finished.  Please remember not to alter the songs or sets in the export while this process runs!", preferredStyle: UIAlertController.Style.alert)
                
                alertProcessing.addAction(UIAlertAction(title: "Include Guide Audio", style: .default, handler: { (action: UIAlertAction!) in
                    self.exportLP16Audio( withGuideAudio: true )
                }))
                
                alertProcessing.addAction(UIAlertAction(title: "No Guide Audio", style: .default, handler: { (action: UIAlertAction!) in
                    self.exportLP16Audio( withGuideAudio: false )
                }))
                
                alertProcessing.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                    
                }))
                
                alertProcessing.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                callingVC?.queuePopup(alertProcessing, animated: true, completion: nil)
            })
            
        }
    }
}
