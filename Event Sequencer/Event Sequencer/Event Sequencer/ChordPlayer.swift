//
//  ChordPlayer.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 17/03/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//

import Foundation
import AudioToolbox
import MediaPlayer
import AVFoundation


open class ChordPlayer
{
    init() {
        self.setupAudio()
    }
    
    /*
    public func playChord( chord:String, instrument:String )
    {
    playNotes( ["C3","E3","G3"], instrument: instrument )
    }*/
    
    open func playChord( _ chord:Chord )
    {
        playChord(
            chord._note, accidental: chord._accidental, interval: chord._interval, extenstion: chord._extenstion, addition: chord._addition, slashNote: chord._slashNote, instrument: chord._instrument! )
        
    }
    
    open func playChord( _ rootChord:String, accidental:String, interval:String, extenstion:String, addition:String, slashNote:String, instrument:String )
    {
        var rootNote = 60
        
        switch( rootChord )
        {
        case "C","c":
            rootNote = 60
            break
            
        case "D","d":
            rootNote = 62
            break
            
        case "E","e":
            rootNote = 64
            break
            
        case "F","f":
            rootNote = 65
            break
            
        case "G","g":
            rootNote = 67
            break
            
        case "A","a":
            rootNote = 69
            break
            
        case "B","b":
            rootNote = 71
            break
            
        default:
            break
        }
        
        switch( accidental )
        {
            case "♯","#","+":
                rootNote += 1
            break
            
            case "♭","b","-":
                rootNote -= 1
            break
            
            case  "♮":
            break
            
            default:
            break
        }
        
        var chordNotes:[Int] = [rootNote]
        
        switch( interval )
        {
            // minor
        case "min","m":
            chordNotes.append(rootNote+3)
            chordNotes.append(rootNote+7)
            break
            
            // sus2
        case "sus2":
            chordNotes.append(rootNote+2)
            chordNotes.append(rootNote+7)
            break
            
            // sus4
        case "sus4":
            chordNotes.append(rootNote+5)
            chordNotes.append(rootNote+7)
            break
            
            // aug
        case "aug":
            chordNotes.append(rootNote+4)
            chordNotes.append(rootNote+8)
            break
            
            // dim
        case "dim":
            chordNotes.append(rootNote+3)
            chordNotes.append(rootNote+6)
            break
            
            // major
        default:
            chordNotes.append(rootNote+4)
            chordNotes.append(rootNote+7)
            break
        }
        
        
        switch(extenstion)
        {
            // 5 - power chord, lose third
        case "5":
            chordNotes[1] = 0
            break
            
            //"(♯5)", "(♭5)", "6", "7", "maj7", "9", "maj9", "11", "13"
            // sharp 5th
        case "(♯5)":
            chordNotes[2] += 1
            break
            
            // flat 5th
        case "(♭5)":
            chordNotes[2] -= 1
            break
            
            // add 6
        case "6":
            chordNotes.append(rootNote+9)
            break
            
        case "7":
            chordNotes.append(rootNote+10)
            break
            
        case "maj7":
            chordNotes.append(rootNote+11)
            break
            
        case "9":
            chordNotes[2]=(rootNote+10)
            chordNotes.append(rootNote+14)
            break
            
        case "maj9":
            chordNotes[2]=(rootNote+11)
            chordNotes.append(rootNote+14)
            break
            
        case "11":
            chordNotes[2]=(rootNote+10)
            chordNotes.append(rootNote+17)
            break
            
        case "13":
            chordNotes[2]=(rootNote+10)
            chordNotes.append(rootNote+21)
            break
            
        default:
            break
        }
        
        switch(addition)
        {
            // add 2
        case "(add2)":
            chordNotes.append(rootNote+2)
            break
            
            // add 4
        case "(add4)":
            chordNotes.append(rootNote+5)
            break
            
            // add 6
        case "(add6)":
            chordNotes.append(rootNote+9)
            break
            
            // add 9
        case "(add9)":
            chordNotes.append(rootNote+14)
            break
            
            // add 11
        case "(add11)":
            chordNotes.append(rootNote+17)
            break
            
            // add 13
        case "(add13)":
            chordNotes.append(rootNote+21)
            break
            
            
        case "(add♯9)", "(add#9)":
            chordNotes.append(rootNote+15)
            break
            
        case "(add♯11)", "(add#11)":
            chordNotes.append(rootNote+18)
            break
            
        case "(add♯13)", "(add#13)":
            chordNotes.append(rootNote+22)
            break
            
        case "(add♭9)", "(addb9)":
            chordNotes.append(rootNote+13)
            break
            
        case "(add♭11)", "(addb11)":
            chordNotes.append(rootNote+16)
            break
            
        case "(add♭13)", "(addb13)":
            chordNotes.append(rootNote+20)
            break
            
        default:
            break
        }
        
        if( slashNote != "" )
        {
            var sNote = 0
            let bassRootRange = slashNote.index(slashNote.startIndex, offsetBy: 1)..<slashNote.index(slashNote.startIndex, offsetBy: 2)
            //let bassRoot = slashNote.substring(with: bassRootRange)
            let bassRoot = slashNote[bassRootRange]
            var bassAccidental = ""
            if( slashNote.count > 2 )
            {
                let accRange = slashNote.index(slashNote.startIndex, offsetBy: 2)..<slashNote.index(slashNote.startIndex, offsetBy: 3)
                //bassAccidental=slashNote.substring(with: accRange)
                bassAccidental = String(slashNote[accRange])
            }
            switch( bassRoot )
            {
            case "C":
                sNote = 36 //60
                break
                
            case "D":
                sNote = 38 //62
                break
                
            case "E":
                sNote = 40 //64
                break
                
            case "F":
                sNote = 41 //65
                break
                
            case "G":
                sNote = 43 //67
                break
                
            case "A":
                sNote = 45 //69
                break
                
            case "B":
                sNote = 47 //71
                break
                
            default:
                break
            }
            
            switch( bassAccidental )
            {
            case "♯", "#":
                sNote += 1
                break
                
            case "♭", "b":
                sNote -= 1
                break
                
            case  "♮":
                break
                
            default:
                break
            }
            
            if( sNote != 0 )
            {
                chordNotes.append(sNote)
            }
        }
        
        playNotes( chordNotes, instrument: instrument )
    }
    
