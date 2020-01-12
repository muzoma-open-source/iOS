//
//  WebSongsViewController
//  Muzoma
//
//  Created by Matthew Hopkins on 14/06/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//
//  Simple UI for web store
//

import UIKit
import WebKit
import SwaggerWPSite

class WebSongsViewController: UIViewController {
    
    
    @IBOutlet weak var webMainView: UIWebView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DefaultAPI.wpV2MediaGet( mimeType:"application/muz" ) { (data, error) in
            Logger.log(  "data \(String(describing: data))")
            Logger.log(  "error \(String(describing: error))")
            Logger.log(  "got media")
            
            if( error == nil )
            {
                if( data != nil )
                {
                    for attach in (data)!
                    {
                        Logger.log(  "caption: \(String(describing: attach.caption))" )
                        Logger.log(  "published: \(String(describing: attach.dateGmt?.datePretty))" )
                        Logger.log(  "description: \(String(describing: attach.description))" )
                        Logger.log(  "" )
                    }
                }
            }
        }
        
        // Do any additional setup after loading the view.
        webMainView.loadHTMLString("<H1><a href='http://muzoma.co.uk/'>Loading Muzoma demo page...</a></H1>", baseURL: URL(string: "http://muzoma.co.uk/"))
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

