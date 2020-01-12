//
//  MultiChannelAudio.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 17/11/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//
//  Classes to handle the intricacies of Multi-channel audio in Swift
//

import Foundation
import CoreFoundation
import AudioToolbox
import AVFoundation
import Accelerate
import MediaPlayer
import MobileCoreServices

let kOutputBus = AudioUnitElement(0)
let kInputBus =  AudioUnitElement(1)
let minus1 = UInt32.max

// track levels structure
class TrackLevels :  NSObject, NSCopying {
    var track:Int = -1
    var trackCount:Int = 1
    var stereo:Bool = false
    var averagePowerForChannel0:Float32 = 0.00
    var averagePowerForChannel1:Float32 = 0.00
    var prevChannel0:Float32 = 0.00
    var prevChannel1:Float32 = 0.00
    
    override init()
    {
    }
    
    init(
        track:Int,
        trackCount:Int,
        stereo:Bool,
        averagePowerForChannel0:Float32,
        averagePowerForChannel1:Float32,
        prevChannel0:Float32,
        prevChannel1:Float32
        )
    {
        self.track                      = track
        self.trackCount                 = trackCount
        self.stereo                     = stereo
        self.averagePowerForChannel0    = averagePowerForChannel0
        self.averagePowerForChannel1    = averagePowerForChannel1
        self.prevChannel0               = prevChannel0
        self.prevChannel1               = prevChannel1
    }
    
    func copy(with zone: NSZone?) -> Any
    {
        let copy = TrackLevels(
            
            track:track,
            trackCount:trackCount,
            stereo:stereo,
            averagePowerForChannel0:averagePowerForChannel0,
            averagePowerForChannel1:averagePowerForChannel1,
            prevChannel0:prevChannel0,
            prevChannel1:prevChannel1
        )
        return copy
    }
}

class ChannelLevels {
    var channel:Int = -1
    var stereo:Bool = false
    var averagePowerForChannel0:Float32 = 0.00
    var averagePowerForChannel1:Float32 = 0.00
    var prevChannel0:Float32 = 0.00
    var prevChannel1:Float32 = 0.00
}


let noiseFloor:Float = 0.002
let noiseCeil:Float = 0.66
func meterNormalize( _ avgValue:Float, prevValue:Float ) -> Float
{
    // -20db = 0.063661
    // -9db = 0.22588
    // -3db = 0.450
    // 0db = 0.636607
    var norm = min(noiseCeil - noiseFloor,(max( avgValue, noiseFloor ) - noiseFloor)) // gives us number between 0 and noiseCeil - noiseFloor
    norm = ((norm * (100/(noiseCeil - noiseFloor))) / 100) // make it a percent
    norm = 16 * log10f(norm) // make it log scale
    norm = (((max( -50, norm ) + 50) * 2) / 100) // make it meterable
    return( norm )
}

// a self contained audio track class
// a player requires an engine, keep them together, otherwise
// end up in a mess
open class AudioTrack
{
    var _engine: AVAudioEngine! = nil
    var _player: AVAudioPlayerNode! = nil
    var _isPrimed: Bool = false
    var _multiTrackDetected = false
    let _nc = NotificationCenter.default
    var _songStartOffset:TimeInterval! = nil
    var _withRecord:Bool = false
    var _trackArmed:Bool = false
    var _startingChan = -1
    var _songFile:AVAudioFile! = nil
    var _recordChan:Int = -1
    var _stereoInput: Bool = false
    var _monitor:Bool = false
    var _monitorWhileRecording:Bool = false
    var _existingPlaybackURL:URL! = nil
    
    // allocate audio engines and players ahead of time
    init()
    {
        //Logger.log("in init() AudioTrack")
        // 1st one can take 50ms, then these ctrs take around 1ms
        _engine = AVAudioEngine()
        _player = AVAudioPlayerNode()
        _engine.attach(_player)
        //Logger.log("out init() AudioTrack")
    }
    
    // deallocate audio engines and players
    deinit
    {
        cleanUp()
    }
    
    func cleanUp()
    {
        // clean up
        // stop the player first - otherwise engine crashes with scheduled sounds pending
        // this call takes around 20ms
        //Logger.log("in deinit AudioTrack")
        if( self._player != nil )
        {
            if(_player.isPlaying)
            {
                _player.stop()
            }
            _player.reset()
            _engine?.detach(_player)
            if( Thread.isMainThread )
            {
                self._player = nil
            }
            else
            {
                // must de-init on the main thread or we end up with lock issues:(
                Logger.log( "deinit _player AudioTrack not called on the main thread")
            }
        }
        
        if( self._engine != nil )
        {
            _engine?.stop()
            _tappedNode?.removeTap(onBus: 0) // kill tap
            _tappedNode = nil
            _engine?.reset()
            
            if( Thread.isMainThread )
            {
                self._engine = nil
            }
            else
            {
                // must de-init on the main thread or we end up with lock issues:(
                Logger.log( "deinit AudioTrack not called on the main thread")
            }
        }
    }
    
