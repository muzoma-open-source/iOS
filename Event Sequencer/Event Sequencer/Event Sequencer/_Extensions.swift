//
//  Extensions.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 29/02/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//

import Foundation
import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


let whitespaceSet = CharacterSet.whitespacesAndNewlines
let colonSet = CharacterSet(charactersIn: ":")
let newLine:Character = "\n"
let newLineDos:Character = "\r\n"
let newLineU:Character = "\u{00002028}"
let newLineSet = CharacterSet(charactersIn: "\r\n\u{00002028}")
let newLineUAttStr:NSAttributedString = NSAttributedString( string: "\u{00002028}")
let chordSet = CharacterSet(charactersIn: "abcdefg ABCDEFG mM123456789 +/#- dim aug sus maj min")
private var _acceptableProperSet:NSMutableCharacterSet = NSMutableCharacterSet()
let xmlAllowedSet =  CharacterSet(charactersIn:"&=\"#%/<>?@\\^`{|}").inverted
let htmlAmpresandAllowedSet = CharacterSet(charactersIn:"&").inverted


var acceptableProperSet:CharacterSet
{
get
{
    if( !((_acceptableProperSet as CharacterSet)).contains(UnicodeScalar(unichar(65))!) )
    {
        _acceptableProperSet.formUnion(with: CharacterSet.alphanumerics)
        _acceptableProperSet.formUnion(with: CharacterSet(charactersIn: " ()-',!$£*?&."))
    }
    return( _acceptableProperSet ) as CharacterSet
}
}


extension Character
{
    func unicodeScalarCodePoint() -> UInt32
    {
        let characterString = String(self)
        let scalars = characterString.unicodeScalars
        
        return scalars[scalars.startIndex].value
    }
}


func hexCharToDec( _ ch:UInt32 ) -> UInt32
{
    var ret:UInt32 = 0
    
    if( ch >= 48 && ch<=57 ) //number
    {
        ret = ch-48
    }
    else if( ch >= 65 && ch <= 70 ) // upper
    {
        ret = ch-55
    } else if( ch >= 97 && ch <= 102 ) // lower
    {
        ret = ch-87
    }
    
    return( ret )
}


protocol UIViewLoading {}
extension UIView : UIViewLoading {}

func JSONStringify(_ value: AnyObject, prettyPrinted: Bool = false) -> String {
    let options = prettyPrinted ? JSONSerialization.WritingOptions.prettyPrinted : JSONSerialization.WritingOptions.init()
    
    if JSONSerialization.isValidJSONObject(value) {
        do
        {
            let data = try JSONSerialization.data(withJSONObject: value, options: options)
            
            if let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                return string as String
            }
        }
        catch
        {
            
        }
    }
    return ""
}

public extension UIWindow {
    var visibleViewController: UIViewController? {
        return UIWindow.getVisibleViewControllerFrom(self.rootViewController)
    }
    
    static func getVisibleViewControllerFrom(_ vc: UIViewController?) -> UIViewController? {
        if let nc = vc as? UINavigationController {
            return UIWindow.getVisibleViewControllerFrom(nc.visibleViewController)
        } else if let tc = vc as? UITabBarController {
            return UIWindow.getVisibleViewControllerFrom(tc.selectedViewController)
        } else {
            if let pvc = vc?.presentedViewController {
                return UIWindow.getVisibleViewControllerFrom(pvc)
            } else {
                return vc
            }
        }
    }
}

extension UIView  {
    func isScrolling () -> Bool {
        
        if let scrollView = self as? UIScrollView {
            if (scrollView.isDragging || scrollView.isDecelerating) {
                return true
            }
        }
        
        for subview in self.subviews {
            if ( subview.isScrolling() ) {
                return true
            }
        }
        return false
    }
}

extension UIViewController {
    func configureChildViewController(_ childController: UIViewController, onView: UIView?) {
        var holderView = self.view
        if let onView = onView {
            holderView = onView
        }
        addChild(childController)
        holderView?.addSubview(childController.view)
        constrainViewEqual(holderView!, view: childController.view)
        childController.didMove(toParent: self)
    }
    
    
    func constrainViewEqual(_ holderView: UIView, view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        //pin 100 points from the top of the super
        let pinTop = NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal,
                                        toItem: holderView, attribute: .top, multiplier: 1.0, constant: 0)
        let pinBottom = NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal,
                                           toItem: holderView, attribute: .bottom, multiplier: 1.0, constant: 0)
        let pinLeft = NSLayoutConstraint(item: view, attribute: .left, relatedBy: .equal,
                                         toItem: holderView, attribute: .left, multiplier: 1.0, constant: 0)
        let pinRight = NSLayoutConstraint(item: view, attribute: .right, relatedBy: .equal,
                                          toItem: holderView, attribute: .right, multiplier: 1.0, constant: 0)
        
        holderView.addConstraints([pinTop, pinBottom, pinLeft, pinRight])
    }
}

