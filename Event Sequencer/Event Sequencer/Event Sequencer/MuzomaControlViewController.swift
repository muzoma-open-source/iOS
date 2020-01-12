//
//  MuzomaControlViewController.swift
//  Event Sequencer
//
//  Created by Matthew Hopkins on 05/04/2015.
//  Copyright (c) 2015 Muzoma.com. All rights reserved.
//
//  Muzoma Midi Remote Control view controller - allow the user to set up remote control parameters
//

import UIKit
import Foundation
import CoreFoundation
import CoreMIDI
import CoreAudioKit

import MediaPlayer
import AVFoundation
import MobileCoreServices
import MIKMIDI

// Midi Remote Control view controller - allow user to set up and learn midi control of the app
// Works in conjunction with MIK Midi 3rd party libaray
class MuzomaControlViewController:  UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, MIKMIDIMappingGeneratorDelegate
{
    fileprivate var _transport:Transport! = nil
    @IBOutlet weak var _scrollView: UIScrollView!
    
    // main code
    override func viewDidLoad() {
        super.viewDidLoad()
        setupControls()
        let pro = MuzomaProducts.store.isProductPurchased( "MuzomaProducer" )

        if(!pro)
        {
            self._scrollView.isUserInteractionEnabled = false
            
            let alert = UIAlertController(title: "Midi Feature", message: "The Midi feature is disabled, please upgrade or restore the Producer version to use this feature", preferredStyle: UIAlertController.Style.alert )
            
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
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    @IBOutlet weak var swShareAudio: UISwitch!
    
    @IBAction func swShareAudioChanged(_ sender: AnyObject) {
        UserDefaults.standard.set(swShareAudio.isOn, forKey: "shareAudio_preference")
    }
    
    @IBOutlet weak var swRunBackground: UISwitch!
    
    @IBAction func swRunBackgroundChanged(_ sender: AnyObject) {
        UserDefaults.standard.set(swRunBackground.isOn, forKey: "runBackground_preference")
    }
    
    
    @IBOutlet weak var swRespondToStopStart: UISwitch!
    @IBAction func swRespondToStopStartChanged(_ sender: AnyObject) {
        _gMidi.settings!.respondToStopStart =  self.swRespondToStopStart.isOn
        _ = _gFSH.saveControlSettings( _gMidi.settings! )
        setupControls()
    }
    
    @IBOutlet weak var swRespondToLearned: UISwitch!
    @IBAction func swRespondToLearnedChanged(_ sender: AnyObject) {
        _gMidi.settings!.respondToLearnedControls =  self.swRespondToLearned.isOn
        _ = _gFSH.saveControlSettings( _gMidi.settings! )
        setupControls()
    }
    
    @IBOutlet weak var swSendMMC: UISwitch!
    @IBAction func swSendMMCChanged(_ sender: Any) {
        _gMidi.settings!.sendMMC  =  self.swSendMMC.isOn
        _ = _gFSH.saveControlSettings( _gMidi.settings! )
        setupControls()
    }
    
    @IBOutlet weak var swRespondMMC: UISwitch!
    
    @IBAction func swRespondMMCChanged(_ sender: Any) {
        _gMidi.settings!.respondToMMC  =  self.swRespondMMC.isOn
        _ = _gFSH.saveControlSettings( _gMidi.settings! )
        setupControls()
    }
    
    //["Stop","Play","Next Track", "Prev Track", "Fast Forward", "Rewind"]
    var _learnAlert:UIAlertController! = nil
    func showLearnAlert( _ command:String, text:String )
    {
        _learnAlert = UIAlertController(title: "Learn midi command", message: "Learning midi command for \(text)...", preferredStyle: UIAlertController.Style.alert)
        _learnAlert.addAction(UIAlertAction(title: "Clear existing", style: .destructive, handler: { (action: UIAlertAction!) in
            _gMidi.clearExisting(_gMidi.transportControl, commandIdentifier: command)
            _gMidi.cancelMidiLearn()
        }))
        _learnAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            //print("Handle Cancel Logic here")
            _gMidi.cancelMidiLearn()
        }))
        
