//
//  MuzomaMultiPeerService.swift
//  Muzoma Limited
//
//  Created by Matthew Hopkins on 11/05/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//
//  Code to handle the multi-user band play aspect of Muzoma - uses Apple's Multi Peer libraries
//  Used in conjunction with GroupPlayerViewController
//

import Foundation
import MultipeerConnectivity
import Security

protocol MuzomaMPServiceManagerDelegate {
    func connectedDevicesChanged(_ manager : MuzomaMPServiceManager, connectedDevices: [String])
    func timeChanged(_ manager : MuzomaMPServiceManager, timeString: String)
    func resignMaster(_ manager : MuzomaMPServiceManager)
    func becomeMaster(_ manager : MuzomaMPServiceManager)
}

class MuzomaMPServiceManager : NSObject {
    
    fileprivate var MuzomaMPServiceType = ("Muz" + (UserDefaults.standard.object(forKey: "bandShareId_preference") as! String))
    fileprivate let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    fileprivate var serviceAdvertiser:MCNearbyServiceAdvertiser! = nil
    fileprivate var serviceBrowser:MCNearbyServiceBrowser! = nil
    fileprivate let nc:NotificationCenter = NotificationCenter.default
    var _isMaster = false
    
    var delegate : MuzomaMPServiceManagerDelegate?
    
    override init() {
        //let serviceTrucd = MuzomaMPServiceType.substring(to: MuzomaMPServiceType.index(MuzomaMPServiceType.startIndex, offsetBy: min(MuzomaMPServiceType.count,16)))
        let serviceTrucd = MuzomaMPServiceType[..<MuzomaMPServiceType.index(MuzomaMPServiceType.startIndex, offsetBy: min(MuzomaMPServiceType.count,16))]
        let alphaNumericCharacterSet = CharacterSet( charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-" )
        let serviceFilter = serviceTrucd.filter {
            return  String($0).rangeOfCharacter(from: alphaNumericCharacterSet) != nil
        }
        let filteredService = String(serviceFilter)
        
        Logger.log(  "%@\(self.myPeerId), service type: \(filteredService)")
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: filteredService)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: filteredService)
        
        super.init()
        
        self.serviceAdvertiser.delegate = self
        self.serviceAdvertiser.startAdvertisingPeer()
        
        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
        self.serviceAdvertiser = nil
        self.serviceBrowser = nil
    }
    
    lazy var session: MCSession = {
        let session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: .none /* MCEncryptionPreference.Required*/)
        session.delegate = self
        return session
    }()
    
    
    var _transport:Transport? = nil
    var _lastDocSendTime:Date! = nil
    var _lastDocSendUId:String! = nil
    
    func sendDoc( _ muzomaDoc:MuzomaDocument! )
    {
        self.delegate?.becomeMaster(self)
        _isMaster = true
        
        if( muzomaDoc != nil )
        {
            if( !muzomaDoc._isSlaveForBandPlay ) // dont send if we are the slaved version
            {
                if( (muzomaDoc._lastUpdateDate != _lastDocSendTime &&
                    muzomaDoc._uid == _lastDocSendUId) ||
                    muzomaDoc._uid != _lastDocSendUId )
                {
                    session.connectedPeers.forEach{ (peer) in
                        Logger.log(  "sending doc to " + peer.displayName )
                        self.session.sendResource( at: muzomaDoc.getDocumentURL()!, withName: "CurrentMuzomaDocument", toPeer: peer, withCompletionHandler: self.sentDoc as (Error?) -> Void )
                    }
                }
                
                _lastDocSendTime = muzomaDoc._lastUpdateDate
                _lastDocSendUId = muzomaDoc._uid
            }
        }
    }
    
    func sentDoc( _ error : Error?)
    {
        Logger.log( "%@\(self.myPeerId) Sent doc \(String(describing: error))" )
    }
    
    func sendColor(_ colorName : String) {
        //Logger.log( "%@\(self.myPeerId)", "sendColor: \(colorName)")
        
        if session.connectedPeers.count > 0 {
            //var error : NSError?
            do
            {
                try self.session.send(colorName.data(using: String.Encoding.utf8, allowLossyConversion: false)!, toPeers: session.connectedPeers, with: MCSessionSendDataMode.reliable)
            }
            catch{
                
            }
        }
    }
    
    func sendTime(_ time : TimeInterval)
    {
        Logger.log(  "%@\(self.myPeerId) sendTime: \(time)")
        if session.connectedPeers.count > 0 {
            //var error : NSError?
            do
            {
                let data = "tm:\(time)".data(using: String.Encoding.utf8)
                try self.session.send( data!, toPeers: session.connectedPeers, with: MCSessionSendDataMode.unreliable)
            }
            catch{
                
            }
        }
    }
}

