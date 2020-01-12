//
//  SetTableViewController.swift
//
//
//  Created by Matthew Hopkins on 02/12/2015.
//
//  UI code to handle the contents of sets as a table
//

import UIKit


// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


class SetTableViewController : UITableViewController {
    @IBOutlet weak var actionButton: UIBarButtonItem!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var butControls: UIBarButtonItem!
    
    let nc = NotificationCenter.default
    var muzomaSetDoc: MuzomaSetDocument?
    var _songLines: [MuzEvent]?
    var selRow:Int! = nil
    var addingToSet = false
    var additionalMuzomaDocs = [MuzomaDocument]()
    var playerDocController:PlayerDocumentViewController! = nil
    var _transport:Transport! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // hide controls button as its already on the transport bar
        butControls.style = .plain;
        butControls.isEnabled = false;
        butControls.title = nil;
        playerDocController = self.storyboard?.instantiateViewController(withIdentifier: "PlayerDocumentViewController") as? PlayerDocumentViewController
        playerDocController!._isPlayingFromSet = true
        self.clearsSelectionOnViewWillAppear = false
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        self.navigationItem.prompt = muzomaSetDoc!.getFolderName()
        
        if( addingToSet )
        {
            let alert = UIAlertController(title: "Add documents", message: "Do you wish to add \(additionalMuzomaDocs.count) documents to this set?", preferredStyle: UIAlertController.Style.alert)
            
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                //print("add set yes")
                self.muzomaSetDoc?.addDocs(self.additionalMuzomaDocs)
                _ = _gFSH.saveMuzomaSetLocally( self.muzomaSetDoc )
                self.tableView.reloadData()
            }))
            
            alert.addAction(UIAlertAction(title: "No", style: .default, handler: { (action: UIAlertAction!) in
                print("add set no")
            }))
            
            alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        _transport = Transport( viewController: self, includeVarispeedButton: false, includeRecordTimingButton: false, isSetPlayer: true, includeExtControlButton: true, includeLoopButton: true )
        _transport.muzomaSetDoc = self.muzomaSetDoc
        self.navigationItem.prompt = muzomaSetDoc!.getFolderName()
        
        selectCurrentlyPlayingEntryInSet()
        
        nc.addObserver(self, selector: #selector(SetTableViewController.playerPlayed(_:)), name: NSNotification.Name(rawValue: "PlayerPlay"), object: nil)
        nc.addObserver(self, selector: #selector(SetTableViewController.setSelectNextSong(_:)), name: NSNotification.Name(rawValue: "SetSelectNextSong"), object: nil)
        nc.addObserver(self, selector: #selector(SetTableViewController.setPreviousSong(_:)), name: NSNotification.Name(rawValue: "SetSelectPreviousSong"), object: nil)
        nc.addObserver(self, selector: #selector(SetTableViewController.setSelectedSong(_:)), name: NSNotification.Name(rawValue: "SetSelectedSong"), object: nil)
        
        return super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "PlayerPlay"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "SetSelectNextSong"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "SetSelectPreviousSong"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "SetSelectedSong"), object: nil )
        
        _transport?.willDeinit()
        _transport = nil
        return( super.viewDidDisappear(animated) )
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func actionPressed(_ sender: AnyObject) {
        
        let alert = UIAlertController(title: "Set Sharing", message: "Note: sharing a set can take up a lot of temporary space", preferredStyle: UIAlertController.Style.alert)
        
        
        alert.addAction(UIAlertAction(title: "Share Set", style: .default, handler: { (action: UIAlertAction!) in
            //print( "action pressed" )
            let textToShare:String = (self.muzomaSetDoc?.getFolderName())!
            self.addSpinnerView()
            
            let delay = DispatchTime.now() + Double(Int64(0.2 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delay,execute: {
                if let zip = _gFSH.getMuzSetZip( self.muzomaSetDoc )
                {
                    let objectsToShare = [textToShare, zip] as [Any]
                    let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
                    
                    activityVC.popoverPresentationController?.barButtonItem = self.actionButton
                    
                    activityVC.excludedActivityTypes = []//UIActivityTypeCopyToPasteboard,UIActivityTypeAirDrop,UIActivityTypeAddToReadingList,UIActivityTypeAssignToContact,UIActivityTypePostToTencentWeibo,UIActivityTypePostToVimeo,UIActivityTypePrint,UIActivityTypeSaveToCameraRoll,UIActivityTypePostToWeibo]
                    
                    activityVC.completionWithItemsHandler = {
                        (activity, success, items, error) in
                        Logger.log("Activity: \(String(describing: activity)) Success: \(success) Items: \(String(describing: items)) Error: \(String(describing: error))")
                        do
                        {
                            try _gFSH.removeItem(at: zip)
                            Logger.log("\(#function)  \(#file) Deleted \(zip.absoluteString)")
                        } catch let error as NSError {
                            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                        }
                    }
                    
                    self.present(activityVC, animated: true, completion: nil)
                }
                self.removeSpinnerView()
                
            })
        }))
        
        alert.addAction(UIAlertAction(title: "Export as Cymatic LP16", style: .default, handler: { (action: UIAlertAction!) in
            let export = CymaticExport( setDocument: self.muzomaSetDoc )
            export.createCymaticFolderStructure()
        }))

        let pro = MuzomaProducts.store.isProductPurchased( "MuzomaProducer" )
        if(!pro)
        {
            for act in alert.actions
            {
                act.isEnabled = false
            }
        }
        
        let actCancel = UIAlertAction(title: pro ? "Cancel" : "Cancel (Producer Only)", style: .cancel, handler: { (action: UIAlertAction!) in
            //print("overwrite file Yes")
            do
            {
            }
        })
        alert.addAction(actCancel)
        
        
        alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        self.present(alert, animated: true, completion: {})
    }
    
    @objc func setSelectNextSong(_ notification: Notification)
    {
        let newDoc = notification.object as! MuzomaDocument
        self._transport.muzomaDoc = newDoc
        selectCurrentlyPlayingEntryInSet()
    }
    
    @objc func setPreviousSong(_ notification: Notification)
    {
        let newDoc = notification.object as! MuzomaDocument
        self._transport.muzomaDoc = newDoc
        selectCurrentlyPlayingEntryInSet()
    }
    
    @objc func setSelectedSong(_ notification: Notification)
    {
        let newDoc = notification.object as! MuzomaDocument
        self._transport.muzomaDoc = newDoc
        selectCurrentlyPlayingEntryInSet()
    }
    
    @objc func playerPlayed(_ notification: Notification) {
        _transport.muzomaDoc = notification.object as? MuzomaDocument
        selectCurrentlyPlayingEntryInSet()
        goToPlayerView()
    }
    
    func goToPlayerView()
    {
        // make sure the player view has the correct doc and show the player view
        playerDocController!.muzomaDoc = _transport.muzomaDoc
        
        if( self.navigationController?.topViewController != playerDocController )
        {
            self.navigationController?.pushViewController(playerDocController!, animated: true)
        }
        else
        {
            playerDocController.viewDidAppear(true)
        }
    }
    
    func selectCurrentlyPlayingEntryInSet()
    {
        // select first item in set?
        if( self.muzomaSetDoc != nil && self.muzomaSetDoc!.muzDocs.count > 0 )
        {
            var currentIdx = _transport.muzomaDoc != nil ? self.muzomaSetDoc?.muzDocs.index( of: _transport.muzomaDoc ) : nil
            
            if( (_transport.muzomaDoc == nil || currentIdx == nil) && (_transport.muzomaDoc == nil || !_transport.muzomaDoc.isPlaying()) )
            {
                _transport.muzomaDoc = self.muzomaSetDoc!.muzDocs[0]
            }
            
            if( _transport.muzomaDoc != nil )
            {
                currentIdx = _transport.muzomaDoc != nil ? self.muzomaSetDoc?.muzDocs.index( of: _transport.muzomaDoc ) : nil
                if( currentIdx != nil && currentIdx != self.tableView.indexPathForSelectedRow?.row
                    && currentIdx < self.tableView.numberOfRows(inSection: 0)  )
                {
                    _transport.muzomaDoc._isBeingPlayedFromSet = true
                    self.tableView.selectRow(at: IndexPath(row: currentIdx!, section: 0), animated: true, scrollPosition: UITableView.ScrollPosition.none)
                }
            }
        }
    }
    
    // MARK: - Table view data source
    // table view
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let curSel = self.tableView.indexPathForSelectedRow
        // start from selected cell
        let setCell = self.tableView.cellForRow(at: curSel!) as! SetTableViewCell?
        if( setCell != nil )
        {
            if( self._transport != nil && self._transport.muzomaDoc != nil
                && setCell!.muzomaDoc == self._transport.muzomaDoc )
            {
                goToPlayerView()
            }
            else
            {
                self._transport.muzomaDoc = setCell?.muzomaDoc
                if( setCell!.muzomaDoc.isPlaying() )
                {
                    self._transport.muzomaDoc.stop()
                }
                else
                {
                    self._transport.muzomaDoc.setCurrentTime(0)
                }
            }
            
            _transport.muzomaDoc?._isBeingPlayedFromSet = true
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (muzomaSetDoc?.muzDocs.count)!
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SetCellReuse", for: indexPath)
        
        // Configure the cell...
        let setCell = (cell as! SetTableViewCell)
        let muzDoc = muzomaSetDoc?.muzDocs[indexPath.row]
        
        setCell.setDocument(muzDoc!)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return( "Remove song?" )
    }
    
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        //print( "from \(sourceIndexPath.row) to \(destinationIndexPath.row)" )
        
        let movedObject = muzomaSetDoc?.muzDocs[sourceIndexPath.row]
        muzomaSetDoc?.muzDocs.remove(at: sourceIndexPath.row)
        muzomaSetDoc?.muzDocs.insert(movedObject!, at: destinationIndexPath.row)
        _ = _gFSH.saveMuzomaSetLocally(muzomaSetDoc)
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        return(proposedDestinationIndexPath)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        if( !editing ){
            selectCurrentlyPlayingEntryInSet()
        }
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if( editingStyle == .delete )
        {
            // Delete the row from the data source
            muzomaSetDoc?.muzDocs.remove(at: indexPath.row)
            _ = _gFSH.saveMuzomaSetLocally(muzomaSetDoc)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
        else if( editingStyle == .insert )
        {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    
    var boxView:UIView! = nil
    let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffect.Style.light))
    var oldBGColor:UIColor! = nil
    
    func addSpinnerView() {
        oldBGColor = self.view.backgroundColor
        self.view.backgroundColor = UIColor.clear
        
        //always fill the view
        blurEffectView.frame = self.view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.view.addSubview(blurEffectView) //if you have more UIViews, use an insertSubview API to place it where needed
        // You only need to adjust this frame to move it anywhere you want
        self.boxView = UIView(frame: CGRect(x: view.frame.midX - 90, y: view.frame.midY - 25, width: 180, height: 50))
        self.boxView.isHidden = false
        self.boxView.backgroundColor = UIColor.white
        self.boxView.alpha = 0.8
        self.boxView.layer.cornerRadius = 10
        
        //Here the spinnier is initialized
        let activityView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
        activityView.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        activityView.startAnimating()
        
        let textLabel = UILabel(frame: CGRect(x: 60, y: 0, width: 200, height: 50))
        textLabel.textColor = UIColor.gray
        textLabel.text = "Working..."
        
        self.boxView.addSubview(activityView)
        self.boxView.addSubview(textLabel)
        
        view.addSubview(self.boxView)
    }
    
    func removeSpinnerView()
    {
        self.boxView.isHidden = true
        self.boxView.removeFromSuperview()
        self.view.backgroundColor =  oldBGColor
        blurEffectView.removeFromSuperview()
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        
        if( (sender is UIBarButtonItem) )
        {
            let but = (sender as! UIBarButtonItem)

            if( but.action?.description == "perform:" ) //but.title == "Details" ) // details pressed
            {
                if( segue.destination.isKind(of: CreateNewSetViewController.self) )
                {
                    let setDetails = (segue.destination as! CreateNewSetViewController)
                    setDetails._newSetDoc = self.muzomaSetDoc
                    setDetails._isUpdateExisting = true
                }
            }
        }
    }
}