extension UIViewLoading where Self : UIView {
    
    // note that this method returns an instance of type `Self`, rather than UIView
    static func loadFromNib() -> Self {
        let nibName = "\(self)".split{$0 == "."}.map(String.init).last!
        let nib = UINib(nibName: nibName, bundle: nil)
        return nib.instantiate(withOwner: self, options: nil).first as! Self
    }
    
}

extension String {
    
    func stringByRemovingCharactersInSet(_ set:CharacterSet) -> String
    {
        return (self.components(separatedBy: set) as NSArray).componentsJoined(by: "")
    }
    
    func stringByCollapsingWhitespace() -> String
    {
        var components:NSArray = self.components(separatedBy: CharacterSet.whitespaces) as NSArray
        let predicate = NSPredicate(format: "self <> ''", argumentArray: nil)
        components = components.filtered(using: predicate) as NSArray
        return components.componentsJoined(by: " ")
    }
    
    subscript (i: Int) -> Character {
        let pos = min(i,self.distance(from: self.startIndex, to: self.index(before: self.endIndex)))
        return self[self.index(self.startIndex, offsetBy: pos)]
    }
    
    subscript (i: Int) -> String {
        let pos = min(i,self.distance(from: self.startIndex, to: self.index(before: self.endIndex)))
        return String(self[pos] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        let start = self.index(startIndex, offsetBy: r.lowerBound)
        let end = self.index(start, offsetBy: r.upperBound - r.lowerBound)
        return String(self[start..<end])
    }
    
    init(htmlEncodedString: String) {
        let cleanStr = htmlEncodedString.removingPercentEncoding
        self.init(stringLiteral: cleanStr!)
    }
    
    init(htmlStringToEncode: String) {
        let encoded = htmlStringToEncode.addingPercentEncoding(withAllowedCharacters: xmlAllowedSet)
        self.init(stringLiteral: encoded!)
    }
    
    var hexColor: UIColor {
        let hex = self.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return UIColor.clear
        }
        return UIColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
    
    
    //"#f00".hexColor       // r 1.0 g 0.0 b 0.0 a 1.0
    //"#be1337".hexColor    // r 0.745 g 0.075 b 0.216 a 1.0
    //"#12345678".hexColor  // r 0.204 g 0.337 b 0.471 a 0.071
    
    
    func split(_ len: Int) -> [String] {
        var currentIndex = 0
        var array = [String]()
        let length = self.count
        while currentIndex < length {
            let startIndex = self.index(self.startIndex, offsetBy: currentIndex)
            let bound = len - (length - currentIndex)
            let endIndex = self.index(startIndex, offsetBy:  bound > -1 ? length : len )
            //let substr = self.substring(with: startIndex..<endIndex)
            let substr = self[startIndex..<endIndex]
            array.append(String(substr))
            currentIndex += len
        }
        return array
    }
    
    
    var parseJSONString: AnyObject? {
        
        let data = self.data(using: String.Encoding.utf8, allowLossyConversion: false)
        
        if let jsonData = data {
            // Will return an object or nil if JSON decoding fails
            var ret:AnyObject? = nil
            do
            {
                ret = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.mutableContainers) as AnyObject
            }
            catch
            {
                
            }
            return ret
        } else {
            // Lossless conversion of the string was not possible
            return nil
        }
    }
    
    /// Returns a new string made by removing from right end of
    /// the `String` characters contained in a given character set.
    func trimRight( _ charSet: CharacterSet ) -> String {
        let theString: NSString = self as NSString
        var lastIdx = theString.length - 1
        
        while ( lastIdx > -1 && charSet.contains(UnicodeScalar(theString.character(at: lastIdx))!) )
        {
            lastIdx = lastIdx - 1
        }
        
        return theString.padding(toLength: lastIdx+1, withPad: " ", startingAt: 0) as String
    }
}

extension Int {
    func format(_ f: String) -> String {
        return NSString(format: "%\(f)d" as NSString, self) as String
    }
}

extension Double {
    func format(_ f: String) -> String {
        return NSString(format: "%\(f)f" as NSString, self) as String
    }
}

