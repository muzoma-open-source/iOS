//
//  CreateNewSetViewController.swift
//  Event Sequencer
//
//  Created by Matthew Hopkins on 10/12/2015.
//  Copyright © 2015 Muzoma.com. All rights reserved.
//
// UI to handle creation of a new set
//

import UIKit
import MediaPlayer
import AVFoundation
import MobileCoreServices

class CreateNewSetViewController : UIViewController, UIDocumentPickerDelegate
{
    fileprivate var _transport:Transport! = nil
    var _newSetDoc:MuzomaSetDocument! = nil
    var _isUpdateExisting = false
    var _duplicated = false
    
    @IBOutlet weak var butDone: UIButton!
    @IBOutlet weak var editTitle: UITextField!
    @IBOutlet weak var editArtist: UITextField!
    @IBOutlet weak var editArtwork: UITextField!
    @IBOutlet weak var artworkImage: UIImageView!
    
    @IBAction func titleEditChanged(_ sender: AnyObject) {
        // don't allow bad chars
        self.editTitle.text = self.editTitle.text?.stringByRemovingCharactersInSet(acceptableProperSet.inverted)
    }
    
    @IBAction func artistEditChanged(_ sender: AnyObject) {
        // don't allow bad chars
        self.editArtist.text = self.editArtist.text?.stringByRemovingCharactersInSet(acceptableProperSet.inverted)
    }
    
    @IBAction func SelectArtwork(_ sender: AnyObject)
    {
        displayImageFilePicker()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        if( _newSetDoc == nil )
        {
            _newSetDoc = MuzomaSetDocument()
            _newSetDoc.loadEmptyDefaultSet()
        }
        
        if( _isUpdateExisting )
        {
            butDone.setTitle("Update", for: UIControl.State() )
        }
        
        shouldClose = true
        editTitle.text = _newSetDoc._title
        editArtist.text = _newSetDoc._artist
        editArtwork.text = _newSetDoc._coverArtURL
        
        let _artSourceURL = _newSetDoc.getArtworkURL()
        if( _artSourceURL != nil )
        {
            let data = try? Data(contentsOf: _artSourceURL! )
            if( data != nil )
            {
                self.artworkImage.image = UIImage(data: data!)
                _newSetDoc._originalArtworkURL = _artSourceURL!.absoluteString // set the artwork source to our current image
                //self.artwork.sizeToFit()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //print( "viewDidAppear Docs View" )
        _transport = Transport( viewController: self, includeBandSelectButton: false )
        self.navigationItem.prompt = _newSetDoc!.getFolderName()
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
                
                if( controller.title == "Select Image File" )
                {
                    editArtwork.text = fileName
                    _newSetDoc.setOriginalURLForArtwork(url)
                    let data = try? Data(contentsOf: url )
                    if( data != nil )
                    {
                        self.artworkImage.image = UIImage(data: data!)
                    }
                }
            }
        }
    }
    
