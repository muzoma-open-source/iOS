//
//  DocumentsCollectionViewController.swift
//  Event Sequencer
//
//  Created by Matthew Hopkins on 16/11/2015.
//  Copyright © 2015 Muzoma.com. All rights reserved.
//
//  A view controller that handles the collection of songs on the screen
//

import UIKit


class DocumentsCollectionViewController : UICollectionViewController {
    fileprivate let reuseIdentifier = "MuzDocCell"
    fileprivate var selectedCells: Set<Int> = []
    fileprivate let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    fileprivate let fileSystemHelper = _gFSH
    fileprivate var muzomaDocs = globalDocumentMapper
    
    let nc = NotificationCenter.default

    @IBOutlet weak var selectButton: UIBarButtonItem!
    
    fileprivate var _transport:Transport! = nil

    fileprivate static var _viewDirty:Bool = false

    
    static internal var viewDirty:Bool
    {
        get
        {
            return(_viewDirty)
        }
        
        set
        {
            _viewDirty = newValue
            if( _viewDirty )
            {
                globalDocumentMapper.reLoad()
            }
        }
    }
    
    var refresher:UIRefreshControl! = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = true
        refreshDocs()
         
        self.collectionView!.alwaysBounceVertical = true
        refresher.tintColor = UIColor.blue
        refresher.addTarget(self, action: #selector(loadData), for: .valueChanged)
        collectionView!.addSubview(refresher)
    }

    
    @objc func loadData()
    {
        //code to execute during refresher
        DocumentsCollectionViewController.viewDirty = true;
        refreshDocs()
        stopRefresher()         //Call this to stop refresher
    }
    
    func stopRefresher()
    {
        refresher?.endRefreshing()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //print( "viewDidAppear Docs View" )

        if( DocumentsCollectionViewController._viewDirty )
        {
            refreshDocs()
        }
        _transport = Transport( viewController: self, includeBandSelectButton: true, includeExtControlButton: true )
        nc.addObserver(self, selector: #selector(DocumentsCollectionViewController.refreshSettingChanges(_:)), name: UserDefaults.didChangeNotification, object: nil)
        nc.addObserver(self, selector: #selector(DocumentsCollectionViewController.refreshDocsView(_:)), name: NSNotification.Name(rawValue: "RefreshDocsView"), object: nil)
        
        // force the download label to get focus
        let originalOffset = self.collectionView?.contentOffset
        self.collectionView?.setContentOffset( CGPoint(x: (originalOffset?.x)!, y: (originalOffset?.y)!+1), animated: true)
        
        return super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        _transport?.willDeinit()
        _transport = nil
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "RefreshDocsView"), object: nil )
        nc.removeObserver(self, name: UserDefaults.didChangeNotification, object: nil )
        super.viewDidDisappear(animated)
    }
    
    @objc func refreshSettingChanges(_ notification: Notification) {
        refreshDocs()
    }
    
    @IBAction func selectButtonClicked(_ sender: AnyObject) {
        self.isEditing = !self.isEditing
        if(self.isEditing)
        {
            //self.navigationItem.rightBarButtonItem?.title = "Done"
            selectButton?.title = "Action"
            selectButton?.isEnabled = true
            collectionView?.allowsMultipleSelection = true
            setsButton.isEnabled = false
        }
        else
        {
            let alert = UIAlertController(title: "Document Tools", message: "", preferredStyle: UIAlertController.Style.alert )
            
            let del = UIAlertAction(title: "Delete", style: .default, handler: { (action: UIAlertAction!) in
                //print("Delete Docs")
                let alert = UIAlertController(title: "Remove Document/s?", message: "All data will be lost.", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                    //print("Handle Ok logic here")
                    //_gFSH.deleteMuzPackage(self.muzomaDoc)
                    
                    var removeDocs=[MuzomaDocument?]()
                    for idx in self.selectedCells
                    {
                        if( idx < self.muzomaDocs.count )
                        {
                            let removeDoc = self.muzomaDocs[idx]
                            removeDocs.append(removeDoc)
                            _ = _gFSH.deleteMuzPackage(removeDoc)
                        }
                    }
                    
                    for doc in (removeDocs)
                    {
                        self.muzomaDocs.remove(doc)
                    }

                    self.nc.post(name: Notification.Name(rawValue: "RefreshDocsView"), object: nil)
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                    //print("Handle Cancel Logic here")
                    self.nc.post(name: Notification.Name(rawValue: "RefreshDocsView"), object: nil)
                }))
                self.present(alert, animated: true, completion: nil)
            })
            
