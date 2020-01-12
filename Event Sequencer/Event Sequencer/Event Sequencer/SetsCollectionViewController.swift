//
//  SetsCollectionViewController.swift
//  Event Sequencer
//
//  Created by Matthew Hopkins on 16/11/2015.
//  Copyright © 2015 Muzoma.com. All rights reserved.
//
// UI to handle collections of sets

import UIKit


class SetsCollectionViewController: UICollectionViewController {
    fileprivate let reuseIdentifier = "MuzSetCell"
    fileprivate let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    fileprivate let fileSystemHelper = _gFSH
    fileprivate var muzomaSetDocs = [MuzomaSetDocument]()
    fileprivate var _transport:Transport! = nil
    
    let nc = NotificationCenter.default
    var selectingSetToAddTo = false
    var additionalMuzomaDocs = [MuzomaDocument]()
    
    
    fileprivate var _viewDirty:Bool = false
    var viewDirty:Bool
        {
        get
        {
            return(_viewDirty)
        }
        
        set
        {
            _viewDirty = newValue
        }
    }
    
    @IBOutlet weak var selectButton: UIBarButtonItem!

    @IBOutlet weak var currentButton: UIBarButtonItem!

    @IBAction func currentButtonClick(_ sender: AnyObject) {
        if( _transport.muzomaSetDoc != nil )
        {
            // go to sets
            let setTableController = self.storyboard?.instantiateViewController(withIdentifier: "setPlayerTableViewController") as? SetTableViewController
            setTableController!.muzomaSetDoc = _transport.muzomaSetDoc
            self.navigationController?.pushViewController(setTableController!, animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = true
        
        self.refreshSets()
        
        if(selectingSetToAddTo)
        {
            let alert = UIAlertController(title: "Select a Set", message: "Select a set to add the songs ...", preferredStyle: UIAlertController.Style.alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
                //print("load file Yes")
                
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                self.dismiss(animated: true, completion: {
                    self.selectingSetToAddTo = false
                })
            }))
            
            alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //print( "viewDidAppear Sets View" )
        _transport = Transport( viewController: self, includeVarispeedButton: false, includeRecordTimingButton: false, isSetPlayer: true, includeExtControlButton: true )
        self.currentButton.isEnabled = _transport.muzomaSetDoc != nil
        nc.addObserver(self, selector: #selector(SetsCollectionViewController.setSelectNextSong(_:)), name: NSNotification.Name(rawValue: "SetSelectNextSong"), object: nil)
        nc.addObserver(self, selector: #selector(SetsCollectionViewController.setSelectPreviousSong(_:)), name: NSNotification.Name(rawValue: "SetSelectPreviousSong"), object: nil)
        nc.addObserver(self, selector: #selector(SetsCollectionViewController.setSelectedSong(_:)), name: NSNotification.Name(rawValue: "SetSelectedSong"), object: nil)
        nc.addObserver(self, selector: #selector(SetsCollectionViewController.RefreshSetsView(_:)), name: NSNotification.Name(rawValue: "RefreshSetsView"), object: nil)

        if( _viewDirty )
        {
            self.refreshSets()
        }
        return super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "SetSelectNextSong"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "SetSelectPreviousSong"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "SetSelectedSong"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "RefreshSetsView"), object: nil )

        _transport?.willDeinit()
        _transport = nil
        return( super.viewDidDisappear(animated) )
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func setSelectNextSong(_ notification: Notification)
    {
        let newDoc = notification.object as! MuzomaDocument
        self._transport.muzomaDoc = newDoc
    }
    
    @objc func setSelectPreviousSong(_ notification: Notification)
    {
        let newDoc = notification.object as! MuzomaDocument
        self._transport.muzomaDoc = newDoc
    }
    
    @objc func setSelectedSong(_ notification: Notification)
    {
        let newDoc = notification.object as! MuzomaDocument
        self._transport.muzomaDoc = newDoc
    }
    
    @IBAction func backButtonPressed(_ sender: AnyObject) {
        navigationController!.popViewController(animated: true)
    }
    
    @IBAction func DeleteButtonClicked(_ sender: AnyObject) {
        _transport.muzomaSetDoc = nil
        let button = sender as! UIButton
        let view = button.superview!
        let cell = view.superview as! MuzSetCollectionViewCell
        cell.DeleteButtonPress(self)
        selectButtonClicked(sender)
    }
    
    @objc func RefreshSetsView(_ notification: Notification) {
        refreshSets()
    }
    
    func refreshSets()
    {
        muzomaSetDocs = fileSystemHelper.getMuzomaSetDocs(filterText)
        self.collectionView?.reloadData()
        _viewDirty = false
    }
    
    @IBAction func addButtonClicked(_ sender: AnyObject) {
        // go to new set
        let newSetController = self.storyboard?.instantiateViewController(withIdentifier: "CreateNewSetViewController") as? CreateNewSetViewController
        self.navigationController?.pushViewController(newSetController!, animated: true)
    }

    @IBAction func selectButtonClicked(_ sender: AnyObject) {
        self.isEditing = !self.isEditing
        
        //Looping through CollectionView Cells in Swift
        //http://stackoverflow.com/questions/25490380/looping-through-collectionview-cells-in-swift
        
        for item in self.collectionView!.visibleCells as! [MuzSetCollectionViewCell] {
            
            let indexpath : IndexPath = self.collectionView!.indexPath(for: item as MuzSetCollectionViewCell)!
            
            let cell : MuzSetCollectionViewCell = self.collectionView!.cellForItem(at: indexpath) as! MuzSetCollectionViewCell
            
            //Close Button
            let close : UIButton = cell.CloseButton //  viewWithTag(102) as UIButton
            close.isHidden = !self.isEditing
        }
        
        if(self.isEditing)
        {
            //self.navigationItem.rightBarButtonItem?.title = "Done"
            selectButton?.title = "Done"
        }
        else
        {
            //self.navigationItem.rightBarButtonItem?.title = "Edit"
            selectButton?.title = "Select"
        }
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        
        var docCell:MuzSetCollectionViewCell! = nil
        var doc:MuzomaSetDocument! = nil
        if( sender is MuzSetCollectionViewCell )
        {
            docCell = (sender as! MuzSetCollectionViewCell)
            doc = docCell.muzomaSetDoc
            
            if( segue.destination.isKind(of: SetTableViewController.self) )
            {
                let setTable = (segue.destination as! SetTableViewController)
                
                // is it the currently playing set then swap it for the transport version for continuity
                if( _transport.muzomaDoc != nil && _transport.muzomaDoc.isPlaying() )
                {
                    if( _transport.muzomaSetDoc != nil &&
                        (_transport.muzomaSetDoc._uid == doc._uid && _transport.muzomaSetDoc._lastUpdateDate == doc._lastUpdateDate) )
                    {
                        setTable.muzomaSetDoc = _transport.muzomaSetDoc
                    }
                    else
                    {
                        setTable.muzomaSetDoc = doc
                    }
                }
                else
                {
                    setTable.muzomaSetDoc = doc
                }
                
                if( selectingSetToAddTo )
                {
                    setTable.addingToSet = true
                    setTable.additionalMuzomaDocs = self.additionalMuzomaDocs
                    self.selectingSetToAddTo = false
                    self.additionalMuzomaDocs = []
                }
            }
        }
    }
    
    
    var filterText:String! = nil
    @IBAction func searchAction(_ sender: AnyObject) {
        let searchFor = (sender as! UITextField)
        searchFor.resignFirstResponder()
        filterText = searchFor.text
        refreshSets()
    }


    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        // #warning Incomplete implementation, return the number of items
        return muzomaSetDocs.count// fileSystemHelper.numberOfMuzomaSetDocumentsLocally()
        //return 10  
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! MuzSetCollectionViewCell
        
        let row=indexPath.row
        if( muzomaSetDocs.count > row )
        {
            let doc=muzomaSetDocs[row]
            //doc._title = "muz \(row)"
            cell.SetDocument(doc)
            cell.backgroundColor = UIColor.white
        }
        
        return cell
    }
    

    func collectionView(_ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
            return CGSize(width: 100, height: 100)
    }

    func collectionView(_ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAtIndex section: Int) -> UIEdgeInsets {
            return sectionInsets
    }
}
