//
//  CreateNewDocViewController.swift
//  Event Sequencer
//
//  Created by Matthew Hopkins on 10/12/2015.
//  Copyright © 2015 Muzoma.com. All rights reserved.
//
//  View controller to handle creating a new song document
//

import UIKit
import MediaPlayer
import AVFoundation
import MobileCoreServices

class CreateNewDocViewController: UIViewController, UIDocumentPickerDelegate/*, MPMediaPickerControllerDelegate*/
{
    fileprivate var _transport:Transport! = nil
    var mediaPicker: MPMediaPickerController?
    var _newDoc:MuzomaDocument! = nil
    fileprivate var _isUpdateExisting = false
    var isUpdateExisting:Bool
        {
        get
        {
            return(_isUpdateExisting)
        }
        
        set
        {
            _isUpdateExisting = newValue
        }
    }
    
    var _originalTitle:String! = nil
    var _originalArtist:String! = nil
    var _duplicated = false
    
    @IBOutlet weak var butCreate: UIButton!
    @IBOutlet weak var editTitle: UITextField!
    @IBOutlet weak var editArtist: UITextField!
    @IBOutlet weak var editGuideTrack: UITextField!
    @IBOutlet weak var editAuthor: UITextField!
    @IBOutlet weak var editCopyright: UITextField!
    @IBOutlet weak var editPublisher: UITextField!
    @IBOutlet weak var editKey: UITextField!
    @IBOutlet weak var editTempo: UITextField!
    @IBOutlet weak var editTimeSignature: UITextField!
    
    @IBOutlet weak var swithSetsOnly: UISwitch!
    
    
    @IBAction func setsOnlyChanged(_ sender: AnyObject) {
    }
    
    @IBAction func SelectGuideTrack(_ sender: AnyObject)
    {
        displayAudioFilePicker()
    }
    
    @IBOutlet weak var editArtwork: UITextField!
    @IBOutlet weak var artworkImage: UIImageView!
    
    @IBAction func SelectArtwork(_ sender: AnyObject)
    {
        displayImageFilePicker()
    }
    
    @IBAction func titleEditChanged(_ sender: AnyObject) {
        // don't allow bad chars
        self.editTitle.text = self.editTitle.text?.stringByRemovingCharactersInSet(acceptableProperSet.inverted)
    }
    
