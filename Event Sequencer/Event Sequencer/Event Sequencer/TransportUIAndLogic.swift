//
//  TransportUIAndLogic.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 27/06/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//
//  Muzoma's transport panel - handle the UI transport and translate that to audio commands
//
//

import UIKit
import Foundation
import CoreFoundation
import MediaPlayer
import AVFoundation
import MobileCoreServices
import MIKMIDI

class Transport
{
    let nc = NotificationCenter.default
    static var _MPService:MuzomaMPServiceManager! = nil
    
    var controllerLabel:UILabel! = nil
    var statusLabel:UILabel! = nil
    var progressTime: UIProgressView! = nil
    var rewindButton:UIBarButtonItem! = nil
    var playButton:UIBarButtonItem! = nil
    var pauseButton:UIBarButtonItem! = nil
    var stopButton:UIBarButtonItem! = nil
    var ffwdButton:UIBarButtonItem! = nil
    var variSpeedButton:UIBarButtonItem! = nil
    var guideTrackSelectButton:UIBarButtonItem! = nil
    var bandSelectButton:UIBarButtonItem! = nil
    var recordTimingButton:UIBarButtonItem! = nil
    var loopButton:UIBarButtonItem! = nil
    var recordAudioButton:UIBarButtonItem! = nil
    var extControlSelectButton:UIBarButtonItem! = nil
    var _monitor:MonitorAudio! = nil
    var _monitorRequired = false
    
    var vc:UIViewController! = nil
    var inLoop = UserDefaults.standard.bool(forKey: "setPlayerLoopOn_preference")
    
    fileprivate static var _muzomaDoc : MuzomaDocument! = nil
    var muzomaDoc : MuzomaDocument! {
        set
        {
            if( newValue != nil && !newValue!._isSlaveForBandPlay ) // send for band play?
            {
                Transport._MPService?.sendDoc(newValue)
            }
            
            if( Transport._muzomaDoc != newValue )
            {
                if( Transport._muzomaDoc != nil )
                {
                    if( Transport._muzomaDoc.isPlaying() )
                    {
                        Transport._muzomaDoc.stop()
                        Transport._muzomaDoc = nil
                    }
                }
                
                if( self.isSetPlayer && muzomaSetDoc != nil && newValue != nil )
                {
                    newValue._fromSetTitled = muzomaSetDoc._title
                    newValue._fromSetArtist = muzomaSetDoc._artist
                    newValue._fromSetTrackIdx =  muzomaSetDoc.muzDocs.index(of: newValue)
                    newValue._fromSetTrackCount = muzomaSetDoc.muzDocs.count
                    self.nc.post(name: Notification.Name(rawValue: "SetSelectSong"), object: newValue)
                }
                
                newValue?.fillMediaInfo( 0, stopping:true)
                Transport._muzomaDoc = newValue
            }
            
            monitor()
            updateStateFromDoc()
        }
        
        get
        {
            return Transport._muzomaDoc
        }
    }
    
    static func getCurrentDoc() -> MuzomaDocument!
    {
        return( _muzomaDoc )
    }
    
    func monitor()
    {
        if( _monitor != nil )
        {
            _monitor?.end()
            _monitor = nil
        }
        
        if( _monitorRequired && Transport._muzomaDoc != nil)
        {
            _monitor = MonitorAudio( guideTrackSpecifics: Transport._muzomaDoc?.getGuideTrackSpecifics(), backingTrackSpecifics: Transport._muzomaDoc.getBackingTrackSpecifics(), recordArmed: Transport._muzomaDoc != nil ? Transport._muzomaDoc!._recordArmed : false, recording: Transport._muzomaDoc.isPlaying() && Transport._muzomaDoc!._recordArmed )
        }
    }
    
    fileprivate static var _muzomaSetDoc : MuzomaSetDocument! = nil
    var muzomaSetDoc : MuzomaSetDocument! {
        set
        {
            if( Transport._muzomaSetDoc != newValue )
            {
                if( Transport._muzomaSetDoc != nil )
                {
                    //print( "nulling current set doc" )
                    Transport._muzomaSetDoc.deactivate()
                    Transport._muzomaSetDoc = nil
                }
                Transport._muzomaSetDoc = newValue
                Transport._muzomaSetDoc?.activate()
                Transport._muzomaSetDoc?._loopSet = self.inLoop
            }
            else
            {
                self.inLoop =  Transport._muzomaSetDoc != nil ? (Transport._muzomaSetDoc?._loopSet)! : false
            }
            updateStateFromDoc()
        }
        
        get
        {
            return Transport._muzomaSetDoc
        }
    }
    
    func armRecord()
    {
        self.muzomaDoc?.armRecord()
        self.monitor()
    }
    
    func dearmRecord()
    {
        self.muzomaDoc?.dearmRecord()
        self.monitor()
    }
    
    fileprivate var isSetPlayer:Bool = false
    let remote:MPRemoteCommandCenter! = MPRemoteCommandCenter.shared()
    
    fileprivate var _hideAllControls = false
    
    static let midiControlImg = UIImage(named: "midi control 4.png")
    static let midiIOImg = UIImage(named: "midi in midi out control 4.png")
    static let midiInImg = UIImage(named: "midi in control 4.png")
    static let midiOutImg = UIImage(named: "midi out control 4.png")
    
