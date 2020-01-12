//
//  Chord.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 19/11/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//
// Model to represent a chord

import Foundation
import AEXML

open class Chord
{
    var _note:String = ""
    var _accidental:String = ""
    var _interval:String = ""
    var _extenstion:String = ""
    var _addition:String = ""
    var _slashNote:String = ""
    var _inversion:String? = nil
    var _instrument:String? = nil
    var _style:String? = nil
    var _BPM:Double? = nil
    var _beatsCovered:Double? = nil
    
    init( chordText:String )
    {
        self.chordString = chordText
        self._instrument = "AcGuitar"
    }
    
    init(
        note:String,
        accidental:String,
        interval:String,
        extenstion:String,
        addition:String,
        slashNote:String,
        inversion:String? = nil,
        instrument:String? = nil,
        style:String? = nil,
        BPM:Double? = nil,
        beatsCovered:Double? = nil
        )
    {
        _note = note
        _accidental = accidental
        _interval = interval
        _extenstion = extenstion
        _addition = addition
        _slashNote = slashNote
        _inversion = inversion
        _instrument = instrument
        _style = style
        _BPM = BPM
        _beatsCovered = beatsCovered
    }
    
    init( xmlEle:AEXMLElement )
    {
        deserialize( xmlEle )
    }
    
    open func serialize()-> AEXMLElement
    {
        let ele = AEXMLElement(name: "Chord")
        ele.addChild(name: "Note",              value: _note )
        ele.addChild(name: "Accidental",        value: _accidental )
        ele.addChild(name: "Interval",          value: _interval )
        ele.addChild(name: "Extenstion",        value: _extenstion )
        ele.addChild(name: "Addition",          value: _addition )
        ele.addChild(name: "SlashNote",         value: _slashNote )
        ele.addChild(name: "Inversion",         value: _inversion )
        ele.addChild(name: "Instrument",        value: _instrument )
        ele.addChild(name: "Style",             value: _style )
        ele.addChild(name: "BeatsCovered",      value: String(describing: _beatsCovered) )
        ele.addChild(name: "BPM",               value: String(describing: _BPM ) )
        
        return( ele )
    }
    
    open func deserialize( _ xmlEle:AEXMLElement )
    {
        for child in xmlEle.children {
            //Logger.log(child.name)
            switch( child.name )
            {
            case "Note":
                if( child.value != nil )
                {
                    //Logger.log( "Note: " + child.value! )
                    _note = child.value!
                    //_note = Int( child.value! )!
                }
                break;
                
            case "Accidental":
                if( child.value != nil )
                {
                    //Logger.log( "Accidental: " + child.value! )
                    _accidental = child.value!
                }
                break;
                
            case "Interval":
                if( child.value != nil )
                {
                    //Logger.log( "Interval: " + child.value! )
                    _interval = child.value!
                }
                break;
                
            case "Extenstion":
                if( child.value != nil )
                {
                    //Logger.log( "Extenstion: " + child.value! )
                    _extenstion = child.value!
                }
                break;
                
            case "Addition":
                if( child.value != nil )
                {
                    //Logger.log( "Addition: " + child.value! )
                    _addition = child.value!
                }
                break;
                
            case "SlashNote":
                if( child.value != nil )
                {
                    //Logger.log( "SlashNote: " + child.value! )
                    _slashNote = child.value!
                }
                break;
                
            case "Inversion":
                if( child.value != nil )
                {
                    //Logger.log( "Inversion: " + child.value! )
                    _inversion = child.value!
                }
                break;
                
            case "Instrument":
                if( child.value != nil )
                {
                    //Logger.log( "Instrument: " + child.value! )
                    _instrument = child.value!
                }
                break;
                
            case "Style":
                if( child.value != nil )
                {
                    //Logger.log( "Style: " + child.value! )
                    _style = child.value!
                }
                break;
                
                
            case "BeatsCovered":
                if( child.value != nil && !(child.value?.isEmpty)! && child.value != "nil" )
                {
                    //Logger.log( "BeatsCovered: " + child.value! )
                    _beatsCovered = Double(child.value!)!
                }
                break;
                
            case "BPM":
                if( child.value != nil && !(child.value?.isEmpty)! && child.value != "nil" )
                {
                    //Logger.log( "BPM: " + child.value! )
                    _BPM = Double(child.value!)!
                }
                break;
                
            default:
                Logger.log( "unknown Chord element: " + child.name)
                break;
            }
        }
    }
    
    
    enum enChordBreaker : Int
    {
        case rootNote = 0
        case accidental = 1
        case interval = 2
        case `extension` = 3
        case additon = 4
        case slash = 5
        case slashAccidental = 6
        case done = 9
        case illegalChord = 10
    }
    