            let create = UIAlertAction(title: "Create New Set", style: .default, handler: { (action: UIAlertAction!) in
                print("Create New Set")
                
                // go to set creation
                let setDocController = self.storyboard?.instantiateViewController(withIdentifier: "CreateNewSetViewController") as? CreateNewSetViewController
                let setDoc = MuzomaSetDocument()
                setDoc.loadEmptyDefaultSet()
                setDoc.muzDocs = []
                for idx in self.selectedCells
                {
                    if( idx < self.muzomaDocs.count )
                    {
                        setDoc.muzDocs.append(self.muzomaDocs[idx])
                    }
                }
                
                setDocController!._newSetDoc = setDoc
                
                self.navigationController?.pushViewController(setDocController!, animated: true)
                self.nc.post(name: Notification.Name(rawValue: "RefreshDocsView"), object: nil)
                self.nc.post(name: Notification.Name(rawValue: "RefreshSetsView"), object: nil)
            })
            
            let addExisting = UIAlertAction(title: "Add To Existing Set", style: .default, handler: { (action: UIAlertAction!) in
                print("Add To Existing Set")
                // go to set creation
                let setsController = self.storyboard?.instantiateViewController(withIdentifier: "SetsCollectionViewController") as? SetsCollectionViewController
                setsController!.selectingSetToAddTo = true
                setsController!.additionalMuzomaDocs = []
                for idx in self.selectedCells
                {
                    if( idx < self.muzomaDocs.count )
                    {
                        setsController!.additionalMuzomaDocs.append(self.muzomaDocs[idx])
                    }
                }
                self.navigationController?.pushViewController(setsController!, animated: true)
                self.nc.post(name: Notification.Name(rawValue: "RefreshDocsView"), object: nil)
                self.nc.post(name: Notification.Name(rawValue: "RefreshSetsView"), object: nil)
            })
            
            if( selectedCells.isEmpty )
            {
                del.isEnabled = false
                create.isEnabled = false
                addExisting.isEnabled = false
            }
            
