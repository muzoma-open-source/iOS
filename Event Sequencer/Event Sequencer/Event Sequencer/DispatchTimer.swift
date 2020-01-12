//
//  DispatchTimer.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 20/02/2016.
//  Copyright © 2016 Muzoma.com. All rights reserved.
//


import Foundation

/*
open class DispatchTimer: Equatable {
    
    public enum Status {
        case notStarted
        case active
        case paused
        case done
        case invalidated
    }
    
    //fileprivate var _timerSource:DispatchSource
    fileprivate var _timerSource:DispatchSourceTimer
    fileprivate var _isInvalidating:Bool = false
    //either startDate or lastFire or lastResume date
    fileprivate var _lastActiveDate:Date?
    fileprivate var _elapsedAccumulatedTime: Double = Double(0)
    
    
    //MARK: PROPERTIES
    
    open fileprivate(set) var remainingFireCount:UInt
    open fileprivate(set) var status:DispatchTimer.Status = .notStarted
    open fileprivate(set) var startDate:Date?
    
    open let queue:DispatchQueue
    open let isFinite:Bool
    open let fireCount:UInt
    open let interval:UInt
    open let invocationBlock:(_ timer:DispatchTimer) -> Void
    
    open var completionHandler:((_ timer:DispatchTimer) -> Void)?
    open var userInfo:Any?
    
    open var valid:Bool { return (self.status != .done || self.status != .invalidated) }
    open var started:Bool { return (self.status != .notStarted) }
    open var startAbsoluteTime:Double? { return (startDate != nil) ? self.startDate!.timeIntervalSince1970 : nil }
    
    
    
    //all parameters are in milliseconds
    fileprivate func _setupTimerSource(_ timeInterval:UInt, startOffset:UInt, leeway: UInt) {

        /*
        _timerSource.scheduleRepeating(deadline:  DispatchTime(uptimeNanoseconds: UInt64(startOffset) * NSEC_PER_MSEC), interval: Double(timeInterval) )
        */
        _timerSource.schedule(deadline:  DispatchTime(uptimeNanoseconds: UInt64(startOffset) * NSEC_PER_MSEC), repeating: true, interval: Double(timeInterval) )
        _timerSource.setEventHandler {
            
            self._elapsedAccumulatedTime = 0
            self._lastActiveDate = Date()
            
            self.invocationBlock(self)
            if(self.isFinite){
                
                self.remainingFireCount -= 1
                if(self.remainingFireCount == 0){
                    self._timerSource.cancel()
                }
            }
        }
        
        _timerSource.setCancelHandler{
            if(self._isInvalidating){
                self.status = .invalidated
                self._isInvalidating = false
            } else {
                self.status = .done
            }
            
            self.completionHandler?(self)
        }
    }
    
    //MARK:
    
    public init(milliseconds:UInt, startOffset:Int, tolerance:UInt, queue: DispatchQueue, isFinite:Bool, fireCount:UInt, userInfo:Any?, completionHandler:((_ timer:DispatchTimer) -> Void)?,invocationBlock: @escaping (_ timer:DispatchTimer) -> Void) {
        
        self.queue = queue
        
        self.userInfo = userInfo
        self.isFinite = isFinite
        self.fireCount = fireCount;
        self.remainingFireCount = self.fireCount
        
        self.userInfo = userInfo
        self.completionHandler = completionHandler
        self.invocationBlock = invocationBlock
        
        self.interval = milliseconds
        _timerSource = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: 0), queue: queue)
  
        let offset:Int = ( (startOffset < 0) && (abs(startOffset) > Int(self.interval)) ) ? -Int(self.interval) : startOffset
        _setupTimerSource(self.interval, startOffset: UInt( Int(self.interval) + offset), leeway: tolerance)
    }
    
    
    open class func timerWithTimeInterval(milliseconds: UInt, queue: DispatchQueue, repeats: Bool, invocationBlock: @escaping (_ timer:DispatchTimer) -> Void) -> DispatchTimer {
        
        
        let timer = DispatchTimer(milliseconds: milliseconds, startOffset: 0, tolerance: 0, queue: queue, isFinite: !repeats, fireCount: (repeats) ? 0 : 1, userInfo: nil, completionHandler:nil, invocationBlock: invocationBlock)
        return timer
    }
    
    open class func timerWithTimeInterval(milliseconds: UInt, queue: DispatchQueue, fireCount: UInt, invocationBlock: @escaping (_ timer:DispatchTimer) -> Void) -> DispatchTimer {
        
        let timer = DispatchTimer(milliseconds: milliseconds, startOffset: 0, tolerance: 0, queue: queue, isFinite: true, fireCount: fireCount, userInfo: nil, completionHandler:nil, invocationBlock: invocationBlock)
        return timer
    }
    
    open class func scheduledTimerWithTimeInterval(milliseconds: UInt, queue: DispatchQueue, repeats: Bool, invocationBlock: @escaping (_ timer:DispatchTimer) -> Void) -> DispatchTimer {
        
        let timer = DispatchTimer(milliseconds: milliseconds, startOffset: 0, tolerance: 0, queue: queue, isFinite: !repeats, fireCount: (repeats) ? 0 : 1, userInfo: nil, completionHandler:nil, invocationBlock: invocationBlock)
        timer.start()
        return timer
    }
    
    open class func scheduledTimerWithTimeInterval(milliseconds: UInt, queue: DispatchQueue, fireCount: UInt, invocationBlock: @escaping (_ timer:DispatchTimer) -> Void) -> DispatchTimer {
        
        let timer = DispatchTimer(milliseconds: milliseconds, startOffset: 0, tolerance: 0, queue: queue, isFinite: true, fireCount: fireCount, userInfo: nil, completionHandler:nil, invocationBlock: invocationBlock)
        timer.start()
        return timer
    }
    
    open class func scheduledTimerWithTimeInterval(milliseconds:UInt, startOffset:Int, tolerance:UInt, queue: DispatchQueue, isFinite:Bool, fireCount:UInt, userInfo:Any?, completionHandler:((_ timer:DispatchTimer) -> Void)?, invocationBlock: @escaping (_ timer:DispatchTimer) -> Void) -> DispatchTimer {
        
        let timer = DispatchTimer(milliseconds: milliseconds, startOffset: startOffset, tolerance: tolerance, queue: queue, isFinite: isFinite, fireCount: fireCount, userInfo: userInfo, completionHandler:completionHandler, invocationBlock: invocationBlock)
        timer.start()
        return timer
    }
    
    //MARK: METHODS
    
    open func start(){
        
        if (!self.started){
            _timerSource.resume()
            
            self.startDate = Date()
            _lastActiveDate = self.startDate
            self.status = .active
        }
    }
    
    open func pause(){
        
        if (self.status == .active){
            
            _timerSource.setCancelHandler{ }
            _timerSource.cancel()
            self.status = .paused
            
            let pauseDate = Date()
            
            _elapsedAccumulatedTime += (pauseDate.timeIntervalSince1970 - _lastActiveDate!.timeIntervalSince1970) * 1000
            
            //print( "%ld milliseconds elapsed", UInt(_elapsedAccumulatedTime))
        }
    }
    
    open func resume(){
        
        if (self.status == .paused){
            
            //print( "%ld milliseconds left till fire", self.interval - UInt(_elapsedAccumulatedTime))
            
            _timerSource = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: 0), queue: queue) /*Migrator FIXME: Use DispatchSourceTimer to avoid the cast*/ as! DispatchSource
            _setupTimerSource(self.interval, startOffset: self.interval - UInt(_elapsedAccumulatedTime), leeway: 0)
            _timerSource.resume()
            
            _lastActiveDate = Date()
            self.status = .active
        }
    }
    
    open func invalidate(_ handler:((_ timer:DispatchTimer)-> Void)? = nil){
        
        _isInvalidating = true;
        
        // reassigning completionHandler if has been passed(non-nil)
        if let handler = completionHandler {
            self.completionHandler = handler
        }
        
        _timerSource.cancel()
    }
}

//MARK: Equatable
public func ==(lhs: DispatchTimer, rhs: DispatchTimer) -> Bool {
    return (lhs._timerSource === rhs._timerSource)
}
*/
