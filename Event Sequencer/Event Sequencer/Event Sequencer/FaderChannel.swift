//
//  FaderChannel.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 08/02/2017.
//  Copyright © 2017 Muzoma.com. All rights reserved.
//
//  Fader or Slider channel view - used per channel in the mixer view
//  As iOS has no native vertical slider, we pull a trick of rotating the view 90 deg to create a vertical slider from a horizonal one!
//  We add observers so that we can receive audio level information for our VU meters
//  We handle double tap so that we can action features fader by fader

import UIKit
import AVFoundation
import MobileCoreServices
import MIKMIDI

class FaderChannel : UIView, UIDocumentPickerDelegate {
    let nc = _gNC
    let _appDelegate = UIApplication.shared.delegate as! AppDelegate
    var _doc:MuzomaDocument! = nil
    var _track:MuzTrack! = nil
    var _trackNumber:Int = -1
    var _specifics:AudioEventSpecifics! = nil
    var _layoutIdx:Int = 0
    var _audioShareTrackImport = false
    var _alert:UIAlertController! = nil
    var _alertAS:UIAlertController! = nil

    // slider container
    @IBOutlet weak var slideHeight: NSLayoutConstraint!
    
    // actual slider
    @IBOutlet weak var sliderHeight: NSLayoutConstraint!
    @IBOutlet weak var sliderWidth: NSLayoutConstraint!
    
    @IBOutlet weak var butTop: UIButton!
    @IBOutlet weak var butBottom: UIButton!
    @IBOutlet weak var labTop: UILabel!
    
    static let tform:CGFloat = (.pi / 2) * -1 // transform 90 degrees
    
    @IBOutlet weak var sliderVolume: UISlider!
        {
        didSet{
            sliderVolume.transform = CGAffineTransform(rotationAngle: FaderChannel.tform)
        }
    }
    
    @IBOutlet weak var inputMeterL: UIProgressView!
        {
        didSet{
            inputMeterL.transform = CGAffineTransform(rotationAngle: FaderChannel.tform )
        }
    }
    
    @IBOutlet weak var inputMeterLWidth: NSLayoutConstraint!
    
    
    @IBOutlet weak var inputMeterR: UIProgressView!
        {
        didSet{
            inputMeterR.transform = CGAffineTransform(rotationAngle: FaderChannel.tform )
        }
    }
    @IBOutlet weak var inputMeterRWidth: NSLayoutConstraint!
    
    @IBOutlet weak var outputMeterL: UIProgressView!
        {
        didSet{
            outputMeterL.transform = CGAffineTransform(rotationAngle: FaderChannel.tform )
        }
    }
    @IBOutlet weak var outputMeterLWidth: NSLayoutConstraint!
    
    @IBOutlet weak var outputMeterR: UIProgressView!
        {
        didSet{
            outputMeterR.transform = CGAffineTransform(rotationAngle: FaderChannel.tform )
        }
    }
    
