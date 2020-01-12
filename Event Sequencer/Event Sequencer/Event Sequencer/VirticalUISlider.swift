//
//  VirticalUISlider.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 08/06/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//

import UIKit

class VirticalUISlider: UISlider {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
/*    {
 didSet{
 sliderVolume.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))
 
 }
 }*/
 
    static let tform:CGFloat = (.pi / 2) * -1
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        //var ratio : CGFloat = CGFloat ( sender.value + 0.5)
        let thumbImage : UIImage = UIImage(named: "BlueAndYellowDot16x16")!
        _ = CGSize( width: thumbImage.size.width, height: thumbImage.size.height )
        self.setThumbImage( thumbImage, for: UIControl.State() )
        self.backgroundColor =  UIColor.black.withAlphaComponent(0.5)
        self.transform = CGAffineTransform(rotationAngle: VirticalUISlider.tform)
    }
    
    var thumbTouchSize : CGSize = CGSize(width: 20, height: 15)
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let bounds = self.bounds.insetBy(dx: -thumbTouchSize.width, dy: -thumbTouchSize.height);
        return bounds.contains(point);
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let thumbPercent = (value - minimumValue) / (maximumValue - minimumValue)
        let thumbSize = thumbImage(for: UIControl.State())!.size.height
        let thumbPos = CGFloat(thumbSize) + (CGFloat(thumbPercent) * (CGFloat(bounds.size.width) - (2 * CGFloat(thumbSize))))
        let touchPoint = touch.location(in: self)
        
        return (touchPoint.x >= (thumbPos - thumbTouchSize.width) &&
            touchPoint.x <= (thumbPos + thumbTouchSize.width))
    }
}
