//
//  ExtScrollUIToolbar
//  Muzoma
//
//  Created by Matthew Hopkins on 08/06/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//

import UIKit

class ExtScrollUIToolbar : UIToolbar, UIGestureRecognizerDelegate { // UIToolbar {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupExtraControls( self.frame )
    }
    
    override init(frame rect: CGRect) {
        super.init(frame: rect)
        setupExtraControls( self.frame )
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    override func valueForKey(key: String) -> AnyObject? {
        var ret:AnyObject? = nil
        if( key=="_title" )
        {
            ret = "Scroller"
        }
        else
        {
            ret = super.valueForKey(key)
        }
        
        return( ret )
    }
    
    func setupExtraControls( rect: CGRect! = nil )
    {
        self.userInteractionEnabled = true
        
        let scrollRect = CGRect( x: 0, y: rect.height-20, width: rect.width, height: 10)
        self.frame.size = CGSizeMake(rect.width, rect.height+10)
        //self.bounds = self.frame
        //self.clipsToBounds = true
        let scroller = UISlider(frame: scrollRect)
    
        //var ratio : CGFloat = CGFloat ( sender.value + 0.5)
        var thumbImage : UIImage = UIImage(named: "BlueAndYellowDot16x16")!
        var size = CGSizeMake( thumbImage.size.width, thumbImage.size.height )
        scroller.setThumbImage( thumbImage, forState: UIControlState.Normal )
        scroller.enabled = true
        scroller.hidden = false
        //scroller.setValue()
        scroller.autoresizingMask = [.FlexibleWidth]
        scroller.userInteractionEnabled = true
        scroller.multipleTouchEnabled = true
        scroller.sizeToFit()
        scroller.layoutIfNeeded()
        self.addSubview(scroller)
    
        
        scroller.value = 0.0
        /*
        let panScroller = UIPanGestureRecognizer(target:self, action:#selector(ExtScrollUIToolbar.panScroller(_:)))
        panScroller.maximumNumberOfTouches = 1
        panScroller.minimumNumberOfTouches = 1
        panScroller.delegate = self
        scroller.addGestureRecognizer(panScroller)
*/
        /*
         let dragRect = CGRect( x: 0, y: 0, width: 4, height: 4)
         let dragCorner = UIImage( named: "dragCorner.png")
         let dragCornerView = UIImageView(image: dragCorner!)
         dragCornerView.frame = dragRect
         self.addSubview(dragCornerView)
         
         let labelRect = CGRect( x: 0, y: 4, width: 10, height: 12)
         lab = UILabel(frame: labelRect)
         lab.textColor = UIColor.blackColor()
         lab.backgroundColor = UIColor.yellowColor()
         lab.textAlignment = NSTextAlignment.Left
         lab.text = ""
         lab.sizeToFit()
         lab.layoutIfNeeded()
         self.addSubview(lab)*/

        
    }
    
    func panScroller( rec:UIPanGestureRecognizer ) {
        
        let p:CGPoint = rec.locationInView( self )
        
        //var center:CGPoint = CGPointZero
        // rec.locationInView(self))
        print( "Pan scroller \(p)" )
    }

    /*
    let img = UIImage( named: "dragCorner.png")
    override func thumbImageForState(state: UIControlState) -> UIImage? {
        return( img )
    }
    
    var thumbTouchSize : CGSize = CGSizeMake(40, 40)
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        let bounds = CGRectInset(self.bounds, -thumbTouchSize.width, -thumbTouchSize.height);
        return CGRectContainsPoint(bounds, point);
    }
    
    override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        let thumbPercent = (value - minimumValue) / (maximumValue - minimumValue)
        let thumbSize = thumbImageForState(UIControlState.Normal)!.size.height
        let thumbPos = CGFloat(thumbSize) + (CGFloat(thumbPercent) * (CGFloat(bounds.size.width) - (2 * CGFloat(thumbSize))))
        let touchPoint = touch.locationInView(self)
        
        return (touchPoint.x >= (thumbPos - thumbTouchSize.width) &&
            touchPoint.x <= (thumbPos + thumbTouchSize.width))
    }*/
}
/*
@objc class ExtUISlider : UISlider {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    var thumbTouchSize : CGSize = CGSizeMake(50, 50)
    
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        let bounds = CGRectInset(self.bounds, -thumbTouchSize.width, -thumbTouchSize.height);
        return CGRectContainsPoint(bounds, point);
    }
    
    override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        let thumbPercent = (value - minimumValue) / (maximumValue - minimumValue)
        let thumbSize = thumbImageForState(UIControlState.Normal)!.size.height
        let thumbPos = CGFloat(thumbSize) + (CGFloat(thumbPercent) * (CGFloat(bounds.size.width) - (2 * CGFloat(thumbSize))))
        let touchPoint = touch.locationInView(self)
        
        return (touchPoint.x >= (thumbPos - thumbTouchSize.width) &&
            touchPoint.x <= (thumbPos + thumbTouchSize.width))
    }
}*/