    @IBOutlet weak var outputMeterRWidth: NSLayoutConstraint!
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    override init(frame rect: CGRect) {
        super.init(frame: rect)
        initialize()
    }
    
    
    func initialize()
    {
        nc.addObserver(self, selector: #selector(FaderChannel.inputTrackLevelUpdate(_:)), name: NSNotification.Name(rawValue: "InputTrackLevel"), object: nil)
        nc.addObserver(self, selector: #selector(FaderChannel.outputTrackLevelUpdate(_:)), name: NSNotification.Name(rawValue: "OutputTrackLevel"), object: nil)
        nc.addObserver(self, selector: #selector(FaderChannel.stopUpdate(_:)), name: NSNotification.Name(rawValue: "TransportStop"), object: nil)
        nc.addObserver(self, selector: #selector(FaderChannel.audioSharePaste(_:)), name: NSNotification.Name(rawValue: "AudioSharePaste"), object: nil)
        nc.addObserver(self, selector: #selector(FaderChannel._midiMappingLearned(_:)), name: NSNotification.Name(rawValue: "MidiMappingLearned"), object: nil)
        nc.addObserver(self, selector: #selector(FaderChannel._faderControlSent(_:)), name: NSNotification.Name(rawValue: "FaderControlSent"), object: nil)
    }
    
    deinit
    {
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "InputTrackLevel"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "OutputTrackLevel"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "TransportStop"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "AudioSharePaste"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "MidiMappingLearned"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "FaderControlSent"), object: nil )
    }
    
    @IBAction func topButtonClicked(_ sender: AnyObject)
    {
        // record arm enable
        let specifics = _doc?.getAudioTrackSpecifics(_trackNumber)
        if( specifics != nil )
        {
            specifics!.recordArmed = !specifics!.recordArmed
            
            var specifics = [AudioEventSpecifics?]()
            specifics.append( _doc.getGuideTrackSpecifics() )
            specifics.append( contentsOf: _doc.getBackingTrackSpecifics() )
            nc.post(name: Notification.Name(rawValue: "AudioSpecificsChanged"), object: specifics)
            setUIFromSpecifics()
        }
    }
    
    @IBAction func volChanged(_ sender: AnyObject)
    {
        // update the volume
        _doc?.setTrackVolume(_trackNumber, volume: sliderVolume.value)
    }
    
    @objc func _faderControlSent(_ notification: Notification)
    {
        if( notification.object is MidiValueObject?)
        {
            let faderValue:MidiValueObject! = notification.object as! MidiValueObject?
            
            if( faderValue.commandIdx == self._layoutIdx )
            {
                DispatchQueue.main.async(execute: {
                    self.sliderVolume.value = Float( faderValue.value ) * (1.00 / 127)
                })
            }
        }
    }
    
    @IBAction func botButtonClicked(_ sender: AnyObject)
    {
        // go to channel details
        nc.post(name: Notification.Name(rawValue: "ShowTrackDetails"), object: self)
    }
    
    static let meterImgGreen = UIImage( named: "meterGreenSegment 40x23 plain.png")
    static let meterImgGreenAmb = UIImage( named: "meterGreenAmbSegment 40x23 plain.png")
    static let meterImgGreenAmbRed = UIImage( named: "meterGreenAmbRedSegment 40x23 plain.png")
    
    // resize if device is rotated for example
    func reSize( _ ownerViewController:UIViewController )
    {
        inputMeterL.trackTintColor = UIColor.white
        inputMeterR.trackTintColor = UIColor.white
        outputMeterL.trackTintColor = UIColor.white
        outputMeterR.trackTintColor = UIColor.white

        // width is height as we are rotated
        self.sliderWidth.constant = CGFloat(ownerViewController.view.frame.height - 250)
        self.inputMeterLWidth.constant = CGFloat(ownerViewController.view.frame.height - 250)
        self.inputMeterRWidth.constant = CGFloat(ownerViewController.view.frame.height - 250)
        
        inputMeterL.progress =  0.0
        inputMeterL.progressTintColor = UIColor.green
        inputMeterR.progress = 0.0
        inputMeterR.progressTintColor = UIColor.green
        inputMeterL.progressImage = FaderChannel.meterImgGreen
        inputMeterR.progressImage = FaderChannel.meterImgGreen
        
        self.outputMeterLWidth.constant = CGFloat(ownerViewController.view.frame.height - 250)
        self.outputMeterRWidth.constant = CGFloat(ownerViewController.view.frame.height - 250)
        outputMeterL.progress = 0.0
        outputMeterL.progressTintColor = UIColor.green
        outputMeterR.progress = 0.0
        outputMeterR.progressTintColor = UIColor.green
        outputMeterL.progressImage = FaderChannel.meterImgGreen
        outputMeterR.progressImage = FaderChannel.meterImgGreen
    }

    // reset
    @objc func stopUpdate(_ notification: Notification) {
        DispatchQueue.main.async(execute: {
            self.outputMeterL.progress = 0.0
            self.outputMeterL.progressTintColor = UIColor.green
            self.outputMeterR.progress = 0.0
            self.outputMeterR.progressTintColor = UIColor.green
            self.inputMeterL.progress = 0.0
            self.inputMeterL.progressTintColor = UIColor.green
            self.inputMeterR.progress = 0.0
            self.inputMeterR.progressTintColor = UIColor.green
        })
    }
    
    // figure VU power levels
    @objc func outputTrackLevelUpdate(_ notification: Notification) {
        if( notification.object is ChannelLevels )
        {
            let levels = notification.object as! ChannelLevels
            
            if( self._specifics != nil )
            {
                if( levels.stereo )
                {
                    if( levels.channel == self._trackNumber)
                    {
                        DispatchQueue.main.async(execute: { // Stereo
                            self.outputMeterL.progress = levels.averagePowerForChannel0
                            self.outputMeterR.progress = levels.averagePowerForChannel1
                            if( levels.averagePowerForChannel0 < 0.8 )
                            {
                                self.outputMeterL.progressImage = FaderChannel.meterImgGreen
                            } else if( levels.averagePowerForChannel0 < 0.9 )
                            {
                                self.outputMeterL.progressImage = FaderChannel.meterImgGreenAmb
                            } else
                            {
                                self.outputMeterL.progressImage = FaderChannel.meterImgGreenAmbRed
                            }
                            
                            if( levels.averagePowerForChannel1 < 0.8 )
                            {
                                self.outputMeterR.progressImage = FaderChannel.meterImgGreen
                            } else if( levels.averagePowerForChannel1 < 0.9 )
                            {
                                self.outputMeterR.progressImage = FaderChannel.meterImgGreenAmb
                            } else
                            {
                                self.outputMeterR.progressImage = FaderChannel.meterImgGreenAmbRed
                            }
                        })
                    }
                }
                else
                {
                    if( levels.channel == self._trackNumber)
                    {
                        DispatchQueue.main.async(execute: {
                            if( levels.averagePowerForChannel0 < 0.8 )
                            {
                                self.outputMeterL.progressImage = FaderChannel.meterImgGreen
                            } else if( levels.averagePowerForChannel0 < 0.9 )
                            {
                                self.outputMeterL.progressImage = FaderChannel.meterImgGreenAmb
                            } else
                            {
                                self.outputMeterL.progressImage = FaderChannel.meterImgGreenAmbRed
                            }
                            self.outputMeterL.progress = levels.averagePowerForChannel0
                        })
                    }
                }
            }
        }
    }
    
    @objc func inputTrackLevelUpdate(_ notification: Notification) {
        if( notification.object is TrackLevels )
        {
            let levels = (notification.object as! TrackLevels).copy() as! TrackLevels // must take a copy on the notification
            
            if( self._specifics != nil )
            {
                let modTrack = (((self._specifics!.inputChan - 1) % levels.trackCount) + 1)
                let modTrack2 = (((self._specifics!.inputChan) % levels.trackCount) + 1)
                
                if( self._specifics!.stereoInput )
                {
                    if( levels.stereo && levels.track == modTrack ) // Stereo in on stereo track
                    {
                        DispatchQueue.main.async(execute: {
                            self.inputMeterL.progress = levels.averagePowerForChannel0
                            self.inputMeterR.progress = levels.averagePowerForChannel1
                            if( levels.averagePowerForChannel0 < 0.8 )
                            {
                                self.inputMeterL.progressImage = FaderChannel.meterImgGreen
                            } else if( levels.averagePowerForChannel0 < 0.9 )
                            {
                                self.inputMeterL.progressImage = FaderChannel.meterImgGreenAmb
                            } else
                            {
                                self.inputMeterL.progressImage = FaderChannel.meterImgGreenAmbRed
                            }
                            
                            if( levels.averagePowerForChannel1 < 0.8 )
                            {
                                self.inputMeterR.progressImage = FaderChannel.meterImgGreen
                            } else if( levels.averagePowerForChannel1 < 0.9 )
                            {
                                self.inputMeterR.progressImage = FaderChannel.meterImgGreenAmb
                            } else
                            {
                                self.inputMeterR.progressImage = FaderChannel.meterImgGreenAmbRed
                            }
                        })
                    }
                    else if( !levels.stereo && levels.track == modTrack) // mono in on stereo track
                    {
                        DispatchQueue.main.async(execute: {
                            self.inputMeterL.progress = levels.averagePowerForChannel0
                            if( levels.averagePowerForChannel0 < 0.8 )
                            {
                                self.inputMeterL.progressImage = FaderChannel.meterImgGreen
                            } else if( levels.averagePowerForChannel0 < 0.9 )
                            {
                                self.inputMeterL.progressImage = FaderChannel.meterImgGreenAmb
                            } else
                            {
                                self.inputMeterL.progressImage = FaderChannel.meterImgGreenAmbRed
                            }
                        })
                    } else if( levels.track == modTrack2) //R source of stereo track
                    {
                        DispatchQueue.main.async(execute: {
                            self.inputMeterR.progress = levels.averagePowerForChannel0
                            if( levels.averagePowerForChannel0 < 0.8 )
                            {
                                self.inputMeterR.progressImage = FaderChannel.meterImgGreen
                            } else if( levels.averagePowerForChannel0 < 0.9 )
                            {
                                self.inputMeterR.progressImage = FaderChannel.meterImgGreenAmb
                            } else
                            {
                                self.inputMeterR.progressImage = FaderChannel.meterImgGreenAmbRed
                            }
                        })
                    }
                }
                else if( levels.track == modTrack ) // us? L / mono
                {
                    DispatchQueue.main.async(execute: {
                        self.inputMeterL.progress = levels.averagePowerForChannel0
                        if( levels.averagePowerForChannel0 < 0.8 )
                        {
                            self.inputMeterL.progressImage = FaderChannel.meterImgGreen
                        } else if( levels.averagePowerForChannel0 < 0.9 )
                        {
                            self.inputMeterL.progressImage = FaderChannel.meterImgGreenAmb
                        } else
                        {
                            self.inputMeterL.progressImage = FaderChannel.meterImgGreenAmbRed
                        }
                    })
                }
            }
        }
    }
    
    // set up the track details
    func setTrack( _ doc:MuzomaDocument!, trackNumber:Int, track:MuzTrack, layoutIdx:Int )
    {
        _track = track
        _trackNumber = trackNumber
        _doc = doc
        _specifics = _doc.getAudioTrackSpecifics(_trackNumber)
        _layoutIdx = layoutIdx
        
        labTop.text = ""
        let attrStrTrackNumber = NSAttributedString(string: "\(trackNumber)")
        let attrStrTrackName = NSAttributedString(string:  "\(track._trackName)")
        self.butTop.setAttributedTitle( attrStrTrackNumber, for: UIControl.State())
        self.butBottom.setAttributedTitle( attrStrTrackName, for: UIControl.State())
        
        setUIFromSpecifics()
    }
    
    // set up from the specific details of a track
    func setUIFromSpecifics()
    {
        if( _specifics != nil )
        {
            if(_appDelegate.isPlayingOnMC )
            {
                if( !_specifics.favourMultiChanPlayback )
                {
                    self.sliderVolume.isEnabled = false
                    self.sliderVolume.backgroundColor = UIColor.lightGray
                }
            }
            else
            {
                if( !_specifics.favouriDevicePlayback )
                {
                    self.sliderVolume.isEnabled = false
                    self.sliderVolume.backgroundColor = UIColor.lightGray
                }
            }
            
            sliderVolume.value = _specifics!.volume
            labTop.text = "(\(_specifics!.inputChan)\(_specifics!.stereoInput ? "S" : "")>\(_specifics!.chan)\(_specifics!.downmixToMono ? "" : "S"))"
            if( _specifics!.recordArmed )
            {
                butTop.backgroundColor = UIColor.red
                butTop.titleLabel?.textColor = UIColor.white
                labTop.backgroundColor = UIColor.red
                labTop.textColor = UIColor.white
            }
            else
            {
                butTop.backgroundColor = nil
                butTop.titleLabel?.textColor = UIColor.blue
                labTop.backgroundColor = nil
                labTop.textColor = UIColor.blue
            }
        }
    }
    
    // export audio?
    func displayAudioExportPicker()
    {
        let originalTrack = self._doc?.getTrackDataAsURL(self._trackNumber, eventIdx: 0 )
        
        if( originalTrack != nil )
        {
            let documentPicker: UIDocumentPickerViewController = UIDocumentPickerViewController( url: originalTrack!, in: UIDocumentPickerMode.exportToService)
            documentPicker.delegate = self
            documentPicker.title = "Export Track Audio File"
            documentPicker.modalPresentationStyle = UIModalPresentationStyle.fullScreen
            self.window?.visibleViewController?.present(documentPicker, animated: true, completion: nil)
        }
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        if controller.documentPickerMode == UIDocumentPickerMode.import {
            if( url.isFileURL )
            {
                do
                {
                    if(_doc!.isPlaying())
                    {
                        _doc!.stop()
                    }
                    
                    // move to package folder
                    let fileManager = FileManager.default
                    let fileName = url.lastPathComponent
                    let destURL = _doc?.getDocumentFolderPathURL()!.appendingPathComponent(fileName)
                    let originalTrack = _doc?.getTrackDataAsURL(_trackNumber, eventIdx: 0 )
                    
                    // remove the old file
                    do
                    {
                        if( originalTrack != nil && fileManager.fileExists(originalTrack!) )
                        {
                            try  fileManager.removeItem(at: originalTrack!)
                            Logger.log("\(#function)  \(#file) Deleted \(originalTrack!.absoluteString)")
                        }
                    } catch let error as NSError {
                        Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                    }
                    
                    // remove the new if it already exists before copying
                    do
                    {
                        if( destURL != nil && fileManager.fileExists(destURL!) )
                        {
                            try fileManager.removeItem(at: destURL!)
                            Logger.log("\(#function)  \(#file) Deleted \(destURL!.absoluteString)")
                        }
                    } catch let error as NSError {
                        Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                    }
                    
                    // copy the new one
                    try fileManager.copyItem( at: url, to: destURL!)
                    
                    if( controller.title == "Select Audio File" )
                    {
                        _doc?.setDataForTrackEvent(_trackNumber, eventIdx: 0, url: destURL!)
                    }
                } catch let error as NSError {
                    Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                        
                        let alert = UIAlertController(title: "Error", message: "File could not be copied", preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                            print("Error copying file")
                            
                        }))
                        self.window?.visibleViewController?.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    // share file
    func displaySharePicker(dontRemoveItemWhenFinished: Bool = true)
    {
        let originalTrack = _doc?.getTrackDataAsURL(_trackNumber, eventIdx: 0 )
        
        if( originalTrack != nil )
        {
            let data = try? Data.init(contentsOf: originalTrack!)
            if( data != nil )
            {
                let objectsToShare = [ originalTrack!.lastPathComponent as String, originalTrack!] as [Any]
                let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                
                activityVC.popoverPresentationController?.sourceView = self.window?.visibleViewController?.view
                
                activityVC.excludedActivityTypes = []//UIActivityTypeCopyToPasteboard,UIActivityTypeAirDrop,UIActivityTypeAddToReadingList,UIActivityTypeAssignToContact,UIActivityTypePostToTencentWeibo,UIActivityTypePostToVimeo,UIActivityTypePrint,UIActivityTypeSaveToCameraRoll,UIActivityTypePostToWeibo]
                
                activityVC.completionWithItemsHandler = {
                    (activity, success, items, error) in
                    Logger.log("Activity: \(String(describing: activity)) Success: \(success) Items: \(String(describing: items)) Error: \(String(describing: error)) Dont remove: \(String(describing: dontRemoveItemWhenFinished))")
                    if( !dontRemoveItemWhenFinished )
                    {
                        do
                        {
                            try _gFSH.removeItem(at: originalTrack!)
                            Logger.log("\(#function)  \(#file) Deleted \(originalTrack!.absoluteString)")
                        } catch let error as NSError {
                            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                        }
                    }
                }
                
                self.window?.visibleViewController?.present(activityVC, animated: true, completion: nil)
            }
        }
    }
    
    func displayAudioFilePicker()
    {
        let documentPicker: UIDocumentPickerViewController = UIDocumentPickerViewController(documentTypes: [kUTTypeMP3 as String, kUTTypeMPEG4Audio as String, kUTTypeWaveformAudio as String, kUTTypeAudio as String, kUTTypeAudioInterchangeFileFormat as String/* kUTTypeMIDIAudio as String, kUTTypeAudio as String*/ ], in: UIDocumentPickerMode.import)
        documentPicker.delegate = self
        documentPicker.title = "Select Audio File"
        documentPicker.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        self.window?.visibleViewController?.present(documentPicker, animated: true, completion: nil)
    }

    // audioshare app - allow paste
    @objc func audioSharePaste(_ notification: Notification)
    {
        if( self._audioShareTrackImport && self._alertAS != nil )
        {
            self._audioShareTrackImport = false
            DispatchQueue.main.async(execute: {
                let ashare = AudioShare()

                ashare.checkPendingImport(notification.object as! URL?, with: { ( tempfile ) in
                    Logger.log("audio share pasted \(String(describing: tempfile))")
                    self._alertAS?.dismiss(animated: true, completion: nil)
                    self._alertAS = nil
                    
                    do
                    {
                        let tempURL = URL(fileURLWithPath: tempfile!)
                        if( (tempURL as NSURL).filePathURL != nil )
                        {
                            let existing = self._doc?.getTrackDataAsURL(self._trackNumber, eventIdx: 0)
                            if( existing != nil && _gFSH.fileExists(existing) ) // clear the old one
                            {
                                do
                                {
                                    try _gFSH.removeItem(at: existing!)
                                    Logger.log("\(#function)  \(#file) Deleted \(existing!.absoluteString)")
                                } catch let error as NSError {
                                    Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                                }
                            }
                            
                            let documentFolderFileWithCorrectExtension = self._doc?.getDocumentFolderPathURL()!.appendingPathComponent(tempURL.lastPathComponent)
                            
                            if( documentFolderFileWithCorrectExtension != nil && _gFSH.fileExists(documentFolderFileWithCorrectExtension) ) // clear the existing one
                            {
                                do
                                {
                                    try _gFSH.removeItem(at: documentFolderFileWithCorrectExtension!)
                                    Logger.log("\(#function)  \(#file) Deleted \(documentFolderFileWithCorrectExtension!.absoluteString)")
                                } catch let error as NSError {
                                    Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                                }
                            }
                            if( tempURL.pathExtension == "mp3" || tempURL.pathExtension == "wav" || tempURL.pathExtension == "m4a" || tempURL.pathExtension == "caf" )
                            {
                                try _gFSH.moveItem(at: tempURL, to: documentFolderFileWithCorrectExtension!)
                                Logger.log("audio share paste file saved \(documentFolderFileWithCorrectExtension!)")
                                
                                self._doc?.setDataForTrackEvent(self._trackNumber, eventIdx: 0, url: documentFolderFileWithCorrectExtension!)
                                _gFSH.queueFinishedAlert( self._doc, destFolder:nil )
                                
                            }
                            else if( tempURL.pathExtension == "zip" )
                            {
                                _ = _gFSH.extractAudioTracksFromZip(self._doc, url: tempURL, removeZip: false)
                            }
                        }
                    } catch let error as NSError {
                        Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                    }
                })
            })
        }
    }
    
    // midi learn
    var _learnAlert:UIAlertController! = nil
    func showLearnAlert( _ command:String, text:String )
    {
        _learnAlert = UIAlertController(title: "Learn midi command", message: "Learning midi command for \(text)...", preferredStyle: UIAlertController.Style.alert)
        _learnAlert.addAction(UIAlertAction(title: "Clear existing", style: .destructive, handler: { (action: UIAlertAction!) in
            _gMidi.clearExisting(_gMidi.mixerControl, commandIdentifier: command)
            _gMidi.cancelMidiLearn()
        }))
        _learnAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            _gMidi.cancelMidiLearn()
        }))
        
        self._learnAlert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        self.window?.visibleViewController?.present(self._learnAlert, animated: true, completion: {})
        _gMidi.startMidiLearn(_gMidi.mixerControl, commandIdentifier: command)
    }
    
    @objc func _midiMappingLearned(_ notification: Notification) {
        DispatchQueue.main.async(execute: {
            if(  notification.object is MIKMIDIMappingItem )
            {
                let obj:MIKMIDIMappingItem = notification.object as! MIKMIDIMappingItem
                self.midiMappingLearned( obj )
            }
        })
    }
    
    // midi learn
    var _learnedAlert:UIAlertController! = nil
    func midiMappingLearned( _ item:MIKMIDIMappingItem )
    {
        _learnAlert?.dismiss(animated: true, completion: {
            
            if( item.interactionType == .button || item.interactionType == .pressButton || item.interactionType == .pressReleaseButton &&
                item.additionalAttributes != nil && item.additionalAttributes!["Byte2"] != nil)
            {
                 self._learnedAlert = UIAlertController(title: "Midi command learned", message: "\(item.commandIdentifier) command learned\n\nType: \(item.commandType.description)\nMidi channel #\(item.channel + 1)\nControl #\(item.controlNumber)\nControl value #\(item.additionalAttributes!["Byte2"]!) ", preferredStyle: UIAlertController.Style.alert)
                
                self._learnedAlert.addAction(UIAlertAction(title: "React only when sent control value of #\(item.additionalAttributes!["Byte2"]!)", style: .default, handler: { (action: UIAlertAction!) in
                    _gMidi.saveMappingItem( item )
                }))
                
                self._learnedAlert.addAction(UIAlertAction(title: "React to any value sent for control #\(item.controlNumber)", style: .default, handler: { (action: UIAlertAction!) in
                    item.additionalAttributes?.removeValue(forKey: "Byte2")
                    _gMidi.saveMappingItem( item )
                }))
                
                self._learnedAlert.addAction(UIAlertAction(title: "Forget this", style: .cancel, handler: { (action: UIAlertAction!) in
                    //_gMidi.clearExisting(_gMidi.transportControl, commandIdentifier: item.commandIdentifier)
                }))
                
                self._learnedAlert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                self.window?.visibleViewController?.present(self._learnedAlert, animated: true, completion: {})
            }
            else
            {
                if( item.commandIdentifier.contains( "Fader" ) )
                {
                    let commandID = item.commandIdentifier
                    var commandIdx:Int = -1
                    let commandIdxStr = NSString( string: commandID.replacingOccurrences(of: "Fader", with: "") )
                    commandIdx = commandIdxStr.integerValue
                    
                    self._learnedAlert = UIAlertController(title: "Midi command learned", message: "\(item.commandIdentifier) command learned\n\nType: \(item.commandType.description)\nMidi channel #\(item.channel + 1), Control #\(item.controlNumber)\n", preferredStyle: UIAlertController.Style.alert)
                    
                    self._learnedAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
                        let newItem:MIKMIDIMappingItem! = MIKMIDIMappingItem(midiResponderIdentifier: item.midiResponderIdentifier, andCommandIdentifier: "Fader\(commandIdx)")
                        newItem.commandType = item.commandType
                        newItem.controlNumber = item.controlNumber
                        //newItem.additionalAttributes = item.additionalAttributes // byte 2
                        newItem.channel = item.channel
                        newItem.isFlipped = item.isFlipped
                        newItem.interactionType = item.interactionType
                        
                        _gMidi.saveMappingItem( newItem )
                    }))
                    
                    self._learnedAlert.addAction(UIAlertAction(title: "Forget this", style: .cancel, handler: { (action: UIAlertAction!) in
                        //_gMidi.clearExisting(_gMidi.transportControl, commandIdentifier: item.commandIdentifier)
                    }))
                    
                    self._learnedAlert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                    self.window?.visibleViewController?.present(self._learnedAlert, animated: true, completion: {})
                }
            }
        })
    }
    
