//
//  EditTracksViewController.swift
//  Event Sequencer
//
//  Created by Matthew Hopkins on 05/04/2015.
//  Copyright (c) 2015 Muzoma.com. All rights reserved.
//
//  UI for editing tracks / channels details of a song
//
//
//

import UIKit
import Foundation
import CoreFoundation
import CoreMIDI
import MediaPlayer
import AVFoundation
import MobileCoreServices

class EditTracksViewController:  UIViewController, UIPickerViewDataSource, UIPickerViewDelegate,  UIDocumentPickerDelegate, UITextFieldDelegate
{
    let _nc = NotificationCenter.default
    fileprivate var _transport:Transport! = nil
    var muzomaDoc: MuzomaDocument?
    var _track: Int?
    var _trackType:TrackType = TrackType.Unknown
    var _trackPurpose:TrackPurpose = TrackPurpose.Unknown
    let maxMultitrackChans = 32//NSUserDefaults.standardUserDefaults().integerForKey("maxMultitrackChans_preference")
    
    @IBOutlet weak var trackName: UITextField!
    @IBOutlet weak var trackPurposePicker: UIPickerView!
    @IBOutlet weak var trackTypePicker: UIPickerView!
    @IBOutlet weak var labPrefChan: UILabel!
    @IBOutlet weak var stepperPrefChan: UIStepper!
    @IBOutlet weak var labChan: UILabel!
    @IBOutlet weak var labPrefVol: UILabel!
    @IBOutlet weak var prefVolSlider: UISlider!
    @IBOutlet weak var labPrefPan: UILabel!
    @IBOutlet weak var prefPanSlider: UISlider!
    @IBOutlet weak var labPrefVolLab: UILabel!
    @IBOutlet weak var labPrefMultitrackChanLab: UILabel!
    @IBOutlet weak var labPrefStereoBalLab: UILabel!
    @IBOutlet weak var switchPrefPlaybackiDevice: UISwitch!
    @IBOutlet weak var switchPrefPlaybackOnMultiChan: UISwitch!
    @IBOutlet weak var switchDownmixToMono: UISwitch!
    @IBOutlet weak var labAudioSettingsTitle: UILabel!
    @IBOutlet weak var buttonTrackSelect: UIButton!
    @IBOutlet weak var labAudioTrackHeading: UILabel!
    @IBOutlet weak var textAudioTrack: UITextField!
    @IBOutlet weak var labDownmixToMonoLabel: UILabel!
    @IBOutlet weak var switchIgnoreDownmixMultiChan: UISwitch!
    @IBOutlet weak var labIgnoreDownmixMultiChan: UILabel!
    @IBOutlet weak var labIgnoreDownmixiDevice: UILabel!
    @IBOutlet weak var switchIgnoreDownmixiDevice: UISwitch!
    @IBOutlet weak var labPlayOnNonMCHW: UILabel!
    @IBOutlet weak var labPlayOnMCHW: UILabel!
    
    // recording controls
    @IBOutlet weak var switchArmRecord: UISwitch!
    @IBOutlet weak var labRecordChan: UILabel!
    @IBOutlet weak var stepperPrefRecordChan: UIStepper!
    @IBOutlet weak var switchPrefMonitorRecord: UISwitch!
    @IBOutlet weak var switchPrefMonitorInput: UISwitch!
    @IBOutlet weak var switchPrefStereoInput: UISwitch!
    @IBOutlet weak var labRecordSettingsTitle: UILabel!
    @IBOutlet weak var labRecordEnable: UILabel!
    @IBOutlet weak var labPreferredRecordInputChan: UILabel!
    @IBOutlet weak var labMonitorWhileRecording: UILabel!
    @IBOutlet weak var labMonitorInput: UILabel!
    @IBOutlet weak var labStereoInput: UILabel!
    
    var isNewTrack = false
    
