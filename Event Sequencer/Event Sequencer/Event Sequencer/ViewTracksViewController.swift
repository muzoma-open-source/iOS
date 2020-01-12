//
//  ViewTracksViewController.swift
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


class ViewTracksViewController:  UIViewController, UIPickerViewDataSource, UIPickerViewDelegate,
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

    @IBOutlet weak var _eventPicker: UIPickerView!

    @IBAction func guideTrackButton(sender: AnyObject) {
        print("guide track button event")
        displayMediaPicker()
        displayFilePicker()
    }


    // main code
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        muzomaDoc = MuzomaDocument()
        muzomaDoc!.loadEmptyDefaultSong()
        
        //muzomaDoc!.loadSampleSong()
        /*
        let xmlStr: String = muzomaDoc!.serialize()
        newMuzDoc = MuzomaDocument()
        newMuzDoc!.deserialize(xmlStr)*/
        _songLines = newMuzDoc!._tracks[1]._events
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

        pickerLabel.textColor = UIColor.blackColor()
            
        switch(component)
        {
            case 0:
                pickerLabel.text = String((row+1)) + " " +
                newMuzDoc!._tracks[row]._trackName
            break
                
            case 1:
                pickerLabel.text =
                newMuzDoc!._tracks[row]._trackType.rawValue
            break

            case 2:
                pickerLabel.text =
                newMuzDoc!._tracks[row]._trackPurpose.rawValue
            break
                
            default:
            break
        }
        // pickerLabel.font = UIFont(name: pickerLabel.font.fontName, size: 15)
        pickerLabel.font = UIFont(name: "Arial-BoldMT", size: 13) // In this use your custom font
        pickerLabel.textAlignment = NSTextAlignment.Left
        
        
        return pickerLabel
    }
    
    
    func numberOfComponentsInPickerView( pickerView: UIPickerView ) -> Int
    {
        return(3)
    }
    
    func pickerView( pickerView: UIPickerView, numberOfRowsInComponent component: Int ) -> Int
    {
        return muzomaDoc!._tracks.count
    }

    
    func pickerView( pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int ) -> String? {
        var ret:String? = nil
        switch( component )
        {
            case 0:
                ret="Name"
            break
            
            case 1:
                ret="Type"
            break
            
            case 2:
                ret="Purpose"
            break
            
            default:
                ret = nil
        }
        return ret
    }


    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        // user changed the picker row
        if( component != 0 )
        {
            _eventPicker.selectRow(row, inComponent: 0, animated: true)
        }
        
        if( component != 1 )
        {
            _eventPicker.selectRow(row, inComponent: 1, animated: true)
        }
        
        if( component != 2 )
        {
            _eventPicker.selectRow(row, inComponent: 2, animated: true)
        }
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
            //self.mediaItemURL = NSURL(fileURLWithPath: "/Users/MatthewHopkins/Documents/mp3s/08 Every Little Thing She Does Is Magic.mp3")
            self.mediaItemURL = NSURL(fileURLWithPath: "/Users/MatthewHopkins/Documents/mp3s/test.mp3")
            //print("playGuide is \(self.mediaItemURL)")
        }
    }
}

