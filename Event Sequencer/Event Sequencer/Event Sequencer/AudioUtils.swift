//
//  AudioUtils.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 05/02/2017.
//  Copyright © 2017 Muzoma.com. All rights reserved.
//
// based on http://stackoverflow.com/questions/30479403/concatenate-two-audio-files-in-swift-and-play-them
import Foundation
import CoreFoundation
import AudioToolbox
import AVFoundation

class AudioUtils
{
    // returns the max duration in seconds from a bunch of audio urls
    func getDurationInSeconds ( audio: [URL] ) -> Double
    {
        var ret:Double = 0
        
        for audioIn in audio
        {
            let avAsset = AVURLAsset(url: audioIn, options: nil )
            if( avAsset.duration.seconds > ret )
            {
                ret = avAsset.duration.seconds
            }
        }
        
        return( ret )
    }
    
    // take an audio files convert to m4a format
    // return the new url
    func toM4a( _ audio1In: URL, synchronous:Bool ) -> URL!
    {
        var outputURL:URL! = nil
        let avAsset1 = AVURLAsset(url: audio1In, options: nil )
        let tracks1 =  avAsset1.tracks(withMediaType: AVMediaType.audio)
        
        if( tracks1.count > 0 )
        {
            let assetTrackToImport:AVAssetTrack! = tracks1[0]
            let composition = AVMutableComposition()
            let compositionAudioTrack:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: CMPersistentTrackID())!
            
            //Insert the tracks into the composition
            do {
                let zeroTime = CMTimeMake(value: 0, timescale: assetTrackToImport.asset!.duration.timescale /*44100*/)
                try compositionAudioTrack.insertTimeRange(CMTimeRangeMake(start: zeroTime ,duration: assetTrackToImport.asset!.duration), of: assetTrackToImport, at: zeroTime)
                let assetExport = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A )
                assetExport?.canPerformMultiplePassesOverSourceMediaData = true
                
                //New file name
                outputURL = (audio1In.deletingPathExtension().appendingPathExtension("m4a") as NSURL).filePathURL // must use this - fileURLWithPath
                
                Logger.log( "Converting \(audio1In.debugDescription) to \(outputURL.debugDescription)" )
                _gNC.post(name: Notification.Name(rawValue: "StatusUpdate"), object: String("Converting \(outputURL.lastPathComponent)"))
                
                let fsh = _gFSH
                if( fsh.fileExists(outputURL!) )
                {
                    do
                    {
                        try fsh.removeItem( at: outputURL )
                        Logger.log("\(#function)  \(#file) Deleted \(outputURL.absoluteString)")
                    } catch let error as NSError {
                        Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                    }
                }
                assetExport?.outputURL = outputURL
                assetExport!.outputFileType = AVFileType.m4a // AVFileTypeMPEGLayer3 doesn't work
                
                // make synchronous
                var sessionWaitSemaphore:DispatchSemaphore! = nil
                
                if( synchronous )
                {
                    sessionWaitSemaphore = DispatchSemaphore(value: 0)
                }
                
                
                //let sessionWaitSemaphore = dispatch_semaphore_create(0)
                assetExport?.exportAsynchronously(completionHandler: {
                    switch assetExport!.status
                    {
                    case  AVAssetExportSession.Status.failed:
                        Logger.log( "AVAssetExportSessionStatus failed \(String(describing: assetExport!.error))" )
                        outputURL = nil
                        break;
                    case AVAssetExportSession.Status.cancelled:
                        Logger.log( "AVAssetExportSessionStatus cancelled \(String(describing: assetExport!.error))" )
                        outputURL = nil
                        break;
                    default:
                        if( fsh.fileExists(audio1In) )
                        {
                            do
                            {
                                try fsh.removeItem( at: audio1In )
                                Logger.log("\(#function)  \(#file) Deleted \(audio1In.absoluteString)")
                            } catch let error as NSError {
                                Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                            }
                        }
                        
                        //print("complete")
                        //self.initializeAudioPlayer()
                        //Logger.log( "AVAssetExportSessionStatus complete" )
                        _gNC.post(name: Notification.Name(rawValue: "StatusUpdate"), object: String("Converted \(outputURL.lastPathComponent)"))
                        break;
                    }
                    
                    if( sessionWaitSemaphore != nil )
                    {
                        sessionWaitSemaphore.signal()
                    }
                    return Void()
                })
                if( sessionWaitSemaphore != nil )
                {
                    _ = sessionWaitSemaphore.wait(timeout: DispatchTime.distantFuture)
                }
            } catch let error as NSError {
                Logger.log( "toM4a error: \(error.localizedDescription)" )
            }
        }
        
        return( outputURL )
    }
    
    // take an audio files convert to wav format
    // return the new url
    func toWav( _ url: URL, outName: String ) -> URL! {
        
        //New file name
        let outputURL1 = (url.deletingLastPathComponent().appendingPathComponent(outName+".wav") as NSURL).filePathURL // must use this - fileURLWithPath
        if( outputURL1 != nil )
        {
            let outputURL = outputURL1! as NSURL
            let fsh = _gFSH
            if( fsh.fileExists(outputURL as URL) )
            {
                do
                {
                    try fsh.removeItem( at: outputURL as URL )
                    Logger.log("\(#function)  \(#file) Deleted \(outputURL.absoluteString ?? "")")
                } catch let error as NSError {
                    Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                }
            }
            
            var error : OSStatus = noErr
            var destinationFile : ExtAudioFileRef? = nil
            var sourceFile : ExtAudioFileRef? = nil
            
            var srcFormat : AudioStreamBasicDescription = AudioStreamBasicDescription()
            var dstFormat : AudioStreamBasicDescription = AudioStreamBasicDescription()
            
            
            ExtAudioFileOpenURL(url as CFURL, &sourceFile)
            if( sourceFile != nil )
            {
                var thePropertySize: UInt32 = UInt32(MemoryLayout.stride(ofValue: srcFormat))
                
                ExtAudioFileGetProperty(sourceFile!,
                                        kExtAudioFileProperty_FileDataFormat,
                                        &thePropertySize, &srcFormat)
                
                dstFormat.mSampleRate = 44100  //Set sample rate
                dstFormat.mFormatID = kAudioFormatLinearPCM
                dstFormat.mChannelsPerFrame = srcFormat.mChannelsPerFrame
                dstFormat.mBitsPerChannel = 16
                dstFormat.mBytesPerPacket = 2 * dstFormat.mChannelsPerFrame
                dstFormat.mBytesPerFrame = 2 * dstFormat.mChannelsPerFrame
                dstFormat.mFramesPerPacket = 1
                dstFormat.mFormatFlags = kLinearPCMFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger
                
                // Create destination file
                error = ExtAudioFileCreateWithURL(
                    outputURL as CFURL,
                    kAudioFileWAVEType,
                    &dstFormat,
                    nil,
                    AudioFileFlags.eraseFile.rawValue,
                    &destinationFile)
                //reportError(error: error)
                
                if( destinationFile != nil && error == 0 )
                {
                    error = ExtAudioFileSetProperty(sourceFile!,
                                                    kExtAudioFileProperty_ClientDataFormat,
                                                    thePropertySize,
                                                    &dstFormat)
                    //reportError(error: error)
                    
                    error = ExtAudioFileSetProperty(destinationFile!,
                                                    kExtAudioFileProperty_ClientDataFormat,
                                                    thePropertySize,
                                                    &dstFormat)
                    //reportError(error: error)
                    
                    let bufferByteSize : UInt32 = 32768
                    var srcBuffer = [UInt8](repeating: 0, count: 32768)
                    var sourceFrameOffset : ULONG = 0
                    
                    while(true){
                        var fillBufList = AudioBufferList(
                            mNumberBuffers: 1,
                            mBuffers: AudioBuffer(
                                mNumberChannels: 2,
                                mDataByteSize: UInt32(srcBuffer.count),
                                mData: &srcBuffer
                            )
                        )
                        var numFrames : UInt32 = 0
                        
                        if(dstFormat.mBytesPerFrame > 0){
                            numFrames = bufferByteSize / dstFormat.mBytesPerFrame
                        }
                        
                        error = ExtAudioFileRead(sourceFile!, &numFrames, &fillBufList)
                        //reportError(error: error)
                        
                        if(numFrames == 0){
                            error = noErr;
                            break;
                        }
                        
                        sourceFrameOffset += numFrames
                        error = ExtAudioFileWrite(destinationFile!, numFrames, &fillBufList)
                        //reportError(error: error)
                    }
                    
                    error = ExtAudioFileDispose(destinationFile!)
                    //reportError(error: error)
                    error = ExtAudioFileDispose(sourceFile!)
                    //reportError(error: error)
                }
                if( error != 0 )
                {
                    Logger.log("\(#function)  \(#file) Error code \(error)")
                }
            }
            else
            {
                // no source file
                Logger.log("\(#function)  \(#file) No source file at \(url.absoluteString)")
            }
        }
        
        return( outputURL1 )
    }
    
    // split a stereo wav to two Mono
    // return true if split
    func splitStereo( _ url: URL, outputURLl: URL, outputURLr: URL ) -> Bool {
        var ret = false
        
        let outputURLL = outputURLl as NSURL
        let outputURLR = outputURLr as NSURL
        var destinationFileL : ExtAudioFileRef? = nil
        var destinationFileR : ExtAudioFileRef? = nil
        var sourceFile : ExtAudioFileRef? = nil
        var srcFormat : AudioStreamBasicDescription = AudioStreamBasicDescription()
        var dstFormat : AudioStreamBasicDescription = AudioStreamBasicDescription()
        
        ExtAudioFileOpenURL(url as CFURL, &sourceFile)
        if( sourceFile != nil )
        {
            var thePropertySize: UInt32 = UInt32(MemoryLayout.stride(ofValue: srcFormat))
            
            ExtAudioFileGetProperty(sourceFile!,
                                    kExtAudioFileProperty_FileDataFormat,
                                    &thePropertySize, &srcFormat)
            
            if( srcFormat.mChannelsPerFrame == 2 ) // stereo in
            {
                dstFormat.mSampleRate = 44100  //Set sample rate
                dstFormat.mFormatID = kAudioFormatLinearPCM
                dstFormat.mChannelsPerFrame = 1
                dstFormat.mBitsPerChannel = 16
                dstFormat.mBytesPerPacket = 2 * dstFormat.mChannelsPerFrame
                dstFormat.mBytesPerFrame = 2 * dstFormat.mChannelsPerFrame
                dstFormat.mFramesPerPacket = 1
                dstFormat.mFormatFlags = kLinearPCMFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger
                
                /*var error : OSStatus = noErr*/
                // Create destination files
                /*error = */ExtAudioFileCreateWithURL(
                    outputURLL as CFURL,
                    kAudioFileWAVEType,
                    &dstFormat,
                    nil,
                    AudioFileFlags.eraseFile.rawValue,
                    &destinationFileL)
                
                //reportError(error: error)
                /*error = */ExtAudioFileCreateWithURL(
                    outputURLR as CFURL,
                    kAudioFileWAVEType,
                    &dstFormat,
                    nil,
                    AudioFileFlags.eraseFile.rawValue,
                    &destinationFileR)
                
                
                /*error = */ExtAudioFileSetProperty(destinationFileL!,
                                                kExtAudioFileProperty_ClientDataFormat,
                                                thePropertySize,
                                                &dstFormat)
                //reportError(error: error)
                
                /*error = */ExtAudioFileSetProperty(destinationFileR!,
                                                kExtAudioFileProperty_ClientDataFormat,
                                                thePropertySize,
                                                &dstFormat)
                
                let bufferByteSize : UInt32 = 32768
                var srcBuffer = [UInt8](repeating: 0, count: 32768)
                var sourceFrameOffset : ULONG = 0
                
                //let LBufferByteSize : UInt32 = 32768 / 2
                var LDestBuffer = [UInt8](repeating: 0, count: 16384)
                
                //let RBufferByteSize : UInt32 = 32768 / 2
                var RDestBuffer = [UInt8](repeating: 0, count: 16384)
                
                while(true){
                    var fillBufList = AudioBufferList(
                        mNumberBuffers: 1,
                        mBuffers: AudioBuffer(
                            mNumberChannels: 2,
                            mDataByteSize: UInt32(srcBuffer.count),
                            mData: &srcBuffer
                        )
                    )
                    var numFrames : UInt32 = 0
                    
                    if(dstFormat.mBytesPerFrame > 0) {
                        numFrames = bufferByteSize / dstFormat.mBytesPerFrame
                    }
                    
                    /*error = */ExtAudioFileRead(sourceFile!, &numFrames, &fillBufList)
                    //reportError(error: error)
                    
                    if(numFrames == 0){
                        /*error = noErr;*/
                        break;
                    }
                    
                    sourceFrameOffset += numFrames
                    
                    var outLBufList = AudioBufferList(
                        mNumberBuffers: 1,
                        mBuffers: AudioBuffer(
                            mNumberChannels: 1,
                            mDataByteSize: UInt32(LDestBuffer.count),
                            mData: &LDestBuffer
                        )
                    )
                    
                    var outRBufList = AudioBufferList(
                        mNumberBuffers: 1,
                        mBuffers: AudioBuffer(
                            mNumberChannels: 1,
                            mDataByteSize: UInt32(RDestBuffer.count),
                            mData: &RDestBuffer
                        )
                    )
                    
                    var outCnt = 0
                    var cntBuffer = 0
                    while( cntBuffer < srcBuffer.count )
                    {
                        // 16 bit interleaved
                        // Left
                        LDestBuffer[outCnt] = srcBuffer[cntBuffer]
                        cntBuffer += 1
                        LDestBuffer[outCnt+1] = srcBuffer[cntBuffer]
                        cntBuffer += 1
                        // Right
                        RDestBuffer[outCnt] = srcBuffer[cntBuffer]
                        cntBuffer += 1
                        RDestBuffer[outCnt+1] = srcBuffer[cntBuffer]
                        cntBuffer += 1
                        outCnt += 2
                    }
                    
                    /*error = */ExtAudioFileWrite(destinationFileL!, numFrames, &outLBufList)
                    //reportError(error: error)
                    /*error = */ExtAudioFileWrite(destinationFileR!, numFrames, &outRBufList)
                }
                
                /*error = */ExtAudioFileDispose(destinationFileL!)
                //reportError(error: error)
                /*error = */ExtAudioFileDispose(destinationFileR!)
                //reportError(error: error)
                /*error = */ExtAudioFileDispose(sourceFile!)
                //reportError(error: error)
                ret = true
            }
        }
        else
        {
            // no source file
        }
        
        return( ret )
    }
    
    // take two audio files and forward pad the shortest so they match in duration
    // return the new url
    func pad( _ audio1In: URL, audio2In: URL, synchronous:Bool ) -> URL!
    {
        var outputURL:URL! = nil
        let loadOptions = [AVURLAssetPreferPreciseDurationAndTimingKey:true]
        let avAsset1 = AVURLAsset(url: audio1In, options: loadOptions)
        let avAsset2 = AVURLAsset(url: audio2In, options: loadOptions)
        
        let tracks1 =  avAsset1.tracks(withMediaType: AVMediaType.audio)
        if( tracks1.count > 0 )
        {
            let assetTrack1:AVAssetTrack = tracks1[0]
            let durationTrack1 = assetTrack1.asset!.duration
            
            let tracks2 = avAsset2.tracks(withMediaType: AVMediaType.audio)
            if( tracks2.count > 0)
            {
                let assetTrack2:AVAssetTrack = tracks2[0]
                let durationTrack2 = assetTrack2.asset!.duration
                
                var extendBy:CMTime! = CMTime()
                var assetTrackToImport:AVAssetTrack! = nil
                
                if( durationTrack1 > durationTrack2 ) // track2 needs extending
                {
                    extendBy = durationTrack1-durationTrack2
                    assetTrackToImport = assetTrack2
                    outputURL = audio2In
                    Logger.log( "Extend \(audio2In.debugDescription) by \(String(describing: extendBy))" )
                    //print("Extend track 2 by \(extendBy)")
                } else if( durationTrack2 > durationTrack1 ) // track1 needs extending
                {
                    extendBy = durationTrack2-durationTrack1
                    assetTrackToImport = assetTrack1
                    outputURL = audio1In
                    Logger.log( "Extend \(audio1In.debugDescription) by \(String(describing: extendBy))" )
                    //print("Extend track 1 by \(extendBy)")
                }
                else // nothing needed
                {
                    outputURL = nil
                    Logger.log( "No extension needed \(audio1In.debugDescription) matches length of \(audio2In.debugDescription)" )
                    //print("No extenstion processing needed")
                }
                
                if( outputURL != nil )
                {
                    //Silence setup
                    //This object will be edited to include both silence and the audio file
                    let composition = AVMutableComposition()
                    let compositionAudioTrack:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: CMPersistentTrackID())!
                    
                    //Insert the tracks into the composition
                    do {
                        compositionAudioTrack.insertEmptyTimeRange( CMTimeRangeMake(start: CMTimeMake(value: 0, timescale: assetTrackToImport.asset!.duration.timescale /*44100*/ ), duration: extendBy) )
                        try compositionAudioTrack.insertTimeRange( CMTimeRangeMake(start: CMTimeMake(value: 0, timescale: assetTrackToImport.asset!.duration.timescale /*44100*/),duration: assetTrackToImport.asset!.duration), of: assetTrackToImport, at:  extendBy)
                        
                        //AVAssetExportSession(asset: assetTrackToImport!.asset!, presetName: AVAssetExportPresetPassthrough )
                        let assetExport = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A )//presetName: AVAssetExportPresetPassthrough) doesnt work
                        assetExport?.canPerformMultiplePassesOverSourceMediaData = true
                        
                        //New file name
                        let newOutputURL = outputURL.deletingPathExtension().appendingPathExtension("\(Date().timeIntervalSince1970).m4a")
                        Logger.log( "generating new file \(newOutputURL.debugDescription)" )
                        let fsh = _gFSH
                        if( fsh.fileExists(newOutputURL) )
                        {
                            do
                            {
                                try fsh.removeItem( at: newOutputURL )
                                Logger.log("\(#function)  \(#file) Deleted \(newOutputURL.absoluteString)")
                            } catch let error as NSError {
                                Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                            }
                        }
                        
                        outputURL = newOutputURL // set the output to the new url
                        assetExport?.outputURL = outputURL
                        assetExport!.outputFileType = AVFileType.m4a // AVFileTypeMPEGLayer3 doesn't work
                        Logger.log( "Saving track \(outputURL.lastPathComponent)" )
                        _gNC.post(name: Notification.Name(rawValue: "StatusUpdate"), object: String("Saving \(outputURL.lastPathComponent)"))
                        
                        // make synchronous
                        var sessionWaitSemaphore:DispatchSemaphore! = nil
                        
                        if( synchronous )
                        {
                            sessionWaitSemaphore = DispatchSemaphore(value: 0)
                        }
                        
                        //let sessionWaitSemaphore = dispatch_semaphore_create(0)
                        assetExport?.exportAsynchronously(completionHandler: {
                            switch assetExport!.status
                            {
                            case  AVAssetExportSession.Status.failed:
                                Logger.log( "AVAssetExportSessionStatus failed \(String(describing: assetExport!.error))" )
                                outputURL = nil
                                break;
                            case AVAssetExportSession.Status.cancelled:
                                Logger.log( "AVAssetExportSessionStatus cancelled \(String(describing: assetExport!.error))" )
                                outputURL = nil
                                break;
                            default:
                                //print("complete")
                                //self.initializeAudioPlayer()
                                //Logger.log( "AVAssetExportSessionStatus complete" )
                                Logger.log( "Saved track \(outputURL.lastPathComponent)" )
                                _gNC.post(name: Notification.Name(rawValue: "StatusUpdate"), object: String("Saved \(outputURL.lastPathComponent)"))
                                break;
                            }
                            
                            if( sessionWaitSemaphore != nil )
                            {
                                sessionWaitSemaphore.signal()
                            }
                            return Void()
                        })
                        if( sessionWaitSemaphore != nil )
                        {
                            _ = sessionWaitSemaphore.wait(timeout: DispatchTime.distantFuture)
                        }
                        Logger.log( "Out export.." )
                    } catch let error as NSError {
                        Logger.log( "toM4a error: \(error.localizedDescription)" )
                    }
                }
            }
        }
        
        return( outputURL )
    }
    
    
    // take one audio files and pads the start by AVAudioTime samples
    // if baseAudioIn is not nil then combine with that file
    // return the new url
    func pad( _ baseAudioIn: URL! = nil, audio1In: URL, padTime: AVAudioTime, dropInMode:Bool = true, synchronous:Bool  ) -> URL!
    {
        var outputURL:URL! = nil
        let loadOptions = [AVURLAssetPreferPreciseDurationAndTimingKey:true]
        //This object will be edited for the audio file
        let composition = AVMutableComposition()
        
        var avAsset0:AVURLAsset! = nil
        var tracks0:[AVAssetTrack?]! = nil
        var track0:AVAssetTrack! = nil
        
        if( baseAudioIn != nil ) // exsting audio to mix
        {
            avAsset0 = AVURLAsset(url: baseAudioIn, options: loadOptions)
            tracks0 =  avAsset0!.tracks(withMediaType: AVMediaType.audio)
            track0 = tracks0 != nil && tracks0.count > 0 ? tracks0![0] : nil
            
            // base track
            do
            {
                if( track0 != nil )
                {
                    let compositionBaseAudioTrack:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: CMPersistentTrackID())!
                    let rng = CMTimeRangeMake(start: CMTime.zero/*CMTimeMake(0, track0!.asset!.duration.timescale)*/, duration: track0!.asset!.duration)
                    try compositionBaseAudioTrack.insertTimeRange(rng, of: track0!, at: CMTime())
                }
                
            } catch let error as NSError {
                Logger.log( "trunc error: \(error.localizedDescription)" )
            }
        }
        
        
        let avAsset1 = AVURLAsset(url: audio1In, options: loadOptions)
        
        //let avAsset2 = AVURLAsset(URL: audio2In, options: loadOptions)
        let tracks1 =  avAsset1.tracks(withMediaType: AVMediaType.audio)
        if( tracks1.count > 0 )
        {
            // track1 needs extending
            let assetTrack1:AVAssetTrack = tracks1[0]
            //let durationTrack1 = assetTrack1.asset!.duration
            let extendBy:CMTime! = CMTimeMake( value: padTime.sampleTime, timescale: Int32(padTime.sampleRate) )
            var assetTrackToImport:AVAssetTrack! = nil
            
            assetTrackToImport = assetTrack1
            Logger.log( "Extend track \(audio1In.debugDescription) by \(String(describing: extendBy))" )
            //print("Extend track 1 by \(extendBy)")
            
            //Silence setup
            //This object will be edited to include both silence and the audio file
            
            let compositionAudioTrack:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: CMPersistentTrackID())!
            
            //Insert the tracks into the composition
            do {
                compositionAudioTrack.insertEmptyTimeRange( CMTimeRangeMake(start: CMTime.zero/*CMTimeMake(0, assetTrackToImport.asset!.duration.timescale /*44100*/ )*/, duration: extendBy) )
                try compositionAudioTrack.insertTimeRange( CMTimeRangeMake(start: CMTime.zero /*CMTimeMake(0, assetTrackToImport.asset!.duration.timescale /*44100*/)*/,duration: assetTrackToImport.asset!.duration), of: assetTrackToImport, at:  extendBy)
                
                //AVAssetExportSession(asset: assetTrackToImport!.asset!, presetName: AVAssetExportPresetPassthrough )
                let assetExport = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A )//presetName: AVAssetExportPresetPassthrough) doesnt work
                assetExport?.canPerformMultiplePassesOverSourceMediaData = true
                
                // duck the original track's volume for drop in mode?
                if( dropInMode && track0 != nil )
                {
                    let params = AVMutableAudioMixInputParameters(track: track0)
                    params.setVolume(0.0, at: extendBy)
                    params.setVolume(0.0, at: extendBy + assetTrackToImport.asset!.duration )
                    params.setVolume(1.0, at: extendBy + assetTrackToImport.asset!.duration + CMTimeMakeWithSeconds(0.01,preferredTimescale: 1000) )
                    
                    let audioMix = AVMutableAudioMix()
                    audioMix.inputParameters = [params]
                    assetExport!.audioMix = audioMix
                    
                    //params.setVolume(1.0, atTime: extendBy )// assetTrackToImport.asset!.duration)
                }
                
                //New file name
                outputURL = audio1In.deletingPathExtension().appendingPathExtension("\(Date().timeIntervalSince1970).m4a")
                Logger.log( "generating new file \(outputURL.debugDescription)" )
                let fsh = _gFSH
                if( fsh.fileExists(outputURL!) )
                {
                    do
                    {
                        try fsh.removeItem( at: outputURL )
                        Logger.log("\(#function)  \(#file) Deleted \(outputURL.absoluteString)")
                    } catch let error as NSError {
                        Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                    }
                }
                
                assetExport?.outputURL = outputURL
                assetExport!.outputFileType = AVFileType.m4a // AVFileTypeMPEGLayer3 doesn't work
                
                Logger.log( "Saving track \(outputURL.lastPathComponent)" )
                _gNC.post(name: Notification.Name(rawValue: "StatusUpdate"), object: String("Saving \(outputURL.lastPathComponent)"))
                
                // make synchronous
                Logger.log( "In export.." )
                
                // make synchronous
                var sessionWaitSemaphore:DispatchSemaphore! = nil
                
                if( synchronous )
                {
                    sessionWaitSemaphore = DispatchSemaphore(value: 0)
                }
                
                
                //let sessionWaitSemaphore = dispatch_semaphore_create(0)
                assetExport?.exportAsynchronously(completionHandler: {
                    switch assetExport!.status
                    {
                    case  AVAssetExportSession.Status.failed:
                        Logger.log( "AVAssetExportSessionStatus failed \(String(describing: assetExport!.error))" )
                        outputURL = nil
                        break;
                    case AVAssetExportSession.Status.cancelled:
                        Logger.log( "AVAssetExportSessionStatus cancelled \(String(describing: assetExport!.error))" )
                        outputURL = nil
                        break;
                    default:
                        if( fsh.fileExists(audio1In) )
                        {
                            do
                            {
                                try fsh.removeItem( at: audio1In )
                                Logger.log("\(#function)  \(#file) Deleted \(audio1In.absoluteString)")
                            } catch let error as NSError {
                                Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                            }
                        }
                        Logger.log( "Saved track \(outputURL.lastPathComponent)" )
                        _gNC.post(name: Notification.Name(rawValue: "StatusUpdate"), object: String("Saved \(outputURL.lastPathComponent)"))
                        
                        break;
                    }
                    
                    if( sessionWaitSemaphore != nil )
                    {
                        sessionWaitSemaphore.signal()
                    }
                    return Void()
                })
                if( sessionWaitSemaphore != nil )
                {
                    _ = sessionWaitSemaphore.wait(timeout: DispatchTime.distantFuture)
                }
                Logger.log( "Out export.." )
            } catch let error as NSError {
                Logger.log( "pad error: \(error.localizedDescription)" )
            }
        }
        
        return( outputURL )
    }
    
    // mix two wavs together
    // return true if mixed
    func mixWavs( _ outputURL: URL, urlWav1: URL, volume1: Float, urlWav2: URL, volume2: Float, synchronous:Bool  ) -> Bool
    {
        var ret = false
        
        let loadOptions = [AVURLAssetPreferPreciseDurationAndTimingKey:true]
        
        //This object will be edited for the audio file
        let composition = AVMutableComposition()
        
        // get tracks for url 1 and 2
        let avAsset1 = AVURLAsset(url: urlWav1, options: loadOptions)
        let tracks1 =  avAsset1.tracks(withMediaType: AVMediaType.audio)
        let track1 = tracks1.count > 0 ? tracks1[0] : nil
        if( track1 != nil )
        {
            let compositionAudioTrack1:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: CMPersistentTrackID())!
            let rng1 = CMTimeRangeMake(start: CMTime.zero, duration: track1!.asset!.duration)
            try? compositionAudioTrack1.insertTimeRange(rng1, of: track1!, at: CMTime.zero)
        }
        
        let avAsset2 = AVURLAsset(url: urlWav2, options: loadOptions)
        let tracks2 =  avAsset2.tracks(withMediaType: AVMediaType.audio)
        let track2 = tracks2.count > 0 ? tracks2[0] : nil
        if( track2 != nil )
        {
            let compositionAudioTrack2:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: CMPersistentTrackID())!
            let rng2 = CMTimeRangeMake(start: CMTime.zero, duration: track2!.asset!.duration)
            try? compositionAudioTrack2.insertTimeRange(rng2, of: track2!, at: CMTime.zero)
        }
        
        let assetExport = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A/* AVAssetExportPresetPassthrough*/ )
        assetExport?.canPerformMultiplePassesOverSourceMediaData = true
        
        
        let audioMix = AVMutableAudioMix()
        audioMix.inputParameters = [AVMutableAudioMixInputParameters]()
        if( track1 != nil )
        {
            let paramsTrack1 = AVMutableAudioMixInputParameters(track: track1)
            paramsTrack1.setVolume(volume1, at: CMTime.zero)
            audioMix.inputParameters.append(paramsTrack1)
        }
        
        if( track2 != nil )
        {
            let paramsTrack2 = AVMutableAudioMixInputParameters(track: track2)
            paramsTrack2.setVolume(volume2, at: CMTime.zero)
            audioMix.inputParameters.append(paramsTrack2)
        }
        
        
        
        assetExport!.audioMix = audioMix
        
        Logger.log( "generating new file \(outputURL.debugDescription)" )
        
        if( _gFSH.fileExists(outputURL) )
        {
            do
            {
                try _gFSH.removeItem( at: outputURL )
                Logger.log("\(#function)  \(#file) Deleted\(outputURL.absoluteString)")
            } catch let error as NSError {
                Logger.log("\(#function) \(#file) \(error.localizedDescription)")
            }
        }
        
        // compose to m4a then convert back to wav
        let outputURLM4A = (outputURL.deletingPathExtension().appendingPathExtension(".m4a") as NSURL).filePathURL
        assetExport!.outputURL = outputURLM4A
        
        assetExport!.outputFileType = AVFileType.m4a //AVFileTypeWAVE
        Logger.log( "Saving track \(outputURL.lastPathComponent)" )
        _gNC.post(name: Notification.Name(rawValue: "StatusUpdate"), object: String("Saving \(outputURL.lastPathComponent)"))
        // make synchronous
        var sessionWaitSemaphore:DispatchSemaphore! = nil
        
        if( synchronous )
        {
            sessionWaitSemaphore = DispatchSemaphore(value: 0)
        }
        
        
        assetExport?.exportAsynchronously(completionHandler: {
            switch assetExport!.status
            {
            case  AVAssetExportSession.Status.failed:
                Logger.log( "AVAssetExportSessionStatus failed \(String(describing: assetExport!.error))" )
                
                break;
            case AVAssetExportSession.Status.cancelled:
                Logger.log( "AVAssetExportSessionStatus cancelled \(String(describing: assetExport!.error))" )
                
                break;
            default:
                Logger.log( "Saved track \(outputURL.lastPathComponent)" )
                let outWavURL = self.toWav(outputURLM4A!, outName: outputURL.lastPathComponent.replacingOccurrences(of: ".wav", with: ""))
                if( outWavURL != nil )
                {
                    try? _gFSH.removeItem(at: outputURLM4A!) // clean up old merger
                    _gNC.post(name: Notification.Name(rawValue: "StatusUpdate"), object: String("Saved \(outputURL.lastPathComponent)"))
                    ret = true
                }
                break;
            }
            
            if( sessionWaitSemaphore != nil )
            {
                sessionWaitSemaphore.signal()
            }
            return Void()
        })
        
        if( sessionWaitSemaphore != nil )
        {
            _ = sessionWaitSemaphore.wait(timeout: DispatchTime.distantFuture)
        }
        
        
        return( ret )
    }
    
    // take one audio files and trunc the start by AVAudioTime samples
    // if baseAudioIn is not nil then combine with that file
    // return the new url
    func trunc( _ baseAudioIn: URL! = nil, audio1In: URL, truncTime: AVAudioTime, dropInMode:Bool = true, synchronous:Bool  ) -> URL!
    {
        var outputURL:URL! = nil
        let loadOptions = [AVURLAssetPreferPreciseDurationAndTimingKey:true]
        
        //This object will be edited for the audio file
        let composition = AVMutableComposition()
        
        var avAsset0:AVURLAsset! = nil
        var tracks0:[AVAssetTrack?]! = nil
        var track0:AVAssetTrack! = nil
        
        if( baseAudioIn != nil ) // exsting audio to mix
        {
            avAsset0 = AVURLAsset(url: baseAudioIn, options: loadOptions)
            tracks0 =  avAsset0!.tracks(withMediaType: AVMediaType.audio)
            track0 = tracks0 != nil && tracks0.count > 0 ? tracks0![0] : nil
            
            // base track
            do
            {
                if( track0 != nil )
                {
                    let compositionBaseAudioTrack:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: CMPersistentTrackID())!
                    let rng = CMTimeRangeMake(start: CMTime.zero /*CMTimeMake(0, track0!.asset!.duration.timescale)*/, duration: track0!.asset!.duration)
                    try compositionBaseAudioTrack.insertTimeRange(rng, of: track0!, at: CMTime.zero /*CMTime()*/)
                }
                
            } catch let error as NSError {
                Logger.log( "trunc error: \(error.localizedDescription)" )
            }
        }
        
        
        let avAsset1 = AVURLAsset(url: audio1In, options: loadOptions)
        let tracks1 =  avAsset1.tracks(withMediaType: AVMediaType.audio)
        if( tracks1.count > 0 )
        {
            // track1 needs extending
            let assetTrack1:AVAssetTrack = tracks1[0]
            //let durationTrack1 = assetTrack1.asset!.duration
            let truncBy:CMTime! = CMTimeMake( value: truncTime.sampleTime, timescale: Int32(truncTime.sampleRate) )
            var assetTrackToImport:AVAssetTrack! = nil
            
            assetTrackToImport = assetTrack1
            Logger.log( "trunc track \(audio1In.debugDescription) by \(String(describing: truncBy))" )
            //print("Extend track 1 by \(extendBy)")
            
            
            //Insert the tracks into the composition
            do {
                
                let compositionAudioTrack:AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: CMPersistentTrackID())!
                
                // compositionAudioTrack.insertEmptyTimeRange( CMTimeRangeMake(CMTimeMake(0, assetTrackToImport.asset!.duration.timescale /*44100*/ ), extendBy) )
                // try compositionAudioTrack.insertTimeRange( CMTimeRangeMake(truncBy, assetTrackToImport.asset!.duration), ofTrack: assetTrackToImport, atTime: 0)
                try compositionAudioTrack.insertTimeRange( CMTimeRangeMake(start: truncBy, duration: assetTrackToImport.asset!.duration), of: assetTrackToImport, at: CMTime.zero /*CMTime()*/)
                //AVAssetExportSession(asset: assetTrackToImport!.asset!, presetName: AVAssetExportPresetPassthrough )
                let assetExport = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A )//presetName: AVAssetExportPresetPassthrough) doesnt work
                assetExport?.canPerformMultiplePassesOverSourceMediaData = true
                
                // duck the original track's volume for drop in mode?
                if( dropInMode && track0 != nil )
                {
                    let params = AVMutableAudioMixInputParameters(track: track0)
                    params.setVolume(0.0, at: CMTime.zero)
                    params.setVolume(0.0, at: assetTrackToImport.asset!.duration)
                    params.setVolume(1.0, at: assetTrackToImport.asset!.duration + CMTimeMakeWithSeconds(0.01,preferredTimescale: 1000) )
                    
                    let audioMix = AVMutableAudioMix()
                    audioMix.inputParameters = [params]
                    assetExport!.audioMix = audioMix
                }
                
                //New file name
                outputURL = audio1In.deletingPathExtension().appendingPathExtension("\(Date().timeIntervalSince1970).m4a")
                Logger.log( "generating new file \(outputURL.debugDescription)" )
                
                if( _gFSH.fileExists(outputURL!) )
                {
                    do
                    {
                        try _gFSH.removeItem( at: outputURL )
                        Logger.log("\(#function)  \(#file) Deleted \(outputURL.absoluteString)")
                    } catch let error as NSError {
                        Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                    }
                }
                
                assetExport?.outputURL = outputURL
                assetExport!.outputFileType = AVFileType.m4a // AVFileTypeMPEGLayer3 doesn't work
                Logger.log( "Saving track \(outputURL.lastPathComponent)" )
                _gNC.post(name: Notification.Name(rawValue: "StatusUpdate"), object: String("Saving \(outputURL.lastPathComponent)"))
                // make synchronous
                var sessionWaitSemaphore:DispatchSemaphore! = nil
                
                if( synchronous )
                {
                    sessionWaitSemaphore = DispatchSemaphore(value: 0)
                }
                
                
                assetExport?.exportAsynchronously(completionHandler: {
                    switch assetExport!.status
                    {
                    case  AVAssetExportSession.Status.failed:
                        Logger.log( "AVAssetExportSessionStatus failed \(String(describing: assetExport!.error))" )
                        outputURL = nil
                        break;
                    case AVAssetExportSession.Status.cancelled:
                        Logger.log( "AVAssetExportSessionStatus cancelled \(String(describing: assetExport!.error))" )
                        outputURL = nil
                        break;
                    default:
                        if( _gFSH.fileExists(audio1In) )
                        {
                            do
                            {
                                try _gFSH.removeItem( at: audio1In )
                                Logger.log("\(#function)  \(#file) Deleted \(audio1In.absoluteString)")
                            } catch let error as NSError {
                                Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                            }
                        }

                        Logger.log( "Saved track \(outputURL.lastPathComponent)" )
                        _gNC.post(name: Notification.Name(rawValue: "StatusUpdate"), object: String("Saved \(outputURL.lastPathComponent)"))
                        
                        break;
                    }
                    
                    if( sessionWaitSemaphore != nil )
                    {
                        sessionWaitSemaphore.signal()
                    }
                    return Void()
                })
                if( sessionWaitSemaphore != nil )
                {
                    _ = sessionWaitSemaphore.wait(timeout: DispatchTime.distantFuture)
                }
                
            } catch let error as NSError {
                Logger.log( "trunc error: \(error.localizedDescription)" )
            }
        }
        
        return( outputURL )
    }
}
