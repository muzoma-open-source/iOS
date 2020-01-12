//
//  DragView.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 20/03/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//

import Foundation
import UIKit
import CoreText

class DragView : UIView {
    //var fillColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0).CGColor
    //var fillColor = UIColor.clearColor().CGColor
    var boundingBoxColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0).cgColor
    
    fileprivate var lab:UILabel! = nil
    fileprivate var _text = ""
    var text:String
    {
        set( newText )
        {
            _text = newText
            lab.text = _text
            lab.sizeToFit()
            lab.layoutIfNeeded()
            self.setNeedsDisplay()
        }
        
        get
        {
            return(_text)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame rect: CGRect) {
        super.init(frame: rect)
        let dragRect = CGRect( x: 0, y: 0, width: 4, height: 4)
        let dragCorner = UIImage( named: "dragCorner.png")
        let dragCornerView = UIImageView(image: dragCorner!)
        dragCornerView.frame = dragRect
        self.addSubview(dragCornerView)
        
        let labelRect = CGRect( x: 0, y: 4, width: 10, height: 12)
        lab = UILabel(frame: labelRect)
        lab.textColor = UIColor.black
        lab.backgroundColor = UIColor.yellow
        lab.textAlignment = NSTextAlignment.left
        lab.text = ""
        lab.sizeToFit()
        lab.layoutIfNeeded()
        self.addSubview(lab)
    }
    
    
    /*
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
    }*/
    /*
    override func drawRect(rect: CGRect) {
        /*let context = UIGraphicsGetCurrentContext()
        CGContextClearRect(context, rect)*/
        super.drawRect(rect)
        self.opaque = false
        self.backgroundColor = UIColor.clearColor()
        let viewWidth = CGRectGetWidth(self.bounds)
        let viewHeight = CGRectGetHeight(self.bounds)
        /*
        // fill
        CGContextSetFillColorWithColor(context, fillColor)
        CGContextFillRect(context, CGRectMake(0, 0, viewWidth, viewHeight))
*/
        /*
        //dash box
        CGContextStrokePath(context)
        CGContextMoveToPoint(context, 3, 1)
        CGContextAddLineToPoint(context, 3, 1)
        CGContextSetLineDash(context, 0, [4], 1)
        CGContextSetStrokeColorWithColor(context, boundingBoxColor)
        CGContextSetLineWidth(context, 3.0)
        CGContextStrokeRect(context, self.bounds)
        */
        
        let dragRect = CGRect( x: rect.minX, y: rect.minY, width: 4, height: 4)
        let dragCorner = UIImage( named: "dragCorner.png")
        let dragCornerView = UIImageView(image: dragCorner!)
        dragCornerView.frame = dragRect
        self.addSubview(dragCornerView)
        
        let labelRect = CGRect( x: rect.minX + 2, y: rect.minY + 2, width: rect.width, height: 12)
        let lab:UILabel = UILabel(frame: labelRect)
        lab.text = _text
        lab.textAlignment = NSTextAlignment.Left
        self.addSubview(lab)
        

        
        print( "drawRect DragView")
    }*/
}