extension MuzomaMPServiceManager : MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        Logger.log(  "%@\(self.myPeerId) didNotStartAdvertisingPeer: \(error)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void)
    {
        //Logger.log(  "%@\(self.myPeerId)", "didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, self.session)
    }
}

extension MuzomaMPServiceManager : MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        //Logger.log(  "%@\(self.myPeerId)", "didNotStartBrowsingForPeers: \(error)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        //Logger.log(  "%@\(self.myPeerId)", "foundPeer: \(peerID)")
        //Logger.log(  "%@\(self.myPeerId)", "invitePeer: \(peerID)")
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        //Logger.log(  "%@\(self.myPeerId)", "lostPeer: \(peerID)")
    }
}

extension MCSessionState {
    
    func stringValue() -> String {
        var ret = "Unknown"
        
        switch(self) {
        case .notConnected:
            ret = "NotConnected"
            break;
        case .connecting:
            ret = "Connecting"
            break;
        case .connected:
            ret  = "Connected"
            break;
            
            /*default:
             break;*/
        }
        return( ret )
    }
}

extension MuzomaMPServiceManager : MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        //Logger.log(  "%@\(self.myPeerId)", "peer \(peerID) didChangeState: \(state.stringValue())")
        self.delegate?.connectedDevicesChanged(self, connectedDevices: session.connectedPeers.map({$0.displayName}))
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        //Logger.log(  "%@\(self.myPeerId)", "didReceiveData: \(data.count) bytes")
        
        let str = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String

        if( str.starts(with: "tm:") )
        {
            //let noTM = str.substring(from: str.index(str.startIndex, offsetBy: 3))
            let noTM = String(str[str.index(str.startIndex, offsetBy: 3)...])
            self.delegate?.timeChanged(self, timeString: noTM)
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        //Logger.log(  "%@\(self.myPeerId)", "didReceiveStream")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        if( resourceName == "CurrentMuzomaDocument" ) // we are being controlled so resign the master
        {
            self.delegate?.resignMaster(self)
            _isMaster = false
        }
        //Logger.log(  "%@\(self.myPeerId)", "didStartReceivingResourceWithName from peer \(peerID) \(resourceName) \(progress)")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        if( error == nil )
        {
            //Logger.log(  "%@\(self.myPeerId)", "didFinishReceivingResourceWithName from peer \(peerID) \(resourceName) \(localURL)")
            let fs = _gFSH
            
            if( resourceName == "CurrentMuzomaDocument" )
            {
                let fileData = try? Data.init(contentsOf: localURL!)
                if( fileData != nil )
                {
                    let outputUrl = fs.getDocumentFolderURL()?.appendingPathComponent("resourceName")
                    if( fs.fileExists(outputUrl) )
                    {
                        do
                        {
                            try fs.removeItem(at: outputUrl!)
                            Logger.log("\(#function)  \(#file) Deleted \(outputUrl!.absoluteString)")
                        }
                        catch let error as NSError {
                            Logger.log("\(#function)  \(#file)  \(error.localizedDescription)")
                        }
                    }
                    
                    if(( (try? fileData?.write( to: outputUrl!, options: [.atomic])) != nil ))
                    {
                        DispatchQueue.main.async(execute: {
                            let muzDoc = MuzomaDocument()
                            muzDoc.deserialize(outputUrl!)
                            //Logger.log(  muzDoc._title )
                            muzDoc._isSlaveForBandPlay = true
                            let vc =  self._transport?.vc
                            
                            // we are being told to slave, so stop play of existing doc
                            Transport.getCurrentDoc()?.stop()
                            
                            if( muzDoc._uid == Transport.getCurrentDoc()?._uid &&
                                muzDoc._lastUpdateDate == Transport.getCurrentDoc()?._lastUpdateDate &&
                                vc is PlayerDocumentViewController )
                            {
                                //Logger.log(  "\(self.myPeerId) already loaded this doc!" )
                            }
                            else
                            {
                                muzDoc.prepareForSlaving()
                                // go to player
                                let playerDocController = vc?.storyboard?.instantiateViewController(withIdentifier: "PlayerDocumentViewController") as? PlayerDocumentViewController
                                if( playerDocController != nil )
                                {
                                    playerDocController!.muzomaDoc = muzDoc
                                    vc!.navigationController?.popToRootViewController(animated: true)
                                    vc!.navigationController?.pushViewController(playerDocController!, animated: true)
                                }
                            }
                        })
                    }
                }
            }
        }
        else
        {
            //Logger.log(  "%@\(self.myPeerId)", error )
        }
    }
}



