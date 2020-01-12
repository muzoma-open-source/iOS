//
//  KVDownloadURL.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 30/11/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//
// Karaoke version download helper code

import Foundation
import UIKit
import WebKit

class KVDownloadURL : NSObject, URLSessionDownloadDelegate
{
    var url : URL?
    // will be used to do whatever is needed once download is complete
    var yourOwnObject : NSObject?
    let nc = NotificationCenter.default
    
    var _destFolder:URL! = nil
    var _destFileName:String! = nil
    init( yourOwnObject : NSObject, destFolder:URL, destFileName:String )
    {
        self.yourOwnObject = yourOwnObject
        _destFolder = destFolder
        _destFileName = destFileName
    }
    
    //is called once the download is complete
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)
    {
        //copy downloaded data to document directory
        let destinationUrl = _destFolder.appendingPathComponent(_destFileName, isDirectory: false)
        let fsh:FileSystemHelper = _gFSH
        do
        {
            //let contents = try String.init(contentsOfURL: location)
            //print( "Downloaded \(destinationUrl.debugDescription)")
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
            self.nc.post(name: Notification.Name(rawValue: "DownloadedExternalKV"), object: self)
        } catch let error as NSError {
            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
        }
        
        session.invalidateAndCancel()
        _task = nil
        _session = nil
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
        self.nc.post(name: Notification.Name(rawValue: "DownloadingExternalKV"), object: self)
        //print( "totalBytesWritten: \(totalBytesWritten) totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)" )
    }
    
    // if there is an error during download this will be called
    var _error: NSError? = nil
    @objc func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {
        //print( "didComplete: \(task.debugDescription)" )
        _error = error != nil ? error! as NSError : nil
        if(error != nil)
        {
            self.nc.post(name: Notification.Name(rawValue: "ErrorDownloadingExternalKV"), object: self)
        }
        session.invalidateAndCancel()
        _task = nil
        _session = nil
    }
    
    var _task:URLSessionDownloadTask! = nil
    var _session:Foundation.URLSession! = nil
    
    //method to be called to download
    func download(_ url: URL)
    {
        _error = nil
        _bytesWritten = 0
        _totalBytesWritten = 0
        _totalBytesExpectedToWrite = 0
        self.url = url
        
        let sessionConfig = URLSessionConfiguration.background(withIdentifier: url.absoluteString)
        _session = Foundation.URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        _task = _session.downloadTask(with: url)
        _task.resume()
    }
    
    func cancel()
    {
        _task?.cancel()
    }
}