    @IBAction func artistEditChanged(_ sender: AnyObject) {
        // don't allow bad chars
        self.editArtist.text = self.editArtist.text?.stringByRemovingCharactersInSet(acceptableProperSet.inverted)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        if( _newDoc == nil )
        {
            _newDoc = MuzomaDocument()
            _newDoc.loadEmptyDefaultSong()
        }
        
        if( _isUpdateExisting )
        {
            butCreate.setTitle("Update", for: UIControl.State())
        }
        
        shouldClose = true
    
        editTitle.text = _newDoc._title
        editArtist.text = _newDoc._artist
        editArtwork.text = _newDoc._coverArtURL
        editAuthor.text = _newDoc._author
        editCopyright.text = _newDoc._copyright
        editPublisher.text = _newDoc._publisher
        editKey.text = _newDoc._key
        editTempo.text = _newDoc._tempo
        editTimeSignature.text = _newDoc._timeSignature
        swithSetsOnly.isOn = _newDoc._setsOnly == true
        
        let _artSourceURL = _newDoc.getArtworkURL()
        if( _artSourceURL != nil )
        {
            _ = _artSourceURL!.startAccessingSecurityScopedResource()
            let data = try? Data( contentsOf: _artSourceURL! )
            _artSourceURL!.stopAccessingSecurityScopedResource()
            
            if( data != nil )
            {
                self.artworkImage.image = UIImage(data: data!)
                _newDoc._originalArtworkURL = _artSourceURL!.absoluteString // set the artwork source to our current image
                //self.artwork.sizeToFit()
            }
        }
        
        let guideTrack = _newDoc.getGuideTrackURL()
        if(guideTrack != nil )
        {
            editGuideTrack.text = guideTrack?.lastPathComponent
        }
        else
        {
            editGuideTrack.text = ""
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //print( "viewDidAppear Docs View" )
        _transport = Transport( viewController: self, includeBandSelectButton: false )
        return super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        _transport?.willDeinit()
        _transport = nil
        super.viewDidDisappear(animated)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func displayAudioFilePicker()
    {
        let documentPicker: UIDocumentPickerViewController = UIDocumentPickerViewController(documentTypes: [kUTTypeMP3 as String, kUTTypeMPEG4Audio as String, kUTTypeWaveformAudio as String, kUTTypeAudio as String, kUTTypeAudioInterchangeFileFormat as String/* kUTTypeMIDIAudio as String, kUTTypeAudio as String*/ ], in: UIDocumentPickerMode.import)
        documentPicker.delegate = self
        documentPicker.title = "Select Audio File"
        documentPicker.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    var originalImageURL:URL? = nil
    
    func displayImageFilePicker()
    {
        let documentPicker: UIDocumentPickerViewController = UIDocumentPickerViewController(documentTypes: [ kUTTypeImage as String], in: UIDocumentPickerMode.import)
        documentPicker.delegate = self
        documentPicker.title = "Select Image File"
        documentPicker.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        self.present(documentPicker, animated: true, completion: nil)
        
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        originalImageURL = nil
        
        if controller.documentPickerMode == UIDocumentPickerMode.import {
            if( url.isFileURL )
            {
                // move to package folder
                let fileName = url.lastPathComponent
                
                if( controller.title == "Select Audio File" )
                {
                    editGuideTrack.text = fileName
                    _newDoc.setOriginalURLForGuideTrack(url)
                    let specifics = _newDoc?.getGuideTrackSpecifics() as AudioEventSpecifics?
                    specifics?.favouriDevicePlayback = true
                    specifics?.favourMultiChanPlayback = false
                    specifics?.volume = 1.0
                    specifics?.pan = -1.0
                    specifics?.ignoreDownmixiDevice = true
                    specifics?.ignoreDownmixMultiChan = false
                    specifics?.downmixToMono = true
                    specifics?.chan = 1
                    specifics?.inputChan = 1
                    
                    self._transport.muzomaDoc = _newDoc
                    let prevShouldClose = shouldClose
                    shouldClose = false
                    createFromScreenFields() // update the guide track
                    shouldClose = prevShouldClose
                }
                else if( controller.title == "Select Image File" )
                {
                    editArtwork.text = fileName
                    _newDoc.setOriginalURLForArtwork(url)
                    
                    _ = url.startAccessingSecurityScopedResource()
                    let data = try? Data(contentsOf: url )
                    url.stopAccessingSecurityScopedResource()
                    if( data != nil )
                    {
                        self.artworkImage.image = UIImage(data: data!)
                        //self.artwork.sizeToFit()
                    }
                }
            }
        }
    }
    
    
    var shouldClose:Bool = true
    func createFromScreenFields()
    {
        _ = self._newDoc.ensureDocumentURLExists()
        let fileManager = FileManager.default
        
        var guideTrackCopied = false
        do
        {
            // move to package folder
            let url = self._newDoc.getGuideTrackOriginalURL() // e.g. file:///private/var/mobile/Containers/Data/Application/0F442F9F/Documents/Band%20-%20A/
            if( url != nil )
            {
                let fileName = url!.lastPathComponent // e.g. Band - A
                
                let destURL = self._newDoc.getDocumentFolderPathURL()!.appendingPathComponent(fileName) //e.g. file:///private/var/mobile/Containers/Data/Application/0F442F9F/Documents/Band%20-%20A/Band%20-%20A
                
                if( !(url!.sameDocumentPathAs(destURL)) ) // we are moving?
                {
                    // remove the old file
                    if( _gFSH.fileExists(url!) ) // still tmp file available?
                    {
                        do
                        {
                            if( _gFSH.fileExists(destURL) )
                            {
                                try fileManager.removeItem(at: destURL)
                                Logger.log("\(#function)  \(#file) Deleted \(destURL.absoluteString)")
                            }
                        }
                        catch let error as NSError {
                            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                        }
                        
                        do
                        {
                            // copy the new one
                            try fileManager.copyItem( at: url!, to: destURL)
                            self._newDoc.setDataForTrackEvent( self._newDoc.getGuideTrackIndex(), eventIdx: 0, url: destURL )
                            
                            let specifics = _newDoc?.getGuideTrackSpecifics() as AudioEventSpecifics?
                            if( specifics == nil || (!(specifics?.favouriDevicePlayback)! && !(specifics?.favourMultiChanPlayback)!) )
                            {
                                specifics?.favouriDevicePlayback = true
                                specifics?.favourMultiChanPlayback = false
                                specifics?.volume = 1.0
                                specifics?.pan = -1.0
                                specifics?.ignoreDownmixiDevice = true
                                specifics?.ignoreDownmixMultiChan = false
                                specifics?.downmixToMono = true
                                specifics?.chan = 1
                                specifics?.inputChan = 1
                            }
                            
                            guideTrackCopied = true
                        }
                        catch let error as NSError {
                            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                        }
                    }
                    else
                    {
                        guideTrackCopied = true // was already copied before
                    }
                }
                else
                {
                    guideTrackCopied = true // was already copied before
                }
            }
        }
        
        if( !guideTrackCopied )
        {
            let alert = UIAlertController(title: "Error", message: "Guide track could not be copied", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                print("Error copying file")
            }))
            
            alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            self.present(alert, animated: true, completion: nil)
            self.shouldClose = false
        }
        
        var imageCopied = false
        do
        {
            // image
            // move to package folder
            let url = self._newDoc.getOriginalArtworkURL()
            if( url != nil )
            {
                let fileName = url!.lastPathComponent
                let destURL = self._newDoc.getDocumentFolderPathURL()!.appendingPathComponent(fileName)
                
                if( _gFSH.fileExists(url!) ) // still tmp file available?
                {
                    if( !(url!.sameDocumentPathAs(destURL)) ) // we are moving?
                    {
                        // remove the old file
                        do
                        {
                            if( _gFSH.fileExists(destURL) )
                            {
                                try fileManager.removeItem(at: destURL)
                                Logger.log("\(#function)  \(#file) Deleted \(destURL.absoluteString)")
                            }
                        }
                        catch let error as NSError {
                            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                        }
                        
                        // copy the new one
                        do
                        {
                            try fileManager.copyItem( at: url!, to: destURL)
                            self._newDoc._coverArtURL = fileName
                            _newDoc.updateArtwork()
                            imageCopied = true
                        }
                        catch let error as NSError {
                            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                        }
                    }
                    else
                    {
                        imageCopied = true // was already copied
                    }
                }
                else
                {
                    imageCopied = true // was already copied
                }
            }
        }
        
        if( !imageCopied )
        {
            let alert = UIAlertController(title: "Error", message: "Artwork image could not be copied", preferredStyle: UIAlertController.Style.alert)
            
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                print("Error copying file")
            }))
            
            alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            
            //self.showViewController(alert, sender: self)
            self.present(alert, animated: true, completion: nil)
            self.shouldClose = false
        }
        
        if( self.shouldClose )
        {
            _newDoc._author = editAuthor.text
            _newDoc._copyright = editCopyright.text
            _newDoc._publisher = editPublisher.text
            _newDoc._key = editKey.text
            _newDoc._tempo = editTempo.text
            _newDoc._timeSignature = editTimeSignature.text
            _newDoc._setsOnly = swithSetsOnly.isOn
            
            _ = _gFSH.saveMuzomaDocLocally(self._newDoc)
            //globalDocumentMapper.addNewDoc(self._newDoc)
            
            // assign latest doc to the transport
            _transport.muzomaDoc = _newDoc
            
            // save and go to top level or previous screen if editing
            var done = false
            if( self.navigationController != nil)
            {
                // pop to previous vc
                let viewControllers: [UIViewController] = self.navigationController!.viewControllers as [UIViewController]
                
                
                for vcCnt in (0..<viewControllers.count)
                {
                    // mark the top view as dirty
                    if( viewControllers[vcCnt] is EditTmingViewController )
                    {
                        let editTimingVC = viewControllers[vcCnt] as! EditTmingViewController
                        editTimingVC.muzomaDoc = _newDoc
                        self.navigationController!.popToViewController(editTimingVC, animated: true)
                        done = true
                    }
                    
                    if( viewControllers[vcCnt] is DocumentsCollectionViewController )
                    {
                        //globalDocumentMapper takes care of the new doc
                        let targetVC = viewControllers[vcCnt] as! DocumentsCollectionViewController
                        targetVC.refreshDocs()
                    }
                }
            }
            
            if( !done )
            {
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
    
    @IBAction func cancelClicked(_ sender: AnyObject) {
        shouldClose = true
        self.dismiss(animated: true, completion: {
            let nc = NotificationCenter.default
            nc.post(name: Notification.Name(rawValue: "RefreshDocsView"), object: nil)
        })
    }
    
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
    }
    
    @IBAction func createClicked(_ sender: AnyObject) {
        shouldClose = true
        
        if( self._isUpdateExisting )
        {
            _newDoc._title = _originalTitle
            _newDoc._artist = _originalArtist
            
            if( editTitle.text != _newDoc._title ||
                editArtist.text != _newDoc._artist
                )
            {
                let fsh = _gFSH
                
                // create a dummy doc at the new location
                let newlocationDoc = MuzomaDocument()
                newlocationDoc._title = self.editTitle.text
                newlocationDoc._artist = self.editArtist.text
                
                if( fsh.fileExists(newlocationDoc.diskFolderFilePath) )
                {
                    // can't update - already exists
                    let alert = UIAlertController(title: "Document already exists", message: "Error, a document already exists with that titile, please rename", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
                        //
                    }))
                    alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                    self.present(alert, animated: true, completion: nil)
                }
                else
                {
                    // changed title / keep existing or overwrite
                    let alert = UIAlertController(title: "Details changed", message: "Do you wish to update the existing song or create a copy with the new details?", preferredStyle: UIAlertController.Style.alert)
                    
                    alert.addAction(UIAlertAction(title: "Copy", style: .default, handler: { (action: UIAlertAction!) in
                        print("Copy")
                        
                        // copy files to new location
                        self._newDoc = fsh.duplicateMuzDoc( self._newDoc, dummyNewLocationDoc: newlocationDoc ) // returns our new one
                        self._newDoc._title = self.editTitle.text
                        self._newDoc._artist = self.editArtist.text
                        self._newDoc._coverArtURL = self.editArtwork.text
                        self._newDoc.updateArtwork()
                        self._duplicated = true
                        self.createFromScreenFields()
                    }))
                    
                    alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { (action: UIAlertAction!) in
                        //print("overwrite existing")
                        let idx = globalDocumentMapper.getDocIndexFromPhysicalLocation(self._newDoc.diskFolderFilePath)
                        if( idx != nil )
                        {
                            globalDocumentMapper.removeUsingDocumentIdx(idx!)
                        }
                        self._newDoc = fsh.moveMuzDoc( self._newDoc, dummyNewLocationDoc: newlocationDoc ) // returns our new one
                        //self._newDoc._originalArtworkURL =
                        self._newDoc._title = self.editTitle.text
                        self._newDoc._artist = self.editArtist.text
                        self._newDoc._coverArtURL = self.editArtwork.text
                        self._newDoc.updateArtwork()
                        self.createFromScreenFields()
                    }))
                    alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                    self.present(alert, animated: true, completion: nil)
                }
            }
            else
            {
                self.createFromScreenFields()
            }
        }
        else
        {
            _newDoc._title = editTitle.text
            _newDoc._artist = editArtist.text
            _newDoc._coverArtURL = editArtwork.text
            _newDoc.updateArtwork()
            
            let fileURL = _newDoc.getDocumentURL()
            
            if( _gFSH.fileExists(fileURL) )
            {
                let alert = UIAlertController(title: "Overwrite", message: "Do you wish to overwrite the existing Muzoma file?", preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                    //print("overwrite file Yes")
                    self.createFromScreenFields()
                }))
                
                alert.addAction(UIAlertAction(title: "No", style: .default, handler: { (action: UIAlertAction!) in
                    //print("overwrite file No")
                }))

                alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                self.present(alert, animated: true, completion: nil)
            }
            else
            {
                self.createFromScreenFields()
            }
        }
    }
}

