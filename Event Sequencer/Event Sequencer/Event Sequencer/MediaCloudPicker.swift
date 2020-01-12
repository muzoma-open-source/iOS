//
//  MediaCloudPicker.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 07/07/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//
//  Handle interaction with cloud docs
//

import UIKit
import Foundation
import CoreFoundation
import MediaPlayer
import AVFoundation
import MobileCoreServices


class UICloudAudioPickerViewConroller : UIDocumentPickerViewController,  UIDocumentPickerDelegate
{
    var muzomaDoc : MuzomaDocument! = nil
    
    init( muzomaDoc : MuzomaDocument! )
    {
        self.muzomaDoc = muzomaDoc
        super.init(documentTypes: [kUTTypeMP3 as String, kUTTypeMPEG4Audio as String, kUTTypeWaveformAudio as String, kUTTypeAudio as String, kUTTypeAudioInterchangeFileFormat as String], in: UIDocumentPickerMode.import)
    }
    
    override init(documentTypes allowedUTIs: [String], in mode: UIDocumentPickerMode)
    {
        super.init(documentTypes: allowedUTIs, in: mode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func displayAudioFilePicker()
    {
        self.delegate = self
        self.title = "Select Audio File"
        self.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        let vc = UIApplication.shared.keyWindow!.rootViewController
        vc?.present(self, animated: true, completion: nil)
    }
    
    // called if the user dismisses the document picker without selecting a document (using the Cancel button)
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController)
    {
        //print( "documentPickerWasCancelled  called" )
    }
    
    let fileManager = FileManager.default
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        
        if controller.documentPickerMode == UIDocumentPickerMode.import {
            if( fileManager.fileExists(url) && url.isFileURL && muzomaDoc != nil )
            {
                do
                {
                    _ = muzomaDoc?.ensureDocumentURLExists()
                    
                    if(muzomaDoc!.isPlaying())
                    {
                        muzomaDoc!.stop()
                    }
                    
                    //print( "source url \(url)" )
                    
                    // move to package folder
                    let fileName = url.lastPathComponent
                    //print( "file name \(fileName)" )
                    
                    let destURL = self.muzomaDoc?.getDocumentFolderPathURL()!.appendingPathComponent(fileName)
                    //print( "destURL \(destURL)" )
                    
                    let originalTrack = muzomaDoc?.getTrackDataAsURL((muzomaDoc?.getGuideTrackIndex())!, eventIdx: 0 )
                    // remove the old file
                    do
                    {
                        if( originalTrack != nil && fileManager.fileExists(originalTrack!) )
                        {
                            try  fileManager.removeItem(at: originalTrack!)
                            Logger.log("\(#function)  \(#file) Deleted \(originalTrack!.absoluteString)")
                        }
                    }
                    catch
                        let error as NSError {
                            print( error.localizedDescription)
                    }
                    
                    // remove the new if it already exists before copying
                    do
                    {
                        if( destURL != nil && fileManager.fileExists(destURL!) )
                        {
                            try fileManager.removeItem(at: destURL!)
                            Logger.log("\(#function)  \(#file) Deleted \(destURL!.absoluteString)")
                        }
                    }
                    catch let error as NSError {
                        Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                    }
                    
                    // move to the new one
                    try fileManager.moveItem(at: url, to: destURL! )
                    
                    if( controller.title == "Select Audio File" )
                    {
                        muzomaDoc?.setDataForTrackEvent((muzomaDoc?.getGuideTrackIndex())!, eventIdx: 0, url: destURL!)
                        let specifics = muzomaDoc?.getGuideTrackSpecifics() as AudioEventSpecifics?
                        specifics?.favouriDevicePlayback = true
                        specifics?.favourMultiChanPlayback = false
                        specifics?.volume = 1.0
                        specifics?.pan = -1.0
                        specifics?.ignoreDownmixiDevice = true
                        specifics?.ignoreDownmixMultiChan = false
                        specifics?.downmixToMono = true
                        
                    }
                } catch let error as NSError {
                    Logger.log("\(#function)  \(#file)  \(error.localizedDescription)")
                    
                    let alert = UIAlertController(title: "Error", message: "File could not be copied", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                        print("Error copying file")
                        
                    }))
                    
                    let vc = UIApplication.shared.keyWindow!.rootViewController
                    vc!.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
}

