//
//  AppDelegate.swift
//  Muzoma App - Entry Point
//
//  Created by Matthew Hopkins on 05/04/2015.
//  Copyright (c) 2015 Muzoma.com. All rights reserved.
//
//  Handle start up and initialization of the device using user preferences
//  Handle connection and disconnection of audio devices
//  Handle external file transfers
//

import UIKit
import Foundation
import CoreFoundation
import AudioToolbox
import MediaPlayer
import AVFoundation
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate/*, DirectoryMonitorDelegate */{
    var window: UIWindow?
    var ubiquityURL:URL?
    var metaDataQuery:NSMetadataQuery?
    
    let nc = _gNC
    let midi = _gMidi
    var boxView:UIView! = nil
    let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffect.Style.light))
    var oldBGColor:UIColor! = nil
    
    fileprivate var _isPlayingOnMC:Bool = false
    var isPlayingOnMC:Bool
    {
        get
        {
            return( _isPlayingOnMC )
        }
    }
    
    var _shareAudio:Bool = false
    var _prefSampleRate:Double = 44100.00
    var _prefBitDepth:Int = 16
    var _prefLatency:Double = 0.005
    
    let none = AVAudioSession.CategoryOptions.init(rawValue: 0x00) // none
    let allowBluetoothA2DP = AVAudioSession.CategoryOptions.init(rawValue: 0x20) // AllowBluetoothA2DP
    let allowAirPlay = AVAudioSession.CategoryOptions.init(rawValue: 0x40) // AllowAirPlay
    @objc dynamic var _settingInactive = false
    @objc dynamic var _routeChanging = false
    var routeChanging:Bool
    {
        get
        {
            return( _routeChanging )
        }
    }
    
    func setupAudioFromPrefs()
    {
        Logger.log("setupAudioFromPrefs called")
        DispatchQueue.main.async(execute: { // set up on main thread
            self._settingInactive = true
            Logger.log("Starting setupAudioFromPrefs()")
            let session: AVAudioSession = AVAudioSession.sharedInstance()
            
            // stop silent playback, recording and background audio when routing changes
            var wasSilent = false
            if( self._backgroundAudioTrack != nil && self._backgroundAudioTrack._playingSilence )
            {
                self._backgroundAudioTrack.stopSilent()
                self._backgroundAudioTrack.cleanUp() // force no delay clean up on the main thread
                self._backgroundAudioTrack = nil
                wasSilent = true
            }
            
            // stop playback, recording and background audio when routing changes
            var playbackWasStopped = false
            let currentDoc = Transport.getCurrentDoc()
            if( currentDoc != nil && (currentDoc?.isPlaying())! )
            {
                currentDoc!.stop(waitForCleanup:true) // wait for clean up
                playbackWasStopped = true
            }
            
            do {
                try session.setActive( false )
                //print("AVAudioSession is Active")
            } catch let error as NSError {
                Logger.log("\(#function) \(#file) \(error.localizedDescription)")
            }
            
            let strAvailCategories =  "Audio session available categories \(convertFromAVAudioSessionCategoryArray(session.availableCategories).description)"
            let strAvailModes =  "Audio session available modes \(convertFromAVAudioSessionModeArray(session.availableModes).description)"
            Logger.log(strAvailCategories)
            Logger.log(strAvailModes)
            
            if( UserDefaults.standard.value(forKey: "shareAudio_preference") == nil )
            {
                UserDefaults.standard.set(false, forKey: "shareAudio_preference")
            }
            self._shareAudio = UserDefaults.standard.bool(forKey: "shareAudio_preference")
            
            do
            {
                var options:AVAudioSession.CategoryOptions = [self.allowAirPlay, self.allowBluetoothA2DP, .defaultToSpeaker]
                if( self._shareAudio )
                {
                    options.insert(.mixWithOthers)
                }
                
                if #available(iOS 11.0, *) {
                    try session.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.default, options: options)
                } else {
                    // Fallback on earlier versions
                }
            } catch let error as NSError {
                Logger.log("\(#function) \(#file) \(error.localizedDescription)")
            }
            
            if( UserDefaults.standard.value(forKey: "sampleRate_preference") == nil )
            {
                UserDefaults.standard.set(44100.00, forKey: "sampleRate_preference")
            }
            
            do
            {
                self._prefSampleRate = UserDefaults.standard.double(forKey: "sampleRate_preference")
                try session.setPreferredSampleRate(self._prefSampleRate)
                Logger.log("pref sample rate \(self._prefSampleRate) actual \(session.preferredSampleRate.debugDescription)")
            } catch let error as NSError {
                Logger.log("\(#function) \(#file) \(error.localizedDescription)")
            }
            
            if( UserDefaults.standard.value(forKey: "bitDepth_preference") == nil )
            {
                UserDefaults.standard.set(16, forKey: "bitDepth_preference")
            }
            
            self._prefBitDepth = UserDefaults.standard.integer(forKey: "bitDepth_preference")
            //try session.setPreferredSampleRate(prefSampleRate)
            Logger.log("pref bit depth \(self._prefBitDepth)")
            
            
            if( UserDefaults.standard.value(forKey: "latency_preference") == nil )
            {
                UserDefaults.standard.set(0.010, forKey: "latency_preference")
            }
            
            do
            {
                self._prefLatency = UserDefaults.standard.double(forKey: "latency_preference")
                try session.setPreferredIOBufferDuration(self._prefLatency)
                Logger.log("pref latency \(self._prefLatency) actual \(session.preferredIOBufferDuration.debugDescription)")
            } catch let error as NSError {
                Logger.log("\(#function) \(#file) \(error.localizedDescription)")
            }
            
            do
            {
                try session.setInputGain(1.0)
            } catch let error as NSError {
                Logger.log("\(#function) \(#file) \(error.localizedDescription)")
            }
            
            do {
                try AVAudioSession.sharedInstance().setActive( true, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation )
                //print("AVAudioSession is Active")
            } catch let error as NSError {
                Logger.log("\(#function) \(#file) \(error.localizedDescription)")
            }
            
            Logger.log("detectHardware, _appInBackground:\(self._appInBackground.description), otherAudioPlaying  \(session.isOtherAudioPlaying.description) secondaryAudioShouldBeSilencedHint: \(session.secondaryAudioShouldBeSilencedHint.description)")
            
            
            let engine = AVAudioEngine()
            let output = engine.outputNode
            
            Logger.log("currentRoute.outputs")
            var routeCount = 0
            for routeOutputDevice in session.currentRoute.outputs
            {
                Logger.log("\(routeCount) - \(routeOutputDevice.debugDescription)")
                routeCount += 1
            }
            
            do
            {
                if( session.maximumOutputNumberOfChannels > 0 )
                {
                    Logger.log("Set pref num outs \(session.maximumOutputNumberOfChannels)")
                    try session.setPreferredOutputNumberOfChannels(session.maximumOutputNumberOfChannels)
                    Logger.log("outputNumberOfChannels: \(session.outputNumberOfChannels)")
                }
            } catch let error as NSError {
                Logger.log("\(#function) \(#file) \(error.localizedDescription)")
            }
            
            Logger.log("currentRoute.inputs")
            routeCount = 0
            for routeInputDevice in session.currentRoute.inputs
            {
                Logger.log("\(routeCount) - \(routeInputDevice.debugDescription)")
                routeCount += 1
            }
            
            do
            {
                if( session.maximumInputNumberOfChannels > 0 )
                {
                    Logger.log("Set pref num ins \(session.maximumInputNumberOfChannels)")
                    try session.setPreferredInputNumberOfChannels(session.maximumInputNumberOfChannels)
                    Logger.log("inputNumberOfChannels: \(session.inputNumberOfChannels)")
                }
            } catch let error as NSError {
                Logger.log("\(#function) \(#file) \(error.localizedDescription)")
            }
            
            let outChanCount:Int = Int( output.outputFormat(forBus: 0).channelCount )
            
            self._isPlayingOnMC = outChanCount > 2
            
            if( playbackWasStopped ) // start playback again
            {
                if( !session.secondaryAudioShouldBeSilencedHint && !session.isOtherAudioPlaying )
                {
                    currentDoc!.play()
                }
            }
            
            if( wasSilent ) // was play silent
            {
                if( !session.secondaryAudioShouldBeSilencedHint && !session.isOtherAudioPlaying )
                {
                    self._backgroundAudioTrack = AudioTrack()
                    self._backgroundAudioTrack.playSilent()
                }
            }
            _gNC.post(name: Notification.Name(rawValue: "DetectHardwareChange"), object: self)
            Logger.log("Done setupAudioFromPrefs()")
            self._settingInactive = false
        })
    }
    
    func redirectConsoleLogToDocumentFolder() {
        let fs = _gFSH
        let logDir = fs.getDocumentFolderURL()?.appendingPathComponent("_log")
        if( !fs.directoryExists(logDir) )
        {
            do
            {
                try fs.createDirectory(at: logDir!, withIntermediateDirectories: true, attributes: nil )
            }
            catch let error as NSError {
                Logger.log("\(#function)  \(#file)  \(error.localizedDescription)")
            }
        }
        
        let paths: NSArray = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        let documentsDirectory: NSString = paths[0] as! NSString
        let logPath: NSString = documentsDirectory.appendingPathComponent("/_log/console.log") as NSString
        let cstr = (logPath as NSString).utf8String
        freopen(cstr, "a+", stderr)
    }
    
    func addSpinnerView() {
        let view = self.window?.rootViewController?.view
        
        oldBGColor = view!.backgroundColor
        view!.backgroundColor = UIColor.clear
        
        //always fill the view
        blurEffectView.frame = view!.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        view!.addSubview(blurEffectView) //if you have more UIViews, use an insertSubview API to place it where needed
        // You only need to adjust this frame to move it anywhere you want
        self.boxView = UIView(frame: CGRect(x: view!.frame.midX - 90, y: view!.frame.midY - 25, width: 180, height: 50))
        self.boxView.isHidden = false
        self.boxView.backgroundColor = UIColor.white
        self.boxView.alpha = 0.8
        self.boxView.layer.cornerRadius = 10
        
        //Here the spinnier is initialized
        let activityView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
        activityView.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        activityView.startAnimating()
        
        let textLabel = UILabel(frame: CGRect(x: 60, y: 0, width: 200, height: 50))
        textLabel.textColor = UIColor.gray
        textLabel.text = "Working..."
        
        self.boxView.addSubview(activityView)
        self.boxView.addSubview(textLabel)
        
        view!.addSubview(self.boxView)
        
    }
    
    func removeSpinnerView()
    {
        if( self.boxView != nil )
        {
            let view = self.window?.rootViewController?.view
            self.boxView.removeFromSuperview()
            self.boxView.isHidden = true
            view!.backgroundColor =  oldBGColor
            blurEffectView.removeFromSuperview()
            boxView = nil
        }
    }
    
    
    @objc func refreshDocsView(_ notification: Notification) {
        removeSpinnerView()
    }
    
    @objc func refreshSetsView(_ notification: Notification) {
        removeSpinnerView()
    }
    
    /* let dm = DirectoryMonitor(URL: _gFSH.getDocumentFolderURL()!.URLByAppendingPathComponent("Inbox"))*/
    
    @objc func userDefaultsChanged(_ notification: Notification) {
        UserDefaults.standard.synchronize()
        //let runBackground = NSUserDefaults.standardUserDefaults().boolForKey("runBackground_preference")
        //Logger.log("bg \(runBackground)")
        
        // figure out if change affects audio or not
        var changed = false
        if( _shareAudio != UserDefaults.standard.bool(forKey: "shareAudio_preference"))
        {
            changed = true
        } else if( _prefSampleRate != UserDefaults.standard.double(forKey: "sampleRate_preference"))
        {
            changed = true
        } else if( _prefBitDepth != UserDefaults.standard.integer(forKey: "bitDepth_preference"))
        {
            changed = true
        } else if( _prefLatency != UserDefaults.standard.double(forKey: "latency_preference"))
        {
            changed = true
        }
        
        if( changed )
        {
            self.setupAudioFromPrefs()
        }
    }
    
    var _wasPlaying = false
    var _notificationsGranted = false
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        UserDefaults.standard.synchronize()
        
        // request to send notifications
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            
            // Request permission to display alerts and play sounds.
            center.requestAuthorization(options: [.alert, .sound])
            { (granted, error) in
                // Enable or disable features based on authorization.
                if( error != nil )
                {
                    Logger.log( "Error getting permission for notifications \(String(describing: error))" )
                }
                else
                {
                    self._notificationsGranted = true
                }
            }
            
            center.getNotificationSettings { (settings) in
                // Do not schedule notifications if not authorized.
                guard settings.authorizationStatus == .authorized else {return}
                
                if settings.alertSetting == .enabled {
                    // Schedule an alert-only notification.
                    self._notificationsGranted = true
                }
            }
        } else {
            // Fallback on earlier versions
        }
        
        
        _gNC.addObserver(self, selector: #selector(AppDelegate.userDefaultsChanged(_:)), name: UserDefaults.didChangeNotification, object: nil)
        
        if( UserDefaults.standard.value(forKey: "debugLogging_preference") == nil )
        {
            UserDefaults.standard.set(false, forKey: "debugLogging_preference")
        }
        
        let debugLogging = UserDefaults.standard.bool(forKey: "debugLogging_preference")
        if( debugLogging )
        {
            redirectConsoleLogToDocumentFolder()
        }
        
        nc.addObserver(self, selector: #selector(AppDelegate.refreshDocsView(_:)), name: NSNotification.Name(rawValue: "RefreshDocsView"), object: nil)
        nc.addObserver(self, selector: #selector(AppDelegate.refreshSetsView(_:)), name: NSNotification.Name(rawValue: "RefreshSetsView"), object: nil)
        
        if( UserDefaults.standard.value(forKey: "bandShareId_preference") == nil )
        {
            UserDefaults.standard.set("band-share", forKey: "bandShareId_preference")
        }
        
        if( UserDefaults.standard.value(forKey: "autoHideToolbar_preference") == nil )
        {
            UserDefaults.standard.set(false, forKey: "autoHideToolbar_preference")
        }
        
        //let dontSleep:Bool = true
        if( UserDefaults.standard.value(forKey: "dontSleep_preference") == nil )
        {
            UserDefaults.standard.set(true, forKey: "dontSleep_preference")
        }
        
        let dontSleep = UserDefaults.standard.bool(forKey: "dontSleep_preference")
        // can affect audio if sleeps!
        UIApplication.shared.isIdleTimerDisabled = dontSleep
        
        
        if( UserDefaults.standard.value(forKey: "runBackground_preference") == nil )
        {
            UserDefaults.standard.set(true, forKey: "runBackground_preference")
        }
        
        //let runBackground = NSUserDefaults.standardUserDefaults().boolForKey("runBackground_preference")
        
        if( UserDefaults.standard.value(forKey: "setAutoPlayNextSong_preference") == nil )
        {
            UserDefaults.standard.set(true, forKey: "setAutoPlayNextSong_preference")
        }
        //let setAutoPlayNextSong = NSUserDefaults.standardUserDefaults().boolForKey("setAutoPlayNextSong_preference")
        
        //sliderMainVolume_preference
        
        if( UserDefaults.standard.value(forKey: "unhideSetOnly_preference") == nil )
        {
            UserDefaults.standard.set(false, forKey: "unhideSetOnly_preference")
        }
        
        /*
         if( NSUserDefaults.standardUserDefaults().valueForKey("maxMultitrackChans_preference") == nil )
         {
         NSUserDefaults.standardUserDefaults().setInteger(32, forKey: "maxMultitrackChans_preference")
         }
         //let maxMultitrackChans = NSUserDefaults.standardUserDefaults().integerForKey("maxMultitrackChans_preference")
         */
        
        if( UserDefaults.standard.value(forKey: "airPlayOnByDefault_preference") == nil )
        {
            UserDefaults.standard.set(true, forKey: "airPlayOnByDefault_preference")
        }
        
        if( UserDefaults.standard.value(forKey: "playerZoomLevel_preference") == nil )
        {
            UserDefaults.standard.set( 1.00, forKey: "playerZoomLevel_preference")
        }
        
        if( UserDefaults.standard.value(forKey: "airplayZoomLevel_preference") == nil )
        {
            UserDefaults.standard.set( 2.00, forKey: "airplayZoomLevel_preference")
        }
        
        if( UserDefaults.standard.value(forKey: "playerColorScheme_preference") == nil )
        {
            UserDefaults.standard.setValue("Light",  forKey: "playerColorScheme_preference")
        }
        
        if( UserDefaults.standard.value(forKey: "setPlayerLoopOn_preference") == nil )
        {
            UserDefaults.standard.set(false, forKey: "setPlayerLoopOn_preference")
        }
        
        
        NotificationCenter.default.addObserver(
        forName: AVAudioSession.routeChangeNotification, object: nil, queue: nil) {
            (note:Notification!) in
            
            guard let userInfo = note.userInfo,
                let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
                let reason = AVAudioSession.RouteChangeReason(rawValue:reasonValue) else {
                    return
            }
            
            switch reason {
                
            case .newDeviceAvailable:
                
                let newRoute = AVAudioSession.sharedInstance().currentRoute
                Logger.log("AVAudioSessionRouteChange newDeviceAvailable: \(newRoute.description)")
                var routeChanged = false
                if( !self._settingInactive ) // not changes as a result of this call
                {
                    if let prevRoute =
                        userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
                        Logger.log("AVAudioSessionRouteChange oldDeviceUnavailable prev route: \(String(describing: prevRoute.description))")
                        let pvIns = prevRoute.inputs
                        let pvOuts = prevRoute.outputs
                        
                        let newIns = newRoute.inputs
                        let newOuts = newRoute.outputs
                        
                        if( newIns.count != pvIns.count || newOuts.count != pvOuts.count )
                        {
                            routeChanged = true
                        }
                        else
                        {
                            for inCnt in 0 ..< newIns.count
                            {
                                let newIn = newIns[inCnt]
                                let pvIn = pvIns[inCnt]
                                
                                if( newIn.uid != pvIn.uid )
                                {
                                    routeChanged = true
                                    break;
                                }
                            }
                            
                            for outCnt in 0 ..< newOuts.count
                            {
                                let newOut = newOuts[outCnt]
                                let pvOut = pvOuts[outCnt]
                                
                                if( newOut.uid != pvOut.uid )
                                {
                                    routeChanged = true
                                    break;
                                }
                            }
                        }
                    }
                }
                
                if( routeChanged )
                {
                    self._routeChanging = true
                    Logger.log("Change Route 1")
                    let delay = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                    DispatchQueue.main.asyncAfter(deadline: delay,execute: {
                        // schedule on main thread
                        let currentDoc = Transport.getCurrentDoc()
                        if( currentDoc != nil && currentDoc!.isPlaying()  )
                        {
                            currentDoc!.stop()
                        }
                        DispatchQueue.main.asyncAfter(deadline: delay,execute: {
                            self.setupAudioFromPrefs()
                            self._routeChanging = false
                        })
                    })
                    //self.setupAudioFromPrefs()
                }
                
            case .oldDeviceUnavailable:
                if let prevRoute =
                    userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
                    Logger.log("AVAudioSessionRouteChange oldDeviceUnavailable prev route: \(String(describing: prevRoute.description))")
                    self._routeChanging = true
                    Logger.log("Change Route 2")
                    let delay = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                    DispatchQueue.main.asyncAfter(deadline: delay,execute: {
                        // schedule on main thread
                        let currentDoc = Transport.getCurrentDoc()
                        if( currentDoc != nil && currentDoc!.isPlaying()  )
                        {
                            currentDoc!.stop()
                        }
                        DispatchQueue.main.asyncAfter(deadline: delay,execute: {
                            self.setupAudioFromPrefs()
                            self._routeChanging = false
                        })
                    })
                }
                
            default: ()
                
            }
            
        }
        
        // properly, if the route changes from some kind of Headphones to Built-In Speaker,
        // we should pause our sound (doesn't happen automatically)
        
        NotificationCenter.default.addObserver(
        forName: AVAudioSession.interruptionNotification, object: nil, queue: nil) {
            (n:Notification) in
            
            Logger.log("AVAudioSessionInterruptionNotification")
            guard let why =
                n.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
                else {return}
            guard let type = AVAudioSession.InterruptionType(rawValue: why)
                else {return}
            if type == .began {
                self._wasPlaying = false
                let inter = "AVAudioSessionInterruptionNotification interruption began:\n\(n.userInfo!)"
                Logger.log(inter)
                if( self._backgroundAudioTrack != nil )
                {
                    self._backgroundAudioTrack?.stopSilent(true)
                    self._backgroundAudioTrack?.cleanUp() // force no delay clean up
                    self._backgroundAudioTrack = nil
                }
                
                let currentDoc = Transport.getCurrentDoc()
                if( currentDoc != nil && currentDoc!.isPlaying() )
                {
                    currentDoc!.stop(waitForCleanup:true)
                    self._wasPlaying = true
                }
            } else
            {
                Logger.log("AVAudioSessionInterruptionNotification ended")
                guard let opt = n.userInfo![AVAudioSessionInterruptionOptionKey] as? UInt else {return}
                let opts = AVAudioSession.InterruptionOptions(rawValue: opt)
                if opts.contains(.shouldResume) {
                    Logger.log("AVAudioSessionInterruptionNotification should resume")
                    if( self._wasPlaying )
                    {
                        let currentDoc = Transport.getCurrentDoc()
                        if( currentDoc != nil )
                        {
                            currentDoc!.play()
                        }
                        self._wasPlaying = false
                    }
                } else {
                    self._wasPlaying = false
                    Logger.log("AVAudioSessionInterruptionNotification should not resume")
                }
            }
        }
        
        // use control center to test, e.g. start and stop a Music song
        NotificationCenter.default.addObserver(
        forName: AVAudioSession.silenceSecondaryAudioHintNotification, object: nil, queue: nil) {
            (n:Notification) in
            guard let why = n.userInfo?[AVAudioSessionSilenceSecondaryAudioHintTypeKey] as? UInt else {return}
            guard let type = AVAudioSession.SilenceSecondaryAudioHintType(rawValue:why) else {return}
            if type == .begin {
                Logger.log("AVAudioSessionSilenceSecondaryAudioHintNotification silence hint begin:\n\(n.userInfo!)")
            } else {
                Logger.log("AVAudioSessionSilenceSecondaryAudioHintNotification silence hint end:\n\(n.userInfo!)")
            }
        }
        
        setupAudioFromPrefs()
        
        let inboxURL = _gFSH.getDocumentFolderURL()!.appendingPathComponent("Inbox")
        if( !_gFSH.directoryExists( inboxURL ) )
        {
            do
            {
                try _gFSH.createDirectory(at: inboxURL, withIntermediateDirectories: true, attributes: nil )
            }
            catch
            {
                
            }
        }
        
        /*
         if( _gFSH.directoryExists( inboxURL ) )
         {
         dm.delegate = self
         dm.startMonitoring()
         }*/
        
        // copy placeholders to documents
        let docplaceholderURL = _gFSH.getDocumentFolderURL()!
        let destDocPlaceholder = docplaceholderURL.appendingPathComponent("Song Placeholder.png")
        if( !_gFSH.fileExists(destDocPlaceholder)  )
        {
            do
            {
                let srcUrl = Bundle.main.url( forResource: "Song Placeholder", withExtension: "png")
                try _gFSH.copyItem(at: srcUrl!, to: destDocPlaceholder)
                //print( "copy \(srcUrl) to \(docplaceholderURL)")
            }
            catch
            {
                
            }
        }
        
        let destLoadingPlaceholder = docplaceholderURL.appendingPathComponent("Placeholder load.gif")
        if( !_gFSH.fileExists(destLoadingPlaceholder)  )
        {
            do
            {
                let srcUrl = Bundle.main.url( forResource: "Placeholder load", withExtension: "gif")
                try _gFSH.copyItem(at: srcUrl!, to: destLoadingPlaceholder)
                //print( "copy \(srcUrl) to \(docplaceholderURL)")
            }
            catch
            {
                
            }
        }
        
        let destSetPlaceholder = docplaceholderURL.appendingPathComponent("Set Placeholder.png")
        if( !_gFSH.fileExists(destSetPlaceholder) )
        {
            do
            {
                let srcUrl = Bundle.main.url( forResource: "Set Placeholder", withExtension: "png")
                try _gFSH.copyItem(at: srcUrl!, to: destSetPlaceholder)
                //print( "copy \(srcUrl) to \(docplaceholderURL)")
            }
            catch
            {
                
            }
        }
        
        return true
    }
    
    
    func processURL(openURL urlIn: URL)
    {
        // move from icloud if necessary
        let url = urlIn
        let isSecuredURL = url.startAccessingSecurityScopedResource() == true
        let coordinator = NSFileCoordinator()
        var error: NSError? = nil
        coordinator.coordinate(readingItemAt: url, options: [], error: &error) { (url) -> Void in
            
            // Create file URL to temporary folder
            var tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            // Apend filename (name+extension) to URL
            tempURL.appendPathComponent(url.lastPathComponent)
            do {
                // If file with same name exists remove it (replace file with new one)
                if FileManager.default.fileExists(atPath: tempURL.path) {
                    try FileManager.default.removeItem(atPath: tempURL.path)
                }
                // Move file from app_id-Inbox to tmp/filename
                try FileManager.default.copyItem(atPath: url.path, toPath: tempURL.path)
                
                self.processURL1(openURL: tempURL)
                //return tempURL
            } catch {
                print(error.localizedDescription)
                //return nil
            }
        }
        
        if (isSecuredURL) {
            url.stopAccessingSecurityScopedResource()
        }
    }
    
    func processURL1(openURL url: URL)
    {
        
        if( url.scheme == "muzoma.audioshare" )
        {
            Logger.log("AudioShare paste \(url.absoluteString)")
            self.nc.post(name: Notification.Name(rawValue: "AudioSharePaste"), object: url)
        }
        else if( url.pathExtension == "zip" )
        {
            Logger.log("Zip sent \(url.absoluteString)")
            let doc = Transport.getCurrentDoc()
            if( doc != nil )
            {
                _ = _gFSH.extractAudioTracksFromZip(doc, url: url, removeZip: false)
            }
            else
            {
                let alert = UIAlertController(title: "Import zip file", message: "Create and select a Muzoma document before attempting to import an audio zip", preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action: UIAlertAction!) in
                }))
                
                alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                let vc =  UIApplication.shared.keyWindow?.visibleViewController
                vc?.present(alert, animated: true, completion: {})
            }
        } else if( url.pathExtension == "mp3" || url.pathExtension == "wav" || url.pathExtension == "m4a" || url.pathExtension == "caf" )
        {
            Logger.log("Audio file sent \(url.absoluteString)")
            
            let doc = Transport.getCurrentDoc()
            if( doc != nil )
            {
                _ = _gFSH.extractAudioTracksFromZip(doc, url: url, removeZip: false)
            }
            else
            {
                let alert = UIAlertController(title: "Import audio file", message: "Create and select a Muzoma document before attempting to import an audio file", preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action: UIAlertAction!) in
                }))
                
                alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                let vc =  UIApplication.shared.keyWindow?.visibleViewController
                vc?.present(alert, animated: true, completion: {})
            }
        }
        else
        {
            let keyWind = UIApplication.shared.keyWindow!
            
            //print( "Process URL, visible VC \(keyWind.visibleViewController?.description)")
            
            if( !(keyWind.visibleViewController! is DocumentsCollectionViewController) )
            {
                let currentVC=keyWind.visibleViewController
                let navCtl = currentVC!.navigationController
                
                if( navCtl != nil )
                {
                    navCtl!.viewControllers.forEach({ (vc) in
                        if( vc is DocumentsCollectionViewController )
                        {
                            navCtl!.popToViewController(vc, animated: false)
                        }
                    })
                }
            }
            
            if( keyWind.visibleViewController is DocumentsCollectionViewController)
            {
                let docsVC = keyWind.visibleViewController as! DocumentsCollectionViewController?
                if( docsVC != nil )
                {
                    processURL1(openURL: url, docsVC: docsVC )
                }
            }
        }
        
    }
    
    func processURL1( openURL url: URL, docsVC: DocumentsCollectionViewController! )
    {
        let vc = docsVC
        let fs = _gFSH
        //docsVC.performSegueWithIdentifier("ComposeSegue", sender: nil) // show editor for this track
        
        //let scheme = url.scheme
        //let path = url.path
        //let query = url.query
        
        // e.g. file:///private/var/mobile/Containers/Data/Application/EF2BCF05-1B3B-402B-A2D1-DE2424366B96/Documents/Inbox/Band%20-%20Example%20Song.muz
        
        //print( "Got called with url: \(url.debugDescription)" )
        //print( "\(url.pathComponents!.description)" )
        let fileName = url.lastPathComponent
        let muzSet = fileName.hasSuffix(".set.muz")
        let fileExt = muzSet ? ".set.muz" : "." + url.pathExtension.lowercased()
        
        if( fileExt == ".set.muz" )
        {
            self.addSpinnerView()
            
            let alert = UIAlertController(title: "Load Muzoma set file", message: "Do you wish to load Muzoma set file \(fileName)?", preferredStyle: UIAlertController.Style.alert)
            
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                //print("load file Yes")
                DispatchQueue.main.async(execute: {
                    _ = url.startAccessingSecurityScopedResource()
                    _ = _gFSH.getMuzSetFromZip( url, callingVC: vc! )
                    _ = url.stopAccessingSecurityScopedResource()
                })
            }))
            
            alert.addAction(UIAlertAction(title: "No", style: .default, handler: { (action: UIAlertAction!) in
                //print("load file No")
                self.nc.post(name: Notification.Name(rawValue: "RefreshDocsView"), object: nil)
            }))
            
            alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            vc!.present(alert, animated: true, completion: {})
        }
        else if( fileExt == ".muz" )
        {
            self.addSpinnerView()
            
            let alert = UIAlertController(title: "Load Muzoma file", message: "Do you wish to load Muzoma file \(fileName)?", preferredStyle: UIAlertController.Style.alert)
            
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                //print("load file Yes")
                DispatchQueue.main.async(execute: {
                    _ = url.startAccessingSecurityScopedResource()
                    _ = _gFSH.getMuzDocFromZip( url, callingVC: vc! )
                    _ = url.stopAccessingSecurityScopedResource()
                })
            }))
            
            alert.addAction(UIAlertAction(title: "No", style: .default, handler: { (action: UIAlertAction!) in
                //print("load file No")
                self.nc.post(name: Notification.Name(rawValue: "RefreshDocsView"), object: nil)
            }))
            
            alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            vc!.present(alert, animated: true, completion: {})
        }
        else if( fileExt == ".pro" || fileExt == ".crd" || fileExt == ".cho" || fileExt == ".chrpro" || fileExt == ".chordpro" || fileExt == ".chopro") // chord pro import
        {
            let alert = UIAlertController(title: "Import Chord Pro", message: "Do you wish to import the chord pro format file \(fileName)?", preferredStyle: UIAlertController.Style.alert)
            
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                docsVC.performSegue(withIdentifier: "ComposeSegue", sender: nil) // show editor for this track
                let keyWind = UIApplication.shared.keyWindow!
                let importVC = keyWind.visibleViewController as! ImportTextDocumentViewController?
                DispatchQueue.main.async(execute: {
                    _ = url.startAccessingSecurityScopedResource()
                    importVC?.importProFromURL(url)
                    _ = url.stopAccessingSecurityScopedResource()
                })
            }))
            
            alert.addAction(UIAlertAction(title: "No", style: .default, handler: { (action: UIAlertAction!) in
                //print("load chord pro file No")
                do {
                    try fs.removeItem(at: url)
                    Logger.log("\(#function)  \(#file) Deleted \(url.absoluteString)")
                }
                catch let error as NSError {
                    Logger.log("\(#function)  \(#file)  \(error.localizedDescription)")
                }
            }))
            
            alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            vc!.present(alert, animated: true, completion: nil)
            
        } else if( fileExt == ".txt" || fileExt == ".rtf" ) // text file
        {
            let alert = UIAlertController(title: "Import text", message: "Do you wish to import the text from file \(fileName)?", preferredStyle: UIAlertController.Style.alert)
            
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                //print("load text file Yes")
                docsVC.performSegue(withIdentifier: "ComposeSegue", sender: nil) // show editor for this track
                let keyWind = UIApplication.shared.keyWindow!
                let importVC = keyWind.visibleViewController as! ImportTextDocumentViewController?
                DispatchQueue.main.async(execute: {
                    _ = url.startAccessingSecurityScopedResource()
                    importVC?.importTextFromURL(url)
                    _ = url.stopAccessingSecurityScopedResource()
                })
            }))
            
            alert.addAction(UIAlertAction(title: "No", style: .default, handler: { (action: UIAlertAction!) in
                //print("load text file No")
                do {
                    try fs.removeItem(at: url)
                    Logger.log("\(#function)  \(#file) Deleted \(url.absoluteString)")
                }
                catch let error as NSError {
                    Logger.log("\(#function)  \(#file)  \(error.localizedDescription)")
                }
            }))
            
            alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            vc!.present(alert, animated: true, completion: nil)
            
        } else if( fileExt == ".set" ) // set file
        {
            let alert = UIAlertController(title: "Import set", message: "Do you wish to import the Muzoma set file \(fileName)?", preferredStyle: UIAlertController.Style.alert)
            
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                //print("load set file Yes")
                // load text import controller
                let storyboard = vc?.storyboard //
                let importsetVC = storyboard!.instantiateViewController(withIdentifier: "SetsCollectionViewController") as! SetsCollectionViewController
                vc!.present(importsetVC, animated: true, completion: {})
            }))
            
            alert.addAction(UIAlertAction(title: "No", style: .default, handler: { (action: UIAlertAction!) in
                //print("load set file No")
            }))
            
            alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            vc!.present(alert, animated: true, completion: nil)
        }
    }
    
    
    var _appInBackground = false
    var _backgroundAudioTrack:AudioTrack! = nil
    func applicationWillResignActive(_ application: UIApplication) {
        Logger.log("applicationWillResignActive")
        
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        
        // if we need to stay running for midi, start up some empty audio
        let runBackground = UserDefaults.standard.bool(forKey: "runBackground_preference")
        var session = AVAudioSession.sharedInstance()
        if( runBackground )
        {
            DispatchQueue.main.async(execute: {
                // check for interruptions with phone calls
                if( !session.isOtherAudioPlaying && !session.secondaryAudioShouldBeSilencedHint )
                {
                    session = AVAudioSession.sharedInstance()
                    self._backgroundAudioTrack = AudioTrack()
                    self._backgroundAudioTrack.playSilent()
                }
            })
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        Logger.log("applicationDidEnterBackground")
        _appInBackground = true
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        Logger.log("applicationWillEnterForeground")
        _appInBackground = false
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
        DispatchQueue.main.async(execute: {
            if( self._backgroundAudioTrack != nil )
            {
                self._backgroundAudioTrack?.stopSilent(/*true*/)  // must de-init on the main thread or we end up with lock issues:(
                self._backgroundAudioTrack?.stop()
                self._backgroundAudioTrack?.cleanUp() // force no delay clean up on the main thread
                self._backgroundAudioTrack = nil
            }})
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        Logger.log("applicationDidBecomeActive")
        _appInBackground = false
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        DispatchQueue.main.async(execute: {
            if( self._backgroundAudioTrack != nil )
            {
                self._backgroundAudioTrack?.stopSilent(/*true*/)  // must de-init on the main thread or we end up with lock issues:(
                self._backgroundAudioTrack?.stop()
                self._backgroundAudioTrack?.cleanUp() // force no delay clean up on the main thread
                self._backgroundAudioTrack = nil
            }})
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        Logger.log("applicationWillTerminate")
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
    func loadExtURL( openURL url: URL )
    {
        let delay = DispatchTime.now() + Double(Int64(1.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delay,execute: {
            _ = url.startAccessingSecurityScopedResource()
            self.processURL(openURL: url)
            url.stopAccessingSecurityScopedResource()
        })
    }
    
    // for airdrop etc
    func application(_ application: UIApplication, open url: URL,
                     sourceApplication: String?, annotation: Any)-> Bool {
        
        Logger.log("In loading External URL 1: \(url)" )
        
        loadExtURL( openURL: url )
        
        return true
    }
    
    // for airdrop etc
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        Logger.log("In loading External URL 2: \(url)" )
        
        loadExtURL( openURL: url )
        
        return true
    }
    
    // for airdrop etc
    func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        
        Logger.log("In loading External URL 3: \(url)" )
        
        loadExtURL( openURL: url )
        
        return(true)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategoryArray(_ input: [AVAudioSession.Category]) -> [String] {
	return input.map { key in key.rawValue }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionModeArray(_ input: [AVAudioSession.Mode]) -> [String] {
	return input.map { key in key.rawValue }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}
