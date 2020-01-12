//
//  RecorderViewController.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 26/01/2017.
//  Copyright © 2017 Muzoma.com. All rights reserved.
//
//  The main UI for the mixer and recording view controller
//  Provides mixer and tape recorder like functions for the user
//
//

import Foundation
import UIKit
import MobileCoreServices
import MIKMIDI


class RecorderViewController : UIViewController, UIDocumentPickerDelegate {
    
    fileprivate var _transport:Transport! = nil
    let nc = _gNC
    
    @IBOutlet weak var scrollMixer: UISlider!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var stackViewWidth: NSLayoutConstraint!
    @IBOutlet weak var stackViewLeading: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.stackView.isLayoutMarginsRelativeArrangement = false
        // Do any additional setup after loading the view.
        
        let pro = MuzomaProducts.store.isProductPurchased( "MuzomaProducer" )
        
        if(!pro)
        {
            self.stackView.isUserInteractionEnabled = false
            
            let alert = UIAlertController(title: "Record and Mixing Feature", message: "Mixing and recording are disabled, please upgrade or restore the Producer version to use this feature", preferredStyle: UIAlertController.Style.alert )
            
            let iap = UIAlertAction(title: "In app purchases", style: .default, handler: { (action: UIAlertAction!) in
                print("IAP")
                let iapVC = self.storyboard?.instantiateViewController(withIdentifier: "IAPTableViewController") as? IAPTableViewController
                self.navigationController?.pushViewController(iapVC!, animated: true)
            })
            
            alert.addAction(iap)
            
            alert.addAction(UIAlertAction(title: "Later", style: .cancel, handler: { (action: UIAlertAction!) in
                print("Cancel")
            }))
            
            alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            self.present(alert, animated: true, completion:
                {
                    //print( "iap alert shown" )
            } )
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        // turn off the swipe to go back gesture as it interfears with out UI slider controls sometimes
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        //print( "viewDidAppear player doc" )
        _transport = Transport( viewController: self,  includeVarispeedButton: false,  includeRecordTimingButton: false, includeGuideTrackSelectButton: false, includeBandSelectButton: false, includeExtControlButton: true, includeRecordAudioButton: true )
        
        nc.addObserver(self, selector: #selector(RecorderViewController.trackDetailsClicked(_:)), name: NSNotification.Name(rawValue: "ShowTrackDetails"), object: nil)
        nc.addObserver(self, selector: #selector(RecorderViewController.detectHardwareChange(_:)), name: NSNotification.Name(rawValue: "DetectHardwareChange"), object: nil)
        nc.addObserver(self, selector: #selector(RecorderViewController.rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
        nc.addObserver(self, selector: #selector(RecorderViewController.audioSharePaste(_:)), name: NSNotification.Name(rawValue: "AudioSharePaste"), object: nil)
        nc.addObserver(self, selector: #selector(RecorderViewController.rotated), name: NSNotification.Name(rawValue: "MuzomaDocWritten"), object: nil)
        nc.addObserver(self, selector: #selector(RecorderViewController._midiMappingLearned(_:)), name: NSNotification.Name(rawValue: "MidiMappingLearned"), object: nil)
        
        // as soon as we see the mixer, start the monitor session
        loadTracks()
        
        return super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        _ = _gFSH.saveMuzomaDocLocally( Transport.getCurrentDoc() )
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "ShowTrackDetails"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "DetectHardwareChange"), object: nil )
        nc.removeObserver( self, name: UIDevice.orientationDidChangeNotification, object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "AudioSharePaste"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "MuzomaDocWritten"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "MidiMappingLearned"), object: nil )
        
        _transport?.willDeinit()
        _transport = nil
        return( super.viewDidDisappear(animated) )
    }
    
    @objc func rotated()
    {
        DispatchQueue.main.async(execute: {
            self.loadTracks()
            self.scrollToolbarsChanged( self )
        })
    }
    
    @objc func detectHardwareChange(_ sender: Notification)
    {
        DispatchQueue.main.async(execute: {
            self.loadTracks()
            self.scrollToolbarsChanged( self )
        })
    }
    
    
    func loadTracks()
    {
        for sv in self.stackView.subviews
        {
            // Remove stack view sub views
            self.stackView.removeArrangedSubview(sv)
            
            // now remove it from the view hierarchy – this is important!
            sv.removeFromSuperview()
        }
        
        let tracks = Transport.getCurrentDoc()?._tracks
        
        if( tracks != nil )
        {
            let trackCount = tracks!.count
            //Logger.log("mixer: track count \(trackCount)")
            
            var audioTrackCount = 0
            for tCnt in 0 ..< trackCount
            {
                //Logger.log("mixer: track \(tCnt) out of \(tracks!.count) type \(tracks![tCnt]._trackType)")
                if( tracks![tCnt]._trackType == TrackType.Audio )
                {
                    // external view
                    var chan:FaderChannel! = nil
                    chan = FaderChannel.loadFromNib()
                    chan.setTrack(Transport.getCurrentDoc(), trackNumber: tCnt, track: tracks![tCnt], layoutIdx:audioTrackCount)
                    chan.reSize(self)
                    self.stackView.addArrangedSubview(chan)
                    audioTrackCount += 1
                }
            }
            
            let width = audioTrackCount * 65
            self.stackViewWidth.constant = CGFloat(width)
        }
    }
    
    @objc func trackDetailsClicked(_ sender: Notification)
    {
        if(sender.object is FaderChannel)
        {
            let chan = sender.object as! FaderChannel
            DispatchQueue.main.async(execute: {
                // go to channel details
                self.performSegue(withIdentifier: "TrackEditSegueFromRecorder", sender:chan) // show editor for this track
            })
        }
    }
    
    func saveAndRefresh()
    {
        if( Transport.getCurrentDoc().isPlaying() )
        {
            Transport.getCurrentDoc().stop()
            Transport.getCurrentDoc().play()
        }
        _ = _gFSH.saveMuzomaDocLocally( Transport.getCurrentDoc() )
        self.loadTracks()
        self.scrollToolbarsChanged( self )
    }
    
    var _learnAlert:UIAlertController! = nil
    func showLearnAlert( _ command:String, text:String )
    {
        _learnAlert = UIAlertController(title: "Learn midi command", message: "Learning midi command for \(text)...", preferredStyle: UIAlertController.Style.alert)
        _learnAlert.addAction(UIAlertAction(title: "Clear existing", style: .destructive, handler: { (action: UIAlertAction!) in
            _gMidi.clearExisting(_gMidi.mixerControl, commandIdentifier: command)
            _gMidi.cancelMidiLearn()
        }))
        _learnAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            //print("Handle Cancel Logic here")
            _gMidi.cancelMidiLearn()
        }))
        
        _learnAlert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        self.present(_learnAlert, animated: true, completion: {})
        _gMidi.startMidiLearn(_gMidi.mixerControl, commandIdentifier: command)
    }
    
