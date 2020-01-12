//
//  PopupQueue.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 05/11/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//

import Foundation
import UIKit
import CoreText

/// A first-in/first-out queue of unconstrained size
/// - Complexity: push is O(1), pop is O(`count`)
public struct Queue<T>: ExpressibleByArrayLiteral {
    /// backing array store
    public fileprivate(set) var elements: Array<T> = []
    
    /// introduce a new element to the queue in O(1) time
    public mutating func push(_ value: T) { elements.append(value) }
    
    /// remove the front of the queue in O(`count` time
    public mutating func pop() -> T { return elements.removeFirst() }
    
    /// test whether the queue is empty
    public var isEmpty: Bool { return elements.isEmpty }
    
    /// queue size, computed property
    public var count: Int { return elements.count }
    
    /// offer `ArrayLiteralConvertible` support
    public init(arrayLiteral elements: T...) { self.elements = elements }
}

struct popupParams {
    var viewControllerPesenting : UIViewController
    var viewControllerToPresent : UIViewController
    var animated : Bool
    var completion: (() -> Void)?
}

let globalPopupManager = popupManager()

class popupManager
{
    var popupQ:Queue<popupParams> = Queue<popupParams>()
    /*let popupQueue:DispatchQueue = DispatchQueue( label: "popupQueue",
                                                             attributes: DispatchQoS(
                                                                _FIXME_useThisWhenCreatingTheQueueAndRemoveFromThisCall: DispatchQueue.Attributes(),
                                                                qosClass: DispatchQoS.QoSClass.background,
                                                                relativePriority: 0))*/
    // TODO 2-3
    let popupQueue:DispatchQueue = DispatchQueue( label: "popupQueue" )
    
    var _popupTimer:RepeatingTimer! = nil
    
    init()
    {
    }
    
    deinit
    {
        _popupTimer?.invalidate()
        _popupTimer = nil
    }
    
    fileprivate var _current : popupParams! = nil
    fileprivate var _presentingVC: UIViewController? = nil
    fileprivate var _processing = false
    
    func tick()
    {
        if( !popupQ.isEmpty && !_processing)
        {
            _processing = true
            let keyWind = UIApplication.shared.keyWindow!
            _presentingVC = keyWind.visibleViewController
            
            if( _presentingVC?.parent != nil ) // current vc is not a standalone dialog ie another popup
            {
                if( _presentingVC != nil && _presentingVC?.presentedViewController == nil )
                {
                    _current = popupQ.pop()
                    _presentingVC!.present(_current.viewControllerToPresent, animated: _current.animated, completion:
                        {
                            self._processing = false
                        }
                    )
                }
                else
                {
                    _processing = false
                }
            }
            else
            {
                _processing = false
            }
            
            if( !_processing )
            {
                if( _popupTimer != nil && popupQ.isEmpty )
                {
                    _popupTimer.pause()
                    _popupTimer.invalidate()
                    _popupTimer = nil
                }
            }
        }
    }
    
    func AddPopup( _ params:popupParams )
    {
        popupQ.push(params)
        
        if(_popupTimer == nil )
        {
            _popupTimer = RepeatingTimer(timeInterval: 0.250, queue: popupQueue)
            _popupTimer.eventHandler =
            {
                DispatchQueue.main.async(execute: {
                    self.tick()
                })
            }
        }
        
        if( !_popupTimer.started )
        {
            _popupTimer.start()
        }
    }
}


extension UIViewController {
    
    public func queuePopup(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)
    {
        let params = popupParams.init(viewControllerPesenting:self, viewControllerToPresent: viewControllerToPresent, animated: flag, completion: completion)
        globalPopupManager.AddPopup( params )
    }
}
