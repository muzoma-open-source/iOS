//
//  FileSystemHelper.swift
//  Event Sequencer
//
//  Created by Matthew Hopkins on 23/11/2015.
//  Copyright © 2015 Muzoma.com. All rights reserved.
//

import Foundation
import Zip
import UIKit
import AEXML

class FileSystemHelper : FileManager {
    
    static var ignoreInboxCleanupSweep = true
    
    func removeItemAndLog(at url: URL!)
    {
        if( url != nil )
        {
            if( fileExists(url!) )
            {
                do
                {
                    try removeItem(at: url!)
                    Logger.log("\(#function)  \(#file) Deleted \(url!.absoluteString)")
                }
                catch let error as NSError {
                    Logger.log("\(#function)  \(#file)  \(error.localizedDescription)")
                }
            }
        }
    }
    
    func loadMuzomaDoc(_ docFolder:String, docFile:String) -> MuzomaDocument?
    {
        var url = getDocumentFolderURL()
        url = url?.appendingPathComponent(docFolder)
        url = url?.appendingPathComponent(docFile)
        let doc = loadMuzomaDoc(url!)
        
        return( doc )
    }
    
    func loadMuzomaDoc( _ loadFileURL:URL ) -> MuzomaDocument?
    {
        var ret:MuzomaDocument? = nil //MuzomaDocument()
        let newDoc = MuzomaDocument()
        newDoc.deserialize(loadFileURL)
        ret=newDoc
        
        return ret
    }
    
    func loadMuzomaDocInFolder( _ loadFolderURL:URL ) -> MuzomaDocument?
    {
        var ret:MuzomaDocument? = nil //MuzomaDocument()
        
        do
        {
            let files = try self.contentsOfDirectory(at: loadFolderURL,
                                                     includingPropertiesForKeys: [URLResourceKey.isDirectoryKey, URLResourceKey.isReadableKey, URLResourceKey.contentModificationDateKey],
                                                     options: FileManager.DirectoryEnumerationOptions()) as [URL]
            
            for file in files {
                //print( "Docs file : " + file.absoluteString)
                let fileName=file.lastPathComponent
                
                if( fileName.hasSuffix( ".muz.xml") )
                {
                    //print(fileName)
                    let newDoc = MuzomaDocument()
                    newDoc.deserialize(file)
                    
                    if( newDoc.isValid() )
                    {
                        ret = newDoc
                    }
                    break;
                }
            }
        }
        catch
        {
            // error
        }
        
        return ret
    }
    
    func docFolderNeedsMoving( _ newDoc:MuzomaDocument! ) -> Bool
    {
        var ret = false
        let file = newDoc.diskFolderFilePath
        let fileDirectoryURL = file?.deletingLastPathComponent()
        
        // see if we need to move the whole directory to align it with the document's name
        let folder = newDoc.getCorrectDocumentFolderPathURL()
        
        if( !(fileDirectoryURL?.sameDocumentPathAs(folder))! ) // folder is the correct destination
        {
            // need to move to the correct folder
            ret = true
        }
        
        return( ret )
    }
    
    // corrects the doc's location - assumes no other existing folder
    func correctDocsLocation( _ newDoc:MuzomaDocument! )  -> Bool
    {
        var ret = false
        
        let file = newDoc.diskFolderFilePath
        let fileDirectoryURL = file?.deletingLastPathComponent()
        
        // see if we need to move the whole directory to align it with the document's name
        let folder = newDoc.getCorrectDocumentFolderPathURL()
        
        if( !(fileDirectoryURL?.sameDocumentPathAs(folder))! ) // folder is the correct destination
        {
            // move to the correct folder
            do
            {
                try self.removeItem(at: folder!)
                Logger.log("\(#function)  \(#file) Deleted \(folder!.absoluteString)")
            } catch let error as NSError {
                Logger.log("\(#function) \(#file) \(error.localizedDescription)")
            }
            
            do
            {
                try self.moveItem(at: fileDirectoryURL!, to: folder!)
            } catch let error as NSError {
                Logger.log("\(#function) \(#file) \(error.localizedDescription)")
            }
            
            newDoc.diskFolderFilePath = nil
            _ = self.saveMuzomaDocLocally(newDoc)
            ret = true
        }
        
        return( ret )
    }
    
