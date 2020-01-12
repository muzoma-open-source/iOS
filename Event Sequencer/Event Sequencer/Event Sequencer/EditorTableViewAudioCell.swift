//
//  EditorTableViewAudioCell.swift
//  Event Sequencer
//
//  Created by Matthew Hopkins on 11/12/2015.
//  Copyright © 2015 Muzoma.com. All rights reserved.
//
//  Allows the user to set up the timing and display of a song as it plays

import UIKit
import AVFoundation
import MobileCoreServices

class EditorTableViewAudioCell : UITableViewCell, UIDocumentPickerDelegate
{
    var mediaItemURL: URL?
    var _parentVC:EditorLinesController?
    var _track:Int?
    var _eventIdx:Int?
    var _audioEventSpecifics:AudioEventSpecifics?
    
    @IBOutlet weak var labChan: UILabel!
    
    @IBOutlet weak var butSetAudioTrack: UIButton!
    
    @IBAction func setAudioTrackClicked(_ sender: AnyObject) {
        displayFilePicker()
    }
    
    @IBOutlet weak var sliderVol: UISlider!
    @IBAction func volSlider(_ sender: AnyObject) {
        
        if( self._parentVC?.muzomaDoc?._tracks[_track!] != nil )
        {
            self._parentVC?.muzomaDoc?.setTrackVolume(_track!,volume: sliderVol.value)
        }
    }
    
    @IBOutlet weak var labTrackName: UILabel!
    
    @IBOutlet weak var labTrackFileName: UILabel!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    // shows a file picker ...
    
    func displayFilePicker()
    {
        let documentPicker: UIDocumentPickerViewController = UIDocumentPickerViewController(documentTypes: [kUTTypeMP3 as String, kUTTypeMPEG4Audio as String, kUTTypeWaveformAudio as String, kUTTypeAudio as String, kUTTypeAudioInterchangeFileFormat as String/* kUTTypeMIDIAudio as String, kUTTypeAudio as String*/ ], in: UIDocumentPickerMode.import)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        _parentVC!.present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        if controller.documentPickerMode == UIDocumentPickerMode.import {
            // This is what it should be
            //self.newNoteBody.text = String(contentsOfFile: url.path!)
           
            if( url.isFileURL )
            {
                let fileManager = FileManager.default
                do
                {
                    // move to package folder
                    let fileName = url.pathComponents[(url.pathComponents.count)-1]
                    //print( "file name \(fileName)" )
                    
                    let destURL = self._parentVC?.muzomaDoc?.getDocumentFolderPathURL()!.appendingPathComponent(fileName)
                    //print( "destURL \(destURL)" )
                    
                    // remove the old file
                    do
                    {
                        try fileManager.removeItem(at: destURL!)
                        Logger.log("\(#function)  \(#file) Deleted \(destURL!.absoluteString)")
                    }
                    catch let error as NSError {
                        Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                    }

                    // copy the new one
                    try fileManager.copyItem( at: url, to: destURL!)
                    
                    // update screen and doc
                    self.mediaItemURL = destURL
                    self.labTrackFileName.text = fileName
                    self._parentVC?.muzomaDoc?.setDataForTrackEvent(_track!, eventIdx: _eventIdx!, url: destURL!)
                }
                catch let error as NSError {
                    Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                    let alert = UIAlertController(title: "Error", message: "File could not be copied", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                        print("Error copying file")

                    }))

                    _parentVC!.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
}