    var _emptyBuff:AVAudioPCMBuffer! = nil
    func getEmptyBuffer( _ format:AVAudioFormat!, frameCount:Int = 50000 ) -> AVAudioPCMBuffer!
    {
        
        if( _emptyBuff == nil )
        {
            let frameCount:AVAudioFrameCount = AVAudioFrameCount(frameCount)
            let buffLen:AVAudioFrameCount = frameCount
            
            let outBuffer = AVAudioPCMBuffer( pcmFormat: format, frameCapacity: buffLen )
            
            var readIdx = Int(outBuffer!.frameLength)
            repeat
            {
                outBuffer!.floatChannelData?.pointee[readIdx] = 0
                readIdx -= 1
            } while( readIdx > -1  )
            outBuffer!.frameLength = frameCount
            _emptyBuff = outBuffer
        }
        return( _emptyBuff )
    }
    
    var _stopSilent = false
    var _playingSilence = false
    var _silentStartTime:Date! = nil
    let _silentTimeoutSecs = 60.0 * 60.0
    
    func stopSilent( _ noWait:Bool = false )
    {
        if( _engine != nil && _player != nil && _playingSilence )
        {
            _stopSilent = true
            _silentStartTime = nil
            
            var retryCount = 1000
            repeat
            {
                if( _playingSilence )
                {
                    //Logger.log("Waiting for silence to end")
                    usleep(10000)
                }
                retryCount -= 1
            } while _playingSilence && retryCount > 0 && noWait == false
            //_engine.detachNode(_player)
            _player = nil
        }
    }
    
    // play silence so that the audio is not out of scoped by the OS - allows background audio to continue
    func playSilent()
    {
        _stopSilent = false
        _silentStartTime = Date()
        do
        {
            if( !_engine.isRunning )
            {
                //Logger.log("Starting playSilent()")
                Logger.log("playSilent output node format:\(_engine.outputNode.outputFormat(forBus: 0).debugDescription)\nplayer node format:\(_player.outputFormat(forBus: 0).debugDescription)\nmainMixerNode  format:\(_engine.mainMixerNode.outputFormat(forBus: 0).debugDescription)" )
                
                _engine.connect(_player, to: _engine.mainMixerNode, format: _player.outputFormat(forBus: 0) )
                _engine.connect(_engine.mainMixerNode, to: _engine.outputNode, format: _engine.mainMixerNode.outputFormat(forBus: 0) )
                //_engine.connect(_player, to: _engine.outputNode, format: _engine.outputNode.outputFormatForBus(0) )
                 //Logger.log("playSilent _engine.prepare" )
                _engine.prepare()
                //Logger.log("playSilent _engine.start" )
                try _engine.start()
               // Logger.log("Started playSilent()")
            }
        }
        catch let error as NSError
        {
            Logger.log( "playSilent error \(error.localizedDescription)" )
            if( _player != nil && _player!.isPlaying )
            {
                _player.stop()
            }
            _playingSilence = false
        }
        
        doPlaySilent()
        
        if( Transport.getCurrentDoc() == nil )
        {
            let silentInfo:[String : AnyObject]! =
                [
                    MPMediaItemPropertyTitle: "Background audio" as AnyObject,
                    MPMediaItemPropertyArtist: "Muzoma" as AnyObject,
                    MPMediaItemPropertyComposer: "Muzoma" as AnyObject,
                    MPNowPlayingInfoPropertyElapsedPlaybackTime: 0.0 as AnyObject,
                    MPNowPlayingInfoPropertyPlaybackRate: 1.0 as AnyObject,
                    MPMediaItemPropertyPlaybackDuration: TimeInterval(_silentTimeoutSecs) as AnyObject
                    //MPMediaItemPropertyArtwork: self._artwork,
                    //MPMediaItemPropertyReleaseDate: (self._lastUpdateDate?.formatted)!
            ]
            
            MPNowPlayingInfoCenter.default().nowPlayingInfo = silentInfo
            
            MPRemoteCommandCenter.shared().togglePlayPauseCommand.isEnabled = false
            MPRemoteCommandCenter.shared().playCommand.isEnabled = false
            MPRemoteCommandCenter.shared().pauseCommand.isEnabled = false
            MPRemoteCommandCenter.shared().stopCommand.isEnabled = false
            MPRemoteCommandCenter.shared().seekForwardCommand.isEnabled = false
            MPRemoteCommandCenter.shared().seekBackwardCommand.isEnabled = false
        }
    }
    
    fileprivate func doPlaySilent()
    {
        let timeResultOK = _silentStartTime != nil ? !(Date().timeIntervalSince1970 > _silentStartTime.addingTimeInterval( TimeInterval(_silentTimeoutSecs) ).timeIntervalSince1970) : false
        
        if( !_stopSilent && timeResultOK && _player != nil )
        {
            _player!.scheduleBuffer(getEmptyBuffer(_player.outputFormat(forBus: 0)), completionHandler:
                {
                    if( !self._stopSilent )
                    {
                        self.doPlaySilent()
                    }
                    else
                    {
                         self._playingSilence = false
                    }
            })
            
            if(  !_player!.isPlaying )
            {
                _player?.play()
                _playingSilence = true
            }
        }
        else
        {
            self._playingSilence = false
        }
    }
    
