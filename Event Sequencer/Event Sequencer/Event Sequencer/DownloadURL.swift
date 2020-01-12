//
//  DownloadURL.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 30/11/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//

import Foundation
import UIKit
import WebKit

class Downloader : NSObject, URLSessionDownloadDelegate
{
    var url : URL?
    // will be used to do whatever is needed once download is complete
    var yourOwnObject : NSObject?
    let nc = NotificationCenter.default
    
    init( yourOwnObject : NSObject )
    {
        self.yourOwnObject = yourOwnObject
    }
    
    //is called once the download is complete
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)
    {
        //copy downloaded data to your documents directory with same names as source file
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let destinationUrl = documentsUrl!.appendingPathComponent(url!.lastPathComponent)
        
        let fsh:FileSystemHelper = _gFSH
        do
        {
            if( fsh.fileExists(destinationUrl) )
            {
                do
                {
                    try fsh.removeItem(at: destinationUrl)
                    Logger.log("\(#function)  \(#file) Deleted \(destinationUrl.absoluteString)")
                } catch let error as NSError {
                    Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                }
            }
            
            try fsh.moveItem( at: location, to: destinationUrl )
            self.nc.post(name: Notification.Name(rawValue: "DownloadedExternal"), object: self)
            
            DispatchQueue.main.async(execute: {
                let keyWind = UIApplication.shared.keyWindow
                let currentVC=keyWind?.visibleViewController
                
                //print( "Process URL, visible VC \(keyWind.visibleViewController?.description)")
                
                if( currentVC != nil )
                {
                    let alert = UIAlertController(title: "Import document", message: "Import downloaded document \(self.url!.lastPathComponent)", preferredStyle: UIAlertController.Style.alert)
                    
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
                        //print("load file Yes")
                        DispatchQueue.main.async(execute: {
                            
                            // unzip
                            if( destinationUrl.absoluteString.contains(".set.muz") || destinationUrl.absoluteString.contains(".set_.muz") )
                            {
                                _ = fsh.getMuzSetFromZip(destinationUrl, callingVC: alert)
                            }
                            else if( destinationUrl.absoluteString.contains(".muz") )
                            {
                                _ = fsh.getMuzDocFromZip(destinationUrl, callingVC: alert)
                                
                            }
                            
                            // refresh docs view
                            if( currentVC != nil && currentVC!.navigationController != nil )
                            {
                                let viewControllers: [UIViewController] = currentVC!.navigationController!.viewControllers as [UIViewController]
                                for vcCnt in (0..<viewControllers.count)
                                {
                                    // mark the top view as dirty
                                    if( viewControllers[vcCnt] is DocumentsCollectionViewController )
                                    {
                                        //globalDocumentMapper takes care of the new doc
                                        let targetVC = viewControllers[vcCnt] as! DocumentsCollectionViewController
                                        //targetVC.viewDirty = true
                                        targetVC.refreshDocs()
                                        break;
                                    }
                                }
                            }
                            
                            if( fsh.fileExists(destinationUrl) )
                            {
                                do
                                {
                                    try fsh.removeItem(at: destinationUrl)
                                    Logger.log("\(#function)  \(#file) Deleted \(destinationUrl.absoluteString)")
                                } catch let error as NSError {
                                    Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                                }
                            }
                        })
                    }))
                    
                    alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action: UIAlertAction!) in
                        if( fsh.fileExists(destinationUrl) )
                        {
                            do
                            {
                                try fsh.removeItem(at: destinationUrl)
                                Logger.log("\(#function)  \(#file) Deleted \(destinationUrl.absoluteString)")
                            } catch let error as NSError {
                                Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                            }
                        }
                    }))
                    
                    alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                    currentVC!.present(alert, animated: true, completion: {})
                }
            })
        } catch let error as NSError {
            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
        }
        
        session.finishTasksAndInvalidate()
    }
    
    //this is to track progress
    var _bytesWritten: Int64 = 0
    var _totalBytesWritten: Int64 = 0
    var _totalBytesExpectedToWrite: Int64 = 0
    
    @objc func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    {
        self._bytesWritten = bytesWritten
        self._totalBytesWritten = totalBytesWritten
        self._totalBytesExpectedToWrite = totalBytesExpectedToWrite
        self.nc.post(name: Notification.Name(rawValue: "DownloadingExternal"), object: self)
        //print( "totalBytesWritten: \(totalBytesWritten) totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)" )
    }
    
    // if there is an error during download this will be called
    var _error: NSError? = nil
    @objc func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {
        _error = error as NSError?
        if(error != nil)
        {
            self.nc.post(name: Notification.Name(rawValue: "ErrorDownloadingExternal"), object: self)
            
            let keyWind = UIApplication.shared.keyWindow
            let currentVC=keyWind?.visibleViewController
            if( currentVC != nil )
            {
                //handle the error
                Logger.log("Download completed with error: \(error!.localizedDescription)");
                
                let alert = UIAlertController(title: "Import document", message: "Error downloading \(self.url!.lastPathComponent)", preferredStyle: UIAlertController.Style.alert)
                
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
                    //print("load file Yes")
                }))
                
                alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                currentVC!.present(alert, animated: true, completion: {})
            }
        }
        session.finishTasksAndInvalidate()
    }
    
    //method to be called to download
    func download(_ url: URL)
    {
        _error = nil
        _bytesWritten = 0
        _totalBytesWritten = 0
        _totalBytesExpectedToWrite = 0
        self.url = url
        
        //download identifier can be customized. I used the "ulr.absoluteString"
        let sessionConfig = URLSessionConfiguration.background(withIdentifier: url.absoluteString)
        let session = Foundation.URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        let task = session.downloadTask(with: url)
        
        task.resume()
    }
}