    init( viewController:UIViewController?, includeVarispeedButton:Bool = false, includeRecordTimingButton:Bool = false, isSetPlayer:Bool = false,
          includeGuideTrackSelectButton:Bool = false, includeBandSelectButton:Bool = false, includeExtControlButton:Bool = false, includeLoopButton:Bool = false, hideAllControls:Bool = false,
          includeRecordAudioButton:Bool = false )
    {
        _hideAllControls = hideAllControls
        _monitorRequired = false
        self.vc = viewController
        self.isSetPlayer = isSetPlayer
        
        Transport._MPService?.delegate = self
        Transport._MPService?._transport = self
        
        if( !_hideAllControls )
        {
            //extControlSelectButton = UIBarButtonItem(title: "🎛" /*"📣🎚🎛🎙💿🎹🎤🎵🔊"*/, style: UIBarButtonItemStyle.Plain, target: self, action:  #selector(Transport.extControlSelectPressed(_:)))
            
            extControlSelectButton = UIBarButtonItem(image: Transport.midiControlImg, landscapeImagePhone: Transport.midiControlImg, style: UIBarButtonItem.Style.plain, target: self, action:  #selector(Transport.extControlSelectPressed(_:)))
            
            //extControlSelectButton.tintColor = UIColor.blueColor()
            //extControlSelectButton.setTitleTextAttributes( [NSFontAttributeName:UIFont(name:"Courier-Bold", size: 22)!], forState: .Normal)
            extControlSelectButton.isEnabled = true
            
            rewindButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.rewind, target: self, action: #selector(Transport.rewindPressed(_:)))
            rewindButton.isEnabled = false
            
            playButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.play, target: self, action: #selector( Transport.playButtonPressed(_:) ))
            playButton.isEnabled = false
            //playButton.setBackgroundImage( Transport.midiIOImg, forState: .Normal, barMetrics: .Default)
            //playButton.setBackgroundImage( Transport.midiControlImg, forState: .Highlighted, barMetrics: .Default)
            
            /*
             playButton = UIBarButtonItem(image: UIImage( named: "btn-preview-press-lg@3x.png" ), landscapeImagePhone: UIImage( named:  "btn-preview-press-lg@3x.png"), style: .Plain, target: self, action: #selector(Transport.playPressed(_:)))
             playButton.enabled = false
             */
            pauseButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.pause, target: self, action: #selector(Transport.pausePressed(_:)))
            pauseButton.isEnabled = false
            
            stopButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.stop, target: self, action: #selector(Transport.stopButtonPressed(_:)))
            stopButton.isEnabled = false
            
            ffwdButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.fastForward, target: self, action: #selector(Transport.fastfwdPressed(_:)))
            ffwdButton.isEnabled = false
            
            variSpeedButton = UIBarButtonItem(title: "½>", style: UIBarButtonItem.Style.plain, target: self, action:  #selector(Transport.variSpeedPressed(_:)))
            variSpeedButton.isEnabled = false
            
            recordTimingButton = UIBarButtonItem(title: "REC", style: UIBarButtonItem.Style.plain, target: self, action:  #selector(Transport.recordTimingPressed(_:)))
            recordTimingButton.isEnabled = false
            
            recordAudioButton = UIBarButtonItem(title: "◉", style: UIBarButtonItem.Style.plain, target: self, action:  #selector(Transport.recordAudioPressed(_:)))
            recordAudioButton.isEnabled = false
            
            loopButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.refresh, target: self, action:  #selector(Transport.loopPressed(_:)))
            loopButton.isEnabled = true
            
            guideTrackSelectButton = UIBarButtonItem(title: "📀" /*"📣🎚🎛🎙💿🎹🎤🎵🔊"*/, style: UIBarButtonItem.Style.plain, target: self, action:  #selector(Transport.guideTrackSelectPressed(_:)))
            guideTrackSelectButton.tintColor = UIColor.blue
            guideTrackSelectButton.setTitleTextAttributes( convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font):UIFont(name:"Courier-Bold", size: 22)!]), for: UIControl.State())
            guideTrackSelectButton.isEnabled = false
            
            bandSelectButton = UIBarButtonItem(title: "Band", style: UIBarButtonItem.Style.plain, target: self, action:  #selector(Transport.bandSelectPressed(_:)))
            bandSelectButton.tintColor = UIColor.blue
            bandSelectButton.setTitleTextAttributes( convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font):UIFont(name:"Courier", size: 14)!]), for: UIControl.State())
            bandSelectButton.isEnabled = false
            
            var toolbarButtons = [UIBarButtonItem]()
            
            
            if( includeExtControlButton )
            {
                toolbarButtons.append(extControlSelectButton!)
                //toolbarButtons.append(UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil) )
            }
            
            toolbarButtons.append( UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil) )
            toolbarButtons.append( rewindButton! )
            toolbarButtons.append( UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil) )
            toolbarButtons.append( playButton! )
            toolbarButtons.append(UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil) )
            
            if( includeVarispeedButton )
            {
                toolbarButtons.append(variSpeedButton!)
                toolbarButtons.append(UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil) )
            }
            
            if( includeRecordTimingButton )
            {
                toolbarButtons.append(recordTimingButton!)
                toolbarButtons.append(UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil) )
            }
            
            if( includeRecordAudioButton )
            {
                toolbarButtons.append(recordAudioButton!)
                toolbarButtons.append(UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil) )
                _monitorRequired = true
                monitor()
            }
            
            /* pauseButton!,
             UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil),
             */
            
            toolbarButtons.append(stopButton!)
            toolbarButtons.append(UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil))
            toolbarButtons.append(ffwdButton!)
            toolbarButtons.append(UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil))
            
            if( includeGuideTrackSelectButton )
            {
                toolbarButtons.append(guideTrackSelectButton!)
                toolbarButtons.append(UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil) )
            }
            
            if( includeBandSelectButton )
            {
                toolbarButtons.append(bandSelectButton!)
                //toolbarButtons.append(UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil) )
            }
            
            if( includeLoopButton )
            {
                toolbarButtons.append(loopButton!)
                toolbarButtons.append(UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil) )
            }
            
            vc.setToolbarItems(toolbarButtons, animated: true)
        }
        
        progressTime = UIProgressView( frame: CGRect(x: 0, y: -1, width: (vc.navigationController!.toolbar.frame.size.width), height: 2) )
        progressTime.backgroundColor = UIColor.white
        progressTime.autoresizingMask = [.flexibleWidth]
        
        // Do any additional setup after loading the view, typically from a nib.
        controllerLabel = UILabel(frame: CGRect(x: 0, y: -20, width: (vc.navigationController!.toolbar.frame.size.width), height: 21))
        controllerLabel.textAlignment = NSTextAlignment.center
        controllerLabel.text = "--:--:--:--"
        controllerLabel.backgroundColor = UIColor.white
        controllerLabel.autoresizingMask = [.flexibleWidth]
        
        // Do any additional setup after loading the view, typically from a nib.
        statusLabel = UILabel(frame: CGRect(x: 0, y: -20, width: (vc.navigationController!.toolbar.frame.size.width), height: 21))
        statusLabel.textAlignment = NSTextAlignment.center
        statusLabel.text = "[status]"
        statusLabel.backgroundColor = UIColor.white
        statusLabel.autoresizingMask = [.flexibleWidth]
        statusLabel.isHidden = true
        
        vc.navigationController!.toolbar.clipsToBounds = false
        vc.navigationController!.toolbar.autoresizesSubviews = true
        vc.navigationController!.toolbar.addSubview(controllerLabel)
        vc.navigationController!.toolbar.addSubview(statusLabel)
        vc.navigationController!.toolbar.addSubview(progressTime)
        
        nc.addObserver(self, selector: #selector(Transport.playerTicked(_:)), name: NSNotification.Name(rawValue: "PlayerTick"), object: nil)
        nc.addObserver(self, selector: #selector(Transport.playerPlayed(_:)), name: NSNotification.Name(rawValue: "PlayerPlay"), object: nil)
        nc.addObserver(self, selector: #selector(Transport.playerPlayVarispeed(_:)), name: NSNotification.Name(rawValue: "PlayerPlayVarispeed"), object: nil)
        nc.addObserver(self, selector: #selector(Transport.playerStopped(_:)), name: NSNotification.Name(rawValue: "PlayerStop"), object: nil)
        nc.addObserver(self, selector: #selector(Transport.playerEnded(_:)), name: NSNotification.Name(rawValue: "SongEnded"), object: nil)
        nc.addObserver(self, selector: #selector(Transport.playerFastForward(_:)), name: NSNotification.Name(rawValue: "PlayerFastForward"), object: nil)
        nc.addObserver(self, selector: #selector(Transport.playerRewind(_:)), name: NSNotification.Name(rawValue: "PlayerRewind"), object: nil)
        nc.addObserver(self, selector: #selector(Transport.statusUpdate(_:)), name: NSNotification.Name(rawValue: "StatusUpdate"), object: nil)
        
        nc.addObserver(self, selector: #selector(Transport._playPressed(_:)), name: NSNotification.Name(rawValue: "ControlStartSent"), object: nil)
        nc.addObserver(self, selector: #selector(Transport._stopPressed(_:)), name: NSNotification.Name(rawValue: "ControlStopSent"), object: nil)
        nc.addObserver(self, selector: #selector(Transport._playPressed(_:)), name: NSNotification.Name(rawValue: "ControlContinueSent"), object: nil)
        nc.addObserver(self, selector: #selector(Transport._songSelectPressed(_:)), name: NSNotification.Name(rawValue: "ControlSongSelectSent"), object: nil)
        nc.addObserver(self, selector: #selector(Transport._nextSongPressed(_:)), name: NSNotification.Name(rawValue: "ControlNextSongSent"), object: nil)
        nc.addObserver(self, selector: #selector(Transport._previousSongPressed(_:)), name: NSNotification.Name(rawValue: "ControlPreviousSongSent"), object: nil)
        nc.addObserver(self, selector: #selector(Transport._recordPressed(_:)), name: NSNotification.Name(rawValue: "ControlRecordSent"), object: nil)
        nc.addObserver(self, selector: #selector(Transport._rewindPressed(_:)), name: NSNotification.Name(rawValue: "ControlRewindSent"), object: nil)
        nc.addObserver(self, selector: #selector(Transport._fastForwardPressed(_:)), name: NSNotification.Name(rawValue: "ControlFastForwardSent"), object: nil)
        
        // MMC
        nc.addObserver(self, selector: #selector(Transport._playPressed(_:)), name: NSNotification.Name(rawValue: "MMCStartSent"), object: nil)
        nc.addObserver(self, selector: #selector(Transport._stopPressed(_:)), name: NSNotification.Name(rawValue: "MMCStopSent"), object: nil)
        nc.addObserver(self, selector: #selector(Transport._stopPressed(_:)), name: NSNotification.Name(rawValue: "MMCPauseSent"), object: nil)
        nc.addObserver(self, selector: #selector(Transport._rewindPressed(_:)), name: NSNotification.Name(rawValue: "MMCRewindSent"), object: nil)
        nc.addObserver(self, selector: #selector(Transport._fastForwardPressed(_:)), name: NSNotification.Name(rawValue: "MMCFastForwardSent"), object: nil)
        nc.addObserver(self, selector: #selector(Transport._recordPressed(_:)), name: NSNotification.Name(rawValue: "MMCRecordStrobeSent"), object: nil)
        nc.addObserver(self, selector: #selector(Transport._recordPressed(_:)), name: NSNotification.Name(rawValue: "MMCRecordExitSent"), object: nil)
        nc.addObserver(self, selector: #selector(Transport._stopPressed(_:)), name: NSNotification.Name(rawValue: "MMCRecordPauseSent"), object: nil)
        
        nc.addObserver(self, selector: #selector(Transport._faderControlSent(_:)), name: NSNotification.Name(rawValue: "FaderControlSent"), object: nil)
        
        nc.addObserver(self, selector: #selector(Transport._MidiStateChange(_:)), name: NSNotification.Name(rawValue: "MidiStateChange"), object: nil)
        
        remote.playCommand.addTarget( handler: self.remotePlay )
        remote.pauseCommand.addTarget( handler: self.remotePause )
        remote.togglePlayPauseCommand.addTarget( handler: self.remotePlayPause )
        remote.stopCommand.addTarget( handler: self.remoteStop )
        remote.nextTrackCommand.addTarget( handler: self.remoteSeekNext )
        remote.previousTrackCommand.addTarget( handler: self.remoteSeekPrev )
        remote.seekForwardCommand.addTarget( handler: self.remoteFastFwd )
        remote.seekBackwardCommand.addTarget( handler: self.remoteRewind )
        if #available(iOS 9.1, *) {
            remote.changePlaybackPositionCommand.addTarget( handler: self.remoteSeek )
        } else {
            // Fallback on earlier versions
        }
        
        updateStateFromDoc()
        // doesn't work navigationController?.setToolbarItems(toolbarButtons, animated: true)// toolbar.setItems(toolbarButtons, animated: true)
    }
    
    @objc func _MidiStateChange(_ notification: Notification)
    {
        if( self.extControlSelectButton != nil && notification.object is ObservableMidiIOState?)
        {
            DispatchQueue.main.async(execute: {
                
                let state = notification.object as! ObservableMidiIOState?
                if( state != nil )
                {
                    switch( state?.midiIOState )
                    {
                    case MidiIOState.None?:
                        self.extControlSelectButton!.image = Transport.midiControlImg
                        break;
                    case MidiIOState.MidiInRx?:
                        self.extControlSelectButton!.image = Transport.midiInImg
                        break;
                    case MidiIOState.MidiOutTx?:
                        self.extControlSelectButton!.image = Transport.midiOutImg
                        break;
                    case MidiIOState.MidiInOutRxTx?:
                        self.extControlSelectButton!.image = Transport.midiIOImg
                        break;
                    default:
                        self.extControlSelectButton!.image = Transport.midiControlImg
                        break;
                        
                    }
                    //self.extControlSelectButton!.tintColor = UIColor.redColor()
                }
            })
        }
    }
    
    @objc func _faderControlSent(_ notification: Notification)
    {
        if( notification.object is MidiValueObject?)
        {
            let faderValue:MidiValueObject! = notification.object as! MidiValueObject?
            let audioTracks = self.muzomaDoc?.getAudioTrackIndexes()
            if( audioTracks != nil && faderValue.commandIdx < audioTracks!.count )
            {
                self.muzomaDoc?.setTrackVolume(audioTracks![faderValue.commandIdx], volume: Float( faderValue.value ) * (1.00 / 127))
            }
        }
    }
    
    
    @objc func bandSelectPressed(_ sender:UIButton!) {
        //print( "bandSelectPressed pressed" )
        DispatchQueue.main.async(execute: {
            if( Transport._MPService == nil )
            {
                self.updateBandButtonState(true)
                Transport._MPService = MuzomaMPServiceManager()
                Transport._MPService.delegate = self
                Transport._MPService._transport = self
            }
            else if( Transport._MPService != nil )
            {
                Transport._MPService = nil
                self.updateBandButtonState()
            }
        })
    }
    
    // notify that the toolbar will de-initialize
    // esure we do this on UI thread and make sure that we notify the update ui component using inDeinit
    
    fileprivate  var _didDeinit = false
    
    func willDeinit()
    {
        objc_sync_enter(self)
        if( !_didDeinit )
        {
            _didDeinit = true
            self.nc.removeObserver( self, name: NSNotification.Name(rawValue: "PlayerTick"), object: nil )
            self.nc.removeObserver( self, name: NSNotification.Name(rawValue: "PlayerPlay"), object: nil )
            self.nc.removeObserver( self, name: NSNotification.Name(rawValue: "PlayerPlayVarispeed"), object: nil )
            self.nc.removeObserver( self, name: NSNotification.Name(rawValue: "PlayerStop"), object: nil )
            self.nc.removeObserver( self, name: NSNotification.Name(rawValue: "SongEnded"), object: nil )
            self.nc.removeObserver( self, name: NSNotification.Name(rawValue: "PlayerFastForward"), object: nil )
            self.nc.removeObserver( self, name: NSNotification.Name(rawValue: "PlayerRewind"), object: nil )
            self.nc.removeObserver( self, name: NSNotification.Name(rawValue: "StatusUpdate"), object: nil )
            
            self.nc.removeObserver( self, name: NSNotification.Name(rawValue: "ControlStartSent"), object: nil )
            self.nc.removeObserver( self, name: NSNotification.Name(rawValue: "ControlStopSent"), object: nil )
            self.nc.removeObserver( self, name: NSNotification.Name(rawValue: "ControlContinueSent"), object: nil )
            self.nc.removeObserver( self, name: NSNotification.Name(rawValue: "ControlSongSelectSent"), object: nil )
            self.nc.removeObserver( self, name: NSNotification.Name(rawValue: "ControlNextSongSent"), object: nil )
            self.nc.removeObserver( self, name: NSNotification.Name(rawValue: "ControlPreviousSongSent"), object: nil )
            self.nc.removeObserver( self, name: NSNotification.Name(rawValue: "ControlRecordSent"), object: nil )
            self.nc.removeObserver( self, name: NSNotification.Name(rawValue: "ControlRewindSent"), object: nil )
            self.nc.removeObserver( self, name: NSNotification.Name(rawValue: "ControlFastForwardSent"), object: nil )
            self.nc.removeObserver( self, name: NSNotification.Name(rawValue: "MidiStateChange"), object: nil )
            
            self.nc.removeObserver( self, name: NSNotification.Name(rawValue: "FaderControlSent"), object: nil )
            
            self.remote?.playCommand.removeTarget( nil )
            self.remote?.pauseCommand.removeTarget( nil )
            self.remote?.togglePlayPauseCommand.removeTarget(nil)
            self.remote?.stopCommand.removeTarget( nil )
            self.remote?.nextTrackCommand.removeTarget( nil )
            self.remote?.previousTrackCommand.removeTarget( nil )
            self.remote?.seekForwardCommand.removeTarget( nil )
            self.remote?.seekBackwardCommand.removeTarget( nil )
            if #available(iOS 9.1, *) {
                self.remote?.changePlaybackPositionCommand.removeTarget(nil)
            } else {
                // Fallback on earlier versions
            }
            
            self.controllerLabel.removeFromSuperview()
            self.controllerLabel = nil
            self.statusLabel.removeFromSuperview()
            self.statusLabel = nil
            self.progressTime.removeFromSuperview()
            self.progressTime = nil
            self.vc.setToolbarItems(nil, animated: true)
            self.vc = nil
            
            _monitor?.end()
            _monitor = nil
        }
        objc_sync_exit(self)
    }
    
    
    @objc func remotePlayPause( _ evt:MPRemoteCommandEvent! ) -> MPRemoteCommandHandlerStatus {
        print( "Remote Play Pause")
        DispatchQueue.main.async(execute: {
            
            if( self.muzomaDoc?.isPlaying() ?? false)
            {
                self.muzomaDoc?.stop()
                self.muzomaDoc?.fillMediaInfo(stopping:true)
            }
            else
            {
                self.muzomaDoc?.play()
                self.muzomaDoc?.fillMediaInfo(stopping:false)
            }
        })
        return(  MPRemoteCommandHandlerStatus.success )
    }
    
    @objc func remotePlay( _ evt:MPRemoteCommandEvent! ) -> MPRemoteCommandHandlerStatus {
        //print( "Remote Play")
        if( !_appDelegate.routeChanging )
        {
        DispatchQueue.main.async(execute: {
            
            if( !self.isSetPlayer && self.muzomaSetDoc != nil )
            {
                self.muzomaSetDoc = nil // cancel the set
            }
            
            self.muzomaDoc?.play()
        })
        }
        return(  MPRemoteCommandHandlerStatus.success )
    }
    
    @objc func remotePause( _ evt:MPRemoteCommandEvent! ) -> MPRemoteCommandHandlerStatus {
        //print( "Remote Pause")
        if( !_appDelegate.routeChanging )
        {
        DispatchQueue.main.async(execute: {
            if( self.muzomaDoc?.isPlaying() ?? false)
            {
                self.muzomaDoc?.stop()
            }
            else
            {
                self.muzomaDoc?.play()
            }
        })
        }
        return(  MPRemoteCommandHandlerStatus.success )
    }
    
    @objc func remoteStop( _ evt:MPRemoteCommandEvent! ) -> MPRemoteCommandHandlerStatus {
        //print( "Remote Stop")
        DispatchQueue.main.async(execute: {
            self.muzomaDoc?.stop()
        })
        return(  MPRemoteCommandHandlerStatus.success )
    }
    
    @objc func remoteSeekNext( _ evt:MPRemoteCommandEvent! ) -> MPRemoteCommandHandlerStatus {
        //print( "Seek Next")
        if( !_appDelegate.routeChanging )
        {
        DispatchQueue.main.async(execute: {
            if( self.muzomaSetDoc != nil )
            {
                self.muzomaDoc = self.muzomaSetDoc.seekNext(self.muzomaDoc, honourWasPlayingOnly: true)
            }
        })
        }
        return(  MPRemoteCommandHandlerStatus.success )
    }
    
    @objc func remoteSeekPrev( _ evt:MPRemoteCommandEvent! ) -> MPRemoteCommandHandlerStatus {
        //print( "Seek Prev")
        if( !_appDelegate.routeChanging )
        {
        DispatchQueue.main.async(execute: {
            if( self.muzomaSetDoc != nil )
            {
                self.muzomaDoc = self.muzomaSetDoc.seekPrevious(self.muzomaDoc, honourWasPlayingOnly: true)
            }
        })
        }
        return(  MPRemoteCommandHandlerStatus.success )
    }
    
    @objc func remoteFastFwd( _ evt:MPRemoteCommandEvent! ) -> MPRemoteCommandHandlerStatus {
        //print( "Fast Fwd")
        return(  MPRemoteCommandHandlerStatus.success )
    }
    
    @objc func remoteRewind( _ evt:MPRemoteCommandEvent! ) -> MPRemoteCommandHandlerStatus {
        //print( "Rewind")
        return(  MPRemoteCommandHandlerStatus.success )
    }
    
    @objc func remoteSeek( _ evt:MPRemoteCommandEvent! ) -> MPRemoteCommandHandlerStatus {
        //print( "Remote seek \(evt.debugDescription)")
        if( !_appDelegate.routeChanging )
        {
        DispatchQueue.main.async(execute: {
            if( self.muzomaDoc != nil )
            {
                if( evt is MPChangePlaybackPositionCommandEvent && evt != nil )
                {
                    let seekEvt = evt as! MPChangePlaybackPositionCommandEvent?
                    if( self.muzomaDoc.isPlaying() )
                    {
                        self.muzomaDoc.stop()
                        self.muzomaDoc.play( 1.0, offsetTime: seekEvt!.positionTime, withRecord: false )
                    }
                    else
                    {
                        self.muzomaDoc.setCurrentTime(seekEvt!.positionTime)
                    }
                }
            }
        })
        }
        return(  MPRemoteCommandHandlerStatus.success )
    }
    
    @objc func playerTicked( _ notification: Notification ) {
        DispatchQueue.main.async(execute: {self.updateDisplayComponents()})
        
        let muzomaDoc=notification.object as! MuzomaDocument?
        if( !(muzomaDoc == nil ? true : muzomaDoc!._isSlaveForBandPlay) && Transport._MPService != nil )
        {
            let time=muzomaDoc?.getCurrentTime()
            //print( "send time: \(time)" )
            if( time != nil )
            {
                Transport._MPService?.sendTime(time!)
            }
        }
        
    }
    
    let _appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @objc func playerPlayed(_ notification: Notification) {
        if( !_appDelegate.routeChanging )
        {
            self.muzomaDoc=notification.object as! MuzomaDocument?
            DispatchQueue.main.async(execute: {self.updateStateFromDoc()})
        }
    }
    
    @objc func playerStopped(_ notification: Notification) {
        DispatchQueue.main.async(execute: {self.updateStateFromDoc()})
    }
    
    @objc func playerFastForward(_ notification: Notification) {
        DispatchQueue.main.async(execute: {self.updateStateFromDoc()})
    }
    
    @objc func playerRewind(_ notification: Notification) {
        DispatchQueue.main.async(execute: {self.updateStateFromDoc()})
    }
    
    @objc func playerPlayVarispeed(_ notification: Notification) {
        if( !_appDelegate.routeChanging )
        {
        self.muzomaDoc=notification.object as! MuzomaDocument?
        DispatchQueue.main.async(execute: {self.updateStateFromDoc()})
        }
    }
    
    // sets
    @objc func playerEnded(_ notification: Notification) {
        //print( "Player ended" )
        //self.muzomaDoc=notification.object as! MuzomaDocument!
        DispatchQueue.main.async(execute: {self.updateStateFromDoc()})
    }
    
    @objc func statusUpdate(_ notification: Notification) {
        if( notification.object is String? )
        {
            let text = notification.object as! String?
            
            DispatchQueue.main.async(execute: {
                self.setStatus(text)
            })
        }
    }
    
    func setStatus( _ status:String! )
    {
        //statusLabel.hidden = status == nil
        if( status != nil )
        {
            statusLabel.isHidden = false
            statusLabel.text = status
            statusLabel.alpha = 1.0
            statusLabel.setNeedsDisplay()
            //statusLabel.backgroundColor = .Clear
            
            UIView.animate(withDuration: TimeInterval(3.0), animations: {
                self.statusLabel.alpha = 0.0
            }, completion: { (boolDone) in
                //self.statusLabel.hidden = true
            }) 
        }
    }
    
    func updateStateFromDoc()
    {
        if( !_didDeinit )
        {
            if( rewindButton != nil )
            {
                rewindButton.isEnabled = false
                playButton.isEnabled = false
                pauseButton.isEnabled = false
                stopButton.isEnabled = false
                ffwdButton.isEnabled = false
                variSpeedButton.isEnabled = false
                recordTimingButton.isEnabled = false
                recordAudioButton.isEnabled = false
                guideTrackSelectButton.isEnabled = false
                bandSelectButton.isEnabled = true
                
                if( muzomaDoc != nil ) // !(muzomaDoc == nil ? true : muzomaDoc!._isSlaveForBandPlay) is used for true to grey out the buttons on band play device
                {
                    stopButton?.isEnabled = !(muzomaDoc == nil ? true : muzomaDoc!._isSlaveForBandPlay)
                    recordTimingButton?.isEnabled = !(muzomaDoc == nil ? true : muzomaDoc!._isSlaveForBandPlay)
                    recordAudioButton?.isEnabled = !(muzomaDoc == nil ? true : muzomaDoc!._isSlaveForBandPlay)
                    ffwdButton?.isEnabled = !(muzomaDoc == nil ? true : muzomaDoc!._isSlaveForBandPlay)
                    rewindButton?.isEnabled = !(muzomaDoc == nil ? true : muzomaDoc!._isSlaveForBandPlay)
                    guideTrackSelectButton?.isEnabled = !(muzomaDoc == nil ? true : muzomaDoc!._isSlaveForBandPlay)
                    guideTrackSelectButton?.title="📀"
                    
                    if( muzomaDoc.isPlaying() )
                    {
                        guideTrackSelectButton?.isEnabled = false
                        guideTrackSelectButton?.title="💿"
                        pauseButton?.isEnabled = !(muzomaDoc == nil ? true : muzomaDoc!._isSlaveForBandPlay)
                        
                        if( muzomaDoc._speed != 1.0)
                        {
                            playButton?.isEnabled = !(muzomaDoc == nil ? true : muzomaDoc!._isSlaveForBandPlay)
                            variSpeedButton?.isEnabled = false
                        }
                        else
                        {
                            playButton?.isEnabled = false
                            variSpeedButton?.isEnabled = !(muzomaDoc == nil ? true : muzomaDoc!._isSlaveForBandPlay)
                        }
                    }
                    else
                    {
                        playButton?.isEnabled = !(muzomaDoc == nil ? true : muzomaDoc!._isSlaveForBandPlay)
                        variSpeedButton?.isEnabled = !(muzomaDoc == nil ? true : muzomaDoc!._isSlaveForBandPlay)
                    }
                    
                    if( self.recordTimingButton?.tintColor == nil )
                    {
                        if( inRecordTiming )
                        {
                            self.recordTimingButton?.tintColor = UIColor.red
                        }
                    }
                    else if( self.recordTimingButton?.tintColor == UIColor.red )
                    {
                        if( !inRecordTiming )
                        {
                            self.recordTimingButton?.tintColor = nil
                        }
                    }
                    
                    if( self.recordAudioButton?.tintColor == nil )
                    {
                        if( inRecordAudio )
                        {
                            self.recordAudioButton?.tintColor = UIColor.red
                        }
                    }
                    else if( self.recordAudioButton?.tintColor == UIColor.red )
                    {
                        if( !inRecordAudio )
                        {
                            self.recordAudioButton?.tintColor = nil
                        }
                    }
                    
                    if( muzomaDoc!._isSlaveForBandPlay )
                    {
                        playButton?.isEnabled = true // will go to the slaved view
                    }
                    
                    updateDisplayComponents()
                }
            }
            
            remote.togglePlayPauseCommand.isEnabled = true
            remote.playCommand.isEnabled = playButton != nil ? playButton.isEnabled : false//!(muzomaDoc == nil ? true : muzomaDoc!._isSlaveForBandPlay) //playButton.enabled //
            remote.pauseCommand.isEnabled = pauseButton != nil ? pauseButton.isEnabled : false //!(muzomaDoc == nil ? true : muzomaDoc!._isSlaveForBandPlay) //pauseButton.enabled //
            remote.stopCommand.isEnabled = stopButton != nil ? stopButton.isEnabled  : false //!(muzomaDoc == nil ? true : muzomaDoc!._isSlaveForBandPlay)
            remote.seekForwardCommand.isEnabled = ffwdButton != nil ? ffwdButton.isEnabled : false//!(muzomaDoc == nil ? true : muzomaDoc!._isSlaveForBandPlay)
            remote.seekBackwardCommand.isEnabled = rewindButton != nil ? rewindButton.isEnabled : false // !(muzomaDoc == nil ? true : muzomaDoc!._isSlaveForBandPlay)
            if #available(iOS 9.1, *) {
                remote.changePlaybackPositionCommand.isEnabled = rewindButton != nil ? rewindButton.isEnabled : false
            } else {
                // Fallback on earlier versions
            }
            remote.nextTrackCommand.isEnabled = isSetPlayer && !(muzomaDoc == nil ? true : muzomaDoc!._isSlaveForBandPlay)
            remote.previousTrackCommand.isEnabled = isSetPlayer && !(muzomaDoc == nil ? true : muzomaDoc!._isSlaveForBandPlay)
        }
        
        self.loopButton?.tintColor = inLoop == true ? UIColor.green : nil
        
        updateBandButtonState()
    }
    
    func updateDisplayComponents()
    {
        if( !_didDeinit )
        {
            if( muzomaDoc != nil )
            {
                if(controllerLabel != nil)
                {
                    let time:TimeInterval = muzomaDoc.getCurrentTime()
                    
                    let hrs = Int(trunc((time / 3600).truncatingRemainder(dividingBy: 3600)))
                    let mins = Int(trunc((time / 60).truncatingRemainder(dividingBy: 60)))
                    let secs = Int(trunc(time.truncatingRemainder(dividingBy: 60)))
                    controllerLabel.text = "\(hrs.format("02")):\(mins.format("02")):\(secs.format("02"))"
                }
                
                if( progressTime != nil )
                {
                    progressTime.progress = muzomaDoc.getProgress()
                }
            }
            else
            {
                if(controllerLabel != nil)
                {
                    controllerLabel.text = "--:--:--"
                }
            }
        }
    }
    
    func updateBandButtonState( _ initializing:Bool = false )
    {
        if( self.bandSelectButton != nil )
        {
            if( initializing )
            {
                DispatchQueue.main.async(execute: {
                    self.bandSelectButton.tintColor = UIColor.darkGray
                })
            }
            else
            {
                var peerCount:Int = 0
                
                if( Transport._MPService != nil && Transport._MPService?.session != nil  )
                {
                    peerCount = Transport._MPService!.session.connectedPeers.count
                    
                    switch( peerCount )
                    {
                    case 0:
                        DispatchQueue.main.async(execute: {
                            self.bandSelectButton.title = Transport._MPService._isMaster ? "L1" : "P1"
                            self.bandSelectButton.setTitleTextAttributes( convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font):UIFont(name:"Courier", size: 22)!]), for: UIControl.State())
                            self.bandSelectButton.tintColor = UIColor.blue
                        })
                        break;
                        
                    case 1:
                        DispatchQueue.main.async(execute: {
                            self.bandSelectButton.title = Transport._MPService._isMaster ? "L2" : "P2"
                            self.bandSelectButton.setTitleTextAttributes( convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font):UIFont(name:"Courier", size: 22)!]), for: UIControl.State())
                            self.bandSelectButton.tintColor = UIColor.magenta // magenta color
                        })
                        break;
                        
                    case 2:
                        self.bandSelectButton.title = Transport._MPService._isMaster ? "L3" : "P3"
                        self.bandSelectButton.setTitleTextAttributes( convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font):UIFont(name:"Courier", size: 22)!]), for: UIControl.State())
                        DispatchQueue.main.async(execute: {
                            self.bandSelectButton.tintColor = UIColor.init(hexString: "#ff8000") // orangey color
                        })
                        break;
                        
                    case 3:
                        self.bandSelectButton.title = Transport._MPService._isMaster ? "L4" : "P4"
                        self.bandSelectButton.setTitleTextAttributes( convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font):UIFont(name:"Courier", size: 22)!]), for: UIControl.State())
                        DispatchQueue.main.async(execute: {
                            self.bandSelectButton.tintColor = UIColor.init(hexString: "#00b34d") // greeny colour
                        })
                        break;
                        
                    case 4:
                        self.bandSelectButton.title = Transport._MPService._isMaster ? "L5" : "P5"
                        self.bandSelectButton.setTitleTextAttributes( convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font):UIFont(name:"Courier", size: 22)!]), for: UIControl.State())
                        DispatchQueue.main.async(execute: {
                            self.bandSelectButton.tintColor = UIColor.init(red: 0.0, green: 0.6, blue: 0.6, alpha: 1.0) // cyan color
                        })
                        break;
                        
                    case 5:
                        self.bandSelectButton.title = Transport._MPService._isMaster ? "L6" : "P6"
                        self.bandSelectButton.setTitleTextAttributes( convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font):UIFont(name:"Courier", size: 22)!]), for: UIControl.State())
                        DispatchQueue.main.async(execute: {
                            self.bandSelectButton.tintColor = UIColor.init(red: 0.8, green: 0.8, blue: 0.2, alpha: 1.0) // dark yellow
                        })
                        break;
                        
                    case 6:
                        self.bandSelectButton.title = Transport._MPService._isMaster ? "L7" : "P7"
                        self.bandSelectButton.setTitleTextAttributes( convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font):UIFont(name:"Courier", size: 22)!]), for: UIControl.State())
                        DispatchQueue.main.async(execute: {
                            self.bandSelectButton.tintColor = UIColor.init( hexString: "#b34dff" ) // purple color
                        })
                        break;
                        
                    case 7:
                        self.bandSelectButton.title = Transport._MPService._isMaster ? "L8" : "P8"
                        self.bandSelectButton.setTitleTextAttributes( convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font):UIFont(name:"Courier", size: 22)!]), for: UIControl.State())
                        DispatchQueue.main.async(execute: {
                            self.bandSelectButton.tintColor = UIColor.init( hexString: "#b34dcc" ) // pink
                        })
                        break;
                        
                    default:
                        break;
                        
                    }
                }
                else
                {
                    bandSelectButton.title = "Band"
                    bandSelectButton.setTitleTextAttributes( convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font):UIFont(name:"Courier", size: 15)!]), for: UIControl.State())
                    self.bandSelectButton.tintColor = UIColor.blue
                }
                
            }
        }
    }
    
    @objc func _playPressed(_ notification: Notification) {
        DispatchQueue.main.async(execute: {
            self.playPressed(notification)
        })
    }
    
    @objc func playButtonPressed(_ sender:UIButton!) {
        playPressed(Notification(name: Notification.Name(rawValue: "playbutton")))
    }
    
    @objc func playPressed(_ notification: Notification) {
        //print( "play pressed" )
        
        if( Transport._muzomaDoc != nil && Transport._muzomaDoc._isSlaveForBandPlay )
        {
            let playerDocController = self.vc!.storyboard?.instantiateViewController(withIdentifier: "PlayerDocumentViewController") as? PlayerDocumentViewController
            playerDocController!.muzomaDoc = Transport._muzomaDoc
            self.vc!.navigationController?.popToRootViewController(animated: true)
            self.vc!.navigationController?.pushViewController(playerDocController!, animated: true)
        }
        else
        {
            if( !self.isSetPlayer && self.muzomaSetDoc != nil )
            {
                self.muzomaSetDoc = nil // cancel the set
            }
            self.muzomaDoc?.play( withRecord: self.inRecordAudio )
        }
    }
    
    @objc func pausePressed(_ sender:UIButton!) {
        //print( "pause pressed" )
        self.muzomaDoc?.pause()
    }
    
    @objc func _stopPressed(_ notification: Notification) {
        stopButtonPressed(nil)
    }
    
    @objc func stopButtonPressed(_ sender:UIButton!){
        //print( "stop pressed" )
        if( self.inRecordAudio )
        {
            self.setStatus("Please wait..." )
        }
        inRecordTiming = false
        inRecordAudio = false
        
        DispatchQueue.main.async(execute: {
            //woz self.muzomaDoc?.stop() but got double press of stop 
            self.muzomaDoc?.stop(sendMidi:sender != nil)
            self.monitor()
            _gNC.post(name: Notification.Name(rawValue: "TransportStop"), object: nil)
        })
    }
    
    @objc func _songSelectPressed(_ notification: Notification) {
        DispatchQueue.main.async(execute: {
            if(notification.object is MIKMIDICommand)
            {
                if( self.muzomaSetDoc != nil )
                {
                    self.muzomaSetDoc.selectSong(notification)
                }
            }
        })
    }
    
    @objc func _nextSongPressed(_ notification: Notification) {
        DispatchQueue.main.async(execute: {
            let evt:MPRemoteCommandEvent! = nil
            _ = self.remoteSeekNext(evt)
        })
    }
    
    @objc func _previousSongPressed(_ notification: Notification) {
        DispatchQueue.main.async(execute: {
            let evt:MPRemoteCommandEvent! = nil
            _ = self.remoteSeekPrev(evt)
        })
    }
    
    @objc func _recordPressed(_ notification: Notification) {
        DispatchQueue.main.async(execute: {
            self.recordAudioPressed(nil)
        })
    }
    
    @objc func _rewindPressed(_ notification: Notification) {
        DispatchQueue.main.async(execute: {
            self.rewindPressed(nil)
        })
    }
    
    @objc func _fastForwardPressed(_ notification: Notification) {
        DispatchQueue.main.async(execute: {
            self.fastfwdPressed(nil)
        })
    }
    
    @objc func fastfwdPressed(_ sender:UIButton!) {
        //print( "fastfwd pressed" )
        
        self.muzomaDoc?.fastFwd()
    }
    
    @objc func rewindPressed(_ sender:UIButton!) {
        //print( "rewind pressed" )
        
        self.muzomaDoc?.rewind()
    }
    
    @objc func variSpeedPressed(_ sender:UIButton!) {
        //print( "variSpeed pressed" )
        
        if( !self.isSetPlayer && self.muzomaSetDoc != nil )
        {
            self.muzomaSetDoc = nil // cancel the set
        }
        self.muzomaDoc?.play(0.5)
    }
    
    @objc func guideTrackSelectPressed(_ sender:UIButton!) {
        //print( "guideTrackSelect pressed" )
        
        DispatchQueue.main.async(execute: {
            if(self.muzomaDoc != nil )
            {
                self.displayAudioFilePicker()
            }
        })
    }
    
    @objc func loopPressed(_ sender:UIButton!) {
        //print("record pressed")
        
        inLoop = !inLoop
        
        if( self.isSetPlayer )
        {
            Transport._muzomaSetDoc?._loopSet = self.inLoop
        }
        
        if( inLoop )
        {
            self.nc.post(name: Notification.Name(rawValue: "LoopOn"), object: self)
        }
        else
        {
            self.nc.post(name: Notification.Name(rawValue: "LoopOff"), object: self)
        }
        updateStateFromDoc()
    }
    
    
    var inRecordTiming = false
    @objc func recordTimingPressed(_ sender:UIButton!) {
        //print("record pressed")
        
        inRecordTiming = !inRecordTiming
        
        if( inRecordTiming )
        {
            self.nc.post(name: Notification.Name(rawValue: "RecordTimingOn"), object: self)
        }
        else
        {
            self.nc.post(name: Notification.Name(rawValue: "RecordTimingOff"), object: self)
        }
        updateStateFromDoc()
    }
    
    var inRecordAudio = false
    @objc func recordAudioPressed(_ sender:UIButton!) {
        //print("record pressed")
        
        inRecordAudio = !inRecordAudio
        
        if( inRecordAudio )
        {
            self.armRecord()
            self.nc.post(name: Notification.Name(rawValue: "RecordAudioOn"), object: self)
        }
        else
        {
            self.dearmRecord()
            self.nc.post(name: Notification.Name(rawValue: "RecordAudioOff"), object: self)
        }
        
        updateStateFromDoc()
    }
    
    
    func displayAudioFilePicker()
    {
        let picker = UICloudAudioPickerViewConroller(muzomaDoc: self.muzomaDoc)
        picker.displayAudioFilePicker()
    }
    
    
    @objc func extControlSelectPressed(_ sender: AnyObject) {
        print("external control pressed")
        let controlsDocController = self.vc?.storyboard?.instantiateViewController(withIdentifier: "MuzomaControlViewController") as? MuzomaControlViewController
        self.vc?.navigationController?.pushViewController(controlsDocController!, animated: true)
    }
}