    fileprivate func setupAudio()
    {
    }
    
    fileprivate func getNoteURLs( _ notes:[String], instrument:String ) -> [URL]
    {
        var ret:[URL] = [URL]()//[NSURL(fileURLWithPath: "http://www.google.com")]
        
        // notes are always sharp and come with the octave and instrument eg GS3
        for (_, note) in notes.enumerated()
        {
            let url = Bundle.main.url( forResource: ("_Muzoma " + note + "-" + instrument) as String, withExtension: "m4a")
            if( url != nil )
            {
                ret.append(url!)
            }
        }
        return( ret )
    }
    
    var players:[AVAudioPlayer] = [AVAudioPlayer]()
    fileprivate func playNotes( _ notes:[String], instrument:String )
    {
        var curTime:TimeInterval = 0
        players.removeAll()
        
        do {
            let noteURLs = getNoteURLs(notes, instrument: instrument)
            for (_, note) in noteURLs.enumerated()
            {
                let player = try AVAudioPlayer( contentsOf: note )
                if( curTime == 0 )
                {
                    curTime = player.deviceCurrentTime.advanced(by: 0.1)
                }
                
                player.prepareToPlay()
                player.play( atTime: curTime )
                players.append(player)
                player.play()
            }
        } catch let error as NSError {
            //error = error1
            print( error.description )
        }
    }
    
    // middle c = 60
    fileprivate func playNotes( _ midiNotes:[Int], instrument:String )
    {
        var noteStrings:[String] = []
        for (_, noteNumber) in midiNotes.enumerated()
        {
            if( noteNumber != 0 )
            {
                let note=noteNumber%12
                let oct=((noteNumber-note)/12)
                var noteString = ""
                switch( note )
                {
                case 0:
                    noteString = "C"
                    break
                    
                case 1:
                    noteString = "Cs"
                    break
                    
                case 2:
                    noteString = "D"
                    break
                    
                case 3:
                    noteString = "Ds"
                    break
                    
                case 4:
                    noteString = "E"
                    break
                    
                case 5:
                    noteString = "F"
                    break
                    
                case 6:
                    noteString = "Fs"
                    break
                    
                case 7:
                    noteString = "G"
                    break
                    
                case 8:
                    noteString = "Gs"
                    break
                    
                case 9:
                    noteString = "A"
                    break
                    
                case 10:
                    noteString = "As"
                    break
                    
                case 11:
                    noteString = "B"
                    break
                    
                default:
                    break
                }
                noteString+=(String(oct-2))
                noteStrings.append(noteString)
            }
        }
        
        playNotes( noteStrings, instrument:instrument )
    }
}
