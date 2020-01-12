//
//  SetPlayerViewController.swift
//  Event Sequencer
//
//  Created by Matthew Hopkins on 05/04/2015.
//  Copyright (c) 2015 Muzoma.com. All rights reserved.
//
/*

todo:

*/
import UIKit
import MediaPlayer
import AVFoundation

import Foundation
import CoreFoundation
import CoreMIDI


class OldSetPlayerDocumentViewController:  UIViewController, UIPickerViewDataSource, UIPickerViewDelegate,
    MPMediaPickerControllerDelegate, AVAudioPlayerDelegate
{
    //var myMusicPlayer: MPMusicPlayerController?
    var mediaPicker: MPMediaPickerController?
    //var mediaItem: MPMediaItem?
    var mediaItemURL: NSURL?
    var audioPlayer: AVAudioPlayer?
    var midi: MidiOut?
    
    var muzomaDoc: MuzomaDocument?
    var newMuzDoc: MuzomaDocument?
    var _songLines: [MuzEvent]?
    
    @IBOutlet weak var fastfwdButton: UIBarButtonItem!
    @IBOutlet weak var playButton: UIBarButtonItem!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var _eventPicker: UIPickerView!
    @IBOutlet weak var progressTime: UIProgressView!
    
    var lastEventTimeType: EventTimeType = EventTimeType.None
    
    @IBAction func ShareActionPress(sender: AnyObject) {
        
        let textToShare = "Swift is awesome!  Check out this website about it!"
        
        if let myWebsite = NSURL(string: "http://www.codingexplorer.com/")
        {
            let objectsToShare = [textToShare, myWebsite]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            
            self.presentViewController(activityVC, animated: true, completion: nil)
        }
    }
    
    @IBAction func guideTrackButton(sender: AnyObject) {
        print("guide track button event")
        displayMediaPicker()
        displayFilePicker()
    }
    
    @IBAction func newEventButton(sender: AnyObject){
        print("new event")
        newGuideTrackEvent()
    }
    
    @IBAction func deleteEventButton(sender: AnyObject) {
        print("delete event")
    }
    
    
    @IBAction func rewindButton(sender: AnyObject) {
        print("rewind")
        
        rewindGuideTrack()
    }
    
    @IBAction func stopButton(sender: AnyObject) {
        print("stop")
        
        stopGuideTrack()
    }
    
    @IBAction func playButton(sender: AnyObject) {
        print("play")
        
        playGuideTrack()
    }
    
    @IBAction func pauseButton(sender: AnyObject) {
        print("pause")
        
        pauseGuideTrack()
    }
    
    @IBAction func fastfwdButton(sender: AnyObject) {
        print("fast fwd")
        fastFwdGuideTrack()
    }

    
    @IBAction func prepareButton(sender: AnyObject) {
        print("prepare")
        print("guide time is \(audioPlayer?.currentTime)")
        prepareButtonGuideTrack()
    }
    
    
    @IBAction func fireButton(sender: AnyObject) {
        print("fire")
        print("guide time is \(audioPlayer?.currentTime)")
        fireButtonGuideTrack()
    }


    // main code
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        muzomaDoc = MuzomaDocument()
        //muzomaDoc!.loadSampleSong()
        muzomaDoc?.loadEmptyDefaultSong()
        /*
        let xmlStr: String = muzomaDoc!.serialize()
        newMuzDoc = MuzomaDocument()
        newMuzDoc!.deserialize(xmlStr)*/
        _songLines = newMuzDoc!._tracks[1]._events
        
        
        midi = MidiOut()
        midi?.Init()
        //print( "midi out : \(midi?.Hello())" )
        lastEventTimeType = EventTimeType.None
        updateDisplayComponents()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        //pickerView.viewForRow(<#row: Int#>, forComponent: <#Int#>)
    }
    
    
    // picker view
    
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView
    {
        let pickerLabel = UILabel()
        
        if( pickerView.selectedRowInComponent(0) == row)
        {
            switch( lastEventTimeType )
            {
                case EventTimeType.Prepare:
                    pickerLabel.textColor = UIColor.redColor()
                break
                
                case EventTimeType.Fire:
                    pickerLabel.textColor = UIColor.greenColor()
                break
                
                default:
                    pickerLabel.textColor = UIColor.blackColor()
                break;
            }
            
        }else{
            pickerLabel.textColor = UIColor.blackColor()
        }
        
        pickerLabel.text = _songLines![row]._data
        // pickerLabel.font = UIFont(name: pickerLabel.font.fontName, size: 15)
        pickerLabel.font = UIFont(name: "Arial-BoldMT", size: 10) // In this use your custom font
        pickerLabel.textAlignment = NSTextAlignment.Left
        
        
        return pickerLabel
    }
    
    
    func numberOfComponentsInPickerView( pickerView: UIPickerView ) -> Int
    {
        return(1)
    }
    
    func pickerView( pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        muzomaDoc!._tracks.count
        return _songLines!.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        var ret:String? = nil
        switch( component )
        {
            case 0:
                ret = _songLines![row]._data
                break;
            
            /*case 1:
                return _songLines[row].line
            break*/
            
            default:
            break;
        }
        return( ret )
    }


    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        // user changed the picker row
        let evtTime = _songLines![row]._prepareTime
        if( evtTime > 0 )
        {
            setCurrentTime(evtTime!)
        }
    }
    
    var _prevScrollToItemAtTime:NSTimeInterval = 0
    
    func scrollToItemAtTime(currentTime:NSTimeInterval)
    {
        if(currentTime != _prevScrollToItemAtTime )
        {
            _prevScrollToItemAtTime = currentTime
            for (n, ele) in _songLines!.enumerate() {
                if( n > 0 && ele._prepareTime > currentTime)
                {
                    _eventPicker.selectRow(n-1, inComponent: 0, animated: true)
                    lastEventTimeType = EventTimeType.Prepare
                    break;
                }
            }
        }

    }
    
    
    func updateDisplayComponents()
    {
        //println("update display")
        
        
        if( audioPlayer != nil)
        {
            timeLabel.text = "\(audioPlayer?.currentTime)"
            progressTime.progress = Float((audioPlayer!.currentTime)/(audioPlayer!.duration))
            scrollToItemAtTime(audioPlayer!.currentTime)
        }
        else
        {
            timeLabel.text = "--:--:--"
            progressTime.progress = 0;
        }
        
        let delayInSeconds = 0.100
        let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delayInSeconds * Double(NSEC_PER_SEC)))
        dispatch_after(popTime, dispatch_get_main_queue()) { self.updateDisplayComponents() }
        
        
        /*dispatch_after(popTime, dispatch_get_global_queue(Int(QOS_CLASS_DEFAULT.value), 0)) { self.updateDisplayComponents() }*/
        /*
        dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_BACKGROUND.value), 0)) { // 1
            sleep(1)
            dispatch_async(dispatch_get_main_queue()) { // 2
                self.updateDisplayComponents() // 3
            }
        }*/
    }
    
    func displayMediaPicker()
    {
        mediaPicker = MPMediaPickerController( mediaTypes: .AnyAudio )
        if let picker = mediaPicker{
            print("instantiated a media picker")
            picker.delegate = self
            picker.allowsPickingMultipleItems = false
            picker.showsCloudItems = true
            picker.prompt = "Select a guide track...."
            //view.addSubview(picker.view)
            //presentViewController( picker, animated: true, completion: nil)
            presentViewController(picker, animated: true, completion: {})

        }
        else
        {
            print("could not instantiate a media player!")
        }
    }
    
    func mediaPicker(mediaPicker: MPMediaPickerController, didPickMediaItems  mediaItems:MPMediaItemCollection) -> Void
    {
        let aMediaItem = mediaItems.items[0] as MPMediaItem
        if (( aMediaItem.artwork ) != nil) {
            //mediaImageView.image = aMediaItem.artwork.imageWithSize(mediaCell.contentView.bounds.size);
            //mediaImageView.hidden = false;
        }
        self.mediaItemURL = aMediaItem.assetURL
        self.dismissViewControllerAnimated(true, completion: {})
    }
    
    func mediaPickerDidCancel(mediaPicker: MPMediaPickerController) {
        self.dismissViewControllerAnimated(true, completion: {})
    }
    
    
    func displayFilePicker()
    {
        let fileManager = NSFileManager.defaultManager()
    
        let urls = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
    
        if let _: NSURL = urls.first {
            //let playGuide = documentDirectoryURL.URLByAppendingPathComponent("08 Every Little Thing She Does Is Magic.mp3")

            self.mediaItemURL = NSURL(fileURLWithPath: "/Users/MatthewHopkins/Documents/mp3s/08 Every Little Thing She Does Is Magic.mp3")
            
            //print("playGuide is \(self.mediaItemURL)")
        }
    }
    
    func playGuideTrack()
    {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        } catch _ {
        }
        
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch _ {
        }
        
        //var mediaItem:MPMediaItem?
        //var error: NSError?
        do {
            if( audioPlayer == nil )
            {
                if(self.mediaItemURL != nil)
                {
                    audioPlayer = try AVAudioPlayer(contentsOfURL: self.mediaItemURL!)
                    audioPlayer!.prepareToPlay()
                    audioPlayer!.play()
                }
            }
            else
            {
                audioPlayer!.play()
            }

        } catch {
            audioPlayer = nil
        }
    }
    
    func pauseGuideTrack()
    {
        audioPlayer?.pause()

    }
    
    func stopGuideTrack()
    {
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    func rewindGuideTrack()
    {
        if( audioPlayer != nil )
        {
            setCurrentTime( (audioPlayer?.currentTime)! - 5 )
        } else {
            setCurrentTime( 0 )
        }
    }
    
    func fastFwdGuideTrack()
    {
        if( audioPlayer != nil )
        {
            setCurrentTime( (audioPlayer?.currentTime)! + 5 )
        } else {
            setCurrentTime( 0 )
        }
    }
    
    func setCurrentTime( newTime: NSTimeInterval )
    {
        if( audioPlayer != nil )
        {
            audioPlayer?.currentTime = newTime;
        }
    }
    
    func prepareButtonGuideTrack()
    {
        if( audioPlayer?.currentTime != nil)
        {
            let nextIdx = _eventPicker.selectedRowInComponent(0) + 1
            _eventPicker.selectRow(nextIdx, inComponent:0, animated: true)
            _songLines![nextIdx]._prepareTime = NSTimeInterval((audioPlayer?.currentTime)!)
            //_eventPicker.reloadAllComponents()
            _eventPicker.reloadComponent(0)
            
            lastEventTimeType = EventTimeType.Prepare
        }
    }
    
    func fireButtonGuideTrack()
    {
        if( audioPlayer?.currentTime != nil)
        {
            let idx = _eventPicker.selectedRowInComponent(0)
            //_eventPicker.selectRow(nextIdx, inComponent:0, animated: true)
            _songLines![idx]._eventTime = NSTimeInterval((audioPlayer?.currentTime)!)
            //_eventPicker.reloadAllComponents()
            _eventPicker.reloadComponent(0)
            
            //midi?.sendMidi()
            lastEventTimeType = EventTimeType.Fire
        }
    }
    
    func newGuideTrackEvent()
    {
        //muzomaDoc!.serialize()
    }
}

