//
//  DocumentMapper.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 02/11/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//
// Optimisation for storing and handling a collection of muzoma documents

import Foundation


let globalDocumentMapper = DocumentMapper()


class DocumentMapper {
    fileprivate let nc = NotificationCenter.default
    fileprivate var fs:FileSystemHelper = _gFSH
    typealias Index = Int
    
    fileprivate var _documents: [MuzomaDocument?] = []
    fileprivate var _filteredDocuments: [MuzomaDocument?] = []

    init()
    {
        reLoad()
    }
    
    deinit
    {
        nc.removeObserver(self)
    }
    
    func reLoad()
    {
        let docs = fs.getMuzomaDocs()
        
        _documents = []
        for doc in docs!
        {
            _documents.append(doc)
        }
        reFilter()
    }
    
    func reFilter( _ ignoreSetHideFilter:Bool = false )
    {
        UserDefaults.standard.synchronize()
        let unhideSetOnly = ignoreSetHideFilter || UserDefaults.standard.bool(forKey: "unhideSetOnly_preference")
        
        _filteredDocuments = []
        for doc in _documents
        {
            var keep = _filterText == nil || _filterText.isEmpty || (doc?.getFileName().localizedCaseInsensitiveContains(_filterText))!
            if( keep && doc?._setsOnly != nil && doc?._setsOnly == true )
            {
                keep = unhideSetOnly
            }
            
            if( keep )
            {
                _filteredDocuments.append(doc)
            }
        }
    }
    
    subscript(index: Index) -> MuzomaDocument {
        get {
            return _filteredDocuments[index]!
        }
        
        set {
            _filteredDocuments[index] = newValue
        }
    }
    
    internal var count:Int
    {
        get {
            return( _filteredDocuments.count )
        }
        
        /*set
        {
            
        }*/
    }
    
    func removeUsingFilterIdx( _ index:Int )
    {
        if( _filteredDocuments.count > index )
        {
            let docToRemove = _filteredDocuments[index]
            
            _filteredDocuments.remove(at: index)
            
            for docCnt in (0 ..< _documents.count)
            {
                let doc = _documents[docCnt]
                
                if( doc?.diskFolderFilePath == docToRemove?.diskFolderFilePath )
                {
                    _documents.remove(at: docCnt)
                    break;
                }
            }
        }
    }
    
    func removeUsingDocumentIdx( _ index:Int )
    {
        if( _documents.count > index )
        {
            let docToRemove = _documents[index]
            
            _documents.remove(at: index)
            
            for docCnt in (0 ..< _filteredDocuments.count)
            {
                let doc = _filteredDocuments[docCnt]
                
                if( doc?.diskFolderFilePath == docToRemove?.diskFolderFilePath )
                {
                    _filteredDocuments.remove(at: docCnt)
                    break;
                }
            }
        }
    }
    
    func remove( _ docToRemove:MuzomaDocument! )
    {
        for docCnt in (0 ..< _documents.count)
        {
            let doc = _documents[docCnt]
            
            if( doc?.diskFolderFilePath == docToRemove.diskFolderFilePath )
            {
                _documents.remove(at: docCnt)
                break;
            }
        }
        
        for docCnt in (0 ..< _filteredDocuments.count)
        {
            let doc = _filteredDocuments[docCnt]
            
            if( doc?.diskFolderFilePath == docToRemove.diskFolderFilePath )
            {
                _filteredDocuments.remove(at: docCnt)
                break;
            }
        }
    }
    
    func addNewDoc( _ newDoc:MuzomaDocument! )
    {
        if( newDoc != nil && newDoc!.isValid() )
        {
            let idx = getDocIndexFromPhysicalLocation( (newDoc!.getDocumentURL())! )
            if( idx != nil )
            {
                _documents[idx!] = newDoc
            }
            else
            {
                _documents.append(newDoc)
            }
        }
    }
    
    // returns nul or a url if a document already exists where we are trying to add the doc
    func addNewDocAtFolder( _ url:URL ) -> URL!
    {
        var ret:URL! = nil
        let newDoc = fs.loadMuzomaDocInFolder(url)

        if( newDoc != nil && newDoc!.isValid() )
        {
            if( fs.docFolderNeedsMoving(newDoc) )
            {
                let attemptedURL = newDoc!.getCorrectDocumentFolderPathURL()?.appendingPathComponent(newDoc!.getFileName())
                if( _gFSH.fileExists(attemptedURL) )
                {
                    ret = attemptedURL
                }
                else
                {
                    _ = fs.correctDocsLocation(newDoc)
                }
            }
            
            // ok to add to cache
            if( ret == nil )
            {
                let idx = getDocIndexFromPhysicalLocation( (newDoc!.getDocumentURL())! )
                if( idx != nil )
                {
                    _documents[idx!] = newDoc
                }
                else
                {
                    _documents.append(newDoc)
                }
            }
        }
        
        return( ret )
    }
    
    fileprivate var _filterText:String! = nil
    internal var filterText:String!
    {
        get{
            return( _filterText )
        }
        
        set
        {
            _filterText = newValue
            reFilter()
        }
    }
    
    func getDocFromPhysicalLocation( _ docLocation:URL ) -> MuzomaDocument!
    {
        var ret:MuzomaDocument! = nil
        
        for doc in _documents
        {
            if( (doc?.diskFolderFilePath.lastPathComponent.removingPercentEncoding == docLocation.lastPathComponent.removingPercentEncoding ) &&
                (doc?.diskFolderFilePath.pathComponents[(doc?.diskFolderFilePath.pathComponents.count)!-2].removingPercentEncoding  == docLocation.pathComponents[docLocation.pathComponents.count-2].removingPercentEncoding)
               )
            {
                ret = doc
                break;
            }
        }
        
        /*
        if( ret == nil )
        {
            print( "not found \(docLocation.absoluteString) \(docLocation.absoluteString.removingPercentEncoding)")
        }*/
        return( ret )
    }
    
    func getDocIndexFromPhysicalLocation( _ docLocation:URL ) -> Int!
    {
        var idx:Int! = nil
        
        var cnt=0
        for doc in _documents
        {
            if( (doc?.diskFolderFilePath.lastPathComponent.removingPercentEncoding == docLocation.lastPathComponent.removingPercentEncoding ) && //same file?
                (doc?.diskFolderFilePath.pathComponents[(doc?.diskFolderFilePath.pathComponents.count)!-2].removingPercentEncoding  == docLocation.pathComponents[docLocation.pathComponents.count-2].removingPercentEncoding)
            )
            {
                idx = cnt
                break;
            }
            cnt += 1
        }
        
        return( idx )
    }
}