    var shouldClose:Bool = true
    func createFromScreenFields()
    {
        _ = self._newSetDoc.ensureSetURLExists() // create new folder
        let fileManager = FileManager.default
        
        var imageCopied = false
        do
        {
            // image
            // move to package folder
            let url = self._newSetDoc.getOriginalArtworkURL()
            if( url != nil )
            {
                let fileName = url!.lastPathComponent
                
                let destURL = self._newSetDoc.getSetFolderPathURL()!.appendingPathComponent(fileName)
                
                if( _gFSH.fileExists(url!) ) // still tmp file available?
                {
                    if( !(url!.sameDocumentPathAs(destURL)) ) // we are moving?
                    {
                        // remove the old file
                        do
                        {
                            try fileManager.removeItem(at: destURL)
                            Logger.log("\(#function)  \(#file) Deleted \(destURL.absoluteString)")
                        }
                        catch let error as NSError {
                            Logger.log("\(#function)  \(#file)  \(error.localizedDescription)")
                        }
                        
                        // copy the new one
                        do
                        {
                            try fileManager.copyItem( at: url!, to: destURL)
                            self._newSetDoc._coverArtURL = fileName
                            imageCopied = true
                        }
                        catch let error as NSError {
                            Logger.log("\(#function)  \(#file)  \(error.localizedDescription)")
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
        
        // save and go to top level or previous screen if editing
        if( self.shouldClose )
        {
            _ = _gFSH.saveMuzomaSetLocally(self._newSetDoc)
            // assign latest doc to the transport
            _transport.muzomaSetDoc = self._newSetDoc
            
            // pop to previous vc
            var done = false
            if( self.navigationController != nil)
            {
            let viewControllers: [UIViewController] = self.navigationController!.viewControllers as [UIViewController]

            for vcCnt in (0..<viewControllers.count)
            {
                // mark the top view as dirty
                if( viewControllers[vcCnt] is SetsCollectionViewController )
                {
                    let setsCollectionVC = viewControllers[vcCnt] as! SetsCollectionViewController
                    setsCollectionVC.viewDirty = true
                }
                
                if( viewControllers[vcCnt] is SetTableViewController )
                {
                    let targetVC = viewControllers[vcCnt] as! SetTableViewController
                    targetVC.muzomaSetDoc = self._newSetDoc
                    self.navigationController!.popToViewController(targetVC, animated: true)
                    done = true
                }
            }
            }

            if( !done )
            {
                self.navigationController!.popViewController(animated: true)
            }
        }
    }
    
    @IBAction func cancelClicked(_ sender: AnyObject) {
        shouldClose = true
    }
    
    
    @IBAction func createClicked(_ sender: AnyObject) {
        shouldClose = true
        
        if( self._isUpdateExisting )
        {
            if( editTitle.text != _newSetDoc._title ||
                editArtist.text != _newSetDoc._artist
                )
            {
                let fsh = _gFSH
                
                // create a dummy doc at the new location
                let newlocationDoc = MuzomaSetDocument()
                newlocationDoc._title = self.editTitle.text
                newlocationDoc._artist = self.editArtist.text
                
                // changed title / keep existing or overwrite
                let alert = UIAlertController(title: "Details changed", message: "Do you wish to update the existing set or create a copy with the new details?", preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "Copy", style: .default, handler: { (action: UIAlertAction!) in
                    //print("Copy")
                    
                    // copy files to new location
                    self._newSetDoc = fsh.duplicateMuzSetDoc( self._newSetDoc, dummyNewLocationDoc: newlocationDoc ) // returns our new one
                    self._newSetDoc._title = self.editTitle.text
                    self._newSetDoc._artist = self.editArtist.text
                    self._newSetDoc._coverArtURL = self.editArtwork.text
                    self._duplicated = true
                    self.createFromScreenFields()
                }))
                
                alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { (action: UIAlertAction!) in
                    //print("overwrite existing")
                    self._newSetDoc = fsh.moveMuzSetDoc( self._newSetDoc, dummyNewLocationDoc: newlocationDoc ) // returns our new one
                    
                    //self._newDoc._originalArtworkURL =
                    self._newSetDoc._title = self.editTitle.text
                    self._newSetDoc._artist = self.editArtist.text
                    self._newSetDoc._coverArtURL = self.editArtwork.text
                    
                    self.createFromScreenFields()
                }))

                alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                self.present(alert, animated: true, completion: nil)
            }
            else
            {
                self.createFromScreenFields()
            }
        }
        else
        {
            _newSetDoc._title = editTitle.text
            _newSetDoc._artist = editArtist.text
            _newSetDoc._coverArtURL = editArtwork.text
            
            let fileURL = _newSetDoc.getSetURL()
            
            if( _gFSH.fileExists(fileURL) )
            {
                let alert = UIAlertController(title: "Overwrite", message: "Do you wish to overwrite the existing Muzoma file?", preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                    print("overwrite file Yes")
                    self.createFromScreenFields()
                }))
                
                alert.addAction(UIAlertAction(title: "No", style: .default, handler: { (action: UIAlertAction!) in
                    print("overwrite file No")
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

