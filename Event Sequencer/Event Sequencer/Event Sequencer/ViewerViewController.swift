//
//  HelpViewController.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 14/06/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//
//
//  Code to handle the viewer screen for a song
//  and the associated buttons like print, save as HTML,PDF,TXT etc
//


import UIKit
import MessageUI
import MobileCoreServices

class ViewerViewController: UIViewController, UIDocumentPickerDelegate, MFMailComposeViewControllerDelegate {
    var muzomaDoc: MuzomaDocument?
    let nc = NotificationCenter.default
    fileprivate var _transport:Transport! = nil
    var _lyricTrackIdx = 0
    var _chordTrackIdx = 0
    var _sectionTrackIdx = 0
    var _guideTrackIdx = 0
    
    @IBOutlet weak var webMainView: UIWebView!
    @IBOutlet weak var printButton: UIBarButtonItem!
    @IBOutlet weak var _navPanel: UINavigationItem!
    
    @IBOutlet weak var butPDF: UIBarButtonItem!
    @IBOutlet weak var butTXT: UIBarButtonItem!
    @IBOutlet weak var butPro: UIBarButtonItem!
    @IBOutlet weak var butHTML: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Do any additional setup after loading the view.
        // let url = NSURL (string: "http://muzoma.com/muzoma-app/app-help/")
        _transport = Transport( viewController: self, includeVarispeedButton: false,  includeRecordTimingButton: false )
        docChanged()
        nc.addObserver(self, selector: #selector(ViewerViewController.setSelectNextSong(_:)), name: NSNotification.Name(rawValue: "SetSelectNextSong"), object: nil)
        nc.addObserver(self, selector: #selector(ViewerViewController.setSelectPreviousSong(_:)), name: NSNotification.Name(rawValue: "SetSelectPreviousSong"), object: nil)
        nc.addObserver(self, selector: #selector(ViewerViewController.setSelectedSong(_:)), name: NSNotification.Name(rawValue: "SetSelectedSong"), object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "SetSelectNextSong"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "SetSelectPreviousSong"), object: nil )
        nc.removeObserver( self, name: NSNotification.Name(rawValue: "SetSelectedSong"), object: nil )
        
        _transport?.willDeinit()
        _transport = nil
        return( super.viewDidDisappear(animated) )
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func printButtonClicked(_ sender: AnyObject) {
        if( muzomaDoc != nil )
        {
            let pic = UIPrintInteractionController.shared
            let printInfo : UIPrintInfo = UIPrintInfo(dictionary: nil)
            
            printInfo.outputType = UIPrintInfo.OutputType.general
            
            if( muzomaDoc != nil )
            {
                printInfo.jobName = "Muzoma - " + muzomaDoc!.getFolderName()
            } else {
                printInfo.jobName = "Muzoma"
            }
            
            pic.printInfo = printInfo
            
            let formatter = UIMarkupTextPrintFormatter(markupText: muzomaDoc!.getHTML(true, ignoreZoom: true, ignoreColourScheme: true, isAirPlay: false))
            formatter.contentInsets = UIEdgeInsets(top: 36, left: 42, bottom: 36, right: 36) // 0.5" margins
            pic.printFormatter = formatter
            pic.showsPageRange = true
            pic.present(animated: true, completionHandler: nil)
        }
    }
    
    @IBAction func txtPressed(_ sender: AnyObject) {
        
        if( muzomaDoc != nil )
        {
            let txt = muzomaDoc!.getTXT()
            
            // Save txt file
            let txtFileURL = muzomaDoc?.getDocumentFolderPathURL()?.appendingPathComponent( (muzomaDoc?.getFolderName())! + ".txt" )
            do {
                try txt.write(to: txtFileURL!, atomically: true, encoding: String.Encoding.utf8)
                displayTXTSaveFilePicker(txtFileURL!)
            }   catch let error as NSError {
                Logger.log("\(#function)  \(#file)  \(error.localizedDescription)")
                
                let alert = UIAlertController(title: "Error", message: "TXT file could not be exported \(error.localizedDescription)", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                    print("Error exporting TXT file")
                }))
                
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func proPressed(_ sender: AnyObject) {
        if( muzomaDoc != nil )
        {
            let pro = muzomaDoc!.getPRO()
            
            // Save pro file
            let proFileURL = muzomaDoc?.getDocumentFolderPathURL()?.appendingPathComponent( (muzomaDoc?.getFolderName())! + ".crd" )
            do {
                try pro.write(to: proFileURL!, atomically: true, encoding: String.Encoding.utf8)
                displayPROSaveFilePicker(proFileURL!)
            } catch let error as NSError {
                Logger.log("\(#function)  \(#file)  \(error.localizedDescription)")
                
                let alert = UIAlertController(title: "Error", message: "Chord Pro file could not be exported \(error.localizedDescription)", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                    print("Error exporting Chord Pro file")
                }))
                
                self.present(alert, animated: true, completion: nil)
            }
        }
    }

    
    @IBAction func htmlPressed(_ sender: AnyObject) {
        
        if( muzomaDoc != nil )
        {
            let html = muzomaDoc!.getHTML( false, ignoreZoom: true, ignoreColourScheme: true, isAirPlay: false)
            // Save HTML file
            let htmlFileURL = muzomaDoc?.getDocumentFolderPathURL()?.appendingPathComponent( (muzomaDoc?.getFolderName())! + ".htm" )
            do {
                try html.write(to: htmlFileURL!, atomically: true, encoding: String.Encoding.utf8)
                displayHTMLSaveFilePicker(htmlFileURL!)
            } catch let error as NSError {
                Logger.log("\(#function)  \(#file)  \(error.localizedDescription)")
                
                let alert = UIAlertController(title: "Error", message: "HTML file could not be exported \(error.localizedDescription)", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                    print("Error exporting HTML file")
                }))
                
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func displayTXTSaveFilePicker( _ txtFileURL:URL )
    {
        let documentPicker: UIDocumentPickerViewController = UIDocumentPickerViewController(url: txtFileURL, in: UIDocumentPickerMode.exportToService)
        documentPicker.delegate = self
        documentPicker.title = "Save TXT File"
        documentPicker.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    func displayPROSaveFilePicker( _ proFileURL:URL )
    {
        let documentPicker: UIDocumentPickerViewController = UIDocumentPickerViewController(url: proFileURL, in: UIDocumentPickerMode.exportToService)
        documentPicker.delegate = self
        documentPicker.title = "Save Chord Pro File"
        documentPicker.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    func displayHTMLSaveFilePicker( _ htmlFileURL:URL )
    {
        let documentPicker: UIDocumentPickerViewController = UIDocumentPickerViewController(url: htmlFileURL, in: UIDocumentPickerMode.exportToService)
        documentPicker.delegate = self
        documentPicker.title = "Save HTML File"
        documentPicker.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    fileprivate func getPDFKey(_ key: String, from dict: CGPDFDictionaryRef) -> String? {
        var cfValue: CGPDFStringRef? = nil
        if (CGPDFDictionaryGetString(dict, key, &cfValue)), let value = CGPDFStringCopyTextString(cfValue!) {
            return value as String
        }
        return nil
    }

    @IBAction func PDFClicked(_ sender: AnyObject) {
        if( muzomaDoc != nil )
        {
            let fmt = UIMarkupTextPrintFormatter(markupText: muzomaDoc!.getHTML( true, ignoreZoom: true, ignoreColourScheme: true, isAirPlay: false ))
            fmt.contentInsets = UIEdgeInsets(top: 36, left: 36, bottom: 36, right: 36) // 0.5" margins
            
            // 2. Assign print formatter to UIPrintPageRenderer
            let render = UIPrintPageRenderer()
            render.addPrintFormatter(fmt, startingAtPageAt: 0)
            
            // 3. Assign paperRect and printableRect
            let page = CGRect(x: 36, y: 36, width: 595.2 - 36, height: 841.8 - 72) // A4, 72 dpi
            let printable = page.insetBy(dx: 0, dy: 0)
            
            render.setValue(NSValue(cgRect: page), forKey: "paperRect")
            render.setValue(NSValue(cgRect: printable), forKey: "printableRect")
            
            // 4. Create PDF context and draw
            let pdfData = NSMutableData()
            var infoDict = [String: AnyObject]()
            infoDict[kCGPDFContextTitle as String] = muzomaDoc?._title as AnyObject
            infoDict[kCGPDFContextAuthor as String] = muzomaDoc?._artist as AnyObject
            infoDict[kCGPDFContextCreator as String] = muzomaDoc?._author as AnyObject
            infoDict[kCGPDFContextSubject as String] = "Muzoma App export - " + (muzomaDoc?.getFolderName())! as AnyObject
            UIGraphicsBeginPDFContextToData(pdfData, CGRect.zero, infoDict)
            
            for i in 1...render.numberOfPages {
                
                UIGraphicsBeginPDFPage()
                let bounds = UIGraphicsGetPDFContextBounds()
                render.drawPage(at: i - 1, in: bounds)
            }
            
            UIGraphicsEndPDFContext()
            
            // 5. Save PDF file
            let pdfFileURL = muzomaDoc?.getDocumentFolderPathURL()?.appendingPathComponent( (muzomaDoc?.getFolderName())! + ".pdf" )
            do {
                try pdfData.write(to: pdfFileURL!, options: .atomicWrite)
                displayPDFSaveFilePicker(pdfFileURL!)
            } catch let error as NSError {
                Logger.log("\(#function)  \(#file)  \(error.localizedDescription)")
                
                let alert = UIAlertController(title: "Error", message: "PDF file could not be exported \(error.localizedDescription)", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                    print("Error exporting PDF file")
                }))
                
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func displayPDFSaveFilePicker( _ pdfFileURL:URL )
    {
        let documentPicker: UIDocumentPickerViewController = UIDocumentPickerViewController(url: pdfFileURL, in: UIDocumentPickerMode.exportToService)
        documentPicker.delegate = self
        documentPicker.title = "Save PDF File"
        documentPicker.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        //originalImageURL = nil
        
        if( url.lastPathComponent.lowercased().contains( ".txt" ))
        {
            let data = try? Data(contentsOf: url)
            if( data != nil )
            {
                self.webMainView.load(data!, mimeType: "text/plain", textEncodingName: "UTF-8", baseURL: url ) // handle utf-8 chars like sharps
            }
        }
        else
        {
            let request = URLRequest(url: url)
            self.webMainView.loadRequest(request)
        }
        
        if controller.documentPickerMode == UIDocumentPickerMode.exportToService {
            if( url.isFileURL )
            {
                DispatchQueue.main.async(execute: {
                    self.showOptionsAlert(url)
                })
            }
        }
    }
    
    func showOptionsAlert( _ url:URL ) {
        let alertController = UIAlertController(title: "Muzoma", message: "Your document has been successfully saved.\n\nDo you want to action it?", preferredStyle: UIAlertController.Style.alert)

        let actionEmail = UIAlertAction(title: "Send it via email", style: UIAlertAction.Style.default) { (action) in
            DispatchQueue.main.async(execute: {
                self.sendEmail(url)
            })
        }
        
        let actionNothing = UIAlertAction(title: "Done", style: UIAlertAction.Style.cancel) { (action) in

        }

        alertController.addAction(actionEmail)
        alertController.addAction(actionNothing)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func sendEmail(_ url:URL) {
        if MFMailComposeViewController.canSendMail() {
            let mailComposeViewController = MFMailComposeViewController()
            mailComposeViewController.mailComposeDelegate = self // can't cancel or leave the popup unless this is set
            mailComposeViewController.setSubject(muzomaDoc!.getFolderName())
            
            var mime = "application/pdf"
            
            if( url.pathExtension == "pdf" )
            {
               mime = "application/pdf"
            }
            else if( url.pathExtension == "txt" )
            {
                mime = "text/plain"
            }
            else if( url.pathExtension == "htm" )
            {
                mime = "text/html"
            }
            else if( url.pathExtension == "crd" )
            {
                mime = "application/chordpro"
            }

            _ = url.startAccessingSecurityScopedResource()
            let data = try? Data(contentsOf: url)
            url.stopAccessingSecurityScopedResource()
            
            if( data != nil )
            {
                mailComposeViewController.addAttachmentData(data!, mimeType: mime, fileName: url.lastPathComponent)
                self.present(mailComposeViewController, animated: true, completion: nil)
            }
            else
            {
                showSendMailErrorAlert()
            }
        }
        else
        {
            showSendMailErrorAlert()
        }
    }
    
    func showSendMailErrorAlert() {
        let alert = UIAlertController(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            print("Error sending email")
        }))
        
        alert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    @objc func setSelectNextSong(_ notification: Notification)
    {
        let newDoc = notification.object as! MuzomaDocument
        self.muzomaDoc = newDoc
        self._transport.muzomaDoc = newDoc
        docChanged()
    }
    
    @objc func setSelectPreviousSong(_ notification: Notification)
    {
        let newDoc = notification.object as! MuzomaDocument
        self.muzomaDoc = newDoc
        self._transport.muzomaDoc = newDoc
        docChanged()
    }
    
    @objc func setSelectedSong(_ notification: Notification)
    {
        let newDoc = notification.object as! MuzomaDocument
        self.muzomaDoc = newDoc
        self._transport.muzomaDoc = newDoc
        docChanged()
    }
    
    func docChanged()
    {
        self.muzomaDoc = _transport.muzomaDoc // update our version of the doc
        
        if( muzomaDoc != nil && muzomaDoc!.isValid() && muzomaDoc!._activeEditTrack > -1 )
        {
            _navPanel.prompt = muzomaDoc!.getFolderName()
            _lyricTrackIdx = muzomaDoc!.getMainLyricTrackIndex()
            _chordTrackIdx = muzomaDoc!.getMainChordTrackIndex()
        }
        
        updateDisplayComponents()
    }
    
    func updateDisplayComponents()
    {
        if( muzomaDoc != nil && muzomaDoc!.isValid() )
        {
            let baseURL = muzomaDoc?.getDocumentFolderPathURL()
            webMainView.loadHTMLString(muzomaDoc!.getHTML(false, ignoreZoom: true, ignoreColourScheme: true, isAirPlay: false ), baseURL: baseURL)
        }
    }
    
    
    override var keyCommands: [UIKeyCommand]? {
            return [ // these will steal the keys from other controls so take care!
                /* UIKeyCommand(input: UIKeyInputLeftArrow, modifierFlags: UIKeyModifierFlags.init(rawValue: 0), action:  #selector(scrollLeftPress), discoverabilityTitle: "Left"),
                 UIKeyCommand(input: UIKeyInputRightArrow, modifierFlags: UIKeyModifierFlags.init(rawValue: 0), action:  #selector(scrollRightPress), discoverabilityTitle: "Right"),*/
                UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: UIKeyModifierFlags.init(rawValue: 0), action:  #selector(scrollUpPress), discoverabilityTitle: "Up"),
                UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: UIKeyModifierFlags.init(rawValue: 0), action:  #selector(scrollDownPress), discoverabilityTitle: "Down"),
                UIKeyCommand(input: "\r", modifierFlags: UIKeyModifierFlags.init(rawValue: 0), action:  #selector(returnKeyPress), discoverabilityTitle: "Enter")
                
            ]
    }
    
    @objc func scrollUpPress() {
        print("up was pressed")
        var scrollPos = self.webMainView.scrollView.contentOffset
        scrollPos.y = max( scrollPos.y - 150, 0 )
        self.webMainView.scrollView.setContentOffset(scrollPos, animated: true)
    }
    
    @objc func scrollDownPress() {
        print("down was pressed")
        
        var scrollPos = self.webMainView.scrollView.contentOffset
        scrollPos.y = min(scrollPos.y + 150, self.webMainView.scrollView.contentSize.height)
        self.webMainView.scrollView.setContentOffset(scrollPos, animated: true)
    }
    
    @objc func scrollLeftPress() {
        print("left was pressed")
    }
    
    @objc func scrollRightPress() {
        print("right was pressed")
    }
    
    @objc func returnKeyPress() {
        print("return key was pressed")
    }
}