    @objc func _midiMappingLearned(_ notification: Notification) {
        DispatchQueue.main.async(execute: {
            if( notification.object is MIKMIDIMappingItem)
            {
                let obj:MIKMIDIMappingItem = notification.object as! MIKMIDIMappingItem
                self.midiMappingLearned( obj )
            }
        })
    }
    
    func midiMappingLearned( _ item:MIKMIDIMappingItem )
    {
        _learnAlert?.dismiss(animated: true, completion: {
            
            if( item.interactionType == .button || item.interactionType == .pressButton || item.interactionType == .pressReleaseButton &&
                item.additionalAttributes != nil && item.additionalAttributes!["Byte2"] != nil)
            {
                let _learnedAlert = UIAlertController(title: "Midi command learned", message: "\(item.commandIdentifier) command learned\n\nType: \(item.commandType.description)\nMidi channel #\(item.channel + 1)\nControl #\(item.controlNumber)\nControl value #\(item.additionalAttributes!["Byte2"]!) ", preferredStyle: UIAlertController.Style.alert)
                
                _learnedAlert.addAction(UIAlertAction(title: "React only when sent control value of #\(item.additionalAttributes!["Byte2"]!)", style: .default, handler: { (action: UIAlertAction!) in
                    _gMidi.saveMappingItem( item )
                }))
                
                _learnedAlert.addAction(UIAlertAction(title: "React to any value sent for control #\(item.controlNumber)", style: .default, handler: { (action: UIAlertAction!) in
                    item.additionalAttributes?.removeValue(forKey: "Byte2")
                    _gMidi.saveMappingItem( item )
                }))
                
                _learnedAlert.addAction(UIAlertAction(title: "Forget this", style: .cancel, handler: { (action: UIAlertAction!) in
                    //_gMidi.clearExisting(_gMidi.transportControl, commandIdentifier: item.commandIdentifier)
                }))
                _learnedAlert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                self.present(_learnedAlert, animated: true, completion: {})
            }
            else
            {
                if( item.commandIdentifier == "Faders" )
                {
                    let endControl = min( item.controlNumber + 63, 127 )
                    let controlRange = (endControl - item.controlNumber) + 1
                    let _learnedAlert = UIAlertController(title: "Midi command learned", message: "\(item.commandIdentifier) command learned\n\nType: \(item.commandType.description)\nMidi channel #\(item.channel + 1), Starting Control #\(item.controlNumber)\nEnding Control #\(endControl) (will map a range of \(controlRange) consecutive controls)", preferredStyle: UIAlertController.Style.alert)
                    
                    _learnedAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
                        
                        var faderIdx=0
                        for ctlIdx in item.controlNumber ..< endControl
                        {
                            let newItem:MIKMIDIMappingItem! = MIKMIDIMappingItem(midiResponderIdentifier: item.midiResponderIdentifier, andCommandIdentifier: "Fader\(faderIdx)")
                            newItem.commandType = item.commandType
                            newItem.controlNumber = ctlIdx
                            //newItem.additionalAttributes = item.additionalAttributes // byte 2
                            newItem.channel = item.channel
                            newItem.isFlipped = item.isFlipped
                            newItem.interactionType = item.interactionType
                            
                            _gMidi.saveMappingItem( newItem )
                            faderIdx = faderIdx + 1
                        }
                    }))
                    
                    _learnedAlert.addAction(UIAlertAction(title: "Forget this", style: .cancel, handler: { (action: UIAlertAction!) in
                        //_gMidi.clearExisting(_gMidi.transportControl, commandIdentifier: item.commandIdentifier)
                    }))
                    
                    _learnedAlert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                    self.present(_learnedAlert, animated: true, completion: {})
                }
            }
        })
    }
    
    
    @IBAction func allClicked(_ sender: AnyObject) {
        let alert = UIAlertController(title: "All Tracks", message: "Apply the following to ALL tracks?", preferredStyle: UIAlertController.Style.alert)
        
        
        alert.addAction(UIAlertAction(title: "Learn Midi For All Faders", style: .default, handler: { (action: UIAlertAction!) in
            self.showLearnAlert( "Faders", text:"All mixer faders" )
        }))
        
        alert.addAction(UIAlertAction(title: "Toggle Record Arm", style: .default, handler: { (action: UIAlertAction!) in
            
            let alert2 = UIAlertController(title: "Record Arm", message: "Arm all tracks for record, on or off?", preferredStyle: UIAlertController.Style.alert)
            alert2.addAction(UIAlertAction(title: "On", style: .default, handler: { (action: UIAlertAction!) in
                let done = Transport.getCurrentDoc()?.toggleRecordArm( true )
                if( done != nil && done! == true )
                {
                    self.saveAndRefresh()
                }
            }))
            alert2.addAction(UIAlertAction(title: "Off", style: .default, handler: { (action: UIAlertAction!) in
                let done = Transport.getCurrentDoc()?.toggleRecordArm( false )
                if( done != nil && done! == true )
                {
                    self.saveAndRefresh()
                }
            }))
            alert2.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            }))
            self.present(alert2, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Delete ALL audio files", style: .destructive, handler: { (action: UIAlertAction!) in
            let alert2 = UIAlertController(title: "Are you sure?", message: "ALL audio will be removed, the tracks will be blank", preferredStyle: UIAlertController.Style.alert)
            alert2.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                let done = Transport.getCurrentDoc()?.removeAllAudio()
                if( done != nil && done! == true )
                {
                    self.saveAndRefresh()
                }
            }))
            alert2.addAction(UIAlertAction(title: "Yes, but leave guide track", style: .default, handler: { (action: UIAlertAction!) in
                let done = Transport.getCurrentDoc()?.removeAllAudio(true)
                if( done != nil && done! == true )
                {
                    self.saveAndRefresh()
                }
            }))
            alert2.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            }))
            self.present(alert2, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Enable/Disable iDevice Playback", style: .default, handler: { (action: UIAlertAction!) in
            let alert2 = UIAlertController(title: "Turn on iDevice playback?", message: "ALL channels will play through the iPhone/iPad/iPod speakers or headphones", preferredStyle: UIAlertController.Style.alert)
            alert2.addAction(UIAlertAction(title: "Enable", style: .default, handler: { (action: UIAlertAction!) in
                let done = Transport.getCurrentDoc()?.enableDisableiDeviceOnAllTracks(false,enable: true)
                if( done != nil && done! == true )
                {
                    self.saveAndRefresh()
                }
            }))
            alert2.addAction(UIAlertAction(title: "Enable, but leave the guide track", style: .default, handler: { (action: UIAlertAction!) in
                let done = Transport.getCurrentDoc()?.enableDisableiDeviceOnAllTracks(true,enable: true)
                if( done != nil && done! == true )
                {
                    self.saveAndRefresh()
                }
            }))
            alert2.addAction(UIAlertAction(title: "Disable", style: .default, handler: { (action: UIAlertAction!) in
                let done = Transport.getCurrentDoc()?.enableDisableiDeviceOnAllTracks(false,enable: false)
                if( done != nil && done! == true )
                {
                    self.saveAndRefresh()
                }
            }))
            alert2.addAction(UIAlertAction(title: "Disable, but leave the guide track", style: .default, handler: { (action: UIAlertAction!) in
                let done = Transport.getCurrentDoc()?.enableDisableiDeviceOnAllTracks(true,enable: false)
                if( done != nil && done! == true )
                {
                    self.saveAndRefresh()
                }
            }))
            alert2.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            }))
            self.present(alert2, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Enable/Disable Multi-Channel Playback", style: .default, handler: { (action: UIAlertAction!) in
            
            let alert2 = UIAlertController(title: "Turn on Multi-Channel playback?", message: "ALL channels will play through the external multi-channel devices", preferredStyle: UIAlertController.Style.alert)
            alert2.addAction(UIAlertAction(title: "Enable", style: .default, handler: { (action: UIAlertAction!) in
                let done = Transport.getCurrentDoc()?.enableDisableMultiChanOnAllTracks(false, enable: true)
                if( done != nil && done! == true )
                {
                    self.saveAndRefresh()
                }
            }))
            alert2.addAction(UIAlertAction(title: "Enable, but leave the guide track", style: .default, handler: { (action: UIAlertAction!) in
                let done = Transport.getCurrentDoc()?.enableDisableMultiChanOnAllTracks(true, enable: true)
                if( done != nil && done! == true )
                {
                    self.saveAndRefresh()
                }
            }))
            alert2.addAction(UIAlertAction(title: "Disable", style: .default, handler: { (action: UIAlertAction!) in
                let done = Transport.getCurrentDoc()?.enableDisableMultiChanOnAllTracks(false, enable: false)
                if( done != nil && done! == true )
                {
                    self.saveAndRefresh()
                }
            }))
            alert2.addAction(UIAlertAction(title: "Disable, but leave the guide track", style: .default, handler: { (action: UIAlertAction!) in
                let done = Transport.getCurrentDoc()?.enableDisableMultiChanOnAllTracks(true, enable: false)
                if( done != nil && done! == true )
                {
                    self.saveAndRefresh()
                }
            }))
            alert2.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            }))
            self.present(alert2, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Downmix all to Mono", style: .default, handler: { (action: UIAlertAction!) in
            
            let alert2 = UIAlertController(title: "Downmix all channels?", message: "Set all channels to mono downmix.\nThe guide track will pan to C and backing tracks are panned L for multi-track playback on single multi channel channels.", preferredStyle: UIAlertController.Style.alert)
            alert2.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                let done = Transport.getCurrentDoc()?.downMixMonoAllTracks()
                if( done != nil && done! == true )
                {
                    self.saveAndRefresh()
                }
            }))
            
            alert2.addAction(UIAlertAction(title: "Yes, but leave the guide track", style: .default, handler: { (action: UIAlertAction!) in
                let done = Transport.getCurrentDoc()?.downMixMonoAllTracks(true)
                if( done != nil && done! == true )
                {
                    self.saveAndRefresh()
                }
            }))
            
            alert2.addAction(UIAlertAction(title: "Downmix off, centre pan", style: .default, handler: { (action: UIAlertAction!) in
                let done = Transport.getCurrentDoc()?.downMixMonoAllTracks(true, on: false)
                if( done != nil && done! == true )
                {
                    self.saveAndRefresh()
                }
            }))
            
            alert2.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            }))
            self.present(alert2, animated: true, completion: nil)
        }))
        
        
        let pro = MuzomaProducts.store.isProductPurchased( "MuzomaProducer" )
        if(!pro)
        {
            for act in alert.actions
            {
                act.isEnabled = false
            }
        }
        
        let actCancel = UIAlertAction(title: pro ? "Cancel" : "Cancel (Producer Only)", style: .cancel, handler: { (action: UIAlertAction!) in
            //print("overwrite file Yes")
            do
            {
            }
        })
        alert.addAction(actCancel)
        
        
        alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        self.present(alert, animated: true, completion: {})
        
    }
    
    
    @IBAction func scrollToolbarsChanged(_ sender: AnyObject) {
        let maxScroll:CGFloat = stackViewWidth.constant
        let pos = ((scrollMixer.value * (Float)(maxScroll)) * -1)
        self.stackViewLeading.constant =  CGFloat(pos)
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        if( segue.destination.isKind(of: EditTracksViewController.self) )
        {
            let editor = (segue.destination as! EditTracksViewController)
            editor.muzomaDoc = Transport.getCurrentDoc()
            
            if( sender is FaderChannel)
            {
                let chan = sender as! FaderChannel
                editor._track = chan._trackNumber
            }
        } else
            if( segue.destination.isKind(of: TracksTableViewController.self) )
            {
                let editor = (segue.destination as! TracksTableViewController)
                editor.muzomaDoc = Transport.getCurrentDoc()
            } else if( segue.destination.isKind(of: ChordPickerController.self) )
            {
                let editor = (segue.destination as! ChordPickerController)
                editor.muzomaDoc = Transport.getCurrentDoc()
            } else if( segue.destination.isKind(of: EditDocumentViewController.self) )
            {
                let editor = (segue.destination as! EditDocumentViewController)
                editor.muzomaDoc = Transport.getCurrentDoc()
            } else if( segue.destination.isKind(of: EditorLinesController.self) )
            {
                let editor = (segue.destination as! EditorLinesController)
                editor.muzomaDoc = Transport.getCurrentDoc()
            } else if( segue.destination.isKind(of: EditTmingViewController.self) )
            {
                let editor = (segue.destination as! EditTmingViewController)
                editor.muzomaDoc = Transport.getCurrentDoc()
            } else if( segue.destination.isKind(of: PlayerDocumentViewController.self) )
            {
                let editor = (segue.destination as! PlayerDocumentViewController)
                editor.muzomaDoc = Transport.getCurrentDoc()
        }
    }
    
    func displayZipFilePicker()
    {
        let documentPicker: UIDocumentPickerViewController = UIDocumentPickerViewController(documentTypes: [kUTTypeURL as String, "public.zip", kUTTypeArchive as String], in: UIDocumentPickerMode.import)
        documentPicker.delegate = self
        documentPicker.title = "Select Audio Archive File"
        documentPicker.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    @IBAction func butImportClicked(_ sender: AnyObject) {
        let doc = Transport.getCurrentDoc()
        if( doc != nil )
        {
            _alert = UIAlertController(title: "Audio Import", message: "Actions for setting all audio files\n\nWARNING ALL TRACK AUDIO WILL BE AFFECTED\n\n(note - single track file assignement is achieved by double tapping a fader on the mixer)", preferredStyle: UIAlertController.Style.alert)
            
            _alert.addAction(UIAlertAction(title: "Cloud import zip for all audio", style: .destructive, handler: { (action: UIAlertAction!) in
                self.displayZipFilePicker()
            }))
            
            _alert.addAction(UIAlertAction(title: "Paste zip audio from AudioShare app", style: .destructive, handler: { (action: UIAlertAction!) in
                let ashare = AudioShare()
                self._audioShareTrackImport = true
                ashare.initiateSoundImport()
                
                self._alertAS = UIAlertController(title: "Waiting for AudioShare", message: "Waiting for paste from AudioShare app", preferredStyle: UIAlertController.Style.alert)
                
                self._alertAS.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                    self._audioShareTrackImport = false
                }))
                
                self._alertAS.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                self.present(self._alertAS, animated: true, completion: {})
            }))
            
            
            let pro = MuzomaProducts.store.isProductPurchased( "MuzomaProducer" )
            if(!pro)
            {
                for act in _alert.actions
                {
                    act.isEnabled = false
                }
            }
            
            let actCancel = UIAlertAction(title: pro ? "Cancel" : "Cancel (Producer Only)", style: .cancel, handler: { (action: UIAlertAction!) in
                //print("overwrite file Yes")
                do
                {
                }
            })
            _alert.addAction(actCancel)
            
            
            _alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            self.present(_alert, animated: true, completion: {})
        }
    }
    
    @objc func audioSharePaste(_ notification: Notification)
    {
        if( self._alertAS != nil )
        {
            DispatchQueue.main.async(execute: {
                let ashare = AudioShare()

                ashare.checkPendingImport(notification.object as! URL?, with: { ( tempfile ) in
                    Logger.log("audio share pasted \(String(describing: tempfile))")
                    
                    self._alertAS?.dismiss(animated: true, completion: nil)
                    self._alertAS = nil
                    
                    let delay = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                    DispatchQueue.main.asyncAfter(deadline: delay,execute: {
                        
                        let tempURL = URL(fileURLWithPath: tempfile!)
                        if( (tempURL as NSURL).filePathURL != nil )
                        {
                            let doc = Transport.getCurrentDoc()
                            if( tempURL.pathExtension == "zip")
                            {
                                _ = _gFSH.extractAudioTracksFromZip(doc, url: tempURL, removeZip: false)
                            } else if( tempURL.pathExtension == "mp3" || tempURL.pathExtension == "wav" || tempURL.pathExtension == "m4a" || tempURL.pathExtension == "caf" )
                            {
                                let alert = UIAlertController(title: "Import individual audio file", message: "For more direct assignment of individual audio files, double tap a fader to import the file on that track", preferredStyle: UIAlertController.Style.alert)
                                alert.addAction(UIAlertAction(title: "Continue with bulk style import", style: .default, handler: { (action: UIAlertAction!) in
                                    _ = _gFSH.extractAudioTracksFromZip(doc, url: tempURL, removeZip: false)
                                }))
                                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                                    
                                }))
                                self.present(alert, animated: true, completion: nil)
                            }
                        }
                    })
                })
            })
        }
    }
    
    
    @IBOutlet weak var butImport: UIBarButtonItem!
    @IBOutlet weak var butExport: UIBarButtonItem!
    
    var _openInController:UIDocumentInteractionController! = nil
    func displaySharePicker()
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addSpinnerView()
        DispatchQueue.main.async(execute: {
                        
                        let zip = _gFSH.getZipForAudioTracks( Transport.getCurrentDoc()! )
                        
                        if( zip != nil )
                        {
                            self._openInController = UIDocumentInteractionController(url: zip!) // don't use UIActivityViewController
                            self._openInController.presentOptionsMenu(from: self.butExport, animated: true)
                        }
                        appDelegate.removeSpinnerView()
        })
    }
    
    func displayAudioExportPicker()
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addSpinnerView()
        DispatchQueue.main.async(execute: {
                        let zip = _gFSH.getZipForAudioTracks( Transport.getCurrentDoc()! )
                        
                        if( zip != nil )
                        {
                            let documentPicker: UIDocumentPickerViewController = UIDocumentPickerViewController( url: zip!, in: UIDocumentPickerMode.exportToService)
                            documentPicker.delegate = self
                            documentPicker.title = "Export Audio Files"
                            documentPicker.modalPresentationStyle = UIModalPresentationStyle.fullScreen
                            self.present(documentPicker, animated: true, completion: nil)
                        }
                        appDelegate.removeSpinnerView()
        })
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL)
    {
        let doc = Transport.getCurrentDoc()
        if controller.documentPickerMode == UIDocumentPickerMode.import
        {
            if( url.isFileURL )
            {
                if( url.pathExtension == "zip")
                {
                    _ = _gFSH.extractAudioTracksFromZip(doc, url: url,removeZip: false)
                }
            }
        }
    }
    
    var _audioShareTrackImport = false
    var _alert:UIAlertController! = nil
    var _alertAS:UIAlertController! = nil
    @IBAction func butExportClicked(_ sender: AnyObject) {
        if(  Transport.getCurrentDoc() != nil )
        {
            _alert = UIAlertController(title: "Audio Export", message: "Actions for exporting all audio files.\n\n(note - single track file copy is achieved by double tapping a fader in the mixer)", preferredStyle: UIAlertController.Style.alert)
            
            let shareAudio = UIAlertAction(title: "Share audio zip", style: .default, handler: { (action: UIAlertAction!) in
                self.displaySharePicker()
            })
            _alert.addAction(shareAudio)
            
            let sendAudioCloud = UIAlertAction(title: "Send audio zip to the Cloud", style: .default, handler: { (action: UIAlertAction!) in
                self.displayAudioExportPicker()
            })
            _alert.addAction(sendAudioCloud)
            
            let copyToAudioShare = UIAlertAction(title: "Copy zip to AudioShare app", style: .default, handler: { (action: UIAlertAction!) in
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.addSpinnerView()
                DispatchQueue.main.async(execute: {
                        let zip = _gFSH.getZipForAudioTracks( Transport.getCurrentDoc()! )
                        let ashare = AudioShare()
                        ashare.addSound(from: zip, withName: zip?.lastPathComponent)
                        appDelegate.removeSpinnerView()
                })
            })

            _alert.addAction(copyToAudioShare)
            
            let pro = MuzomaProducts.store.isProductPurchased( "MuzomaProducer" )
            if(!pro)
            {
                for act in _alert.actions
                {
                    act.isEnabled = false
                }
            }
            
            let actCancel = UIAlertAction(title: pro ? "Cancel" : "Cancel (Producer Only)", style: .cancel, handler: { (action: UIAlertAction!) in
                //print("overwrite file Yes")
                do
                {
                }
            })
            _alert.addAction(actCancel)
            
            _alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            self.present(_alert, animated: true, completion: {})
        }
    }
}