    /*
     enum enChordTypes : Int
     {
     case Major = 0
     case Minor = 1
     case MajorAug = 2
     }*/
    
    //let chromatic_sharp_scale:[String]  =  [ "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B" ]
    //let chromatic_flat_scale:[String] =  [ "C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B" ]
    static let notesSet = CharacterSet(charactersIn: "abcdefgABCDEFG")
    static let accidentalSet = CharacterSet(charactersIn: "#♯b♭♮")
    static let additionalSet = CharacterSet(charactersIn: "#♯+b♭-246913")
    
    open var chordString : String
        {
        get
        {
            return( _note+_accidental+_interval+_extenstion+_addition+_slashNote )
        }
        
        set
        {
            // parse the string
            let chordName_ = newValue
            
            var cbState = enChordBreaker.rootNote
            //for var nPosCnt in ( 0 ..< chordName_.count ) nPos changes not recognised
            //for( var nPosCnt = 0; nPosCnt < chordName_.characters.count; nPosCnt += 1 )
            
            
            // should use index rather than int here!
            var nPosCnt = 0
            var exit = false
            repeat
            {
                switch( cbState )
                {
                case enChordBreaker.rootNote:
                    
                    let rootNote:String = chordName_[nPosCnt]
                    
                    if( rootNote.trimmingCharacters(in: Chord.notesSet) == "") // is it a valid note
                    {
                        self._note = rootNote.uppercased()
                        cbState = enChordBreaker.accidental
                    }
                    else
                    {
                        cbState = enChordBreaker.illegalChord
                        break
                    }
                    break;
                    
                case enChordBreaker.accidental:
                    let rootNoteAccidental:String = chordName_[nPosCnt]
                    if( rootNoteAccidental.trimmingCharacters(in: Chord.accidentalSet) == "") // is it sharp of flat
                    {
                        self._accidental = rootNoteAccidental
                    }
                    else
                    {
                        nPosCnt -= 1
                    }
                    cbState = enChordBreaker.interval
                    break;
                    
                
                case enChordBreaker.interval:
 
                    //let intervalString:String = chordName_.substring(from: chordName_.index(chordName_.startIndex, offsetBy: nPosCnt))
                    let posn = chordName_.index(chordName_.startIndex, offsetBy: nPosCnt)
                    let intervalString:String = String(chordName_[posn...])
                    if( cbState == enChordBreaker.interval && chordName_.count-nPosCnt > 3 )
                    {
                        let toIdx = intervalString.index(intervalString.startIndex, offsetBy: 4)
                        let interval4:String = intervalString[..<toIdx].lowercased()
                        if( interval4 == "sus2" || interval4 == "sus4" )
                        {
                            self._interval = interval4
                            nPosCnt+=3
                            cbState = enChordBreaker.extension
                        }
                    }
                    
                    if( cbState == enChordBreaker.interval && chordName_.count-nPosCnt > 2 )
                    {
                        let toIdx = intervalString.index(intervalString.startIndex, offsetBy: 3)
                        let interval3:String = intervalString[..<toIdx].lowercased()
                        if( interval3 == "dim" || interval3 == "aug" )
                        {
                            self._interval = interval3
                            nPosCnt+=2
                            cbState = enChordBreaker.extension
                        }
                    }
                    
                    if( cbState == enChordBreaker.interval &&  chordName_.count-nPosCnt > 0 )
                    {
                        let toIdx = intervalString.index(intervalString.startIndex, offsetBy: 1)
                        let interval1:String = intervalString[..<toIdx].lowercased()
                        if( interval1 == "m" )
                        {
                            self._interval = interval1
                            cbState = enChordBreaker.extension
                        }
                    }
                    
                    if( cbState == enChordBreaker.interval ) // none found
                    {
                        nPosCnt -= 1
                        cbState = enChordBreaker.extension
                    }
                    
                    break;
                
                case enChordBreaker.extension:
                    //let extensionString:String = chordName_.substring(from: chordName_.index(chordName_.startIndex, offsetBy: nPosCnt))
                    let posn = chordName_.index(chordName_.startIndex, offsetBy: nPosCnt)
                    let extensionString:String = String(chordName_[posn...])
                    
                    if( cbState == enChordBreaker.extension && chordName_.count-nPosCnt > 3 )
                    {
                        let toIdx = extensionString.index(extensionString.startIndex, offsetBy: 4)
                        let extension4:String = extensionString[..<toIdx].lowercased()
                        if( extension4 == "(#5)" || extension4 == "(♯5)" || extension4 == "(b5)" || extension4 == "(♭5)" ||
                            extension4 == "maj7" || extension4 == "maj9" )
                        {
                            self._extenstion = extension4
                            nPosCnt+=3
                            cbState = enChordBreaker.additon
                        }
                    }
                    
                    if( cbState == enChordBreaker.extension && chordName_.count-nPosCnt > 1 )
                    {
                        let toIdx = extensionString.index(extensionString.startIndex, offsetBy: 2)
                        let extension2:String = extensionString[..<toIdx].lowercased()
                        if( extension2 == "#5" || extension2 == "♯5" || extension2 == "b5" || extension2 == "♭5" ||
                            extension2 == "11" || extension2 == "13" )
                        {
                            self._extenstion = extension2
                            nPosCnt+=1
                            cbState = enChordBreaker.additon
                        }
                    }
                    
                    if( cbState == enChordBreaker.extension && chordName_.count-nPosCnt > 0 )
                    {
                        let toIdx = extensionString.index(extensionString.startIndex, offsetBy: 1)
                        let extension1:String = extensionString[..<toIdx].lowercased()
                        if( extension1 == "5" || extension1 == "6" || extension1 == "7" || extension1 == "9" )
                        {
                            self._extenstion = extension1
                            cbState = enChordBreaker.additon
                        }
                    }
                    
                    if( cbState == enChordBreaker.extension ) // none found
                    {
                        nPosCnt -= 1
                        cbState = enChordBreaker.additon
                    }
                    
                    break;
                    
                case enChordBreaker.additon:
                    let toIdx = chordName_.index(chordName_.startIndex, offsetBy: nPosCnt)
                    var additionString:String = chordName_[..<toIdx].lowercased()
                    
                    if( additionString.lowercased().contains("add") || additionString.lowercased().contains("+") )
                    {
                        var idxAdd = additionString.range( of: "add" )?.upperBound
                        if( idxAdd != nil )
                        {
                            //let additionalRange: Range<String.Index> = Range<String.Index>(start: idxAdd!, end: (additionString.rangeOfString( "add" )?.endIndex)!)
                            //nPosCnt += additionalRange.count
                            nPosCnt += 3
                            // woz in 7.3 additionString = additionString.substring(from: <#T##Collection corresponding to your index##Collection#>.index(idxAdd!, offsetBy: 3))
                            //additionString = additionString.substringFromIndex(idxAdd!.advancedBy(3))
                            
                            //additionString = additionString.substring(from: idxAdd!)
                            additionString = String(additionString[idxAdd!...])
                        }
                        else
                        {
                            idxAdd = additionString.range( of: "+" )?.upperBound
                            if( idxAdd != nil )
                            {
                                //let additionalRange: Range<String.Index> = Range<String.Index>(start: idxAdd!, end: (additionString.rangeOfString( "+" )?.endIndex)!)
                                //nPosCnt += additionalRange.count
                                nPosCnt += 1
                                //woz in 7.3 additionString = additionString.substring(from: <#T##Collection corresponding to your index##Collection#>.index(idxAdd!, offsetBy: 1))
                                
                                //additionString = additionString.substring(from: idxAdd!)
                                additionString = String(additionString[idxAdd!...])
                            }
                            else
                            {
                                additionString = ""
                            }
                        }
                        
                        var additional:String = ""
                        while( additionString.count > 0 )
                        {
                            //let nextChar = additionString.substring(to: additionString.index(additionString.startIndex, offsetBy: 1))
                            let nextChar = additionString[..<additionString.index(additionString.startIndex, offsetBy: 1)]
                            
                            
                            if( nextChar.trimmingCharacters(in: Chord.additionalSet) == "" ) // ok keep going
                            {
                                additional += nextChar
                                //additionString = additionString.substring(from: additionString.index(additionString.startIndex, offsetBy: 1))
                                additionString = String(additionString[additionString.index(additionString.startIndex, offsetBy: 1)...])
                                nPosCnt += 1
                            }
                            else
                            {
                                break;
                            }
                        }
                        
                        if( additional.count > 0 )
                        {
                            self._addition = "(add" + additional + ")"
                        }
                    }
                    else
                    {
                        // not found
                        nPosCnt -= 1
                    }
                    
                    cbState = enChordBreaker.slash
                    break;
                    
                    
                case enChordBreaker.slash:
                    //chordName_.substringFromIndex(<#T##index: Index##Index#>)
                    //var slashString:String = chordName_.substringFromIndex(chordName_.startIndex.advancedBy(nPosCnt))
                    
                    var slashString:String! = nil
                    var fwdSlashRange = chordName_.range( of: "/" )
                    if( fwdSlashRange != .none && fwdSlashRange?.upperBound != nil )
                    {
                        //slashString = chordName_.substring(from: (chordName_.index(before: fwdSlashRange!.upperBound)))
                        slashString = String(chordName_[(chordName_.index(before: fwdSlashRange!.upperBound))...])
                        nPosCnt = chordName_.distance(from: chordName_.startIndex, to: chordName_.index(before: fwdSlashRange!.upperBound))
                    }
                    else
                    {
                        fwdSlashRange = chordName_.range( of: "\\" )
                        if( fwdSlashRange != .none )
                        {
                            //slashString = chordName_.substring(from: (chordName_.index(before: fwdSlashRange!.upperBound)))
                            slashString = String(chordName_[(chordName_.index(before: fwdSlashRange!.upperBound))...])
                            nPosCnt = chordName_.distance(from: chordName_.startIndex, to: chordName_.index(before: fwdSlashRange!.upperBound))
                        }
                    }
                    
                    
                    //Logger.log( "slash: \(slashString)")
                    if( slashString != nil && slashString.count > 0 && (slashString[0] == "/" || slashString[0] == "\\")  ) // slash bass note?
                    {
                        nPosCnt += 1
                        if( slashString.count > 1 )
                        {
                            let slashNoteString:String = slashString.dropFirst().uppercased()
                            if( slashNoteString.trimmingCharacters(in: Chord.notesSet) == "") // is it a valid note
                            {
                                self._slashNote = "/" + slashString.dropFirst().uppercased()
                                cbState = enChordBreaker.slashAccidental
                            }
                            else
                            {
                                cbState = enChordBreaker.done
                                break
                            }
                        }
                        
                        break;
                    }
                    else
                    {
                        cbState = enChordBreaker.done
                    }
                    break;
                    
                    
                case enChordBreaker.slashAccidental:
                    let slashAccidentalString:String = chordName_[nPosCnt]
                    
                    //Logger.log( "slash accidental: \(slashAccidentalString)")
                    
                    if( slashAccidentalString.trimmingCharacters(in: Chord.accidentalSet) == "") // is it a valid accidental
                    {
                        self._slashNote += slashAccidentalString
                    }
                    cbState = enChordBreaker.done
                    break;
                    
                default:
                    exit = true
                    break;
                }
                
                nPosCnt+=1
            } while( exit == false && nPosCnt <  chordName_.count )
        }
    }
}

