//
//  UserDownloads.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 17/01/2017.
//  Copyright © 2017 Muzoma.com. All rights reserved.
//
//  User downloads store
//

// e.g. http://muzo.azurewebsites.net/Content/Codes/1234/SiteSong.html
import Foundation
import SwaggerWPSite

class UserDownloads
{
    internal var remoteDocs = [Attachment]()
    
    fileprivate let baseURL = URL(string: "http://muzo.azurewebsites.net/Content/Codes/")
    let reg = UserRegistration()
    
    func refreshRemoteDocs()
    {
        let objs = UserDefaults.standard.object(forKey: "userDownloadCodes")
        var badObjs:[String] = [String]()
        
        if( objs is [String] )
        {
            var downloadObjs = objs! as! [String]
            
            for folder in downloadObjs
            {
                let folderURL = baseURL?.appendingPathComponent(folder, isDirectory: true)
                let file = "SiteSong.html"
                let fileURL = folderURL?.appendingPathComponent(file)
                var htmlURL = URLComponents(string: fileURL!.absoluteString)
                
                if( reg.communityName != nil && !reg.communityName!.isEmpty)
                {
                    htmlURL?.queryItems = [URLQueryItem(name: "user", value: reg.communityName!)]
                }
                
                do
                {
                    let htmlString = try String.init(contentsOf: htmlURL!.url!)
                    //print( htmlString )
                    let attachment = Attachment()
                    let attachmentDescription = AttachmentDescription()
                    attachmentDescription.rendered = htmlString
                    attachment.description = attachmentDescription
                   
                    attachment.sourceUrl = ""
                    remoteDocs.append(attachment)
                }
                catch let error as NSError {
                    //Regprint(error.localizedDescription)
                    if( error.code == 256 )
                    {
                        badObjs.append(folder)
                    }
                }
            }
            // clean up bad download codes
            if( badObjs.count > 0 )
            {
                for badObj in badObjs
                {
                    let removeIdx = downloadObjs.index(of: badObj)
                    if( removeIdx != nil )
                    {
                        downloadObjs.remove(at: removeIdx!)
                    }
                }
                UserDefaults.standard.set(downloadObjs, forKey: "userDownloadCodes")
            }
        }
    }
}