    // takes an audio file and sets the player/recorder ready
    // this call takes around 30ms on an average iPad
    // priming allows the syncronisation of multiple audio tracks, it also handles the i/o mapping of avaudiosession, playback speed and down mixing if necessary
    func primeTrack( _ startingChan:Int, songFile:AVAudioFile!, requestMonoDownMix:Bool = true, ignoreDownmixOnMultiChan:Bool = true,
                     ignoreDownmixiDevice:Bool = true, speed:Float = 1.0, songStartOffset:TimeInterval, withRecord: Bool = false, trackArmed: Bool = false,
                     recordChan:Int, stereoInput: Bool, monitor:Bool, monitorWhileRecording: Bool  )
    {
        _songStartOffset = songStartOffset
        _withRecord = withRecord
        _trackArmed = trackArmed
        _startingChan = startingChan
        _recordChan = recordChan
        _stereoInput = stereoInput
        _monitor = monitor
        _monitorWhileRecording = monitorWhileRecording
        _tappedNode = nil
        
        //let inputUrl:String = songFile.url.absoluteString
        //print( "file: \(inputUrl)" )
        if( !_isPrimed  )
        {
            _isPrimed = true
            
            if( !(_withRecord && trackArmed) ) // playing not recording
            {
                if( songFile != nil )
                {
                    _songFile = songFile
                    //Logger.log(  "start: primeTrack \(startingChan) ignoreDownmixOnMultiChan: \(ignoreDownmixOnMultiChan) speed: \(speed)" )
                    
                    do
                    {
                        /* based on http://stackoverflow.com/questions/21832733/how-to-use-avaudiosessioncategorymultiroute-on-iphone-device/35009801 */
                        
                        let output = _engine.outputNode
                        let outChanCount:Int = Int( output.outputFormat(forBus: 0).channelCount )
                        let songFileChanCount = songFile.processingFormat.channelCount
                        
                        //Logger.log(  "outChanCount: \(outChanCount) songFileChanCount: \(songFileChanCount)" )
                        
                        // multi channel out
                        if( outChanCount > 2 )
                        {
                            _multiTrackDetected = true
                            
                            // Play audio to output channel3, channel4
                            // let outputChannelMap = [-1, -1, 0, 1]
                            // This will play audio to output channel1, channel2
                            // [0, 1, -1, -1]
                            let minus1 = UInt32.max
                            var outputChannelMap:[UInt32] = [UInt32]() //= [ minus1, minus1, UInt32(0), UInt32(1)]
                            let allocChanStartIdx:Int = ((startingChan % (outChanCount+1)) - 1)
                            let allocChanEndIdx = allocChanStartIdx + Int(songFileChanCount)
                            Logger.log(  "Multi channel configuration detected \(outChanCount) chans, playing \(songFileChanCount) chans starting on \(startingChan) allocChanStartIdx \(allocChanStartIdx), allocChanEndIdx \(allocChanEndIdx)" )
                            
                            for chanCnt in ( 0 ..< outChanCount )
                            {
                                if( chanCnt >= allocChanStartIdx && chanCnt < allocChanEndIdx )
                                {
                                    outputChannelMap.append( UInt32(chanCnt - allocChanStartIdx) )
                                }
                                else
                                {
                                    outputChannelMap.append( minus1 )
                                }
                            }
                            
                            Logger.log(  "start chan \(startingChan) audio output channel map \(outputChannelMap.debugDescription)" )
                            // set channel map on outputNode AU need to implement AVAudioIONode
                            let err:OSStatus = AudioUnitSetProperty( output.audioUnit!, kAudioOutputUnitProperty_ChannelMap, kAudioUnitScope_Global, 0, outputChannelMap, UInt32(outputChannelMap.count * 4))
                            
                            if( err != 0 )
                            {
                                Logger.log(  "start chan \(startingChan) audio track set prop chan map err \(err)" )
                            }
                        }
                        else
                        {
                            //Logger.log(  "Non Multi channel configuration detected" )
                        }
                        
                        let doMonoDownMix = (songFileChanCount==1 && !_multiTrackDetected) /* for some reason, we still have to re-sample mono input files to mono*/ || ( requestMonoDownMix && ( (_multiTrackDetected==false && !ignoreDownmixiDevice) || (_multiTrackDetected == true && !ignoreDownmixOnMultiChan && songFileChanCount > 1 )))
                        
                        /*
                         Logger.log( "doMonoDownMix: \(doMonoDownMix)" )
                         Logger.log(  "stream desc: \(songFile.processingFormat.streamDescription)" )
                         */
                        // make connections
                        // for panning, only works with the environment mixer and mono input sources
                        
                        // take the input and downcast to mono?
                        var monoDownMix:AVAudioNode! = nil
                        if( doMonoDownMix  )
                        {
                            //Logger.log( "doing Mono Down Mix" )
                            monoDownMix = AVAudioMixerNode()
                            let monoChannelLayout = AVAudioChannelLayout( layoutTag: kAudioChannelLayoutTag_DiscreteInOrder | UInt32(1) )
                            let monoFormat = AVAudioFormat(standardFormatWithSampleRate: songFile.processingFormat.sampleRate, channelLayout: monoChannelLayout!)
                            _engine.attach(monoDownMix)
                            _engine.connect(_player, to: monoDownMix, format: monoFormat )
                            Logger.log(  "start chan \(startingChan) _engine.connect player, to: mono downmix: \(monoFormat.description)" )
                        }
                        else
                        {
                            Logger.log( "start chan \(startingChan) NOT doing Mono Down Mix multiTrackDetected: \(_multiTrackDetected) ignoreDownmixOnMultiChan: \(ignoreDownmixOnMultiChan) ignoreDownmixOniDevice: \(ignoreDownmixiDevice)" )
                            monoDownMix = _player
                        }
                        
                        let outputChannelCount = _engine.outputNode.outputFormat(forBus: 1).channelCount
                        let hardwareSampleRate = _engine.outputNode.outputFormat(forBus: 1).sampleRate
                        let renderAsChannelCount = _multiTrackDetected ? songFileChanCount : outputChannelCount // how many chans to render on our output
                        
                        Logger.log( "start chan \(startingChan) doMonoDownMix: \(doMonoDownMix) outputChannelCount: \(outputChannelCount) hardwareSampleRate: \(hardwareSampleRate) renderAsChannelCount: \(renderAsChannelCount)" )
                        
                        var environment:AVAudioEnvironmentNode! = nil
                        if( doMonoDownMix && outputChannelCount > 1/*iphone speaker*/  ) // need environment node to reposition L R
                        {
                            //Logger.log( "using environment node" )
                            environment = AVAudioEnvironmentNode()
                            _engine.attach(environment)
                            let environmentOutputConnectionFormat = AVAudioFormat(standardFormatWithSampleRate: hardwareSampleRate, channels: renderAsChannelCount)
                            _player.renderingAlgorithm = .equalPowerPanning //AVAudio3DMixingRenderingAlgorithm.EqualPowerPanning
                            _engine.connect(monoDownMix, to: environment, format: environmentOutputConnectionFormat /* outputFormat*//* inputFormat*/ )
                            //Logger.log( "connected environment node" )
                            //mixer = environment
                            Logger.log(  "start chan \(startingChan) _engine.connect player, to: environment: \(environmentOutputConnectionFormat!.description)" )
                        }
                        
                        // now we have the correct mixer and player ready to pitch
                        let mixer = _engine.mainMixerNode as AVAudioNode
                        let player = environment != nil ? environment : monoDownMix
                        
                        // figure out the channel layout
                        let outputChannelLayout = AVAudioChannelLayout( layoutTag: kAudioChannelLayoutTag_DiscreteInOrder | UInt32(renderAsChannelCount) )
                        //woz let outputFormat = AVAudioFormat(standardFormatWithSampleRate: songFile.processingFormat.sampleRate, channelLayout: outputChannelLayout)
                        let outputFormat = AVAudioFormat(standardFormatWithSampleRate: _engine.outputNode.outputFormat(forBus: 0).sampleRate, channelLayout: outputChannelLayout!)
                        
                        /* playback speed */
                        if( speed != 1.0 ) // insert a time pitch processor
                        {
                            //Logger.log( "connecting pitch unit" )
                            let auTimePitch = AVAudioUnitTimePitch()
                            auTimePitch.pitch = 0.0 // In cents. The default value is 1.0. The range of values is -2400 to 2400
                            auTimePitch.rate = abs(speed)  //The default value is 1.0. The range of supported values is 1/32 to 32.0.
                            _engine.attach(auTimePitch)
                            _engine.connect(player!, to: auTimePitch, format: outputFormat )
                            _engine.connect(auTimePitch, to: mixer, format: outputFormat )
                            //Logger.log( "done connecting pitch unit" )
                        }
                        else
                        {
                            //Logger.log( "connecting player to mixer" )
                            _engine.connect(player!, to: mixer, format: outputFormat )
                            //Logger.log(  "_engine.connect player, to: mixer: \(inputFormat.description)" )
                            //Logger.log( "done connecting player to mixer" )
                        }
                        
                        //Logger.log( "connecting mixer to output with outputFormat: \(outputFormat)" )
                        // mixer -> Output
                        _engine.connect(mixer, to: output, format: outputFormat)
                        Logger.log(  "start chan \(startingChan) _engine.connect mixer, to: _engine.mainMixerNode: \(outputFormat.description)" )
                        //Logger.log( "done connecting mixer to output with outputFormat: \(outputFormat)" )
                        
                        // tap the mixer for level data
                        let levelData = ChannelLevels()
                        mixer.installTap(onBus: 0, bufferSize: 1024, format: nil ) {
                            (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
                            
                            // scan through the channels and get and publish the meter data we need
                            
                            if( buffer.format.channelCount > 0 && self._tappedNode != nil)
                            {
                                levelData.channel = self._originalRecordedTrackIdx
                                
                                let inNumberFrames:UInt32 = buffer.frameLength
                                let samplesCh1:UnsafeMutablePointer<Float32> = buffer.floatChannelData![0] // L or chan 1
                                
                                vDSP_meamgv(samplesCh1, 1, &levelData.averagePowerForChannel0, vDSP_Length(inNumberFrames))
                                levelData.prevChannel0  = meterNormalize(levelData.averagePowerForChannel0, prevValue: levelData.prevChannel0)
                                levelData.averagePowerForChannel0 = levelData.prevChannel0
                                if(  buffer.format.channelCount > 1 )
                                {
                                    levelData.stereo = true
                                    let samplesCh2:UnsafeMutablePointer<Float32> = buffer.floatChannelData![1] // R or chan 2
                                    vDSP_meamgv(samplesCh2, 1, &levelData.averagePowerForChannel1, vDSP_Length(inNumberFrames))
                                    levelData.prevChannel1  = meterNormalize(levelData.averagePowerForChannel1, prevValue: levelData.prevChannel1)
                                    levelData.averagePowerForChannel1 = levelData.prevChannel1
                                }
                                
                                self._nc.post(name: Notification.Name(rawValue: "OutputTrackLevel"), object:levelData)
                            }
                            
                            return
                        }
                        
                        _tappedNode = mixer
                        
                        //Logger.log( "start engine" )
                        if( !_engine.isRunning )
                        {
                            //_engine.prepare()
                            try _engine.start()
                            //Logger.log( "done start engine" ) // takes 3ms from prepare to start
                        }
                    }
                    catch let error as NSError
                    {
                        Logger.log( "start chan \(startingChan) error \(error.localizedDescription)" )
                    }
                    
                } else // no song file
                {
                    
                }
            }
            else
            {
                // recording
                _recFile = songFile
            }
        }
        
        //Logger.log(  "end: primeTrack" )
    }
    
    // stop playback
    var _recordedFileURL:URL! = nil
    var _originalRecordedTrackIdx:Int = -1
    func stop()
    {
        self._player?.stop()
        _emptyBuff = nil
        
        if( self._recFile != nil ) // recording
        {
            _recordedFileURL = nil
            let srcURL = (self._recFile!.url as NSURL).filePathURL
            self._recFile = nil
            _engine?.stop()
            _tappedNode?.removeTap(onBus: 0) // kill tap
            _tappedNode = nil
            
            if( srcURL != nil && _firstRecTime != nil)
            {
                let padder = AudioUtils()
                
                //Logger.log( "record done" )
                var m4url:URL! = nil
                if( srcURL!.pathExtension != "m4a" )
                {
                    //Logger.log( "convert to m4a" )
                    m4url = padder.toM4a(srcURL!, synchronous: false)
                }
                else
                {
                    m4url = srcURL!
                }
                
                if( m4url != nil )
                {
                    let syncTime = _requestedSyncTime.hostTime
                    // figure latency compensation
                    let recTime = _firstRecTime.hostTime + AVAudioTime.hostTime(forSeconds: _songStartOffset) - AVAudioTime.hostTime(forSeconds: AVAudioSession.sharedInstance().inputLatency) - AVAudioTime.hostTime(forSeconds: AVAudioSession.sharedInstance().ioBufferDuration)
                    
                    //Logger.log( "pad/trunc m4a" )
                    
                    let inputLatency = AVAudioSession.sharedInstance().inputLatency
                    let dur = AVAudioSession.sharedInstance().ioBufferDuration
                    
                    //                   306                                      325                                       0
                    Logger.log("_firstRecTime:\(_firstRecTime.hostTime)  _requestedSyncTime:\(_requestedSyncTime.hostTime) _songStartOffset:\(String(describing: _songStartOffset)) syncTime:\(syncTime), input latency \(inputLatency.debugDescription), ioBuff \(dur.debugDescription)" )
                    
                    // captured more than we need so truncate the recording
                    if( syncTime > recTime )
                    {
                        let hostTime = syncTime - recTime
                        let secondsToTruncate = AVAudioTime.seconds(forHostTime: hostTime)
                        let samples = (secondsToTruncate * AVAudioSession.sharedInstance().sampleRate)
                        let offsetTime = AVAudioTime(hostTime: hostTime, sampleTime: AVAudioFramePosition(samples), atRate: AVAudioSession.sharedInstance().sampleRate)
                        let truncer = padder.trunc( self._existingPlaybackURL, audio1In: m4url, truncTime: offsetTime, synchronous: false)
                        if( truncer != nil )
                        {
                            _recordedFileURL = truncer
                        }
                    }
                    else // captured less than we need so pad the recording
                    {
                        let hostTime = recTime - syncTime
                        let secondsToPad = AVAudioTime.seconds(forHostTime: hostTime)
                        let samples = ((secondsToPad * AVAudioSession.sharedInstance().sampleRate))
                        let offsetTime = AVAudioTime(hostTime: hostTime, sampleTime: AVAudioFramePosition(samples), atRate: AVAudioSession.sharedInstance().sampleRate)
                        let padded = padder.pad( self._existingPlaybackURL, audio1In: m4url, padTime: offsetTime, synchronous: false)
                        if( padded != nil )
                        {
                            _recordedFileURL = padded
                        }
                    }
                }
                self._recFile = nil
            }
        }
        else // playback
        {
            _tappedNode?.reset()
            // !!! check for crash - race condition
            _tappedNode?.removeTap(onBus: 0) // kill tap
            _tappedNode = nil
        }
    }
    
    
    // Recording, handle the channel and buffer mapping
    var _tappedNode:AVAudioNode! = nil
    var _recFile:AVAudioFile! = nil
    var _firstRecTime:AVAudioTime! = nil
    var _requestedSyncTime:AVAudioTime! = nil
    var err:OSStatus! = nil
    let buffLen = AVAudioFrameCount(32768)
    var outBuffer:AVAudioPCMBuffer! = nil
    
    func recordAtTime(_ when: AVAudioTime?, track:AudioTrack!)
    {
        // set channel map on outputNode AU need to implement AVAudioIONode
        // see http://stackoverflow.com/questions/16674760/how-to-set-scope-and-element-when-using-audio-unit
        //Logger.log( "Record at time \(when), Track primed \(self._isPrimed), Track record armed \(self._trackArmed))" )
        _requestedSyncTime = when
        
        outBuffer = AVAudioPCMBuffer( pcmFormat: self._recFile.processingFormat, frameCapacity: buffLen )
        
        let input = _engine.inputNode

        let inChanCount:Int = Int( input.inputFormat(forBus: 0).channelCount ) // num of input chans avail
        let inOutbusChanCount:Int = Int( input.outputFormat(forBus: 0).channelCount ) // num of outputs on input
        let startChan = ((_recordChan-1) % inChanCount) // starting chan given specified rec chan - zero relative
        let songFileChanCount:Int = min( (_stereoInput ? 2 : 1), inChanCount > 1 ? 2 : 1, inChanCount-startChan  )
        let endChan = startChan + songFileChanCount
        let inputLatency = AVAudioSession.sharedInstance().inputLatency
        let dur = AVAudioSession.sharedInstance().ioBufferDuration
        Logger.log( "Record at time, \(self._recFile.url.absoluteString) \(String(describing: when)), Track primed \(self._isPrimed), Track record armed \(self._trackArmed) song start offset \(_songStartOffset.debugDescription), original rec chan \(_recordChan), start chan \(startChan), end chan \(endChan), input Chan Count \(inChanCount), output bus count \(inOutbusChanCount), song file chan count \(songFileChanCount), input latency \(inputLatency.debugDescription), ioBuff \(dur.debugDescription) rec file format \(self._recFile.fileFormat.debugDescription)" )
        
        // recording
        do
        {
            //Logger.log("")
            
            if(track != nil )
            {
                _tappedNode  = _engine.inputNode
                
                _tappedNode.installTap(onBus: 0, bufferSize: buffLen, format: nil ) {
                    (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
                    //Logger.log("buff rx \(time) : \(self._recFile.url.debugDescription)")
                    
                    if( self.outBuffer.frameCapacity < buffer.frameCapacity )
                    {
                        // re-allocate the buffer
                        self.outBuffer = AVAudioPCMBuffer( pcmFormat: self._recFile.processingFormat, frameCapacity: buffer.frameCapacity )
                    }
                    
                    if( self._firstRecTime == nil ) // capture the first record time
                    {
                        self._firstRecTime = time
                    }
                    
                    // meter and file data
                    if( buffer.format.channelCount >= AVAudioChannelCount(endChan) )
                    {
                        self.outBuffer.frameLength = buffer.frameLength
                        let inNumberFrames:UInt32  = buffer.frameLength
                        let samplesCh1:UnsafeMutablePointer<Float32> = buffer.floatChannelData![startChan] // L or chan 1
                        self.outBuffer.floatChannelData![0].assign(from: samplesCh1, count: Int(inNumberFrames)) // copy data to our file's buffer
                        
                        //Logger.log("Chan \(startChan)  Power \(self.averagePowerForChannel0)")
                        
                        // stereo file?
                        if( endChan > startChan+1 )
                        {
                            let samplesCh2:UnsafeMutablePointer<Float32> = buffer.floatChannelData![endChan-1] // R or chan 2
                            //Logger.log("Chan \(endChan-1) Power \(self.averagePowerForChannel1)")
                            self.outBuffer.floatChannelData![1].assign(from: samplesCh2, count: Int(inNumberFrames)) // copy data to our file's buffer
                        }
                        
                        do
                        {
                            if( self._recFile != nil )
                            {
                                try self._recFile?.write(from: self.outBuffer)
                            }
                        }
                        catch let error as NSError
                        {
                            Logger.log( "error \(error.localizedDescription)" )
                        }
                    }
                    
                    return
                }
            }
            
            if( !_engine.isRunning )
            {
                _engine.prepare() // takes 3ms from prepare to start
                try _engine.start()
                //Logger.log( "done record start engine" )
            }
        }
        catch let error as NSError
        {
            Logger.log( "error \(error.localizedDescription)" )
        }
    }
}

// wrapper class handles a set of tracks for multi-channel audio
open class MultiChannelAudio
{
    var _audioTracks:[AudioTrack?]! = nil
    let _nc = _gNC
    let _trackPlayerQueue:DispatchQueue = DispatchQueue( label: "trackPlayerQueue" )
    var _trackIdxs: [Int] = []

    // allocate audio engines and players ahead of time
    init( numberOfTracksRequired:Int )
    {
        //Logger.log("Init multi track 1" )
        _audioTracks = [AudioTrack?]()
        
        for _ in (0 ..< numberOfTracksRequired)
        {
            _audioTracks.append( AudioTrack() )
        }
    }
    
    init( guideTrackIdx:Int, backingTrackIdxs: [Int] )
    {
        //Logger.log("Init multi track 2" )
        _audioTracks = [AudioTrack?]()
        
        let numberOfTracksRequired = 1 + backingTrackIdxs.count
        
        for trackCnt in (0 ..< numberOfTracksRequired)
        {
            if( trackCnt == 0)
            {
                _trackIdxs.append(guideTrackIdx)
            }
            else
            {
                _trackIdxs.append(backingTrackIdxs[trackCnt-1])
            }
            
            _audioTracks.append( AudioTrack() )
        }
    }
    
    fileprivate var _isPlaying:Bool = false
    var isPlaying:Bool
        {
        get{ return( _isPlaying ) }
    }
    
    func getAudioIndexFromTrackIndex( _ trackIndex:Int ) -> Int
    {
        var ret = -1
        let idx = _trackIdxs.index(of: trackIndex)
        if( idx != nil )
        {
            ret = idx!
        }
        return( ret )
    }
    
    func getTrackIndexFromAudioIndex( _ audioIndex:Int ) -> Int
    {
        var ret = -1
        
        let idx:Int! = audioIndex < _trackIdxs.count ? _trackIdxs[audioIndex] : nil
        
        if( idx != nil )
        {
            ret = idx!
        }
        return( ret )
    }
    
    func playAtTime(_ when: AVAudioTime?, withRecord:Bool = false)
    {
        _isPlaying = true
        let audioPlayersGroupService:DispatchGroup = DispatchGroup()
        
        for (idx,track) in self._audioTracks.enumerated()
        {
            track!._originalRecordedTrackIdx = getTrackIndexFromAudioIndex(idx)
            //Logger.log("original recorded track index \( track!._originalRecordedTrackIdx)")
            
            audioPlayersGroupService.enter()
            self._trackPlayerQueue.async(execute: {
                if( track?._player != nil )
                {
                    //Logger.log( "track \(idx) - play at time" )
                    if( (track?._trackArmed)! && withRecord)
                    {
                        track?.recordAtTime(when, track: track)
                    }
                    else if( track?._player != nil && (track?._player.engine!.isRunning)! )
                    {
                        track?._player?.play(at: when)
                    } else
                    {
                        //Logger.log( "track \(idx) - expected player engine to be running!" )
                    }
                    //track._player?.prepareWithFrameCount(2048)
                    //Logger.log( "track \(idx) - done play at time" )
                }
                else
                {
                    Logger.log( "track \(idx) - no player!" )
                }
                audioPlayersGroupService.leave()
            })
        }
        
        // allow all the player threads to complete and join together to sync them in playback
        _ = audioPlayersGroupService.wait(timeout: DispatchTime.distantFuture)
    }
    
    // returns any tracks that were recorded
    func stop( _ waitForCleanup:Bool = false ) -> [AudioTrack?]!
    {
        var _retRecordedTracks:[AudioTrack?]! = [AudioTrack?]()
        _isPlaying = false
        var idx = 0
        for track in _audioTracks
        {
            track?.stop()

            if( waitForCleanup )
            {
                track?.cleanUp()
            }
            if( track?._recordedFileURL != nil )
            {
                _retRecordedTracks.append(track)
            }
            idx = idx + 1
        }

        return( _retRecordedTracks )
    }
}

// class to handle the monitoring of audio levels
open class MonitorAudio
{
    var _specifics:[AudioEventSpecifics?]! = nil
    let _nc = NotificationCenter.default
    var _tappedNode:AVAudioNode! = nil
    
    init( guideTrackSpecifics:AudioEventSpecifics!, backingTrackSpecifics:[AudioEventSpecifics?], recordArmed:Bool = false, recording:Bool = false )
    {
        initMonitor(guideTrackSpecifics,backingTrackSpecifics: backingTrackSpecifics, recordArmed: recordArmed, recording: recording)
        _nc.addObserver(self, selector: #selector(MonitorAudio.audioSpecificsChanged(_:)), name: NSNotification.Name(rawValue: "AudioSpecificsChanged"), object: nil)
    }
    
    // deallocate audio engines and players
    deinit
    {
        //Logger.log("deinit monitor" )
        _nc.removeObserver( self, name: NSNotification.Name(rawValue: "AudioSpecificsChanged"), object: nil )
        end()
    }
    
    @objc func audioSpecificsChanged(_ notification: Notification) {
        _specifics = (notification.object as! [AudioEventSpecifics?])
        
        // todo bug??
        initMonitor()
    }
    
    func end()
    {
        // clean up
        if( _monitorEngine != nil )
        {
            Logger.log("end monitor" )
            _monitorEngine?.stop()
            // remove the tap - must be done after calling stop
            _tappedNode?.removeTap(onBus: 0)
            _tappedNode = nil
            _monitorEngine?.reset()
            _monitorEngine = nil
        }
    }
    
    var _recordArmed = false
    var _recording = false
    
    fileprivate func initMonitor( _ guideTrackSpecifics:AudioEventSpecifics!, backingTrackSpecifics:[AudioEventSpecifics?], recordArmed:Bool = false, recording:Bool = false )
    {
        //Logger.log("initMonitor" )
        _specifics = [AudioEventSpecifics?]()
        _specifics.append(guideTrackSpecifics)
        _specifics.append(contentsOf: backingTrackSpecifics)
        _recordArmed = recordArmed
        _recording = recording
        
        initMonitor()
    }
    
    // monitor is separate from play, we use the specifics to determine what the channel map should be
    // and grab the input levels
    var _monitorEngine:AVAudioEngine! = nil
    fileprivate func initMonitor()
    {
        //Logger.log("monitor init")
        end()
        _monitorEngine = AVAudioEngine()
        
        
        let input = _monitorEngine.inputNode
        let output = _monitorEngine.outputNode
        
        var inputChannelMap:[UInt32] = [UInt32]()
        var outputChannelMap:[UInt32] = [UInt32]()
        
        let inChanCount:Int = Int( input.outputFormat(forBus: 0).channelCount ) // num of input chans avail
        let outChanCount:Int = Int( output.inputFormat(forBus: 0).channelCount ) // num of ouput chans avail
        
        //Logger.log("monitor in chan cnt \(inChanCount)")
        // clear down the default input channel mapping
        for _ in ( 0 ..< inChanCount )
        {
            inputChannelMap.append( minus1 )
        }
        //Logger.log("monitor done in chan cnt \(inChanCount)")
        
        // clear down the default output channel mapping
        for _ in ( 0 ..< outChanCount )
        {
            outputChannelMap.append( minus1 )
        }
        
        for specific in _specifics
        {
            //Logger.log("monitor specific chan \(specific?.chan)")
            
            if( specific != nil && (specific?.recordArmed)! ) // monitor when red record armed is set
            {
                let inputChan = (((specific?.inputChan)! - 1) % inChanCount)
                let outputChan = (((specific?.chan)! - 1) % outChanCount)
                //doneMap = true
                
                inputChannelMap[inputChan] = UInt32(inputChan)
                
                if( (specific?.monitorInput)! || (_recording && (specific?.monitorWhileRecording)!) )
                {
                    outputChannelMap[outputChan] = UInt32(inputChan)
                }
                
                let inputChan2:Int = ((specific!.inputChan) % inChanCount)
                let outputChan2:Int = ((specific!.chan) % outChanCount)
                if( (specific?.stereoInput)! && !(specific?.downmixToMono)!) // stereo in / stereo out
                {
                    inputChannelMap[inputChan2] = UInt32(inputChan2)
                    if( (specific?.monitorInput)! || (_recording && (specific?.monitorWhileRecording)!) )
                    {
                        outputChannelMap[outputChan2] = UInt32(inputChan2)
                    }
                }
            }
        }
        
        //Logger.log("monitor: input.inputFormatForBus(0) \(input.inputFormatForBus(0).debugDescription)\n inputChannelMap \(inputChannelMap.debugDescription)")
        //the order here matters!
        // we are mapping the internals of the input's audio unit - the physical input channels
        
        //var err:OSStatus! = nil
        /*err = */AudioUnitSetProperty( input.audioUnit!, kAudioOutputUnitProperty_ChannelMap, kAudioUnitScope_Global, kInputBus, inputChannelMap, UInt32(inputChannelMap.count * 4))
        
        // set channel map on outputNode AU need to implement AVAudioIONode
        /*err = */AudioUnitSetProperty( output.audioUnit!, kAudioOutputUnitProperty_ChannelMap, kAudioUnitScope_Input, /*kInputBus*/ kOutputBus, outputChannelMap, UInt32(outputChannelMap.count * 4))
        
        _monitorEngine.connect(input, to: output, format: input.inputFormat(forBus: 0) )
        
        let buffLen = AVAudioFrameCount(1024)
        _tappedNode = input
        
        //var levelDatas = [TrackLevels!](count:self._specifics.count, repeatedValue: TrackLevels())
        //Logger.log("monitor: install tap ")
        input.installTap(onBus: 0, bufferSize: buffLen, format: nil ) {
            (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) -> Void in
            
            var chanSent = [Int]()
            let inputBuffChanCount = Int(buffer.format.channelCount)
            
            // scan through the channels and get and publish the meter data we need
            for idx in 0 ..< inputBuffChanCount
            {
                //Logger.log("monitor: idx \(idx) of buff count\(inputBuffChanCount)")
                
                for specific in self._specifics
                {
                    if( specific != nil )
                    {
                        let chan1 = (((specific?.inputChan)!-1) % inputBuffChanCount)
                        let chan2 = ((specific?.inputChan)! % inputBuffChanCount)

                        //Logger.log("monitor: specific \(specific.inputChan) chan1:\(chan1) chan2: \(chan2) ")
                        
                        if( chan1 == idx && !chanSent.contains(chan1)) // we're interested in this input channel and haven't broadcast its data yet
                        {
                            chanSent.append(chan1)
                            
                            //Logger.log("monitor: levelDatas count: \(levelDatas.count) idx: \(idx), buffer.floatChannelData \(buffer.floatChannelData.debugDescription)")
                            //Logger.log("monitor: levelData idx: \(idx), buffer.floatChannelData \(buffer.floatChannelData.debugDescription)")
                            let levelData = TrackLevels()//levelDatas[idx]
                            levelData.track = idx + 1
                            levelData.trackCount = inputBuffChanCount
                            let inNumberFrames:UInt32 = buffer.frameLength
                            let samplesCh1:UnsafeMutablePointer<Float32> = buffer.floatChannelData![idx] // L or chan 1
                            
                            vDSP_meamgv(samplesCh1, 1, &levelData.averagePowerForChannel0, vDSP_Length(inNumberFrames))
                            levelData.prevChannel0  = meterNormalize(levelData.averagePowerForChannel0, prevValue: levelData.prevChannel0)
                            levelData.averagePowerForChannel0 = levelData.prevChannel0
                            
                            if( (specific?.stereoInput)! && (chan2 == ((idx + 1) % inputBuffChanCount) )) // we're interested in this input channel / stereo
                            {
                                let samplesCh2:UnsafeMutablePointer<Float32> = buffer.floatChannelData![(idx + 1) % inputBuffChanCount] // R or chan 2
                                vDSP_meamgv(samplesCh2, 1, &levelData.averagePowerForChannel1, vDSP_Length(inNumberFrames))
                                levelData.prevChannel1  = meterNormalize(levelData.averagePowerForChannel1, prevValue: levelData.prevChannel1)
                                levelData.averagePowerForChannel1 = levelData.prevChannel1
                                levelData.stereo = true
                            }
                            self._nc.post(name: Notification.Name(rawValue: "InputTrackLevel"), object:levelData)
                            
                            break;
                        }
                    }
                }
            }
            
            return
        }
        
        
        if( !_monitorEngine.isRunning )
        {
            _monitorEngine.prepare()
            do
            {
                try _monitorEngine.start()
                Logger.log( "done monitor start engine" ) // takes 3ms from prepare to start
            }
            catch let error as NSError
            {
                Logger.log( "error \(error.localizedDescription)" )
            }
        }
    }
}