            alert.addAction(del)
            alert.addAction(create)
            alert.addAction(addExisting)
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                print("Cancel")
                self.nc.post(name: Notification.Name(rawValue: "RefreshDocsView"), object: nil)
            }))
            
            alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            self.present(alert, animated: true, completion:
                {
                    //print( "document alert shown" )
            } )
        }
    }
    
    var filterText:String! = nil
    @IBAction func searchAction(_ sender: AnyObject) {
        let searchFor = (sender as! UITextField)
        searchFor.resignFirstResponder()
        filterText = searchFor.text
        refreshDocs()
    }
    
    @IBOutlet weak var setsButton: UIBarButtonItem!
    @IBAction func setsButtonClicked(_ sender: AnyObject) {
        // go to sets
        let setsDocController = self.storyboard?.instantiateViewController(withIdentifier: "SetsCollectionViewController") as? SetsCollectionViewController
        self.navigationController?.pushViewController(setsDocController!, animated: true)
    }

    @objc func refreshDocsView(_ notification: Notification) {
        muzomaDocs.reFilter()
        refreshDocs()
    }
    
    func refreshDocs()
    {
        self.collectionView?.allowsSelection = false
        self.collectionView?.allowsSelection = true
        self.selectedCells.removeAll()
        
        selectButton?.title = "Select"
        collectionView?.allowsMultipleSelection = false
        setsButton.isEnabled = true

        muzomaDocs.filterText = filterText
        self.collectionView?.reloadData()
        DocumentsCollectionViewController._viewDirty = false
    }

    @IBAction func DeleteButtonClicked(_ sender: AnyObject) {
        let button = sender as! UIButton
        let view = button.superview!
        let cell = view.superview as! MuzDocCollectionViewCell
        cell.DeleteButtonPress(self)
    }


    // MARK: - Navigation
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        var ret = true
        if( identifier == "ComposeSegue" )
        {
            let pro = MuzomaProducts.store.isProductPurchased( "MuzomaProducer" )
            if(!pro)
            {
                ret = false
                
                let alert = UIAlertController(title: "Composer Feature", message: "Please upgrade to the Producer version to use this feature", preferredStyle: UIAlertController.Style.alert )
                
                //let row = _eventPicker.selectedRowInComponent(0)
                //let lyricEvt = muzomaDoc!._tracks[_lyricTrackIdx]._events[row]
                //let chordEvt = muzomaDoc!._tracks[_chordTrackIdx]._events[row]
                let iap = UIAlertAction(title: "In app purchases", style: .default, handler: { (action: UIAlertAction!) in
                    print("IAP")
                    let iapVC = self.storyboard?.instantiateViewController(withIdentifier: "IAPTableViewController") as? IAPTableViewController
                    self.navigationController?.pushViewController(iapVC!, animated: true)
                })
                

                alert.addAction(iap)
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                    print("Cancel")
                    //self.nc.postNotificationName("RefreshDocsView", object: nil)
                }))
                
                alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                self.present(alert, animated: true, completion:
                    {
                        //print( "iap alert shown" )
                } )
            }
        }
        return( ret )
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        
        var docCell:MuzDocCollectionViewCell! = nil
        var doc:MuzomaDocument! = nil
        if( sender is MuzDocCollectionViewCell)
        {
            docCell = (sender as! MuzDocCollectionViewCell)
            doc = docCell.muzomaDoc
            
            if( segue.destination.isKind(of: PlayerDocumentViewController.self) )
            {
                let player = (segue.destination as! PlayerDocumentViewController)
                player.muzomaDoc = doc
            } else if( segue.destination.isKind(of: TracksTableViewController.self) )
            {
                let editor = (segue.destination as! TracksTableViewController)
                editor.muzomaDoc = doc
            } else if( segue.destination.isKind(of: ChordPickerController.self) )
            {
                let editor = (segue.destination as! ChordPickerController)
                editor.muzomaDoc = doc
            } else if( segue.destination.isKind(of: EditDocumentViewController.self) )
            {
                let editor = (segue.destination as! EditDocumentViewController)
                editor.muzomaDoc = doc
            } else if( segue.destination.isKind(of: EditorLinesController.self) )
            {
                let editor = (segue.destination as! EditorLinesController)
                editor.muzomaDoc = doc
            } else if( segue.destination.isKind(of: EditTmingViewController.self) )
            {
                let editor = (segue.destination as! EditTmingViewController)
                editor.muzomaDoc = doc
            }
        }
    }


    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        // #warning Incomplete implementation, return the number of items
        return muzomaDocs.count// fileSystemHelper.numberOfMuzomaDocumentsLocally()
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! MuzDocCollectionViewCell
        let row=indexPath.row
        if( muzomaDocs.count > row )
        {
            let doc = muzomaDocs[row]
            cell.SetDocument(doc, vc: self, indexPath: indexPath, table: collectionView)
            //print( "new: idx \(indexPath.row) - \(cell.muzomaDoc._artist) - \(cell.muzomaDoc._title)")
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
    
    
    override func collectionView(_ collectionView: UICollectionView,
                                 didSelectItemAt indexPath: IndexPath) {

        //print( "didSelectItemAtIndexPath" )
        
        if( !self.isEditing )
        {
            // go to player
            let playerDocController = self.storyboard?.instantiateViewController(withIdentifier: "PlayerDocumentViewController") as? PlayerDocumentViewController
            let cell = collectionView.cellForItem(at: indexPath) as? MuzDocCollectionViewCell
            if(( cell?.muzomaDoc._isPlaceholder ) != nil)
            {
                cell!.muzomaDoc.deserialize(cell!.muzomaDoc.diskFolderFilePath!)
                cell!.SetDocument(cell!.muzomaDoc, vc: self, indexPath: indexPath, table: collectionView)
            }
            playerDocController!.muzomaDoc = cell?.muzomaDoc
            if( !playerDocController!.muzomaDoc!.isPlaying() )
            {
                playerDocController!.muzomaDoc!._isBeingPlayedFromSet = false
            }
            self.navigationController?.pushViewController(playerDocController!, animated: true)
        }
        else
        {
            selectButton?.isEnabled = true
            selectedCells.insert(indexPath.row)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                 didDeselectItemAt indexPath: IndexPath) {
        //print( "didDeselectItemAtIndexPath" )
        selectedCells.remove(indexPath.row)
    }

    // MARK: UICollectionViewDelegate

    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if( cell is MuzDocCollectionViewCell )
        {
            let docCell = cell as! MuzDocCollectionViewCell

            if( docCell.muzomaDoc?._setsOnly != nil && (docCell.muzomaDoc!._setsOnly! == true && !UserDefaults.standard.bool( forKey: "unhideSetOnly_preference" ) ))
            {
                _needsReload = true
            }
            
            // finished displaying
            if( indexPath.row - 1 == collectionView.indexPathsForVisibleItems.last?.row )
            {
                checkForReload()
                //print( "finished displaying \(indexPath.row)")
            }
        }
    }
    
    var _needsReload = false
    func checkForReload()
    {
        if( _needsReload )
        {
            let delay = DispatchTime.now() + Double(Int64(1.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delay,execute: {
                            if(self._needsReload)
                            {
                                self._needsReload = false
                                //print( "needs reload")
                                self.refreshDocs()
                                //self.collectionView?.reloadData()
                                //print( "loading ..." )
                            }
            })
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        var ret:UICollectionReusableView! = nil

        if kind == UICollectionView.elementKindSectionHeader {
            ret = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "GetContentDownloadCell", for: indexPath) as UICollectionReusableView?
        }    else    if kind == UICollectionView.elementKindSectionFooter {
            ret = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "GetContentDownloadCellFooter", for: indexPath) as UICollectionReusableView?
        }
        return( ret )
    }
    
    @IBAction func downloadOnlineContentClicked(_ sender: AnyObject) {
        
    }
}