extension URL {
    
    func sameDocumentPathAs( _ url:URL? ) -> Bool {
        var ret = false
        
        if( self.pathComponents.count >= 2 && url?.pathComponents.count >= 2  )
        {
            let pathCount = self.pathComponents.count
            let testPathCount = url!.pathComponents.count
            
            if( (self.pathComponents[pathCount-1] == url!.pathComponents[testPathCount-1]) &&
                (self.pathComponents[pathCount-2] == url!.pathComponents[testPathCount-2])
                )
            {
                ret = true
            }
        }
        
        return( ret )
    }
}

extension FileManager {
    
    func directoryExists( _ url:URL? ) -> Bool {
        var dirExists:Bool =  false
        if(url != nil )
        {
            do{
                var rsrc: AnyObject?
                try (url! as NSURL).getResourceValue(&rsrc, forKey: URLResourceKey.isDirectoryKey)
                if let isDirectory = rsrc as? NSNumber {
                    if isDirectory == true {
                        dirExists = true
                    }
                }
            }catch _ {
                //print(error.localizedDescription)
            }
        }
        return dirExists
    }
    
    func fileExists(_ url:URL? ) -> Bool {
        var fileExists:Bool =  false
        if( url != nil )
        {
            do{
                var rsrc: AnyObject?
                try (url! as NSURL).getResourceValue(&rsrc, forKey: URLResourceKey.isRegularFileKey)
                if let isFile = rsrc as? NSNumber {
                    if isFile == true {
                        fileExists = true
                    }
                }
            }catch _ as NSError {
                //print( "\(url) error \(error.localizedDescription)" )
            }
        }
        return fileExists
    }
    
    func copyDirectory( _ srcFolder:URL?, destFolder:URL? )
    {
        do{
            if( !self.directoryExists(destFolder) )
            {
                do {
                    try self.createDirectory(at: destFolder!, withIntermediateDirectories: true, attributes: nil)
                } catch let error as NSError {
                    Logger.log("\(#function)  \(#file)  \(error.localizedDescription)")
                }
            }
            
            let files = try self.contentsOfDirectory(at: srcFolder!,
                                                          includingPropertiesForKeys: [URLResourceKey.isDirectoryKey, URLResourceKey.isReadableKey, URLResourceKey.contentModificationDateKey],
                                                          options: FileManager.DirectoryEnumerationOptions()) as [URL]
            
            for file in files
            {
                let srcURL = file
                let destURL = destFolder!.appendingPathComponent(file.lastPathComponent)
                //print( "copy \(srcURL) to \(destURL) ")
                try self.copyItem(at: srcURL, to: destURL)
            }
        } catch let error as NSError {
            Logger.log("\(#function)  \(#file)  \(error.localizedDescription)")
        }
    }
}

extension Foundation.Date
{
    init(dateString:String) {
        let dateStringFormatter = DateFormatter()
        if( dateString.count == 10 )
        {
            dateStringFormatter.dateFormat = "yyyy-MM-dd"
            dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
            let d = dateStringFormatter.date(from: dateString)!
            self.init(timeInterval: 0, since: d)
        }
        else if( dateString.count == 24)
        {
            Date.formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSX"
            Date.formatter.timeZone = TimeZone(secondsFromGMT: 0)
            //Date.formatter.calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierISO8601)!
            //Date.formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
            let d = Date.formatter.date(from: dateString)
            self.init(timeInterval: 0, since: d!)
        }
        else
        {
            let d = Date.formatter.date(from: dateString)
            self.init(timeInterval: 0, since: d!)
        }
    }
    
    struct Date {
        static let formatter = DateFormatter()
    }
    
    var formatted: String {
        Date.formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSX"
        Date.formatter.timeZone = TimeZone(secondsFromGMT: 0)
        Date.formatter.calendar = Calendar(identifier: Calendar.Identifier.iso8601)
        Date.formatter.locale = Locale(identifier: "en_US_POSIX")
        //var test = Date.formatter.dateFromString(Date.formatter.stringFromDate(self))
        return Date.formatter.string(from: self)
    }
    
    var datePretty: String {
        Date.formatter.dateFormat = "dd MMM yyyy"
        Date.formatter.timeZone = TimeZone(secondsFromGMT: 0)
        Date.formatter.calendar = Calendar(identifier: Calendar.Identifier.iso8601)
        Date.formatter.locale = Locale(identifier: "en_US_POSIX")
        //var test = Date.formatter.dateFromString(Date.formatter.stringFromDate(self))
        return Date.formatter.string(from: self)
    }
    