    fileprivate func _initGetDocumentFolderURL() -> URL?
    {
        var ret:URL? = nil
        /*
         //let fileManager = NSFileManager.defaultManager()
         let urls = self.urls(for: .documentDirectory, in: .userDomainMask)
         if let documentDirectoryURL: URL = urls.first {
         ret = documentDirectoryURL
         }*/
        
        if let documentsPathURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            //This gives you the URL of the path
            ret = documentsPathURL
        }
        return( ret )
    }
    
    fileprivate static let _vgetDocumentFolderURL = FileSystemHelper()._initGetDocumentFolderURL()
    
    func getDocumentFolderURL() -> URL?
    {
        return( FileSystemHelper._vgetDocumentFolderURL )
    }
    
    func getMappingFolderURL() -> URL?
    {
        var ret:URL? = nil
        ret = getDocumentFolderURL()?.appendingPathComponent("Mappings")
        if( !self.directoryExists( ret ) )
        {
            _ = self.ensureFolderExists(ret)
        }
        
        return( ret )
    }
    
    fileprivate func _initGetSetsFolderURL() -> URL?
    {
        var ret:URL? = nil
        ret = getDocumentFolderURL()!.appendingPathComponent("Sets")
        if( !self.directoryExists( ret ) )
        {
            _ = self.ensureFolderExists(ret)
        }
        
        return( ret )
    }
    
    static let _vgetSetsFolderURL = FileSystemHelper()._initGetSetsFolderURL()
    
    func getSetsFolderURL() -> URL?
    {
        return( FileSystemHelper._vgetSetsFolderURL )
    }
    
    func ensureFolderExists( _ folderURL:URL! ) -> Bool
    {
        var ret:Bool = false
        
        // create the directory if necessary
        do {
            if( !self.directoryExists( folderURL) )
            {
                try self.createDirectory(at: folderURL!, withIntermediateDirectories: true, attributes: nil)
                ret = true
            }
        } catch let error as NSError {
            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
        }
        return ret
    }
    
    func getMuzomaDocs( _ search:String! ) -> [MuzomaDocument]!
    {
        let docs = getMuzomaDocs()
        var ret:[MuzomaDocument]! = [MuzomaDocument]()
        for doc in docs! {
            //print( "Docs file : " + file.absoluteString)
            let keep = search == nil || search.isEmpty || doc.getFileName().localizedCaseInsensitiveContains(search)
            if( keep )
            {
                ret.append(doc)
            }
        }
        
        return( ret )
    }
    
    func getMuzomaDocs( _ index:Int! = nil ) -> [MuzomaDocument]!
    {
        var ret:[MuzomaDocument]! = [MuzomaDocument]()
        
        let docsFolder = getDocumentFolderURL()!
        
        //print( "Docs folder: " + docsFolder.absoluteString)
        do {
            let dirs = try self.contentsOfDirectory(at: docsFolder,
                                                    includingPropertiesForKeys: [URLResourceKey.isDirectoryKey, URLResourceKey.isReadableKey, URLResourceKey.contentModificationDateKey],
                                                    options: FileManager.DirectoryEnumerationOptions()) as [URL]
            for dir in dirs {
                //print( "Docs folder dir: \(dir.absoluteString)" )
                
                if( dir.pathComponents.last == "Sets" )
                {
                } else if( dir.pathComponents.last == "Cymatic" ){
                } else if( dir.pathComponents.last == ".Trash" ){   
                } else if( dir.pathComponents.last == "Inbox" ){
                } else
                {
                    do {
                        var rsrc: AnyObject?
                        try (dir as NSURL).getResourceValue(&rsrc, forKey: URLResourceKey.isDirectoryKey)
                        if let isDirectory = rsrc as? NSNumber {
                            if isDirectory == true {
                                //var error:NSError?
                                let files = try self.contentsOfDirectory(at: dir,
                                                                         includingPropertiesForKeys: [URLResourceKey.isDirectoryKey, URLResourceKey.isReadableKey, URLResourceKey.contentModificationDateKey],
                                                                         options: FileManager.DirectoryEnumerationOptions()) as [URL]
                                //error: &error
                                //enumeratorAtPath(docsFolder.absoluteString)
                                
                                
                                var cnt:Int = 0
                                var gotMuz = false
                                for file in files {
                                    //print( "Docs file : " + file.absoluteString)
                                    let fileName=file.lastPathComponent
                                    
                                    if( fileName.hasSuffix( ".muz.xml") )
                                    {
                                        if( index == nil || index==cnt )
                                        {
                                            //print(fileName)
                                            //Logger.log("Loading \(fileName) ...")
                                            let newDoc = MuzomaDocument()
                                            //newDoc.deserialize(file)
                                            newDoc.loadPlaceholder(file)
                                            Logger.log("Loaded \(fileName) ...")
                                            
                                            if( newDoc.isValid() )
                                            {
                                                ret.append(newDoc)
                                                cnt += 1
                                                gotMuz = true
                                            }else
                                            {
                                                //print( "attempt to load invalid doc \(fileName)")
                                                Logger.log("\(#function)  \(#file) 1 bad file detected \(file.absoluteString)")
                                                //try self.moveItem(at: file, to: file.appendingPathExtension("bad"))
                                            }
                                            //print(file.absoluteString)
                                        }
                                        break;
                                    }
                                }
                                
                                // no muz file found in folder
                                if( !gotMuz )
                                {
                                    // clean up

                                        //print( "Delete \(dir.absoluteString)" )
                                        if( dir.lastPathComponent != "_log" && dir.lastPathComponent != "Mappings" && dir.lastPathComponent != "Cymatic" )
                                        {
                                            Logger.log("\(#function)  \(#file) bad folder detected \(dir.absoluteString)")
                                            //try self.removeItem(at: dir)
                                        }
                                }
                            }
                            else // misplaced file!
                            {
                                // clean up
                                    //print( "Delete \(dir.absoluteString)" )
                                    let delFile = dir.absoluteString
                                    if( !delFile.contains("Placeholder") && !delFile.contains("mapping.xml") && !delFile.contains("ControlSettings.xml"))
                                    {
                                        Logger.log("\(#function)  \(#file) 2 bad file detected \(delFile)")
                                        //try self.removeItem(at: dir)
                                    }
                            }
                        }
                    } catch let error as NSError {
                        Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                    }
                }
            }
        } catch let error as NSError {
            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
        }
        
        return( ret )
    }
    
    
    func numberOfMuzomaDocumentsLocally() -> Int {
        var ret:Int = 0
        
        let docsFolder = getDocumentFolderURL()!
        
        //print( "Docs folder: " + docsFolder.absoluteString)
        do{
            let dirs = try self.contentsOfDirectory(at: docsFolder,
                                                    includingPropertiesForKeys: [URLResourceKey.isDirectoryKey, URLResourceKey.isReadableKey, URLResourceKey.contentModificationDateKey],
                                                    options: FileManager.DirectoryEnumerationOptions()) as [URL]
            for dir in dirs {
                do {
                    var rsrc: AnyObject?
                    try (dir as NSURL).getResourceValue(&rsrc, forKey: URLResourceKey.isDirectoryKey)
                    if let isDirectory = rsrc as? NSNumber {
                        if isDirectory == true {
                            //var error:NSError?
                            let files = try self.contentsOfDirectory(at: dir,
                                                                     includingPropertiesForKeys: [URLResourceKey.isDirectoryKey, URLResourceKey.isReadableKey, URLResourceKey.contentModificationDateKey],
                                                                     options: FileManager.DirectoryEnumerationOptions()) as [URL]
                            //error: &error
                            //enumeratorAtPath(docsFolder.absoluteString)
                            
                            
                            for file in files {
                                let fileName=file.lastPathComponent
                                
                                if( fileName.hasSuffix( ".muz.xml") )
                                {
                                    ret += 1
                                    //print(fileName)
                                    //print(file.absoluteString)
                                    //print(file.lastPathComponent)
                                }
                            }
                        }
                    }
                } catch let error as NSError {
                    Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                }
            }
        } catch let error as NSError {
            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
        }
        
        return( ret )
    }
    
    
    func deleteMuzPackage( _ doc:MuzomaDocument! ) -> Bool {
        var ret:Bool = false
        
        if( doc != nil ){
            do{
                let fileURL=doc.getDocumentFolderPathURL()
                try self.removeItem(at: fileURL!)
                Logger.log("\(#function)  \(#file) Deleted \(fileURL!.absoluteString)")
                ret = true
            } catch let error as NSError {
                Logger.log("\(#function) \(#file) \(error.localizedDescription)")
            }
        }
        
        return ret
    }
    
    func deleteDoc( _ doc:MuzomaDocument! ) -> Bool {
        var ret:Bool = false
        
        if( doc != nil ){
            do{
                let fileURL=doc.getDocumentURL()
                try self.removeItem(at: fileURL!)
                Logger.log("\(#function)  \(#file) Deleted \(fileURL!.absoluteString)")
                ret = true
            } catch let error as NSError {
                Logger.log("\(#function) \(#file) \(error.localizedDescription)")
            }
        }
        
        return ret
    }
    
    func saveMuzomaDocLocally( _ doc:MuzomaDocument!, warnOnOverwrite:Bool = false ) -> Bool {
        var ret:Bool = false
        var dirExists = false
        
        if( doc != nil && !doc._isPlaceholder ){
            doc._lastUpdateDate = Date()
            let docXML = doc.serialize()
            
            do{
                let folderURL = doc.getDocumentFolderPathURL()
                
                if( !self.directoryExists(folderURL) )
                {
                    //print("Saving to \(folderURL)" )
                    // create the directory
                    do {
                        try self.createDirectory(at: folderURL!, withIntermediateDirectories: true, attributes: nil)
                    } catch let error as NSError {
                        Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                    }
                }
                else
                {
                    dirExists = true
                }
                
                let fileURL=doc.getDocumentURL()
                
                //print( "saving \(fileURL?.absoluteString)" )
                if( warnOnOverwrite && (dirExists || self.fileExists(fileURL)) )
                {
                    let alert = UIAlertController(title: "Overwrite", message: "Do you wish to overwrite the existing Muzoma file?", preferredStyle: UIAlertController.Style.alert)
                    
                    alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                        //print("overwrite file Yes")
                        do{
                            try docXML.write(to: fileURL!, atomically: true, encoding: String.Encoding.utf8)
                            globalDocumentMapper.addNewDoc(doc)
                            NotificationCenter.default.post(name: Notification.Name(rawValue: "MuzomaDocWritten"), object: self)
                        } catch let error as NSError {
                            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                        }
                    }))
                    
                    alert.addAction(UIAlertAction(title: "No", style: .default, handler: { (action: UIAlertAction!) in
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "MuzomaDocDontOverwrite"), object: self)
                    }))
                    
                    alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                    let vc =  UIApplication.shared.keyWindow?.rootViewController
                    vc!.present(alert, animated: true, completion: nil)
                }
                else
                {
                    try docXML.write(to: fileURL!, atomically: true, encoding: String.Encoding.utf8)
                    globalDocumentMapper.addNewDoc(doc)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "MuzomaDocWritten"), object: self)
                    ret = true
                }
            } catch let error as NSError {
                Logger.log("\(#function) \(#file) \(error.localizedDescription)")
            }
        }
        
        return ret
    }
    
    func duplicateMuzDoc( _ sourceDoc:MuzomaDocument!, dummyNewLocationDoc:MuzomaDocument! ) -> MuzomaDocument?
    {
        let srcFolder = sourceDoc.getDocumentFolderPathURL()
        let destFolder = dummyNewLocationDoc.getDocumentFolderPathURL()
        
        copyDirectory( srcFolder, destFolder: destFolder )
        
        // rename the actual document
        let destSrcFileName = sourceDoc.getDocumentURL()?.lastPathComponent
        let destSrcURL = destFolder?.appendingPathComponent(destSrcFileName!)
        let destURL = dummyNewLocationDoc.getDocumentURL()
        //print( "rename  \(destSrcURL) to \(destURL)")
        do{ try self.moveItem( at: destSrcURL!, to: destURL!) } catch let error as NSError {
            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
        }
        
        let newDoc = self.loadMuzomaDoc(destURL!)
        
        return( newDoc )
    }
    
    func moveMuzDoc( _ sourceDoc:MuzomaDocument!, dummyNewLocationDoc:MuzomaDocument! ) -> MuzomaDocument?
    {
        let srcFolder = sourceDoc.getDocumentFolderPathURL()
        let destFolder = dummyNewLocationDoc.getDocumentFolderPathURL()
        
        do{ try self.moveItem(at: srcFolder!, to: destFolder!) }  catch let error as NSError {
            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
        }
        
        // rename the actual document
        let destSrcFileName = sourceDoc.getDocumentURL()?.lastPathComponent
        let destSrcURL = destFolder?.appendingPathComponent(destSrcFileName!)
        let destURL = dummyNewLocationDoc.getDocumentURL()
        //print( "rename  \(destSrcURL) to \(destURL)")
        do{ try self.moveItem( at: destSrcURL!, to: destURL!) }  catch let error as NSError {
            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
        }
        
        let newDoc = self.loadMuzomaDoc(destURL!)
        
        return( newDoc )
    }
    
    
    func duplicateMuzSetDoc( _ sourceDoc:MuzomaSetDocument!, dummyNewLocationDoc:MuzomaSetDocument! ) -> MuzomaSetDocument?
    {
        let srcFolder = sourceDoc.getSetFolderPathURL()
        let destFolder = dummyNewLocationDoc.getSetFolderPathURL()
        
        copyDirectory( srcFolder, destFolder: destFolder )
        
        // rename the actual document
        let destSrcFileName = sourceDoc.getSetURL()?.lastPathComponent
        let destSrcURL = destFolder?.appendingPathComponent(destSrcFileName!)
        let destURL = dummyNewLocationDoc.getSetURL()
        //print( "rename  \(destSrcURL) to \(destURL)")
        do{ try self.moveItem( at: destSrcURL!, to: destURL!) }  catch let error as NSError {
            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
        }
        
        let newDoc = self.loadMuzomaSet(destURL!)
        return( newDoc )
    }
    
    func moveMuzSetDoc( _ sourceDoc:MuzomaSetDocument!, dummyNewLocationDoc:MuzomaSetDocument! ) -> MuzomaSetDocument?
    {
        let srcFolder = sourceDoc.getSetFolderPathURL()
        let destFolder = dummyNewLocationDoc.getSetFolderPathURL()
        
        do{ try self.moveItem(at: srcFolder!, to: destFolder!) }  catch let error as NSError {
            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
        }
        
        // rename the actual document
        let destSrcFileName = sourceDoc.getSetURL()?.lastPathComponent
        let destSrcURL = destFolder?.appendingPathComponent(destSrcFileName!)
        let destURL = dummyNewLocationDoc.getSetURL()
        //print( "rename  \(destSrcURL) to \(destURL)")
        do{ try self.moveItem( at: destSrcURL!, to: destURL!) }  catch let error as NSError {
            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
        }
        
        let newDoc = self.loadMuzomaSet(destURL!)
        return( newDoc )
    }
    
    func getMuzZip( _ doc:MuzomaDocument! ) -> URL?
    {
        var ret:URL? = nil
        _ = saveMuzomaDocLocally( doc )
        let folderURL = doc.getDocumentFolderPathURL()
        let fileName = doc.getMuzZipFileName()
        
        do
        {
            //Zip.init()
            
            let fileURL = folderURL!.appendingPathComponent(fileName)
            if( self.fileExists(fileURL) )
            {
                do
                {
                    try self.removeItem(at: fileURL)
                    Logger.log("\(#function)  \(#file) Deleted \(fileURL.absoluteString)")
                } catch let error as NSError {
                    Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                }
            }
            let files = try self.contentsOfDirectory(at: folderURL!,
                                                     includingPropertiesForKeys: [URLResourceKey.isReadableKey, URLResourceKey.contentModificationDateKey],
                                                     options: FileManager.DirectoryEnumerationOptions()) as [URL]
            
            try Zip.zipFiles( paths: files, zipFilePath: fileURL, password: "Muzoma Ltd", progress: nil )
            ret = fileURL
        } catch let error as NSError {
            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
        }
        
        return(ret)
    }
    
    
    
    func getMuzDocFromZip( _ muzDocURL:URL, callingVC:UIViewController ) -> MuzomaDocument?
    {
        let ret:MuzomaDocument? = nil
        
        do
        {
            //print( "getMuzDocFromZip - input url \(muzDocURL.absoluteString)")
            //Zip.init()
            let zipFileName = muzDocURL.lastPathComponent + ".zip"
            
            let docsURL = self.getDocumentFolderURL()
            let newZipURL = docsURL?.appendingPathComponent(zipFileName, isDirectory: false)
            
            do{
                if( FileSystemHelper().fileExists(newZipURL) )
                {
                    try self.removeItem(at: newZipURL!)
                    Logger.log("\(#function)  \(#file) Deleted \(newZipURL!.absoluteString)")
                }
            } catch let error as NSError {
                Logger.log("\(#function) \(#file) \(error.localizedDescription)")
            }
            
            try self.moveItem(at: muzDocURL, to: newZipURL! )
            let zipDestFolder = newZipURL?.deletingPathExtension().deletingPathExtension()//.appendingPathComponent("", isDirectory: true)
            
            //let zipDestFolder = (newZipURL as NSURL).deletingPathExtension!.deletingPathExtension().appendingPathComponent("", isDirectory: true) // .muz.zip -> base dir
            
            do{
                // remove existing dest folder?
                if( self.directoryExists(zipDestFolder) )
                {
                    let alert = UIAlertController(title: "Overwrite", message: "Do you wish to overwrite the existing Muzoma song \(zipDestFolder!.lastPathComponent)?", preferredStyle: UIAlertController.Style.alert)
                    
                    alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                        //print("overwrite file Yes")
                        do{
                            do
                            {
                                try self.removeItem(at: zipDestFolder!)
                                Logger.log("\(#function)  \(#file) Deleted \(zipDestFolder!.absoluteString)")
                            } catch let error as NSError {
                                Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                            }
                            _ = _gFSH.ensureFolderExists(zipDestFolder)
                            try Zip.unzipFile(newZipURL!, destination: zipDestFolder!, overwrite: true, password: "Muzoma Ltd", progress: nil)
                            let existingURL = globalDocumentMapper.addNewDocAtFolder(zipDestFolder!)
                            
                            if( existingURL != nil ) // already got permission to overwrite
                            {
                                try self.removeItem(at: existingURL!)
                                Logger.log("\(#function)  \(#file) Deleted \(existingURL!.absoluteString)")
                                _ = globalDocumentMapper.addNewDocAtFolder(zipDestFolder!)
                            }
                            
                            // remove the zip
                            try self.removeItem(at: newZipURL!)
                            Logger.log("\(#function)  \(#file) Deleted \(newZipURL!.absoluteString)")
                            
                            let nc = NotificationCenter.default
                            nc.post(name: Notification.Name(rawValue: "RefreshDocsView"), object: nil)
                            
                        } catch let error as NSError {
                            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                        }
                    }))
                    
                    alert.addAction(UIAlertAction(title: "No", style: .default, handler: { (action: UIAlertAction!) in
                        //print("no overwrite")
                        do{
                            // remove the zip
                            try self.removeItem(at: newZipURL!)
                            Logger.log("\(#function)  \(#file) Deleted \(newZipURL!.absoluteString)")
                            
                            let nc = NotificationCenter.default
                            nc.post(name: Notification.Name(rawValue: "RefreshDocsView"), object: nil)
                        } catch let error as NSError {
                            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                        }
                    }))
                    
                    alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                    callingVC.queuePopup(alert, animated: true, completion: nil)
                }
                else
                {
                    do{
                        _ = _gFSH.ensureFolderExists(zipDestFolder)
                        try Zip.unzipFile(newZipURL!, destination: zipDestFolder!, overwrite: true, password: "Muzoma Ltd", progress: nil)
                        let existingURL = globalDocumentMapper.addNewDocAtFolder(zipDestFolder!)
                        
                        if( existingURL != nil ) // ask permission to overwrite
                        {
                            let alert = UIAlertController(title: "Overwrite", message: "Do you wish to overwrite the existing Muzoma song \(existingURL!.lastPathComponent))?", preferredStyle: UIAlertController.Style.alert)
                            
                            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                                //print("overwrite file Yes")
                                do{
                                    do
                                    {
                                        try self.removeItem(at: existingURL!)
                                        Logger.log("\(#function)  \(#file) Deleted \(existingURL!.absoluteString)")
                                    }  catch let error as NSError {
                                        Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                                    }
                                    
                                    _ = globalDocumentMapper.addNewDocAtFolder(zipDestFolder!) //got permission to overwrite
                                    
                                    // remove the zip
                                    try self.removeItem(at: newZipURL!)
                                    Logger.log("\(#function)  \(#file) Deleted \(newZipURL!.absoluteString)")
                                    
                                    let nc = NotificationCenter.default
                                    nc.post(name: Notification.Name(rawValue: "RefreshDocsView"), object: nil)
                                    
                                } catch let error as NSError {
                                    Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                                }
                            }))
                            
                            alert.addAction(UIAlertAction(title: "No", style: .default, handler: { (action: UIAlertAction!) in
                                //print("no overwrite")
                                do{
                                    // remove the zip, and the unzipped version
                                    try self.removeItem(at: newZipURL!)
                                    Logger.log("\(#function)  \(#file) Deleted \(newZipURL!.absoluteString)")
                                    try self.removeItem(at: zipDestFolder!)
                                    Logger.log("\(#function)  \(#file) Deleted \(zipDestFolder!.absoluteString)")
                                    let nc = NotificationCenter.default
                                    nc.post(name: Notification.Name(rawValue: "RefreshDocsView"), object: nil)
                                } catch let error as NSError {
                                    Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                                }
                            }))
                            
                            alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                            callingVC.queuePopup(alert, animated: true, completion: nil)
                        }
                        else
                        {
                            // remove the zip
                            try self.removeItem(at: newZipURL!)
                            Logger.log("\(#function)  \(#file) Deleted \(newZipURL!.absoluteString)")
                            let nc = NotificationCenter.default
                            nc.post(name: Notification.Name(rawValue: "RefreshDocsView"), object: nil)
                        }
                    } catch let error as NSError {
                        Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                    }
                }
            }
        }
        catch let error as NSError {
            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
        }
        
        return ret
    }
    
    // sets
    func loadMuzomaSet(_ setFolder:String, setFile:String) -> MuzomaSetDocument?
    {
        var url = getSetsFolderURL()
        url = url?.appendingPathComponent(setFolder)
        url = url?.appendingPathComponent(setFile)
        let set = loadMuzomaSet(url!)
        
        return( set )
    }
    
    func loadMuzomaSet( _ loadSetURL:URL ) -> MuzomaSetDocument?
    {
        let newSet = MuzomaSetDocument()
        newSet.deserialize(loadSetURL)
        return newSet
    }
    
    func getMuzomaSetDocs( _ search:String! ) -> [MuzomaSetDocument]!
    {
        let docs = getMuzomaSetDocs()
        var ret:[MuzomaSetDocument]! = [MuzomaSetDocument]()
        for doc in docs! {
            //print( "Docs file : " + file.absoluteString)
            let keep = search == nil || search.isEmpty || doc.getFileName().localizedCaseInsensitiveContains(search)
            if( keep )
            {
                ret.append(doc)
            }
        }
        
        return( ret )
    }
    
    
    func getMuzomaSetDocs( _ index:Int! = nil ) -> [MuzomaSetDocument]!
    {
        var ret:[MuzomaSetDocument]! = [MuzomaSetDocument]()
        
        let setsFolder = getSetsFolderURL()!
        
        //print( "Sets folder: " + setsFolder.absoluteString)
        do{
            let dirs = try self.contentsOfDirectory(at: setsFolder,
                                                    includingPropertiesForKeys: [URLResourceKey.isDirectoryKey, URLResourceKey.isReadableKey, URLResourceKey.contentModificationDateKey],
                                                    options: FileManager.DirectoryEnumerationOptions()) as [URL]
            for dir in dirs {
                //print( "Sets folder dir: \(dir.absoluteString)" )
                
                
                if( dir.pathComponents.last == "Inbox" )
                {
                }
                else
                {
                    do {
                        var rsrc: AnyObject?
                        try (dir as NSURL).getResourceValue(&rsrc, forKey: URLResourceKey.isDirectoryKey)
                        if let isDirectory = rsrc as? NSNumber {
                            if isDirectory == true {
                                //var error:NSError?
                                let files = try self.contentsOfDirectory(at: dir,
                                                                         includingPropertiesForKeys: [URLResourceKey.isDirectoryKey, URLResourceKey.isReadableKey, URLResourceKey.contentModificationDateKey],
                                                                         options: FileManager.DirectoryEnumerationOptions()) as [URL]
                                //error: &error
                                //enumeratorAtPath(docsFolder.absoluteString)
                                
                                
                                var cnt:Int = 0
                                var gotSet = false
                                for file in files {
                                    //print( "Sets file : " + file.absoluteString)
                                    let fileName=file.lastPathComponent
                                    
                                    if( fileName.hasSuffix( ".set.xml") )
                                    {
                                        if( index == nil || index==cnt )
                                        {
                                            //print(fileName)
                                            let newDoc = MuzomaSetDocument()
                                            newDoc.deserialize(file)
                                            if( newDoc.isValid() )
                                            {
                                                ret.append(newDoc)
                                                cnt += 1
                                                gotSet = true
                                            }else
                                            {
                                                //print( "attempt to load invalid set \(fileName)")
                                                Logger.log("attempt to load invalid set \(fileName) \(#function)  \(#file)")
                                                //try self.moveItem(at: file, to: file.appendingPathExtension("bad"))
                                            }
                                            //print(file.absoluteString)
                                        }
                                        break;
                                    }
                                }
                                
                                // no set file found in folder
                                if( !gotSet )
                                {
                                    // clean up

                                        //print( "Delete \(dir.absoluteString)" )
                                        //let delFile = dir.absoluteString
                                        //print( "\(#function)  \(#file) Deleting \(delFile)" )
                                        Logger.log("attempt to load invalid set 2 \(dir.absoluteString) \(#function)  \(#file)")
                                        //Logger.log("used to delete \(#function)  \(#file) Deleting \(dir.absoluteString)")
                                        //try self.removeItem(at: dir)
                                        
                                }
                            }
                            else // misplaced file!
                            {
                                // clean up

                                    //print( "Delete \(dir.absoluteString)" )
                                    //let delFile = dir.absoluteString
                                    //print( "\(#function)  \(#file) Deleting \(delFile)" )
                                    Logger.log("attempt to load misplaced file 2 \(dir.absoluteString) \(#function)  \(#file)")
                                    //try self.removeItem(at: dir)
                            }
                        }
                    } catch let error as NSError {
                        Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                    }
                }
            }
            
        } catch let error as NSError {
            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
        }
        
        return( ret )
    }
    
    func deleteMuzSet( _ doc:MuzomaSetDocument! ) -> Bool {
        var ret:Bool = false
        
        if( doc != nil ){
            do{
                let fileURL=doc.getSetFolderPathURL()
                try self.removeItem(at: fileURL!)
                Logger.log("\(#function)  \(#file) Deleted \(fileURL!.absoluteString)")
                ret = true
            } catch let error as NSError {
                Logger.log("\(#function) \(#file) \(error.localizedDescription)")
            }
        }
        
        return ret
    }
    
    func saveMuzomaSetLocally( _ doc:MuzomaSetDocument!, warnOnOverwrite:Bool = false ) -> Bool {
        var ret:Bool = false
        
        var dirExists = false
        
        if( doc != nil ){
            doc._lastUpdateDate = Date()
            let docXML = doc.serialize()
            
            do{
                let folderURL = doc.getSetFolderPathURL()
                
                if( !self.directoryExists(folderURL) )
                {
                    Logger.log( "Saving set to \(String(describing: folderURL))" )
                    // create the directory
                    do {
                        try self.createDirectory(at: folderURL!, withIntermediateDirectories: true, attributes: nil)
                    } catch let error as NSError {
                        Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                    }
                }
                else
                {
                    dirExists = true
                }
                
                let fileURL=doc.getSetURL()
                
                if( warnOnOverwrite && (dirExists || self.fileExists(fileURL)) )
                {
                    let alert = UIAlertController(title: "Overwrite", message: "Do you wish to overwrite the existing set file?", preferredStyle: UIAlertController.Style.alert)
                    
                    alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                        //print("overwrite file Yes")
                        do{
                            try docXML.write(to: fileURL!, atomically: true, encoding: String.Encoding.utf8)
                        } catch let error as NSError {
                            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                        }
                    }))
                    
                    alert.addAction(UIAlertAction(title: "No", style: .default, handler: { (action: UIAlertAction!) in
                        //print("overwrite file No")
                    }))
                    
                    alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                    let vc =  UIApplication.shared.keyWindow?.rootViewController
                    vc!.present(alert, animated: true, completion: nil)
                }
                else
                {
                    try docXML.write(to: fileURL!, atomically: true, encoding: String.Encoding.utf8)
                    ret = true
                }
            } catch let error as NSError {
                Logger.log("\(#function) \(#file) \(error.localizedDescription)")
            }
        }
        
        return ret
    }
    
    func numberOfMuzomaSetDocumentsLocally() -> Int {
        var ret:Int = 0
        
        let setsFolder = getSetsFolderURL()!
        
        //print( "Sets folder: " + setsFolder.absoluteString)
        do{
            let dirs = try self.contentsOfDirectory(at: setsFolder,
                                                    includingPropertiesForKeys: [URLResourceKey.isDirectoryKey, URLResourceKey.isReadableKey, URLResourceKey.contentModificationDateKey],
                                                    options: FileManager.DirectoryEnumerationOptions()) as [URL]
            for dir in dirs {
                do {
                    var rsrc: AnyObject?
                    try (dir as NSURL).getResourceValue(&rsrc, forKey: URLResourceKey.isDirectoryKey)
                    if let isDirectory = rsrc as? NSNumber {
                        if isDirectory == true {
                            //var error:NSError?
                            let files = try self.contentsOfDirectory(at: dir,
                                                                     includingPropertiesForKeys: [URLResourceKey.isDirectoryKey, URLResourceKey.isReadableKey, URLResourceKey.contentModificationDateKey],
                                                                     options: FileManager.DirectoryEnumerationOptions()) as [URL]
                            //error: &error
                            //enumeratorAtPath(docsFolder.absoluteString)
                            
                            
                            for file in files {
                                let fileName=file.lastPathComponent
                                
                                if( fileName.hasSuffix( ".set.xml") )
                                {
                                    ret += 1
                                    //print(fileName)
                                    //print(file.absoluteString)
                                    //print(file.lastPathComponent)
                                }
                            }
                        }
                    }
                } catch let error as NSError {
                    Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                }
            }
        }  catch let error as NSError {
            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
        }
        
        return( ret )
    }
    
    func getMuzSetZip( _ doc:MuzomaSetDocument! ) -> URL?
    {
        var ret:URL? = nil
        
        _ = saveMuzomaSetLocally( doc )
        
        let fileURL = (doc.getSetURL() as NSURL?)?.deletingPathExtension?.deletingPathExtension().appendingPathExtension("set").appendingPathExtension("muz") // .set.xml -> .set.muz
        // target zip
        
        do
        {
            //Zip.init()
            
            if( self.fileExists(fileURL) )
            {
                do
                {
                    try self.removeItem(at: fileURL!)
                    Logger.log("\(#function)  \(#file) Deleted \(fileURL!.absoluteString)")
                } catch let error as NSError {
                    Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                }
            }
            
            let setFileURL = doc.getSetURL()!
            let artworkFileURL = doc.getArtworkURL()!
            
            var files = [setFileURL, artworkFileURL]
            
            // zip every song in the set!
            //let fileHelper = FileSystemHelper()
            for (_, doc) in doc.muzDocs.enumerated() {
                let docZip = self.getMuzZip(doc)
                files.append(docZip!)
            }
            
            try Zip.zipFiles( paths: files, zipFilePath: fileURL!, password: "Muzoma Ltd", progress: nil )
            ret = fileURL
            
            // remove muz files of zip
            for (_, url) in files.enumerated() {
                do
                {
                    if( url.pathExtension == "muz" )
                    {
                        try _gFSH.removeItem(at: url)
                        Logger.log("\(#function)  \(#file) Deleted \(url.absoluteString)")
                    }
                } catch let error as NSError {
                    Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                }
            }
        }
        catch let error as NSError {
            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
        }
        
        return(ret)
    }
    
    
    fileprivate func navigateToSets(_ vc:UIViewController)
    {
        let delay = DispatchTime.now() + Double(Int64(0.1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delay,execute: {
            let setsDocController = vc.storyboard?.instantiateViewController(withIdentifier: "SetsCollectionViewController") as? SetsCollectionViewController
            vc.navigationController?.popToRootViewController(animated: true)
            vc.navigationController?.pushViewController(setsDocController!, animated: true)
        })
    }
    
    func getMuzSetFromZip( _ muzDocURL:URL, callingVC:UIViewController ) -> MuzomaSetDocument?
    {
        let ret:MuzomaSetDocument? = nil
        
        do
        {
            //print( "getMuzDocFromZip - input url \(muzDocURL.absoluteString)")
            //Zip.init()
            let zipFileName = muzDocURL.lastPathComponent + ".zip"
            
            let setsURL = self.getSetsFolderURL()
            let newZipURL = setsURL!.appendingPathComponent(zipFileName, isDirectory: false)
            do{
                if( FileSystemHelper().fileExists(newZipURL) )
                {
                    try self.removeItem(at: newZipURL)
                    Logger.log("\(#function)  \(#file) Deleted \(newZipURL.absoluteString)")
                }
            } catch let error as NSError {
                Logger.log("\(#function) \(#file) \(error.localizedDescription)")
            }
            try self.moveItem(at: muzDocURL, to: newZipURL )
            
            // .set.muz.zip -> .set.xml
            let finalDestFolder = newZipURL.deletingPathExtension().deletingPathExtension()
            
            //let finalDestFolder = ((newZipURL as NSURL).deletingPathExtension! as NSURL).deletingPathExtension!.deletingPathExtension().appendingPathComponent("", isDirectory: true)
            
            //let setFileDest = newZipURL.URLByDeletingPathExtension!.URLByDeletingPathExtension!.URLByAppendingPathComponent(".xml", isDirectory: false)
            
            do{ 
                if( self.directoryExists(finalDestFolder) )
                {
                    let alert = UIAlertController(title: "Overwrite", message: "Do you wish to overwrite the existing Muzoma set? (you will still be prompted to overwrite any songs individually)\n", preferredStyle: UIAlertController.Style.alert)
                    
                    alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                        //print("overwrite file Yes")
                        do{
                            
                            // remove previous set directory
                            do
                            {
                                try self.removeItem(at: finalDestFolder)
                                Logger.log("\(#function)  \(#file) Deleted \(finalDestFolder.absoluteString)")
                            }  catch let error as NSError {
                                Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                            }
                            
                            _ = _gFSH.ensureFolderExists(finalDestFolder)
                            try Zip.unzipFile(newZipURL, destination: finalDestFolder, overwrite: true, password: "Muzoma Ltd", progress: nil)
                            
                            let files = try self.contentsOfDirectory(at: finalDestFolder,
                                                                     includingPropertiesForKeys: [URLResourceKey.isDirectoryKey, URLResourceKey.isReadableKey, URLResourceKey.contentModificationDateKey],
                                                                     options: FileManager.DirectoryEnumerationOptions()) as [URL]
                            
                            var muzFileCnt = 0
                            for file in files {
                                //print( "Set file : " + file.absoluteString)
                                let fileName=file.lastPathComponent
                                
                                if( fileName.hasSuffix( ".muz") ) // muzoma file
                                {
                                    muzFileCnt += 1
                                }
                            }
                            
                            let alertProcessing = UIAlertController(title: "Processing songs", message: "Processing \(muzFileCnt) songs\nThis can take some time and you are told when the import completes", preferredStyle: UIAlertController.Style.alert)
                            
                            alertProcessing.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
                                //print("overwrite file No")
                            }))
                            
                            alertProcessing.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                            //callingVC.presentViewController(alert, animated: true, completion: nil)
                            callingVC.queuePopup(alertProcessing, animated: true, completion: nil)
                            
                            
                            for file in files {
                                //print( "Set file : " + file.absoluteString)
                                let fileName=file.lastPathComponent
                                
                                if( fileName.hasSuffix( ".muz") ) // muzoma file
                                {
                                    _ = self.getMuzDocFromZip( file, callingVC: callingVC )
                                }
                            }
                            
                            let alertProcessed = UIAlertController(title: "Set processed", message: "Processed \(muzFileCnt) songs", preferredStyle: UIAlertController.Style.alert)
                            
                            alertProcessed.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
                                self.navigateToSets( callingVC )
                                let nc = NotificationCenter.default
                                nc.post(name: Notification.Name(rawValue: "RefreshSetsView"), object: nil)
                            }))
                            
                            alertProcessed.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                            //callingVC.presentViewController(alert, animated: true, completion: nil)
                            callingVC.queuePopup(alertProcessed, animated: true, completion: nil)
                            
                            // remove the zip
                            try self.removeItem(at: newZipURL)
                            Logger.log("\(#function)  \(#file) Deleted \(newZipURL.absoluteString)")
                        } catch let error as NSError {
                            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                            let nc = NotificationCenter.default
                            nc.post(name: Notification.Name(rawValue: "RefreshSetsView"), object: nil)
                        }
                    }))
                    
                    alert.addAction(UIAlertAction(title: "No", style: .default, handler: { (action: UIAlertAction!) in
                        //print("no overwrite")
                        do{
                            let nc = NotificationCenter.default
                            nc.post(name: Notification.Name(rawValue: "RefreshSetsView"), object: nil)
                            // remove the zip
                            try self.removeItem(at: newZipURL)
                            Logger.log("\(#function)  \(#file) Deleted \(newZipURL.absoluteString)")
                        } catch let error as NSError {
                            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                            let nc = NotificationCenter.default
                            nc.post(name: Notification.Name(rawValue: "RefreshSetsView"), object: nil)
                        }
                    }))
                    
                    alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                    //callingVC.presentViewController(alert, animated: true, completion: nil)
                    callingVC.queuePopup(alert, animated: true, completion: nil)
                }
                else
                {
                    do{
                        _ = _gFSH.ensureFolderExists(finalDestFolder)
                        try Zip.unzipFile(newZipURL, destination: finalDestFolder, overwrite: true, password: "Muzoma Ltd", progress: nil)
                        
                        let files = try self.contentsOfDirectory(at: finalDestFolder,
                                                                 includingPropertiesForKeys: [URLResourceKey.isDirectoryKey, URLResourceKey.isReadableKey, URLResourceKey.contentModificationDateKey],
                                                                 options: FileManager.DirectoryEnumerationOptions()) as [URL]
                        
                        var muzFileCnt = 0
                        for file in files {
                            //print( "Set file : " + file.absoluteString)
                            let fileName=file.lastPathComponent
                            
                            if( fileName.hasSuffix( ".muz") ) // muzoma file
                            {
                                muzFileCnt += 1
                            }
                        }
                        
                        let alertProcessing = UIAlertController(title: "Processing songs", message: "Processing \(muzFileCnt) songs\nThis can take some time and you are told when the import completes", preferredStyle: UIAlertController.Style.alert)
                        
                        alertProcessing.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
                            //print("overwrite file No")
                        }))
                        
                        alertProcessing.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                        //callingVC.presentViewController(alert, animated: true, completion: nil)
                        callingVC.queuePopup(alertProcessing, animated: true, completion: nil)
                        
                        for file in files {
                            //print( "Set file : " + file.absoluteString)
                            let fileName=file.lastPathComponent
                            
                            if( fileName.hasSuffix(".muz") ) // muzoma file
                            {
                                _ = self.getMuzDocFromZip( file, callingVC: callingVC )
                            }
                        }
                        
                        let alertProcessed = UIAlertController(title: "Set processed", message: "Processed \(muzFileCnt) songs", preferredStyle: UIAlertController.Style.alert)
                        
                        alertProcessed.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
                            self.navigateToSets( callingVC )
                            let nc = NotificationCenter.default
                            nc.post(name: Notification.Name(rawValue: "RefreshSetsView"), object: nil)
                        }))
                        
                        alertProcessed.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                        //callingVC.presentViewController(alert, animated: true, completion: nil)
                        callingVC.queuePopup(alertProcessed, animated: true, completion: nil)
                        
                        // remove the zip
                        try self.removeItem(at: newZipURL)
                        Logger.log("\(#function)  \(#file) Deleted \(newZipURL.absoluteString)")
                    } catch let error as NSError {
                        Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                        let nc = NotificationCenter.default
                        nc.post(name: Notification.Name(rawValue: "RefreshSetsView"), object: nil)
                    }
                }
            }
        } catch let error as NSError {
            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
            let nc = NotificationCenter.default
            nc.post(name: Notification.Name(rawValue: "RefreshSetsView"), object: nil)
        }
        
        return ret
    }
    
    func getControlSettings() -> ControlSettings!
    {
        let settings:ControlSettings! = ControlSettings()

        let settingURL = self.getDocumentFolderURL()?.appendingPathComponent("ControlSettings.xml")
        if( FileSystemHelper().fileExists(settingURL) )
        {
            do
            {
                let docContents = try NSString( contentsOf: settingURL!, encoding: String.Encoding.utf8.rawValue)
                var xmlParserOptions = AEXMLOptions();
                xmlParserOptions.parserSettings.shouldTrimWhitespace = false;
                let xmlDoc = try? AEXMLDocument(xml: docContents as String, encoding: String.Encoding.utf8, options: xmlParserOptions)
                if xmlDoc != nil {
                    settings.deserialize(xmlDoc!)
                }
            } catch let error as NSError {
                Logger.log("\(#function) \(#file) \(error.localizedDescription)")
            }
        }
        
        return( settings )
    }
    
    
    func saveControlSettings( _ settings:ControlSettings! ) -> Bool
    {
        var ret:Bool = false
        
        let settingURL = self.getDocumentFolderURL()?.appendingPathComponent("ControlSettings.xml")
        do{
            let docXML = settings?.serialize().xml
            if( docXML != nil )
            {
                try docXML!.write(to: settingURL!, atomically: true, encoding: String.Encoding.utf8)
                ret = true
            }
        } catch let error as NSError {
            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
        }
        
        return( ret )
    }
    
    
    func getZipForAudioTracks( _ doc:MuzomaDocument! ) -> URL?
    {
        var ret:URL? = nil
        let folderURL = doc.getDocumentFolderPathURL()
        let fileName = doc.getAudioZipFileName()
        
        do
        {
            let fileURL = folderURL?.appendingPathComponent(fileName)
            if( self.fileExists(fileURL) )
            {
                do
                {
                    try self.removeItem(at: fileURL!)
                }  catch let error as NSError {
                    Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                }
            }
            
            var audioFiles:[URL]! = [URL]()
            if( doc.getGuideTrackURL() != nil )
            {
                audioFiles.insert(doc.getGuideTrackURL()!, at: 0)
            }
            
            for file in doc.getBackingTrackURLs()
            {
                if( file != nil )
                {
                    audioFiles.append(file!)
                }
            }
            
            if(audioFiles.count > 0)
            {
                try Zip.zipFiles(paths: audioFiles, zipFilePath: fileURL!, password: nil, progress: { (progress) in
                    
                })
                //try Zip.zipFiles( audioFiles, zipFilePath: fileURL!, password: nil, progress: nil )
                ret = fileURL
            }
        } catch let error as NSError {
            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
        }
        
        return(ret)
    }
    
    
    fileprivate func assignAudioContentURLToDoc( _ doc:MuzomaDocument!, assignAlert:UIAlertController!, audioURL:URL!, track:MuzTrack!, trackIdx:Int )
    {
        //Logger.log("Audio url \(audioURL)")
        
        if( assignAlert != nil )
        {
            let act = UIAlertAction(title: audioURL.lastPathComponent, style: .default, handler: { (action: UIAlertAction!) in
                //print("overwrite file Yes")
                do
                {
                    let newURL = doc.getDocumentFolderPathURL()?.appendingPathComponent(audioURL.lastPathComponent, isDirectory: false)
                    do{
                        if( self.fileExists(newURL) )
                        {
                            try self.removeItem(at: newURL!)
                            Logger.log("\(#function)  \(#file) Deleted \(newURL!.absoluteString)")
                        }
                    } catch let error as NSError {
                        Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                    }
                    try _gFSH.copyItem(at: audioURL, to: newURL!)
                    doc.setDataForTrackEvent(trackIdx, eventIdx: 0, url: newURL!)
                } catch let error as NSError {
                    Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                }
            })
            
            assignAlert.addAction(act)
        }
        else
        {
            do
            {
                let newURL = doc.getDocumentFolderPathURL()?.appendingPathComponent(audioURL.lastPathComponent, isDirectory: false)
                do{
                    if( self.fileExists(newURL) )
                    {
                        try self.removeItem(at: newURL!)
                        Logger.log("\(#function)  \(#file) Deleted \(newURL!.absoluteString)")
                    }
                } catch let error as NSError {
                    Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                }
                try _gFSH.copyItem(at: audioURL, to: newURL!)
                doc.setDataForTrackEvent(trackIdx, eventIdx: 0, url: newURL!)
            } catch let error as NSError {
                Logger.log("\(#function) \(#file) \(error.localizedDescription)")
            }
        }
    }
    
    func assignAudioFilesFromFolder( _ doc:MuzomaDocument!, assignAlert:UIAlertController!, audioURLFolder:URL!, track:MuzTrack!, trackIdx:Int ) -> Int
    {
        var ret = -1
        do
        {
            let files = try self.contentsOfDirectory(at: audioURLFolder,
                                                     includingPropertiesForKeys: [URLResourceKey.isDirectoryKey, URLResourceKey.isReadableKey, URLResourceKey.contentModificationDateKey],
                                                     options: FileManager.DirectoryEnumerationOptions()) as [URL]
            var fileCnt = 0
            for file in files {
                
                if( file.hasDirectoryPath )
                {
                    _ = assignAudioFilesFromFolder( doc, assignAlert: assignAlert, audioURLFolder: file, track: track, trackIdx: trackIdx )
                }
                else
                {
                    let fileName=file.lastPathComponent
                    
                    if( fileName.hasSuffix( "wav") || fileName.hasSuffix( "m4a") || fileName.hasSuffix( "mp3") || fileName.hasSuffix( "caf") )
                    {
                        var trackUsed:MuzTrack! = track
                        var trackIdxUsed:Int = trackIdx
                        if( track == nil || trackIdx == -1 ) // create a new one
                        {
                            let specifics:EventSpecifics! = nil
                            // use the file name as the track name
                            ret = doc.addNewTrack( file.lastPathComponent.replacingOccurrences(of: "." + file.pathExtension, with: ""), trackType: TrackType.Audio, trackPurpose: TrackPurpose.BackingTrackAudio, eventspecifcs: specifics  )
                            
                            let audioSpecifics = doc!.getAudioTrackSpecifics(ret)
                            audioSpecifics?.favouriDevicePlayback = true
                            audioSpecifics?.favourMultiChanPlayback = true
                            audioSpecifics?.inputChan = ret
                            audioSpecifics?.chan = ret
                            audioSpecifics?.downmixToMono = true
                            audioSpecifics?.ignoreDownmixiDevice = true
                            audioSpecifics?.ignoreDownmixMultiChan = false
                            audioSpecifics?.pan = -1.0
                            trackUsed = doc._tracks[ret]
                            trackIdxUsed = ret
                        }
                        
                        assignAudioContentURLToDoc( doc, assignAlert: assignAlert, audioURL: file, track:trackUsed, trackIdx: trackIdxUsed  )
                    }
                    else
                    {
                        Logger.log("Ignoring \(fileName) in zip extract")
                        do
                        {
                            try self.removeItem(at: file)
                            Logger.log("\(#function)  \(#file) Deleted \(file.absoluteString)")
                        } catch let error as NSError {
                            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
                        }
                    }
                }
                fileCnt += 1
            }
        } catch let error as NSError {
            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
        }
        return( ret )
    }
    
    func queueFinishedAlert( _ doc:MuzomaDocument!, destFolder:URL! )
    {
        let finishedAlert = UIAlertController(title: "Import complete", message: "Audio was imported", preferredStyle: UIAlertController.Style.alert)
        
        let actOK = UIAlertAction(title: "OK", style: .cancel, handler: { (action: UIAlertAction!) in
            do{
                if( destFolder != nil && self.directoryExists(destFolder) )
                {
                    try self.removeItem(at: destFolder)
                    Logger.log("\(#function)  \(#file) Deleted \(destFolder.absoluteString)")
                }
            } catch let error as NSError {
                Logger.log("\(#function) \(#file) \(error.localizedDescription)")
            }
            _ = _gFSH.saveMuzomaDocLocally(doc)
        })
        finishedAlert.addAction(actOK)
        
        finishedAlert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        let vc =  UIApplication.shared.keyWindow?.visibleViewController
        vc!.queuePopup(finishedAlert, animated: true, completion: nil)
    }
    
    func extractAudioTracksFromZip( _ doc:MuzomaDocument!, url:URL!, removeZip:Bool = true ) -> Bool
    {
        let ret:Bool = false
        
        let destFolder = doc.getDocumentFolderPathURL()!.appendingPathComponent("zip", isDirectory: true)
        
        do{
            if( self.directoryExists(destFolder) )
            {
                try self.removeItem(at: destFolder)
                Logger.log("\(#function)  \(#file) Deleted \(destFolder.absoluteString)")
            }
        } catch let error as NSError {
            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
        }
        
        _ = ensureFolderExists(destFolder)
        
        do
        {
            if( url.pathExtension == "zip" )
            {
                try Zip.unzipFile(url, destination: destFolder, overwrite: true, password: nil, progress:nil )
            }
            else
            {
                // just copy the file
                try _gFSH.copyItem(at: url, to: destFolder.appendingPathComponent(url.lastPathComponent, isDirectory: false))
            }
        } catch let error as NSError {
            Logger.log("\(#function) \(#file) \(error.localizedDescription)")
        }
        
        let assignAlertMain = UIAlertController(title: "Assign audio files", message: "Assign audio files from the archive", preferredStyle: UIAlertController.Style.alert)
        let actAllToNew = UIAlertAction(title: "Assign audio file/s to a new track", style: .default, handler: { (action: UIAlertAction!) in
            _ = self.assignAudioFilesFromFolder( doc, assignAlert: nil, audioURLFolder: destFolder,  track: nil, trackIdx:-1 )
            self.queueFinishedAlert(doc, destFolder: destFolder)
        })
        assignAlertMain.addAction(actAllToNew)
        
        let individualAssign = UIAlertAction(title: "Assign audio file/s individually", style: .default, handler: { (action: UIAlertAction!) in
            
            var btIdxs = doc?.getBackingTrackIndexes()
            let guideTrackIdx = doc?.getGuideTrackIndex()
            btIdxs?.insert(guideTrackIdx!, at: 0) //guide first
            
            for track in btIdxs!
            {
                let name = doc._tracks[track]._trackName
                
                let assignAlert = UIAlertController(title: "Assign audio to \(name)", message: "Assign an audio files from the source for track \(track), \(name)", preferredStyle: UIAlertController.Style.alert)
                _ = self.assignAudioFilesFromFolder( doc, assignAlert: assignAlert, audioURLFolder: destFolder, track: doc._tracks[track], trackIdx: track )
                
                let actIgnore = UIAlertAction(title: "Ignore this track", style: .cancel, handler: { (action: UIAlertAction!) in
                })
                assignAlert.addAction(actIgnore)
                
                assignAlert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                let vc =  UIApplication.shared.keyWindow?.visibleViewController
                vc!.queuePopup(assignAlert, animated: true, completion: nil)
            }
            
            self.queueFinishedAlert(doc, destFolder: destFolder)
            
        })
        assignAlertMain.addAction(individualAssign)
        
        let pro = MuzomaProducts.store.isProductPurchased( "MuzomaProducer" )
        if(!pro)
        {
            for act in assignAlertMain.actions
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
        assignAlertMain.addAction(actCancel)
        
        assignAlertMain.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        let vc =  UIApplication.shared.keyWindow?.visibleViewController
        vc!.queuePopup(assignAlertMain, animated: true, completion: nil)
        
        // delete zip
        if( removeZip )
        {
            do{
                if( fileExists(url) )
                {
                    try self.removeItem(at: url)
                    Logger.log("\(#function)  \(#file) Deleted \(url.absoluteString)")
                }
            } catch let error as NSError {
                Logger.log("\(#function) \(#file) \(error.localizedDescription)")
            }
        }
        
        return( ret )
    }
}
