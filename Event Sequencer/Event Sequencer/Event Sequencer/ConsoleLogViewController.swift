//
//  ConsoleLogViewController.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 10/08/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//
//  Logging class - allows our users to log and help debug

import UIKit

class ConsoleLogViewController: UIViewController {

    @IBAction func clearConsole(_ sender: AnyObject) {
        let logPath = getLogPath()
        if( _gFSH.fileExists(atPath: logPath) )
        {
            do
            {
                try _gFSH.removeItem(atPath: logPath)
                let cstr = (logPath as NSString).utf8String
                freopen(cstr, "a+", stderr)
                textLogText.text = ""
            }
            catch {
                
            }
        }
    }
    
    func getLogPath() -> String
    {
        let paths: NSArray = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        let documentsDirectory: NSString = paths[0] as! NSString
        let logPath: String = documentsDirectory.appendingPathComponent("/_log/console.log")
        return logPath
    }
    
    @IBOutlet weak var textLogText: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do
        {
            let logPath = getLogPath()
            let fileContents:String = try String.init(contentsOfFile: logPath)
            textLogText.text = fileContents
        }
        catch let error as NSError {
            Logger.log("\(#function)  \(#file)  \(error.localizedDescription)")
        }
        // Do any additional setup after loading the view.
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
