//
//  UISuperTextView.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 10/05/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//
//  A text control that allows pan and zoom - annoyingly Apple don't provide this type of view out of the box
//  -- remember that if you hold the spacebar down with two fingers,
//  you can move the carett like a mouse
//

import UIKit


class UISuperTextView: UIScrollView, UIScrollViewDelegate, UITextViewDelegate {
    var _textView: UITextView! = nil
    let _nc = NotificationCenter.default
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        _nc.addObserver(self, selector: #selector(UISuperTextView.keyboardShow(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        _nc.addObserver(self, selector: #selector(UISuperTextView.keyboardHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        self.canCancelContentTouches = false
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    deinit
    {
        _nc.removeObserver( self, name: UIResponder.keyboardWillShowNotification, object: nil )
        _nc.removeObserver( self, name: UIResponder.keyboardWillHideNotification, object: nil )
    }
    
    
    var keyboardShowing = false
    
    
    @objc func keyboardShow(_ n:Notification) {
        //print("kb show")
        
        // must do this resize on a delay otherwise the intelisense quick type bar is not taken into the sizing calc!
        let delay = DispatchTime.now() + Double(Int64(0.1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delay,execute: {
            
            let prevZoom = self.zoomScale /* store the zoom as calcs can't be made if zoomed */
            self.zoomScale = 1.00 /* set the zoom as calcs can't be made if zoomed */

            let d = n.userInfo!
            var r = (d[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            r = self.convert(r, from:nil)
            // allow the height of the keyboard as the bottom offset
            self.contentInset.bottom = r.size.height
            self.scrollIndicatorInsets.bottom = r.size.height
            
            // new new new
            // allow the height of the two toolbars as the top offset
            self.contentInset.top = 60
            self.scrollIndicatorInsets.top = 60
 
            // new new new
            // re-find the cursor
            let selHeight = self._textView.selectedTextRange?.start
            if( selHeight != nil )
            {
                let pos = self._textView.caretRect(for: selHeight!)
                self.scrollRectToVisible(pos, animated: true)
            }
            
            self.zoomScale = prevZoom
            self.keyboardShowing = true
            
            self.resizeTextView()
        })
    }
    
    @objc func keyboardHide(_ n:Notification) {
        //print("kb hide")
        resizeTextView()
        
        /* reset resize */
        self.contentInset = UIEdgeInsets.zero
        self.scrollIndicatorInsets = UIEdgeInsets.zero
        
        self.keyboardShowing = false
    }
    
    func setup()
    {
        self._textView = UITextView()
        self._textView.delegate = self
        self._textView.backgroundColor = UIColor.black
        self.addSubview(_textView)
        
        self.delegate = self
        self.isScrollEnabled = true
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight] //[.None]//
        self.minimumZoomScale = 0.99 // woz 0.99 // any less and we start getting black outs round the text
        self.maximumZoomScale = 2.0
        self.bouncesZoom = true
        self.autoresizesSubviews = true
        // this fudge actives the zoom - expect pinch / zoom gesture on the control
        self.zoomScale = 0.99
        self.zoomScale = 1.00
        
        // show the dismiss kb icon on the keyboard
        self._textView.keyboardDismissMode = .interactive
        self._textView.isScrollEnabled = true
        
        self._textView.autoresizingMask =  UIView.AutoresizingMask() // .FlexibleHeight, .FlexibleWidth ]
        
        do
        {
            let url = Bundle.main.url( forResource: ("DefaultText") as String, withExtension: ".rtf")
            let attributedString = try NSAttributedString( url: url!, options: convertToNSAttributedStringDocumentReadingOptionKeyDictionary([convertFromNSAttributedStringDocumentAttributeKey(NSAttributedString.DocumentAttributeKey.documentType):convertFromNSAttributedStringDocumentType(NSAttributedString.DocumentType.rtf)]), documentAttributes: nil)
            
            let masString:NSMutableAttributedString = NSMutableAttributedString.init(attributedString: attributedString)
            
            /* replace with registration versions*/
            let reg = UserRegistration()
            masString.mutableString.replaceOccurrences(of: "Artist", with:  reg.artist != nil ? reg.artist! : "Artist", options: NSString.CompareOptions.forcedOrdering, range: NSMakeRange(0, masString.mutableString.length))
            masString.mutableString.replaceOccurrences(of: "Author", with:  reg.author != nil ? reg.author! : "Author", options: NSString.CompareOptions.forcedOrdering, range: NSMakeRange(0, masString.mutableString.length))
            masString.mutableString.replaceOccurrences(of: "Copyright 2016-20 Muzoma Ltd", with:  reg.copyright != nil ? reg.copyright! : "(c) " + Date().datePretty, options: NSString.CompareOptions.forcedOrdering, range: NSMakeRange(0, masString.mutableString.length))
            masString.mutableString.replaceOccurrences(of: "Published by Muzoma Ltd", with:  reg.publisher != nil ? reg.publisher! : "Pubisher", options: NSString.CompareOptions.forcedOrdering, range: NSMakeRange(0, masString.mutableString.length))
            
            self._textView.attributedText = masString
        }
        catch
        {
            // print( "no default text could be loaded for the text view" )
        }
        
        resizeTextView()
        self.becomeFirstResponder()
        
        self._textView.allowsEditingTextAttributes = true // need this for copy/paste
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        //print( "tv shouldChangeTextInRange \(range) \(text) \(self._textView.selectedRange)")
        var ret = true
        if( text==". " && range.location != self._textView.selectedRange.location ) // filter out auto full stop
        {
            ret = false
        }
        else if( text == UIPasteboard.general.string ) // pasting in text
        {
            if( UIPasteboard.general.types.contains("com.apple.flat-rtfd") ) // rtf
            {
                let data = UIPasteboard.general.data(forPasteboardType: "com.apple.flat-rtfd")
                if( data != nil )
                {
                    do {
                        let rtf = try NSMutableAttributedString(data: data!, options: convertToNSAttributedStringDocumentReadingOptionKeyDictionary([convertFromNSAttributedStringDocumentAttributeKey(NSAttributedString.DocumentAttributeKey.documentType): convertFromNSAttributedStringDocumentType(NSAttributedString.DocumentType.rtfd)]), documentAttributes: nil)
                        //print( "paste rtf: \(rtf.string)")
                        self._nc.post(name: Notification.Name(rawValue: "SuperTVPasting"), object: rtf)
                    }
                    catch
                    {
                        
                    }
                    ret = false
                }
            }
            else // plain text
            {
                //print( "paste plain text: \(UIPasteboard.generalPasteboard().string)")
                self._nc.post(name: Notification.Name(rawValue: "SuperTVPasting"), object: UIPasteboard.general.string)
                ret = false
            }
        }
        return( ret )
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        //print( "tv did begin editing" )
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        //print( "tv did end editing" )
    }
    
    func textViewDidChange(_ textView: UITextView)
    {
        // print( "Content size \(self.contentSize)" )
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        self._nc.post(name: Notification.Name(rawValue: "SuperTVSelectionChanged"), object: self)
        //print( "tv did change selection" )
    }

    func resizeTextView()
    {
        let prevZoom = self.zoomScale /* store the zoom as calcs can't be made if zoomed */
        self.zoomScale = 1.00 /* set the zoom as calcs can't be made if zoomed */
        
        let newSize = _textView.sizeThatFits(CGSize(width: self.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
        
        var newTextViewFrame = _textView.frame
        newTextViewFrame.size = CGSize(width: max(newSize.width,  self.frame.size.width, 2000), height: max( newSize.height, self.frame.size.height ) )
        _textView.frame = newTextViewFrame

        // allow the height of the keyboard as the bottom offset
        let selHeight = self._textView.selectedTextRange?.start
        if( selHeight != nil )
        {
            let pos = self._textView.caretRect(for: selHeight!)
            self.scrollRectToVisible(pos, animated: true)
        }
        
        //print( "new size \(newSize) new frame \(newTextViewFrame) offset \(self.contentOffset)" )
        self.zoomScale = prevZoom /* reset the zoom */
        //print("UISuperTextView zoom scale \(self.zoomScale.description)")
        
    }
    
    @objc func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        if( scrollView == self ) // must check this or we can return the wrong view and crash the app
        {
            return _textView
        }
        else
        {
            return nil
        }
    }
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