    // handle double click
    @IBAction func sliderDoubleClick(_ sender: AnyObject) {
        //Logger.log("slider dclick")
        
        // specifics
        let specifics = _doc?.getAudioTrackSpecifics(_trackNumber)
        
        if( specifics != nil )
        {
            let originalTrack = self._doc?.getTrackDataAsURL(self._trackNumber, eventIdx: 0 )
            let fileExists = originalTrack != nil && _gFSH.fileExists(originalTrack)
            
            _alert = UIAlertController(title: "Track Settings", message: "Actions for this track\nWARNING the RED options are non-reversible", preferredStyle: UIAlertController.Style.alert)
            
            let learnMidi = UIAlertAction(title: "Learn midi for fader", style: .default, handler: { (action: UIAlertAction!) in
                self.showLearnAlert( "Fader\(self._layoutIdx)", text: String("fader \(self._layoutIdx + 1)") )
            })
            _alert.addAction(learnMidi)
            
            
            let shareAudio = UIAlertAction(title: "Share audio", style: .default, handler: { (action: UIAlertAction!) in
                self.displaySharePicker()
            })
            shareAudio.isEnabled = fileExists
            _alert.addAction(shareAudio)
            
            let sendAudioCloud = UIAlertAction(title: "Send audio to the Cloud", style: .default, handler: { (action: UIAlertAction!) in
                self.displayAudioExportPicker()
            })
            sendAudioCloud.isEnabled = fileExists
            _alert.addAction(sendAudioCloud)
            
            let copyToAudioShare = UIAlertAction(title: "Copy to AudioShare app", style: .default, handler: { (action: UIAlertAction!) in
                if( self._doc != nil && self._track != nil )
                {
                    self._doc!.copyTrackAudioToAudioShare( self._trackNumber )
                }
            })
            copyToAudioShare.isEnabled = fileExists
            _alert.addAction(copyToAudioShare)
            
            let copyToClipboard = UIAlertAction(title: "Copy to general clipboard", style: .default, handler: { (action: UIAlertAction!) in
                if( self._doc != nil && self._track != nil )
                {
                    self._doc!.copyTrackAudioToClipboard( self._trackNumber )
                }
            })
            copyToClipboard.isEnabled = fileExists
            _alert.addAction(copyToClipboard)
            
            let clearAudio = UIAlertAction(title: "Clear track audio", style: .destructive, handler: { (action: UIAlertAction!) in
                let wasPlaying = self._doc.isPlaying()
                if( wasPlaying )
                {
                    self._doc.stop()
                }
                _ = self._doc.removeTrackFile(self._trackNumber, eventIdx: 0 )
                if( wasPlaying )
                {
                    self._doc.play()
                }
            })
            clearAudio.isEnabled = fileExists
            _alert.addAction( clearAudio )
            
            _alert.addAction(UIAlertAction(title: "Cloud file import", style: .destructive, handler: { (action: UIAlertAction!) in
                self.displayAudioFilePicker()
            }))
            
            _alert.addAction(UIAlertAction(title: "Paste from AudioShare app", style: .destructive, handler: { (action: UIAlertAction!) in
                let ashare = AudioShare()
                self._audioShareTrackImport = true
                ashare.initiateSoundImport()
                
                self._alertAS = UIAlertController(title: "Waiting for AudioShare", message: "Waiting for paste from AudioShare app", preferredStyle: UIAlertController.Style.alert)
                
                self._alertAS.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                    self._audioShareTrackImport = false
                }))
                
                self._alertAS.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                self.window?.visibleViewController?.present(self._alertAS, animated: true, completion: {})
            }))
            
            _alert.addAction(UIAlertAction(title: "Paste from general clipboard", style: .destructive, handler: { (action: UIAlertAction!) in
                _ = self._doc.pasteTrackAudioFromClipboard(self._trackNumber)
            }))
            
            
            _alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                //print("Cancel")
            }))
            
            
            _alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            self.window?.visibleViewController?.present(_alert, animated: true, completion: {})
        }
    }
}