    var dateDDMM: String {
        Date.formatter.dateFormat = "ddMM"
        Date.formatter.timeZone = TimeZone(secondsFromGMT: 0)
        Date.formatter.calendar = Calendar(identifier: Calendar.Identifier.iso8601)
        Date.formatter.locale = Locale(identifier: "en_US_POSIX")
        //var test = Date.formatter.dateFromString(Date.formatter.stringFromDate(self))
        return Date.formatter.string(from: self)
    }
}

extension UIBarButtonItem {
    func addTargetForAction(_ target: AnyObject, action: Selector) {
        self.target = target
        self.action = action
    }
    
    override open func value(forUndefinedKey key: String) -> Any? {
        return nil
    }
}

extension UIColor {
    convenience init(hexString:String) {
        let hexString:NSString = hexString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) as NSString
        let nsHex = hexString as String
        let scanner = Scanner(string: nsHex )
        
        if (hexString.hasPrefix("#")) {
            scanner.scanLocation = 1
        }
        
        var color:UInt32 = 0
        scanner.scanHexInt32(&color)
        
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        
        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0
        
        self.init(red:red, green:green, blue:blue, alpha:1)
    }
    
    func toHexString() -> String {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        
        
        let ret = String.init(format: "#%06x", rgb)
        return ret
    }
}

extension UITextField
{
    
    func getRangeOfNearestWordFromSelectedPos() -> NSRange
    {
        // we need to return an NSRange which is different to a TextRange - NSRange counts unicode chars - TextRange treats each character as one char
        // http://stackoverflow.com/questions/27040924/nsrange-from-swift-range
        // and also
        // https://medium.com/@sorenlind/three-ways-to-enumerate-the-words-in-a-string-using-swift-7da5504f0062#.fdc38kxrq
        var ret = NSMakeRange(0, 0)
        
        if( self.selectedTextRange != nil && self.text != nil )
        {
            let nsText = self.text! as NSString
            let textRange = NSMakeRange(0, nsText.length)
            
            let beginning = self.beginningOfDocument
            let selectedRange = self.selectedTextRange
            let selectionStart = selectedRange!.start
            let selectionEnd = selectedRange!.end
            let location:NSInteger  = self.offset( from: beginning, to: selectionStart )
            let length:NSInteger = self.offset( from: selectionStart, to: selectionEnd )
            let range1 = NSMakeRange(location, length)
            
            var continuation = false
            var range2:NSRange = NSMakeRange(0, 0)
            nsText.enumerateSubstrings(in: textRange, options: .byWords /*stops with endings like / */, using: {
                (substring,_,inclusiveRange, _) in  // use the enclosing range with the line feed
                
                if( !continuation )
                {
                    range2 = inclusiveRange
                }
                else
                {
                    range2.length += inclusiveRange.length
                }
                
                continuation = false
                if( inclusiveRange.length > 1 ) // we may end with some characters that we want to include in the word like /
                {
                    let lastChar = nsText.character(at: inclusiveRange.location+(inclusiveRange.length-1))
                    
                    if( lastChar > 0 )
                    {
                        let ch = Character(UnicodeScalar(lastChar)!)
                        let str = String(ch)
                        if( !str.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty )
                        {
                            continuation = true
                        }
                    }
                }
                
                if (
                    (range1.location >= range2.location &&
                        range1.location + range1.length <= range2.location + range2.length)  )
                {
                    ret = NSMakeRange(range2.location, range2.length)
                    //print( "ret: \(range2.location) - \(range2.length)" )
                }
            })
        }
        
        return ret
    }
}

extension UITextView
{
    func getLineCount() -> Int
    {
        // we need to return an NSRange which is different to a TextRange - NSRange counts unicode chars - TextRange treats each character as one char
        // http://stackoverflow.com/questions/27040924/nsrange-from-swift-range
        let nsText = self.attributedText.string as NSString
        let textRange = NSMakeRange(0, nsText.length)
        
        //let attributedString = NSMutableAttributedString(string: text)
        var lineCnt = 0
        nsText.enumerateSubstrings(in: textRange, options: NSString.EnumerationOptions(), using: {
            (substring,_,range2, _) in  // use the enclosing range with the line feed
            lineCnt += 1
        })
        
        return lineCnt
    }
    