        _learnAlert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        let vc =  UIApplication.shared.keyWindow?.visibleViewController
        vc?.present(_learnAlert, animated: true, completion: {})
        _gMidi.startMidiLearn(_gMidi.transportControl, commandIdentifier: command)
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
                let vc =  UIApplication.shared.keyWindow?.visibleViewController
                vc?.present(_learnedAlert, animated: true, completion: {})
            }
            else
            {
                let _learnedAlert = UIAlertController(title: "Midi command learned", message: "\(item.commandIdentifier) command learned\n\nType: \(item.commandType.description)\nMidi channel #\(item.channel + 1), Control #\(item.controlNumber)\n", preferredStyle: UIAlertController.Style.alert)
                
                _learnedAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
                    item.additionalAttributes?.removeValue(forKey: "Byte2") // should be any value
                    _gMidi.saveMappingItem( item )
                }))
                
                _learnedAlert.addAction(UIAlertAction(title: "Forget this", style: .cancel, handler: { (action: UIAlertAction!) in
                    //_gMidi.clearExisting(_gMidi.transportControl, commandIdentifier: item.commandIdentifier)
                }))
                
                _learnedAlert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                let vc =  UIApplication.shared.keyWindow?.visibleViewController
                vc?.present(_learnedAlert, animated: true, completion: {})
            }
        })
    }
    
    @IBOutlet weak var butLearnPlay: UIButton!
    @IBAction func butLearnPlayPressed(_ sender: AnyObject) {
        showLearnAlert( "Play", text: "Play")
    }
    
    @IBOutlet weak var butLearnStop: UIButton!
    @IBAction func butLearnStopPressed(_ sender: AnyObject) {
        showLearnAlert( "Stop", text: "Stop")
    }
    
    @IBOutlet weak var butLearnSongSel: UIButton!
    @IBAction func butLearnSongSelPressed(_ sender: AnyObject) {
        showLearnAlert( "Song Select", text: "Song Select")
    }
    
    @IBOutlet weak var butNextSong: UIButton!
    @IBAction func butNextSongPressed(_ sender: AnyObject) {
        showLearnAlert( "Next Song", text: "Next Song")
    }
    
    @IBOutlet weak var butPreviousSong: UIButton!
    @IBAction func butPreviousSongPressed(_ sender: AnyObject) {
        showLearnAlert( "Previous Song", text: "Previous Song")
    }
    
    @IBOutlet weak var butRecord: UIButton!
    @IBAction func butRecordPressed(_ sender: AnyObject) {
        showLearnAlert( "Record", text: "Record")
    }
    
    @IBOutlet weak var butRewind: UIButton!
    @IBAction func butRewindPressed(_ sender: AnyObject) {
        showLearnAlert( "Rewind", text: "Rewind")
    }
    
    @IBOutlet weak var butFastFwd: UIButton!
    @IBAction func butFastFwdPressed(_ sender: AnyObject) {
        showLearnAlert( "Fast Forward", text: "Fast Forward")
    }
    
    @IBOutlet weak var butLearnFader: UIButton!
    @IBAction func butLearnFaderPressed(_ sender: AnyObject) {
        showLearnAlert( "Mix Fader", text: "Mix Fader")
    }
    
    @IBOutlet weak var swRespondToMixerFader: UISwitch!
    @IBAction func swRespondToMixerFaderPressed(_ sender: AnyObject) {
        _gMidi.settings!.respondToMixerFader =  self.swRespondToMixerFader.isOn
        _ = _gFSH.saveControlSettings( _gMidi.settings! )
        setupControls()
    }
    
    @IBOutlet weak var swSendStopStart: UISwitch!
    
    @IBAction func swSendStopStartChangedChanged(_ sender: AnyObject) {
        _gMidi.settings!.sendStopStart = self.swSendStopStart.isOn
        _ = _gFSH.saveControlSettings( _gMidi.settings! )
        setupControls()
    }
    
    @IBOutlet weak var swSendLearned: UISwitch!
    
    @IBAction func swSendLearned(_ sender: AnyObject) {
        _gMidi.settings!.sendLearnedControls = self.swSendLearned.isOn
        _ = _gFSH.saveControlSettings( _gMidi.settings! )
        setupControls()
    }
    
    @IBOutlet weak var swSendLearnedMixerFader: UISwitch!
    
    @IBAction func swSendLearnedMixerFaderChanged(_ sender: AnyObject) {
        _gMidi.settings!.sendLearnedMixerFader = self.swSendLearnedMixerFader.isOn
        _ = _gFSH.saveControlSettings( _gMidi.settings! )
        setupControls()
    }
    
    @IBOutlet weak var selControlMidiInPort: UIPickerView!
    @IBOutlet weak var selControlMidiOutPort: UIPickerView!
    
    @IBOutlet weak var labMidiIn: UILabel!
    @IBOutlet weak var labMidiOut: UILabel!
    
    
    override func viewDidAppear(_ animated: Bool) {
        _transport = Transport( viewController: self, includeExtControlButton: true )
        _gNC.addObserver(self, selector: #selector(MuzomaControlViewController._midiSetupChanged(_:)), name: NSNotification.Name(rawValue: "MIKMIDIDeviceWasAddedNotification"), object: nil)
        _gNC.addObserver(self, selector: #selector(MuzomaControlViewController._midiSetupChanged(_:)), name: NSNotification.Name(rawValue: "MIKMIDIDeviceWasRemovedNotification"), object: nil)
        _gNC.addObserver(self, selector: #selector(MuzomaControlViewController._midiSetupChanged(_:)), name: NSNotification.Name(rawValue: "MIKMIDIVirtualEndpointWasAddedNotification"), object: nil)
        _gNC.addObserver(self, selector: #selector(MuzomaControlViewController._midiSetupChanged(_:)), name: NSNotification.Name(rawValue: "MIKMIDIVirtualEndpointWasRemovedNotification"), object: nil)
        _gNC.addObserver(self, selector: #selector(MuzomaControlViewController._midiMappingLearned(_:)), name: NSNotification.Name(rawValue: "MidiMappingLearned"), object: nil)
        
        midiSetupChanged()
        return super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        _gNC.removeObserver( self, name: NSNotification.Name(rawValue: "MIKMIDIDeviceWasAddedNotification"), object: nil )
        _gNC.removeObserver( self, name: NSNotification.Name(rawValue: "MIKMIDIDeviceWasRemovedNotification"), object: nil )
        _gNC.removeObserver( self, name: NSNotification.Name(rawValue: "MIKMIDIVirtualEndpointWasAddedNotification"), object: nil )
        _gNC.removeObserver( self, name: NSNotification.Name(rawValue: "MIKMIDIVirtualEndpointWasRemovedNotification"), object: nil )
        _gNC.removeObserver( self, name: NSNotification.Name(rawValue: "MidiMappingLearned"), object: nil )
        _transport?.willDeinit()
        _transport = nil
        return( super.viewDidDisappear(animated) )
    }
    
    
    @objc func _midiSetupChanged(_ notification: Notification) {
        DispatchQueue.main.async(execute: {
                        self.midiSetupChanged()
        })
    }
    
    @objc func _midiMappingLearned(_ notification: Notification) {
        DispatchQueue.main.async(execute: {
            if( notification.object != nil && notification.object is MIKMIDIMappingItem )
            {
                let item:MIKMIDIMappingItem = notification.object as! MIKMIDIMappingItem
                self.midiMappingLearned( item )
            }
        })
    }
    
    
    
    var _allMidiInDevices:[MIKMIDISourceEndpoint?] = [MIKMIDISourceEndpoint?]()
    
    var _activeMidiInDevice:String!
    {
        get
        {
            return(_gMidi.activeMidiInName)
        }
    }
    var _activeMidiInDeviceIdx:Int
        {
        get{
            var idx = -1
            
            var count = 0
            if( _activeMidiInDevice != nil )
            {
                for dev in _allMidiInDevices
                {
                    if( dev?.displayName == _activeMidiInDevice )
                    {
                        idx = count
                        break;
                    }
                    count += 1
                }
            }
            return( idx )
        }
    }
    
    var _allMidiOutDevices:[MIKMIDIDestinationEndpoint?] = [MIKMIDIDestinationEndpoint?]()
    var _activeMidiOutDevice:String!
        {
        get
        {
            return(_gMidi.activeMidiOutName)
        }
    }
    var _activeMidiOutDeviceIdx:Int
        {
        get{
            var idx = -1
            
            var count = 0
            if( _activeMidiOutDevice != nil )
            {
                for dev in _allMidiOutDevices
                {
                    if( dev?.displayName == _activeMidiOutDevice )
                    {
                        idx = count
                        break;
                    }
                    count += 1
                }
            }
            return( idx )
        }
    }
    
    func midiSetupChanged()
    {
        _allMidiInDevices = _gMidi.getMidiDeviceIns()
        _allMidiOutDevices = _gMidi.getMidiDeviceOuts()
        
        setupControls()
    }
    
    var doneSave = false
    @IBAction func doneClicked(_ sender: AnyObject) {
        captureChanges()
        navigationController?.popViewController(animated: true)
    }
    
    func captureChanges()
    {
        doneSave = true
    }
    
    func setupControls()
    {
        swRunBackground.isOn = UserDefaults.standard.bool(forKey: "runBackground_preference")
        swShareAudio.isOn = UserDefaults.standard.bool(forKey: "shareAudio_preference")
        selControlMidiInPort.reloadAllComponents()
        selControlMidiInPort.selectRow(_activeMidiInDeviceIdx + 1, inComponent: 0, animated: false)
        labMidiIn.text = _activeMidiInDevice
        labMidiIn.isEnabled = _activeMidiInDeviceIdx > -1
        
        selControlMidiOutPort.reloadAllComponents()
        selControlMidiOutPort.selectRow(_activeMidiOutDeviceIdx + 1, inComponent: 0, animated: false)
        labMidiOut.text = _activeMidiOutDevice
        labMidiOut.isEnabled =  _activeMidiOutDeviceIdx > -1
        
        if(_gMidi.settings != nil )
        {
            self.swRespondToStopStart.isOn = _gMidi.settings!.respondToStopStart
            self.swSendStopStart.isOn = _gMidi.settings!.sendStopStart
            
            self.swRespondMMC.isOn = _gMidi.settings!.respondToMMC
            self.swSendMMC.isOn = _gMidi.settings!.sendMMC
            
            self.swRespondToLearned.isOn = _gMidi.settings!.respondToLearnedControls
            self.swSendLearned.isOn = _gMidi.settings!.sendLearnedControls
            
            self.swRespondToMixerFader.isOn = _gMidi.settings!.respondToMixerFader
            self.swSendLearnedMixerFader.isOn = _gMidi.settings!.sendLearnedMixerFader
        }
    }
    
    // picker view
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView
    {
        let pickerLabel = UILabel()
        pickerLabel.textColor = UIColor.black
        
        if( pickerView == selControlMidiInPort )
        {
            if( row == 0 )
            {
                pickerLabel.text = "No additional midi port"
            }
            else
            {
                pickerLabel.text = _allMidiInDevices[row-1]?.displayName
            }
        } else if( pickerView == selControlMidiOutPort )
        {
            if( row == 0 )
            {
                pickerLabel.text = "No additional midi port"
            }
            else
            {
                pickerLabel.text = _allMidiOutDevices[row-1]?.displayName
            }
        } else
        {
            pickerLabel.text = "placeholder"
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
        
        if( pickerView == selControlMidiInPort )
        {
            ret = _allMidiInDevices.count + 1
        } else if( pickerView == selControlMidiOutPort )
        {
            ret = _allMidiOutDevices.count + 1
        }
        else
        {
            ret = 0
        }
        return ret
    }
    
    func pickerView( _ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int ) -> String? {
        
        var ret = ""
        
        if( pickerView == selControlMidiInPort )
        {
            ret = "Midi In"
        } else if( pickerView == selControlMidiOutPort )
        {
            ret = "Midi Out"
        }
        else
        {
            ret = "title"
        }
        
        return ret
    }
    
    func pickerView( _ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int )
    {
        // user changed the picker row
        
        if( pickerView == selControlMidiInPort )
        {
            let sel = (row > 0 ? _allMidiInDevices[row-1]?.displayName : "No additional midi port")
            Logger.log("selControlMidiInPort \(String(describing: sel))")
            if( sel == "No additional midi port" || _gMidi.selectMidiInByName(sel!) != nil )
            {
                labMidiIn.text = sel
                labMidiIn.isEnabled = true
                _ = _gFSH.saveControlSettings(_gMidi.settings)
            }
        } else if( pickerView == selControlMidiOutPort )
        {
            let sel = (row > 0 ? _allMidiOutDevices[row-1]?.displayName : "No additional midi port")
            Logger.log("selControlMidiOutPort \(String(describing: sel))")
            if(  sel == "No additional midi port" || _gMidi.selectMidiOutByName(sel!) != nil )
            {
                labMidiOut.text = sel
                labMidiOut.isEnabled = true
                _ = _gFSH.saveControlSettings(_gMidi.settings)
            }
        }
    }
    
    override func willMove(toParent parent: UIViewController?) {
        
        // called when shown and exiting, on exit parent is nil
        if( parent == nil)
        {
            //print("Back Button Pressed Editor!")
        }
        super.willMove(toParent: parent)
    }
    
    
    var localPeripheralViewController:CABTMIDILocalPeripheralViewController?
    var centralViewController:CABTMIDICentralViewController?
    
    @IBAction func blueToothHostConfigPressed(_ sender: AnyObject) {
        localPeripheralViewController = CABTMIDILocalPeripheralViewController()
        self.navigationController?.pushViewController(localPeripheralViewController!, animated: true)
    }
    
    
    @IBAction func blueToothClientConfigPressed(_ sender: AnyObject){
        centralViewController = CABTMIDICentralViewController()
        self.navigationController?.pushViewController(centralViewController!, animated: true)
    }
}