    // main code
    override func viewDidLoad() {
        super.viewDidLoad()
        self.trackName.delegate = self
        stepperPrefChan.maximumValue = Double(maxMultitrackChans)
        stepperPrefChan.autorepeat = true
        
        stepperPrefRecordChan.maximumValue = Double(maxMultitrackChans)
        stepperPrefRecordChan.autorepeat = true
        doneSave = false
        
        // dont enable change of track type at present
        trackPurposePicker.isUserInteractionEnabled = false
        trackTypePicker.isUserInteractionEnabled = false
        
        butUpload.isEnabled = false
        butDownload.isEnabled = false
        
        // Do any additional setup after loading the view, typically from a nib.
        if( _track != nil )
        {
            trackTypePicker.reloadAllComponents()
            trackPurposePicker.reloadAllComponents()
            
            trackName.text = (muzomaDoc?._tracks[_track!]._trackName)!
            _trackType = (muzomaDoc?._tracks[_track!]._trackType)!
            _trackPurpose = (muzomaDoc?._tracks[_track!]._trackPurpose)!
            
            
            let idxTrackType = TrackType.all().index(of: _trackType)
            if( idxTrackType != nil )
            {
                trackTypePicker.selectRow(idxTrackType!, inComponent: 0, animated: false)
                let idxPurpose = TrackType.purposeFor( _trackType ).index(of: _trackPurpose)
                if(idxPurpose != nil)
                {
                    trackPurposePicker.selectRow(idxPurpose!, inComponent: 0, animated: false)
                }
            }
            
            if( _trackType == TrackType.Audio )
            {
                butUpload.isEnabled = true
                butDownload.isEnabled = true
                let audioSpecifics = muzomaDoc?.getAudioTrackSpecifics(_track!)
                if( audioSpecifics != nil )
                {
                    stepperPrefChan.value = Double(audioSpecifics!.chan)
                    labChan.text = String(Int(stepperPrefChan.value))
                    prefVolSlider.value = Float(audioSpecifics!.volume * 100)
                    prefVolChange(prefVolSlider)
                    labPrefVol.text = String(Int( prefVolSlider.value ))
                    prefPanSlider.value = Float(audioSpecifics!.pan * 100)
                    prefPanChange(prefPanSlider)
                    
                    switchPrefPlaybackiDevice.isOn = audioSpecifics!.favouriDevicePlayback
                    switchPrefPlaybackOnMultiChan.isOn = audioSpecifics!.favourMultiChanPlayback
                    switchIgnoreDownmixMultiChan.isOn = audioSpecifics!.ignoreDownmixMultiChan
                    switchIgnoreDownmixiDevice.isOn = audioSpecifics!.ignoreDownmixiDevice
                    switchDownmixToMono.isOn = audioSpecifics!.downmixToMono
                    let originalTrack = muzomaDoc?.getTrackDataAsURL(_track!, eventIdx: 0 )
                    if( originalTrack != nil )
                    {
                        textAudioTrack.text = originalTrack?.lastPathComponent
                    }
                    else
                    {
                        textAudioTrack.text = ""
                    }
                    
                    // recording
                    switchArmRecord.isOn = audioSpecifics!.recordArmed
                    stepperPrefRecordChan.value = Double(audioSpecifics!.inputChan)
                    labRecordChan.text = String(Int(stepperPrefRecordChan.value))
                    switchPrefMonitorRecord.isOn = audioSpecifics!.monitorWhileRecording
                    switchPrefMonitorInput.isOn = audioSpecifics!.monitorInput
                    switchPrefStereoInput.isOn = audioSpecifics!.stereoInput
                }
            }
        }
        else
        {   // only enable new backing tracks to be added at present
            let idxTrackType = TrackType.all().index(of: TrackType.Audio)
            _trackType = TrackType.Audio
            trackTypePicker.selectRow(idxTrackType!, inComponent: 0, animated: false)
            let idxPurpose = TrackType.purposeFor(TrackType.Audio).index(of: TrackPurpose.BackingTrackAudio)
            trackPurposePicker.selectRow(idxPurpose!, inComponent: 0, animated: false)
            _trackPurpose = TrackPurpose.BackingTrackAudio
            
            //new one
            isNewTrack = true
            let specifics:EventSpecifics! = nil
            _track = muzomaDoc?.addNewTrack( self.trackName.text!, trackType: _trackType, trackPurpose: _trackPurpose, eventspecifcs: specifics  )
            if( _track != nil )
            {
                let audioSpecifics = muzomaDoc!.getAudioTrackSpecifics(_track!)
                audioSpecifics?.favouriDevicePlayback = true
                audioSpecifics?.favourMultiChanPlayback = true
                switchPrefPlaybackiDevice?.isOn = (audioSpecifics?.favouriDevicePlayback)!
                switchPrefPlaybackOnMultiChan?.isOn = (audioSpecifics?.favourMultiChanPlayback)!
            }
        }
        
        checkPropVisibility()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override func viewDidAppear(_ animated: Bool) {
        _transport = Transport( viewController: self )
        
        _gNC.addObserver(self, selector: #selector(EditTracksViewController.audioSharePaste(_:)), name: NSNotification.Name(rawValue: "AudioSharePaste"), object: nil)
        
        return super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        _transport?.willDeinit()
        _gNC.removeObserver( self, name: NSNotification.Name(rawValue: "AudioSharePaste"), object: nil )
        _transport = nil
        return( super.viewDidDisappear(animated) )
    }
    
    @IBAction func recordArmChanged(_ sender: AnyObject) {
        
    }
    
    func displaySharePicker(dontRemoveItemWhenFinished: Bool = true)
    {
        let originalTrack = self.muzomaDoc?.getTrackDataAsURL(self._track!, eventIdx: 0 )
        
        if( originalTrack != nil )
        {
            let data = try? Data.init(contentsOf: originalTrack!)
            if( data != nil )
            {
                let objectsToShare = [ originalTrack!.lastPathComponent as String, originalTrack!] as [Any]
                let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                
                activityVC.popoverPresentationController?.barButtonItem = self.butUpload
                
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
                self.present(activityVC, animated: true, completion: nil)
            }
        }
    }
    
    func displayAudioExportPicker()
    {
        let originalTrack = self.muzomaDoc?.getTrackDataAsURL(self._track!, eventIdx: 0 )
        
        if( originalTrack != nil )
        {
            let documentPicker: UIDocumentPickerViewController = UIDocumentPickerViewController( url: originalTrack!, in: UIDocumentPickerMode.exportToService)
            documentPicker.delegate = self
            documentPicker.title = "Export Track Audio File"
            documentPicker.modalPresentationStyle = UIModalPresentationStyle.fullScreen
            self.present(documentPicker, animated: true, completion: nil)
        }
    }
    
    func displayAudioFilePicker()
    {
        let documentPicker: UIDocumentPickerViewController = UIDocumentPickerViewController(documentTypes: [kUTTypeMP3 as String, kUTTypeMPEG4Audio as String, kUTTypeWaveformAudio as String, kUTTypeAudio as String, kUTTypeAudioInterchangeFileFormat as String/* kUTTypeMIDIAudio as String, kUTTypeAudio as String*/ ], in: UIDocumentPickerMode.import)
        documentPicker.delegate = self
        documentPicker.title = "Select Audio File"
        documentPicker.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        if controller.documentPickerMode == UIDocumentPickerMode.import {
            if( url.isFileURL )
            {
                do
                {
                    if(muzomaDoc!.isPlaying())
                    {
                        muzomaDoc!.stop()
                    }
                    
                    // move to package folder
                    let fileManager = FileManager.default
                    let fileName = url.lastPathComponent
                    let destURL = self.muzomaDoc?.getDocumentFolderPathURL()!.appendingPathComponent(fileName)
                    let originalTrack = muzomaDoc?.getTrackDataAsURL(_track!, eventIdx: 0 )
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
                        textAudioTrack.text = fileName
                        muzomaDoc?.setDataForTrackEvent(_track!, eventIdx: 0, url: destURL!)
                    }
                } catch let error as NSError {
                    Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                        
                        let alert = UIAlertController(title: "Error", message: "File could not be copied", preferredStyle: UIAlertController.Style.alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                            print("Error copying file")
                            
                        }))
                        
                        self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    
    @IBAction func stepValChanged(_ sender: AnyObject) {
        labChan.text = String(Int((sender as! UIStepper).value))
    }
    
    @IBAction func downMixToMonoChanged(_ sender: AnyObject) {
        let audioSpecifics = muzomaDoc?.getAudioTrackSpecifics(_track!)
        audioSpecifics!.downmixToMono = switchDownmixToMono.isOn
        
        if( muzomaDoc!.isPlaying() )
        {
            muzomaDoc?.stop()
            muzomaDoc?.play()
        }
        
        labPrefPan.isEnabled  = switchDownmixToMono.isOn
        prefPanSlider.isEnabled  = switchDownmixToMono.isOn
        labPrefStereoBalLab.isEnabled  = switchDownmixToMono.isOn
        switchIgnoreDownmixMultiChan.isEnabled = switchDownmixToMono.isOn
        labIgnoreDownmixMultiChan.isEnabled = switchDownmixToMono.isOn
        switchIgnoreDownmixiDevice.isEnabled = switchDownmixToMono.isOn
        labIgnoreDownmixiDevice.isEnabled = switchDownmixToMono.isOn
        
    }
    
    @IBAction func ignoreDownmixMultiChanPress(_ sender: AnyObject) {
        muzomaDoc?.setIgnoreDownMixMC(_track!, ignore: ((sender as! UISwitch).isOn))
        if( muzomaDoc!.isPlaying() )
        {
            muzomaDoc?.stop()
            muzomaDoc?.play()
        }
    }
    
    @IBAction func ignoreDownmixiDevicePress(_ sender: AnyObject) {
        muzomaDoc?.setIgnoreDownMixiDevice(_track!, ignore: ((sender as! UISwitch).isOn))
        if( muzomaDoc!.isPlaying() )
        {
            muzomaDoc?.stop()
            muzomaDoc?.play()
        }
    }
    
    let _appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBAction func includeOnNonMC(_ sender: AnyObject) {
        muzomaDoc?.setIncludeOnNonMC(_track!, include: ((sender as! UISwitch).isOn))
        if( muzomaDoc!.isPlaying() && !self._appDelegate.isPlayingOnMC  )
        {
            muzomaDoc?.stop()
            muzomaDoc?.play()
        }
    }
    
    @IBAction func includeOnMC(_ sender: AnyObject) {
        muzomaDoc?.setIncludeOnMC(_track!, include: ((sender as! UISwitch).isOn))
        
        if( muzomaDoc!.isPlaying() && self._appDelegate.isPlayingOnMC )
        {
            muzomaDoc?.stop()
            muzomaDoc?.play()
        }
    }
    
    @IBAction func prefVolChange(_ sender: AnyObject) {
        labPrefVol.text = String(Int((sender as! UISlider).value))
        muzomaDoc?.setTrackVolume(_track!, volume: ((sender as! UISlider).value / 100))
    }
    
    @IBAction func prefPanChange(_ sender: AnyObject) {
        let panVal = Int(prefPanSlider.value)
        
        switch( panVal )
        {
        case 0:
            labPrefPan.text = "C"
            break;
            
        case 100:
            labPrefPan.text = "R"
            break;
            
        case -100:
            labPrefPan.text = "L"
            break;
            
        default:
            labPrefPan.text = String(panVal)
            break;
        }
        
        muzomaDoc?.setTrackPan(_track!, pan: ((sender as! UISlider).value / 100))
    }
    
    @IBAction func prefInternalPlaybackChanged(_ sender: AnyObject) {
    }
    
    var doneSave = false

    
    func captureChanges()
    {
        let clickTrack = muzomaDoc?.getClickTrackIndex()
        let guideTrack = muzomaDoc?.getGuideTrackIndex()

        if( _trackPurpose == TrackPurpose.GuideAudio && muzomaDoc?.getGuideTrackIndex() != _track! && guideTrack != -1 )
        {
            // can't have two guides
            let alert = UIAlertController(title: "Error", message: "You can't define more than one guide audio track, please remove the original one first", preferredStyle: UIAlertController.Style.alert)
            
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                
            }))
            
            alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            self.present(alert, animated: true, completion: nil)
        }
        else if( _trackPurpose == TrackPurpose.ClickTrackAudio && clickTrack != _track! && clickTrack != -1 )
        {
            // can't have two click
            let alert = UIAlertController(title: "Error", message: "You can't define more than one click audio track, please remove the original one first", preferredStyle: UIAlertController.Style.alert)
            
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                
            }))
            
            alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            
            //self.showViewController(alert, sender: self)
            self.present(alert, animated: true, completion: nil)
        }
        else
        {
            muzomaDoc?._tracks[_track!]._trackPurpose = _trackPurpose
            muzomaDoc?._tracks[_track!]._trackType = _trackType
            muzomaDoc?._tracks[_track!]._trackName = self.trackName.text!
            
            if( _trackType == TrackType.Audio )
            {
                let audioSpecifics = muzomaDoc?.getAudioTrackSpecifics(_track!)
                audioSpecifics!.chan = Int(labChan.text!)!
                audioSpecifics!.volume = prefVolSlider.value / 100
                audioSpecifics!.pan = prefPanSlider.value / 100
                audioSpecifics!.favouriDevicePlayback = switchPrefPlaybackiDevice.isOn
                audioSpecifics!.favourMultiChanPlayback = switchPrefPlaybackOnMultiChan.isOn
                audioSpecifics!.downmixToMono = switchDownmixToMono.isOn
                audioSpecifics!.ignoreDownmixMultiChan = switchIgnoreDownmixMultiChan.isOn
                // recording
                audioSpecifics!.recordArmed = switchArmRecord.isOn
                audioSpecifics!.inputChan = Int( self.labRecordChan .text!)!
                audioSpecifics!.monitorWhileRecording = switchPrefMonitorRecord.isOn
                audioSpecifics!.monitorInput = switchPrefMonitorInput.isOn
                audioSpecifics!.stereoInput = switchPrefStereoInput.isOn
            }
            
            _ = _gFSH.saveMuzomaDocLocally( muzomaDoc! )
            doneSave = true
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func checkPropVisibility()
    {
        if( _trackType == TrackType.Audio )
        {
            labPrefChan.isHidden = false
            stepperPrefChan.isHidden  = false
            labChan.isHidden  = false
            labPrefVol.isHidden  = false
            prefVolSlider.isHidden  = false
            labPrefPan.isHidden  = false
            prefPanSlider.isHidden  = false
            labPrefVolLab.isHidden  = false
            labPrefMultitrackChanLab.isHidden  = false
            labPrefStereoBalLab.isHidden  = false
            labAudioSettingsTitle.isHidden  = false
            buttonTrackSelect.isHidden  = false
            labAudioTrackHeading.isHidden  = false
            textAudioTrack.isHidden  = false
            labDownmixToMonoLabel.isHidden = false
            switchDownmixToMono.isHidden = false
            switchIgnoreDownmixMultiChan.isHidden = false
            switchIgnoreDownmixiDevice.isHidden = false
            switchPrefPlaybackiDevice.isHidden = false
            switchPrefPlaybackOnMultiChan.isHidden = false
            switchArmRecord.isHidden = false
            labIgnoreDownmixMultiChan.isHidden = false
            labIgnoreDownmixiDevice.isHidden = false
            labPlayOnNonMCHW.isHidden = false
            labPlayOnMCHW.isHidden = false
            
            switchArmRecord.isHidden = false
            labRecordChan.isHidden = false
            stepperPrefRecordChan.isHidden = false
            switchPrefMonitorRecord.isHidden = false
            switchPrefMonitorInput.isHidden = false
            switchPrefStereoInput.isHidden = false
            labRecordSettingsTitle.isHidden = false
            labRecordEnable.isHidden = false
            labPreferredRecordInputChan.isHidden = false
            labMonitorWhileRecording.isHidden = false
            labMonitorInput.isHidden = false
            labStereoInput.isHidden = false
            
            labPrefPan.isEnabled  = switchDownmixToMono.isOn
            prefPanSlider.isEnabled  = switchDownmixToMono.isOn
            labPrefStereoBalLab.isEnabled  = switchDownmixToMono.isOn
            switchIgnoreDownmixMultiChan.isEnabled = switchDownmixToMono.isOn
            switchIgnoreDownmixiDevice.isEnabled = switchDownmixToMono.isOn
            labIgnoreDownmixMultiChan.isEnabled = switchDownmixToMono.isOn
            labIgnoreDownmixiDevice.isEnabled = switchDownmixToMono.isOn
        }
        else
        {
            labPrefChan.isHidden = true
            stepperPrefChan.isHidden  = true
            labChan.isHidden  = true
            labPrefVol.isHidden  = true
            prefVolSlider.isHidden  = true
            labPrefPan.isHidden  = true
            prefPanSlider.isHidden  = true
            labPrefVolLab.isHidden  = true
            labPrefMultitrackChanLab.isHidden  = true
            labPrefStereoBalLab.isHidden  = true
            labPlayOnNonMCHW.isHidden = true
            labPlayOnMCHW.isHidden = true
            switchPrefPlaybackiDevice.isHidden = true
            switchArmRecord.isHidden = true
            switchPrefPlaybackOnMultiChan.isHidden = true
            labAudioSettingsTitle.isHidden  = true
            buttonTrackSelect.isHidden  = true
            labAudioTrackHeading.isHidden  = true
            textAudioTrack.isHidden  = true
            labDownmixToMonoLabel.isHidden = true
            switchDownmixToMono.isHidden = true
            switchIgnoreDownmixMultiChan.isHidden = true
            switchIgnoreDownmixiDevice.isHidden = true
            labIgnoreDownmixMultiChan.isHidden = true
            labIgnoreDownmixiDevice.isHidden = true
            
            switchArmRecord.isHidden = true
            labRecordChan.isHidden =  true
            stepperPrefRecordChan.isHidden =  true
            switchPrefMonitorRecord.isHidden =  true
            switchPrefMonitorInput.isHidden =  true
            switchPrefStereoInput.isHidden =  true
            labRecordSettingsTitle.isHidden =  true
            labRecordEnable.isHidden =  true
            labPreferredRecordInputChan.isHidden =  true
            labMonitorWhileRecording.isHidden =  true
            labMonitorInput.isHidden =  true
            labStereoInput.isHidden =  true
        }
        
        if( _trackPurpose != .GuideAudio ) // one and only!
        {
            trackPurposePicker.isUserInteractionEnabled = true
        }
    }
    
    // picker view
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView
    {
        let pickerLabel = UILabel()
        pickerLabel.textColor = UIColor.black
        
        if( pickerView == trackPurposePicker )
        {
            pickerLabel.text = TrackType.purposeFor( _trackType )[row].rawValue
        }
        else if( pickerView == trackTypePicker )
        {
            pickerLabel.text = TrackType.all()[row].rawValue
        }
        
        pickerLabel.font = UIFont(name: "Arial-BoldMT", size: 13) // In this use your custom font
        pickerLabel.textAlignment = NSTextAlignment.left
        
        return pickerLabel
    }
    
    func numberOfComponents( in pickerView: UIPickerView ) -> Int
    {
        return(1)
    }
    
    func pickerView( _ pickerView: UIPickerView, numberOfRowsInComponent component: Int ) -> Int
    {
        var ret:Int = 0
        
        if( pickerView == trackPurposePicker )
        {
            ret = TrackType.purposeFor(_trackType).count
        }
        else if( pickerView == trackTypePicker )
        {
            ret = TrackType.all().endIndex
        }
        
        return ret
    }
    
    func pickerView( _ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int ) -> String? {
        
        var ret = ""
        if( pickerView == trackTypePicker)
        {
            ret = TrackType.all()[row].rawValue
        }
        
        return ret
    }
    
    func pickerView( _ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int )
    {
        // user changed the picker row
        if( pickerView == trackTypePicker)
        {
            _trackType = TrackType.all()[row]
            checkPropVisibility()
            trackPurposePicker.reloadAllComponents()
        }
        else if( pickerView == trackPurposePicker)
        {
            _trackPurpose = TrackType.purposeFor( _trackType )[row]
        }
    }
    
    override func willMove(toParent parent: UIViewController?) {
        
        // called when shown and exiting, on exit parent is nil
        if( parent == nil)
        {
            //print("Back Button Pressed Editor!")
            if( !doneSave )
            {
                self.captureChanges()
                self._nc.post(name: Notification.Name(rawValue: "RefreshTracksList"), object: nil)
            }
        }
        super.willMove(toParent: parent)
    }
    
    @IBAction func stepperInputChanChanged(_ sender: AnyObject) {
        labRecordChan.text = String(Int((sender as! UIStepper).value))
    }
    
    @IBAction func monitorWhileRecordingChanged(_ sender: AnyObject) {
        if( muzomaDoc!.isPlaying() )
        {
            muzomaDoc?.stop()
            muzomaDoc?.play()
        }
        else
        {
            specificsChanged()
        }
    }
    
    @IBAction func monitorInputChanged(_ sender: AnyObject) {
        if( muzomaDoc!.isPlaying() )
        {
            muzomaDoc?.stop()
            muzomaDoc?.play()
        }
        else
        {
            specificsChanged()
        }
    }
    
    @IBAction func stereoInputChanged(_ sender: AnyObject) {
        if( muzomaDoc!.isPlaying() )
        {
            muzomaDoc?.stop()
            muzomaDoc?.play()
        }
        else
        {
            specificsChanged()
        }
    }
    
    func specificsChanged()
    {
        var specifics = [AudioEventSpecifics?]()
        specifics.append( muzomaDoc!.getGuideTrackSpecifics() )
        specifics.append(contentsOf: muzomaDoc!.getBackingTrackSpecifics() )
        _nc.post(name: Notification.Name(rawValue: "AudioSpecificsChanged"), object: specifics)
    }
    
    func didCopy(_ player: AnyObject!) {
        Logger.log("did copy")
    }
    
    func didPaste(_ viewcontroller: AnyObject!, atPath path: String!, itemNamed name: String!, withMetaData meta: [AnyHashable: Any]!) {
        Logger.log("did paste")
    }
    
    @objc func audioSharePaste(_ notification: Notification)
    {
        DispatchQueue.main.async(execute: {
            let ashare = AudioShare()

            ashare.checkPendingImport(notification.object as! URL?, with: { ( tempfile ) in
                Logger.log("audio share pasted \(String(describing: tempfile))")
                
                do
                {
                    let tempURL = URL(fileURLWithPath: tempfile!)
                    if( (tempURL as NSURL).filePathURL != nil )
                    {
                        let existing = self.muzomaDoc?.getTrackDataAsURL(self._track!, eventIdx: 0)
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
                        
                        let documentFolderFileWithCorrectExtension = self.muzomaDoc?.getDocumentFolderPathURL()!.appendingPathComponent(tempURL.lastPathComponent)
                        if( _gFSH.fileExists(documentFolderFileWithCorrectExtension) ) // clear the existing one
                        {
                            do
                            {
                                try _gFSH.removeItem(at: documentFolderFileWithCorrectExtension!)
                                Logger.log("\(#function)  \(#file) Deleted \(documentFolderFileWithCorrectExtension!.absoluteString)")
                            } catch let error as NSError {
                                Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                            }
                        }
                        try _gFSH.moveItem(at: tempURL, to: documentFolderFileWithCorrectExtension!)
                        Logger.log("audio share paste file saved \(documentFolderFileWithCorrectExtension!)")
                        
                        self.muzomaDoc?.setDataForTrackEvent(self._track!, eventIdx: 0, url: documentFolderFileWithCorrectExtension!)
                        
                        self.textAudioTrack.text = documentFolderFileWithCorrectExtension?.lastPathComponent
                        self.specificsChanged()
                    }
                } catch let error as NSError {
                    Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                }
            })
        })
    }
    
    @IBOutlet weak var butDownload: UIBarButtonItem!
    
    @IBAction func butDownloadClicked(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Import Audio", message: "Select a source and load a file for this track's audio.\n\nTHE CURRENT AUDIO WILL BE REPLACED", preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "Cloud file import", style: .destructive, handler: { (action: UIAlertAction!) in
            self.displayAudioFilePicker()
        }))
        
        alert.addAction(UIAlertAction(title: "Paste from AudioShare app", style: .destructive, handler: { (action: UIAlertAction!) in
            let ashare = AudioShare()
            ashare.initiateSoundImport()
        }))
        
        alert.addAction(UIAlertAction(title: "Paste from general clipboard", style: .destructive, handler: { (action: UIAlertAction!) in
            let newFile = self.muzomaDoc!.pasteTrackAudioFromClipboard(self._track!)

            if( newFile != nil )
            {
                DispatchQueue.main.async(execute: {
                    self.textAudioTrack.text = newFile
                    self.specificsChanged()
                })
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            //print("Cancel")
        }))
        
        alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        self.present(alert, animated: true, completion: {})
    }
    
    
    @IBOutlet weak var butUpload: UIBarButtonItem!
    
    @IBAction func butUploadClicked(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Export Audio", message: "Select a source and save this track's audio.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Cloud file export", style: .default, handler: { (action: UIAlertAction!) in
            self.displayAudioExportPicker()
        }))
        
        alert.addAction(UIAlertAction(title: "Share audio file", style: .default, handler: { (action: UIAlertAction!) in
            self.displaySharePicker()
        }))
        
        alert.addAction(UIAlertAction(title: "Copy to AudioShare app", style: .default, handler: { (action: UIAlertAction!) in
            self.captureChanges()
            if( self.muzomaDoc != nil && self._track != nil )
            {
                self.muzomaDoc!.copyTrackAudioToAudioShare( self._track! )
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Copy to general clipboard", style: .default, handler: { (action: UIAlertAction!) in
            if( self.muzomaDoc != nil && self._track != nil )
            {
                self.muzomaDoc!.copyTrackAudioToClipboard(self._track!)
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            //print("Cancel")
        }))
        
        
        alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        self.present(alert, animated: true, completion: {})
    }
    
    @IBAction func trackSelectPressed(_ sender: AnyObject) {
        
    }
}