extension Transport : MuzomaMPServiceManagerDelegate {
    
    func connectedDevicesChanged(_ manager: MuzomaMPServiceManager, connectedDevices: [String]) {
        //print(  "Connections: \(connectedDevices)" )
        
        DispatchQueue.main.async(execute: {
            self.updateBandButtonState()
        })
        
        OperationQueue.main.addOperation { () -> Void in
            //self.connectionsLabel.text = "Connections: \(connectedDevices)"
            if( Transport._MPService != nil && self.muzomaDoc != nil && !(self.muzomaDoc?._isSlaveForBandPlay)!)
            {
                Transport._MPService?.sendDoc(Transport._muzomaDoc) // tell peers about the new doc
            }
        }
    }
    
    func timeChanged(_ manager: MuzomaMPServiceManager, timeString: String) {
        if( self.muzomaDoc != nil && self.muzomaDoc._isSlaveForBandPlay )
        {
            //print( "time rx: \(timeString)" )
            self.muzomaDoc.setCurrentTime(TimeInterval(timeString)!)
            self.nc.post(name: Notification.Name(rawValue: "PlayerTick"), object: self.muzomaDoc)
        }
    }
    
    func resignMaster(_ manager : MuzomaMPServiceManager)
    {
        if( self.muzomaDoc != nil && !self.muzomaDoc._isSlaveForBandPlay )
        {
            self.muzomaDoc.stop()
        }
        
        DispatchQueue.main.async(execute: {
            self.updateBandButtonState()
        })
    }
    
    func becomeMaster(_ manager : MuzomaMPServiceManager)
    {
        DispatchQueue.main.async(execute: {
            self.updateBandButtonState()
        })
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}
