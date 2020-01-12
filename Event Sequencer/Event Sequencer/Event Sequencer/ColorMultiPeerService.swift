//
//  MuzomaMultiPeerService.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 11/05/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//

import Foundation
import MultipeerConnectivity

//
//  ColorServiceManager.swift
//  ConnectedColors
//
//  Created by Ralf Ebert on 28/04/15.
//  Copyright (c) 2015 Ralf Ebert. All rights reserved.
//

import Foundation
import MultipeerConnectivity

protocol ColorServiceManagerDelegate {
    
    func connectedDevicesChanged(manager : ColorServiceManager, connectedDevices: [String])
    func colorChanged(manager : ColorServiceManager, colorString: String)
    
}

class ColorServiceManager : NSObject {
    
    private let ColorServiceType = "example-color"
    private let myPeerId = MCPeerID(displayName: UIDevice.currentDevice().name)
    private let serviceAdvertiser : MCNearbyServiceAdvertiser
    private let serviceBrowser : MCNearbyServiceBrowser
    var delegate : ColorServiceManagerDelegate?
    
    override init() {
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: ColorServiceType)
        
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: ColorServiceType)
        
        super.init()
        
        self.serviceAdvertiser.delegate = self
        self.serviceAdvertiser.startAdvertisingPeer()
        
        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
    lazy var session: MCSession = {
        let session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.Required)
        session.delegate = self
        return session
    }()
    
    func sendColor(colorName : String) {
        print( "%@", "sendColor: \(colorName)")
        
        if session.connectedPeers.count > 0 {
            //var error : NSError?
            do
            {
                try self.session.sendData(colorName.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, toPeers: session.connectedPeers, withMode: MCSessionSendDataMode.Reliable)
            }
            catch{
                
            }
        }
        
    }
}

extension ColorServiceManager : MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: NSError) {
        print( "%@", "didNotStartAdvertisingPeer: \(error)")
    }
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: NSData?, invitationHandler: (Bool, MCSession) -> Void)
    {
        print( "%@", "didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, self.session)
        
    }
}

extension ColorServiceManager : MCNearbyServiceBrowserDelegate {
    
    func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {
        print( "%@", "didNotStartBrowsingForPeers: \(error)")
    }
    
    func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print( "%@", "foundPeer: \(peerID)")
        print( "%@", "invitePeer: \(peerID)")
        browser.invitePeer(peerID, toSession: self.session, withContext: nil, timeout: 10)
    }
    
    func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print( "%@", "lostPeer: \(peerID)")
    }
}

extension MCSessionState {
    
    func stringValue() -> String {
        var ret = "Unknown"
        
        switch(self) {
            case .NotConnected:
                ret = "NotConnected"
                break;
            case .Connecting:
                ret = "Connecting"
                break;
            case .Connected:
                ret  = "Connected"
            break;
            
            /*default:
            break;*/
        }
        return( ret )
    }
}

extension ColorServiceManager : MCSessionDelegate {
    
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        print( "%@", "peer \(peerID) didChangeState: \(state.stringValue())")
        self.delegate?.connectedDevicesChanged(self, connectedDevices: session.connectedPeers.map({$0.displayName}))
    }
    
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        print( "%@", "didReceiveData: \(data.length) bytes")
        let str = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
        self.delegate?.colorChanged(self, colorString: str)
    }
    
    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print( "%@", "didReceiveStream")
    }
    
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
        print( "%@", "didFinishReceivingResourceWithName")
    }
    
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
        print( "%@", "didStartReceivingResourceWithName")
    }
}



