//
//  AboutViewController.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 14/06/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//
//  Help About UI code

import UIKit

class AboutViewController: UIViewController, UITextViewDelegate {

    fileprivate var _transport:Transport! = nil
    
    @IBOutlet weak var versionLabel: UILabel!
    
    @IBOutlet weak var buildLabel: UILabel!
    
    @IBOutlet weak var copyrightDetailsTextView: UITextView!
    
    @IBOutlet weak var releaseDetails: UILabel!
    
    @IBOutlet weak var labPaidOrFreeVersionText: UILabel!
    
    @IBOutlet weak var consoleButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let debugLogging = UserDefaults.standard.bool(forKey: "debugLogging_preference")
        consoleButton.isEnabled = debugLogging
        
        let pro = MuzomaProducts.store.isProductPurchased( "MuzomaProducer" )
        labPaidOrFreeVersionText.text = pro ? "Producer Version" : "Free viewer version"
        
        // Do any additional setup after loading the view.
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            self.versionLabel.text = "Version: \(version)"

            if( Version.VersionHistory.keys.contains(version) )
            {
                let history = Version.VersionHistory[version]
                let fmt =  DateFormatter()
                fmt.dateFormat = "MMM dd yyyy"
                let dateString = fmt.string(from: (history?.date)!)
                let desc = history!.longDescription
                releaseDetails.text = "Release detail: \(dateString) - \(desc)"
            }
        }
        
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            self.buildLabel.text = "Build: \(build)"
        }
        
        DispatchQueue.main.async(execute: {self.copyrightDetailsTextView.isScrollEnabled = true
            self.copyrightDetailsTextView.flashScrollIndicators()
        })
        
        // https://developer.apple.com/documentation/uikit/uitextviewdelegate/1649337-textview
        copyrightDetailsTextView.delegate = self
        do
        {
            let url = Bundle.main.url( forResource: ("About") as String, withExtension: ".rtf")
            let attributedString = try NSAttributedString( url: url!, options: convertToNSAttributedStringDocumentReadingOptionKeyDictionary([convertFromNSAttributedStringDocumentAttributeKey(NSAttributedString.DocumentAttributeKey.documentType):convertFromNSAttributedStringDocumentType(NSAttributedString.DocumentType.rtf)]), documentAttributes: nil)
            
            copyrightDetailsTextView.attributedText = attributedString
            
        }
        catch
        {
            
        }

        copyrightDetailsTextView.isUserInteractionEnabled = true
        copyrightDetailsTextView.isSelectable = true
        copyrightDetailsTextView.isEditable = false
        copyrightDetailsTextView.scrollRangeToVisible( NSMakeRange(0, 0) )
    }
    
    @available(iOS, deprecated: 10.0)
    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange) -> Bool {
        return true
    }

    //For iOS 10
    @available(iOS 10.0, *)
    func textView(_ textView: UITextView, shouldInteractWith url: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return true
    }
    /*
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        return true
    }*/
    
    override func viewDidAppear(_ animated: Bool) {
        //print( "viewDidAppear Docs View" )
        _transport = Transport( viewController: self, hideAllControls: true )
        return super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        _transport?.willDeinit()
        _transport = nil
        super.viewDidDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func inAppPurchasesPressed(_ sender: AnyObject) {
        let iapVC = IAPTableViewController()
        //let importDocController = self.storyboard?.instantiateViewControllerWithIdentifier("ImportTextDocumentViewController") as? ImportTextDocumentViewController

        self.navigationController?.pushViewController(iapVC, animated: true)
    }

    // Helper function inserted by Swift 4.2 migrator.
    fileprivate func convertToNSAttributedStringDocumentReadingOptionKeyDictionary(_ input: [String: Any]) -> [NSAttributedString.DocumentReadingOptionKey: Any] {
        return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.DocumentReadingOptionKey(rawValue: key), value)})
    }

    // Helper function inserted by Swift 4.2 migrator.
    fileprivate func convertFromNSAttributedStringDocumentAttributeKey(_ input: NSAttributedString.DocumentAttributeKey) -> String {
        return input.rawValue
    }

    // Helper function inserted by Swift 4.2 migrator.
    fileprivate func convertFromNSAttributedStringDocumentType(_ input: NSAttributedString.DocumentType) -> String {
        return input.rawValue
    }


}