    func selectEndOfDoc()
    {
        /*
        let end:UITextPosition  = self.endOfDocument
        let newCursorFromPosition = self.position(from: end, offset:0)
        let newCursorToPosition = self.position(from: end, offset:0)
        if( newCursorFromPosition != nil )
        {
            let newSelectedRange = textRange(from: newCursorFromPosition!, to:newCursorToPosition!)
            self.selectedTextRange = newSelectedRange
        }*/
        
        self.selectedTextRange = self.textRange(from: self.endOfDocument, to: self.endOfDocument)
    }
    
    func getRangeForLineIndex( _ lineNumber:Int ) -> NSRange
    {
        // we need to return an NSRange which is different to a TextRange - NSRange counts unicode chars - TextRange treats each character as one char
        // http://stackoverflow.com/questions/27040924/nsrange-from-swift-range
        var ret = NSMakeRange(0, 0)
        
        let nsText = self.attributedText.string as NSString
        let textRange = NSMakeRange(0, nsText.length)
        
        //let attributedString = NSMutableAttributedString(string: text)
        var lineCnt = 0
        nsText.enumerateSubstrings(in: textRange, options: NSString.EnumerationOptions(), using: {
            (substring,_,range2, stop) in  // use the enclosing range with the line feed
            
            if ( lineNumber == lineCnt )
            {
                //retval = YES;
                //print( "\(lineCnt) - \(range2.location)" )
                ret = NSMakeRange(range2.location, range2.length)
                stop.pointee = true
            }
            lineCnt += 1
        })
        
        return ret
    }
    
    
    func getLineNumberFromSelectedPos() -> Int
    {
        // we need to return an NSRange which is different to a TextRange - NSRange counts unicode chars - TextRange treats each character as one char
        // http://stackoverflow.com/questions/27040924/nsrange-from-swift-range
        
        var ret = -1
        let nsText = self.attributedText.string as NSString
        let textRange = NSMakeRange(0, nsText.length)
        let range1 = self.selectedRange
        var lineCount = 0
        nsText.enumerateSubstrings(in: textRange, options: NSString.EnumerationOptions(), using: {
            (_,_,range2, stop) in  // use the enclosing range with the line feed
            
            if (range1.location >= range2.location &&
                range1.location + range1.length <= range2.location + range2.length  )
            {
                ret = lineCount
                stop.pointee = true
            }
            lineCount += 1
        })
        
        return ret
    }
    
    
    func getLineRangeFromSelectedPos() -> NSRange
    {
        // we need to return an NSRange which is different to a TextRange - NSRange counts unicode chars - TextRange treats each character as one char
        // http://stackoverflow.com/questions/27040924/nsrange-from-swift-range
        var ret = NSMakeRange(0, 0)
        
        let nsText = self.attributedText.string as NSString
        let textRange = NSMakeRange(0, nsText.length)
        let range1 = self.selectedRange
        nsText.enumerateSubstrings(in: textRange, options: NSString.EnumerationOptions(), using: {
            (substring,_,range2, stop) in  // use the enclosing range with the line feed
            
            if (range1.location >= range2.location &&
                range1.location + range1.length <= range2.location + range2.length  )
            {
                //retval = YES;
                //print( "\(lineCnt) - \(range2.location)" )
                ret = NSMakeRange(range2.location, range2.length)
                stop.pointee = true
            }
        })
        
        return ret
    }
    
    func getRangeOfNearestWordFromSelectedPos() -> NSRange
    {
        // we need to return an NSRange which is different to a TextRange - NSRange counts unicode chars - TextRange treats each character as one char
        // http://stackoverflow.com/questions/27040924/nsrange-from-swift-range
        // and also
        // https://medium.com/@sorenlind/three-ways-to-enumerate-the-words-in-a-string-using-swift-7da5504f0062#.fdc38kxrq
        var ret = NSMakeRange(0, 0)
        
        let nsText = self.attributedText.string as NSString
        let textRange = NSMakeRange(0, nsText.length)
        let range1 = self.selectedRange
        
        var continuation = false
        var range2:NSRange = NSMakeRange(0, 0)
        nsText.enumerateSubstrings(in: textRange, options: .byWords /*stops with endings like / */, using: {
            (substring,_,inclusiveRange, _) in  // use the enclosing range with the line feed
            
            if( !continuation )
            {
                range2 = inclusiveRange
            }
            else
            {
                range2.length += inclusiveRange.length
            }
            
            continuation = false
            if( inclusiveRange.length > 1 ) // we may end with some characters that we want to include in the word like /
            {
                let lastChar = nsText.character(at: inclusiveRange.location+(inclusiveRange.length-1))
                
                if( lastChar > 0 )
                {
                    let ch = Character(UnicodeScalar(lastChar)!)
                    let str = String(ch)
                    if( !str.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty )
                    {
                        continuation = true
                    }
                }
            }
            
            if (
                (range1.location >= range2.location &&
                    range1.location + range1.length <= range2.location + range2.length)  )
            {
                ret = NSMakeRange(range2.location, range2.length)
                //print( "ret: \(range2.location) - \(range2.length)" )
            }
        })
        
        return ret
    }
    
