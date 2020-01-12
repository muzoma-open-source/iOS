//
//  GroupPlayerViewController.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 11/05/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//
//  UI side of multi-peer band play - used in conjunction with MuzomaMultiPeerService
//

import UIKit
import MultipeerConnectivity

class GroupPlayerViewController: UIViewController {
    
    @IBOutlet weak var _picker: UIPickerView!
    
    @IBOutlet weak var _externalView: UIView!
    
    @IBOutlet weak var fastfwdButton: UIBarButtonItem!
    
    @IBAction func fastfwdButtonPress(_ sender: AnyObject) {
    }
    
    @IBOutlet weak var pauseButton: UIBarButtonItem!
    
    @IBAction func pauseButtonPress(_ sender: AnyObject) {
    }
    
    @IBOutlet weak var playButton: UIBarButtonItem!
    
    @IBAction func playButtonPress(_ sender: AnyObject) {
    }
    
    @IBOutlet weak var stopButton: UIBarButtonItem!
    
    @IBAction func stopButtonPress(_ sender: AnyObject) {
    }
    
    @IBOutlet weak var rewindButton: UIBarButtonItem!
    
    @IBAction func rewindButtonPress(_ sender: AnyObject) {
    }

    var externalWindow: UIWindow!
    var MuzomaMPService:MuzomaMPServiceManager! = nil
    let center = NotificationCenter.default
    
    @IBAction func sendRedPressed(_ sender: AnyObject) {
        MuzomaMPService.sendColor("red")
    }
    
    @IBAction func sendYellowPressed(_ sender: AnyObject) {
        MuzomaMPService.sendColor("yellow")
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if( UIScreen.screens.count > 1 ) {
            
            //find the second screen (the 'as! UIScreen' is not needed in Xcode 7 and above)
            let secondScreen = UIScreen.screens[1]
            initializeExternalScreen(secondScreen)
        }

        registerForScreenNotifications()
        
        MuzomaMPService = MuzomaMPServiceManager()
        MuzomaMPService.delegate = self
    }
    
    
    let nc = NotificationCenter.default
    override func viewDidAppear(_ animated: Bool) {
        nc.addObserver(self, selector: #selector(Transport.playerTicked(_:)), name: NSNotification.Name(rawValue: "PlayerTick"), object: nil)

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.nc.removeObserver( self, name: NSNotification.Name(rawValue: "PlayerTick"), object: nil )

        // external screen
        center.removeObserver( self, name: UIScreen.didConnectNotification, object: nil )
        center.removeObserver( self, name: UIScreen.didDisconnectNotification, object: nil )
        
        MuzomaMPService = nil
        return( super.viewDidDisappear(animated) )
    }
    
    @objc func playerTicked(_ notification: Notification) {
        let muzomaDoc=notification.object as! MuzomaDocument?
        let time=muzomaDoc?.getCurrentTime()
        //print( "\(muzomaDoc.getCurrentTime())" )
        MuzomaMPService.sendTime(time!)
        DispatchQueue.main.async(execute: {self.updateDisplayComponents()})
    }
    
    func updateDisplayComponents()
    {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func redTapped(_ sender: AnyObject) {
        self.changeColor(UIColor.red)
        MuzomaMPService.sendColor("red")
    }
    
    @IBAction func yellowTapped(_ sender: AnyObject) {
        self.changeColor(UIColor.yellow)
        MuzomaMPService.sendColor("yellow")
    }
    
    
    func changeColor(_ color : UIColor) {
        UIView.animate(withDuration: 0.2, animations: {
            self.view.backgroundColor = color
        }) 
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    // external view
    var externalPlayerView:ExternalPlayerView! = nil
    
    // Initialize an external screen
    func initializeExternalScreen(_ externalScreen: UIScreen) {
        //print( "Screens \(UIScreen.screens().count)" )
        if( UIScreen.screens.count > 1 ) {
            
            // Create a new window sized to the external screen's bounds
            self.externalWindow = UIWindow(frame: externalScreen.bounds)
            
            // Assign the screen object to the screen property of the new window
            self.externalWindow.screen = externalScreen;
 
            externalPlayerView = ExternalPlayerView.loadFromNib()
            externalPlayerView.frame = self.externalWindow.frame
            externalPlayerView.backgroundColor = UIColor.red
            
            self.externalWindow.addSubview(externalPlayerView)
            
            // Make the window visible
            self.externalWindow.makeKeyAndVisible()
        }
    }
    
    func registerForScreenNotifications(){
        center.addObserver(self, selector: #selector(GroupPlayerViewController.handleScreenDidConnectNotification(_:)), name: UIScreen.didConnectNotification, object: nil)
        
        center.addObserver(self, selector: #selector(GroupPlayerViewController.handleScreenDidDisconnectNotification(_:)), name: UIScreen.didDisconnectNotification, object: nil)
    }
    
    @objc func handleScreenDidConnectNotification(_ aNotification: Notification) {
        //print( "Screen connected!" )
        if let screen = aNotification.object as? UIScreen {
            self.initializeExternalScreen(screen)
        }
    }
    
    @objc func handleScreenDidDisconnectNotification(_ aNotification: Notification) {
        //print( "Screen disconnected!" )
        if self.externalWindow != nil {
            self.externalWindow.isHidden = true
            self.externalWindow = nil
        }
    }
}

extension GroupPlayerViewController : MuzomaMPServiceManagerDelegate {
    
    func connectedDevicesChanged(_ manager: MuzomaMPServiceManager, connectedDevices: [String]) {
        OperationQueue.main.addOperation { () -> Void in
            //self.connectionsLabel.text = "Connections: \(connectedDevices)"
            //print(  "Connections: \(connectedDevices)" )
        }
    }
    
    func timeChanged(_ manager: MuzomaMPServiceManager, timeString: String) {
        //print( "time rx: \(timeString)" )
    }
    
    func resignMaster(_ manager : MuzomaMPServiceManager)
    {
    }
    
    func becomeMaster(_ manager : MuzomaMPServiceManager)
    {
    }
}
