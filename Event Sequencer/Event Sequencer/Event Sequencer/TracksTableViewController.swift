//
//  TracksTableViewController.swift
//  
//
//  Created by Matthew Hopkins on 02/12/2015.
//
//  UI for managing tracks / channels  of a song
//

import UIKit

class TracksTableViewController: UITableViewController {
    let nc = NotificationCenter.default
    var muzomaDoc: MuzomaDocument?
    var selRow:Int! = nil

    @IBOutlet weak var butAdd: UIBarButtonItem!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = true

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        self.navigationItem.prompt = muzomaDoc!.getFolderName()
        
        let pro = MuzomaProducts.store.isProductPurchased( "MuzomaProducer" )
        //pro = true
        if(!pro)
        {
            self.tableView.isUserInteractionEnabled = false
            self.butAdd.isEnabled = false
            
            let alert = UIAlertController(title: "Track List", message: "The track list feature is disabled, please upgrade or restore the Producer version to use this feature", preferredStyle: UIAlertController.Style.alert )
            
            let iap = UIAlertAction(title: "In app purchases", style: .default, handler: { (action: UIAlertAction!) in
                print("IAP")
                let iapVC = self.storyboard?.instantiateViewController(withIdentifier: "IAPTableViewController") as? IAPTableViewController
                self.navigationController?.pushViewController(iapVC!, animated: true)
            })
            
            alert.addAction(iap)
            
            alert.addAction(UIAlertAction(title: "Later", style: .cancel, handler: { (action: UIAlertAction!) in
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

    override func viewDidAppear(_ animated: Bool) {
        //print( "viewDidAppear tracks table" )
        nc.addObserver(self, selector: #selector(TracksTableViewController.refreshTracksList(_:)), name: NSNotification.Name(rawValue: "RefreshTracksList"), object: nil)
        selRow = nil
        self.tableView.reloadData()
        return super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "RefreshTracksList"), object: nil )
        return( super.viewDidDisappear(animated) )
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @objc func refreshTracksList(_ notification: Notification) {
        selRow = nil
        self.tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return (muzomaDoc?._tracks.count)!
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrackCellReuse", for: indexPath)

        // Configure the cell...
        let trackCell = (cell as! TracksTableViewCell)
        
        trackCell.trackIdEditor.text = String(indexPath.row)
        trackCell.trackNameEditor.text = muzomaDoc?._tracks[indexPath.row]._trackName
        //trackCell.trackType.text = muzomaDoc?._tracks[indexPath.row]._trackType.description
        trackCell.trackPurpose.text = muzomaDoc?._tracks[indexPath.row]._trackPurpose.description
        return cell
    }
    
    //override func tableView( tableView: UITableView

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        let track = muzomaDoc?._tracks[indexPath.row]
        var ret:Bool = true
        switch( track?._trackPurpose )
        {  // can't remove these tracks as they are assumed present and needed
            case TrackPurpose.Structure?:
                ret = false
            break;

            case TrackPurpose.Conductor?:
                ret = false
            break;
            
            case TrackPurpose.GuideAudio?:
                ret = false
            break;
            
            case TrackPurpose.KeySignature?:
                ret = false
            break;
            
            case TrackPurpose.MainLyrics?:
                ret = false
            break;
            
            case TrackPurpose.MainSongChords?:
                ret = false
            break;
            
            default:
                ret = true
            break;
        }
        
        // Return false if you do not want the specified item to be editable.
        return ret
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        selRow = self.tableView.indexPathForSelectedRow!.row
        // now nav to editor
        if( self.tableView.indexPathForSelectedRow != nil ) // selected row
        {
            performSegue(withIdentifier: "TrackEditSegue", sender: nil) // show editor for this track
        }
        
    /*   let newSelRow = self.tableView.indexPathForSelectedRow!.row
         
         if( selRow != nil )
        {
            if( newSelRow == selRow )
            {
                /* was de-select
                selRow=nil
                self.tableView.deselectRowAtIndexPath(self.tableView.indexPathForSelectedRow!,animated: true)
                self.reloadInputViews()*/
            }
            else
            {
                selRow = newSelRow
            }
        }
        else
        {
            selRow = newSelRow
        }*/
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        selRow = nil
        
        var doSuper = true
        if( editing == true ) // if editing
        {
            if( self.tableView.indexPathForSelectedRow != nil ) // selected row
            {
                doSuper=false
                performSegue(withIdentifier: "TrackEditSegue", sender: nil) // show editor for this track
            }
        }

        if( doSuper )
        {
            super.setEditing(editing, animated: animated)
            
            var updated = false
            // make cells contents editable or not
            for item in self.tableView.visibleCells as! [TracksTableViewCell] {
                let indexPath : IndexPath = self.tableView!.indexPath(for: item as TracksTableViewCell)!
                let trackCell : TracksTableViewCell = self.tableView!.cellForRow(at: indexPath) as! TracksTableViewCell
                trackCell.trackNameEditor.isEnabled = editing
                trackCell.trackIdEditor.text = String(indexPath.row)
                if( editing )
                {
                    trackCell.trackNameEditor.text = muzomaDoc?._tracks[indexPath.row]._trackName
                }
                else
                {
                    if(  muzomaDoc?._tracks[indexPath.row]._trackName != trackCell.trackNameEditor.text!)
                    {
                        muzomaDoc?._tracks[indexPath.row]._trackName = trackCell.trackNameEditor.text!
                        updated = true
                    }
                }
                //trackCell.trackType.text = muzomaDoc?._tracks[indexPath.row]._trackType.description
                trackCell.trackPurpose.text = muzomaDoc?._tracks[indexPath.row]._trackPurpose.description
            }
            
            if( updated )
            {
                _ = _gFSH.saveMuzomaDocLocally(muzomaDoc)
            }
        }
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            muzomaDoc?.removeTrack(indexPath.row)
            _ = _gFSH.saveMuzomaDocLocally(muzomaDoc)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        let movedObject = muzomaDoc?._tracks[sourceIndexPath.row]
        muzomaDoc?._tracks.remove(at: sourceIndexPath.row)
        muzomaDoc?._tracks.insert(movedObject!, at: destinationIndexPath.row)
        _ = _gFSH.saveMuzomaDocLocally(muzomaDoc)
    }
    
    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return( "Remove track?" )
    }
    
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        if( segue.destination.isKind(of: EditTracksViewController.self) )
        {
            let editor = (segue.destination as! EditTracksViewController)
            editor.muzomaDoc = muzomaDoc
            if( self.tableView.indexPathForSelectedRow != nil)
            {
                selRow = self.tableView.indexPathForSelectedRow!.row
                editor._track = selRow
                //editor._tracksTableViewController = self
            }
            else
            {
                selRow = nil
                editor._track = nil
            }
        }
    }
}