    func getRangeOfString( _ str:String ) -> NSRange
    {
        // we need to return an NSRange which is different to a TextRange - NSRange counts unicode chars - TextRange treats each character as one char
        // http://stackoverflow.com/questions/27040924/nsrange-from-swift-range
        var ret = NSMakeRange(0, 0)
        
        let nsText = self.attributedText.string as NSString
        let textRange = NSMakeRange(0, nsText.length)
        
        //let range1 = self.selectedRange
        nsText.enumerateSubstrings(in: textRange, options: .byWords, using: {
            (substring,_,range2, stop) in  // use the enclosing range with the line feed
            
            if( str == substring )
            {
                //retval = YES;
                //print( "\(lineCnt) - \(range2.location)" )
                ret = NSMakeRange(range2.location, range2.length)
                stop.pointee = true
            }
        })
        
        return ret
    }
    
    func setSelectedLine( _ lineNumber:Int, returnContent:Bool = false ) -> String?
    {
        var ret:String? = nil
        
        let selRange = self.getRangeForLineIndex( lineNumber )
        self.selectedRange = selRange
        if( returnContent && selRange.length > 0 )
        {
            ret = self.text(in: self.selectedTextRange!)
        }
        
        return( ret )
    }
    
    func mark( _ backColor:UIColor, foreColor:UIColor = UIColor.white, fontSize:CGFloat = 18.0, bold:Bool = false )
    {
        var range:NSRange = NSMakeRange(0, 0)
        
        if(  self.selectedRange.length < 2 ) // single line
        {
            range = self.getLineRangeFromSelectedPos()
        }
        else
        {
            range = self.selectedRange
        }
        
        let attribText:NSMutableAttributedString = NSMutableAttributedString(attributedString: self.attributedText)
        attribText.fixAttributes(in: range)
        attribText.addAttribute(NSAttributedString.Key.backgroundColor, value: backColor, range: range )
        attribText.addAttribute(NSAttributedString.Key.foregroundColor, value: foreColor, range: range )
        if( bold == false )
        {
            attribText.addAttribute(NSAttributedString.Key.font, value: UIFont(name:"Courier", size: fontSize )!, range: range )
        }
        else
        {
            attribText.addAttribute(NSAttributedString.Key.font, value: UIFont(name:"Courier-Bold", size: fontSize )!, range: range )
        }
        
        self.attributedText = attribText
    }
    
    func markOff()
    {
        let curSel = self.selectedRange
        let attribText:NSMutableAttributedString = NSMutableAttributedString(attributedString: self.attributedText)
        let range = self.getLineRangeFromSelectedPos()
        attribText.removeAttribute(NSAttributedString.Key.backgroundColor, range: range )
        attribText.removeAttribute(NSAttributedString.Key.font, range: range )
        attribText.addAttribute(NSAttributedString.Key.font, value: UIFont(name:"Courier", size: 18.0 )!, range: range )
        self.attributedText = attribText
        self.selectedRange = curSel
    }
}

extension Dictionary {
    func sortedKeys(_ isOrderedBefore:(Key,Key) -> Bool) -> [Key] {
        return Array(self.keys).sorted(by: isOrderedBefore)
    }
    
    // Slower because of a lot of lookups, but probably takes less memory (this is equivalent to Pascals answer in an generic extension)
    func sortedKeysByValue(_ isOrderedBefore:(Value, Value) -> Bool) -> [Key] {
        return sortedKeys {
            isOrderedBefore(self[$0]!, self[$1]!)
        }
    }
    
    // Faster because of no lookups, may take more memory because of duplicating contents
    func keysSortedByValue(_ isOrderedBefore:(Value, Value) -> Bool) -> [Key] {
        return Array(self)
            .sorted() {
                let (_, lv) = $0
                let (_, rv) = $1
                return isOrderedBefore(lv, rv)
            }
            .map {
                let (k, _) = $0
                return k
        }
    }
}
