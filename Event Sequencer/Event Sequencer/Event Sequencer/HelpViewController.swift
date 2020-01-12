//
//  HelpViewController.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 14/06/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//
//  Help UI - based on a web view

import UIKit
import WebKit

class HelpViewController: UIViewController {
    
    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        //let url = NSURL (string: "http://muzoma.com/muzoma-app/app-help/")
        //let url = NSURL (string: "http://muzoma.com/muzoma-app/muzoma-demos/" )
        webView.loadHTMLString("<H1><a href='https://itunes.apple.com/gb/book/muzoma-user-guide/id1168049813#'>Loading iBooks Muzoma User Guide page...</a></H1>", baseURL: URL(string: "https://itunes.apple.com/"))
        let url = URL (string: "https://itunes.apple.com/gb/book/muzoma-user-guide/id1168049813#")
        let requestObj = URLRequest(url: url!)
        webView.loadRequest(requestObj)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
