//
//  RepeatingTimer.swift
//  Muzoma
//
//  Created by Matthew Hopkins on 22/08/2018.
//  Copyright © 2018 Muzoma.com. All rights reserved.
//

import Foundation

/// RepeatingTimer mimics the API of DispatchSourceTimer but in a way that prevents
/// crashes that occur from calling resume multiple times on a timer that is
/// already resumed (noted by https://github.com/SiftScience/sift-ios/issues/52
class RepeatingTimer {
    
    let timeInterval: TimeInterval
    let queue: DispatchQueue!
    var _valid: Bool = true
    
    init(timeInterval: TimeInterval, queue:DispatchQueue! = nil) {
        self.timeInterval = timeInterval
        self.queue = queue
    }
    
    public var started: Bool = false
    
    private lazy var timer: DispatchSourceTimer! = nil
    
    var eventHandler: (() -> Void)?
    
    private enum State {
        case suspended
        case resumed
    }
    
    private var state: State = .suspended
    
    func start()
    {
        started = true
        timer = {
            let t = DispatchSource.makeTimerSource( queue: queue )
            t.schedule(deadline: .now() + self.timeInterval, repeating: self.timeInterval)
            t.setEventHandler(handler: { [weak self] in
                self?.eventHandler?()
            })
            return t
        }()
        timer.resume()
    }
    
    func cleanup()
    {
        if( _valid )
        {
            _valid = false
            if( !timer.isCancelled )
            {
                timer.setEventHandler {}
                timer.cancel()
            }
            /*
             If the timer is suspended, calling cancel without resuming
             triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
             */
            //resume()
            eventHandler = nil
        }
    }
    
    deinit {
        cleanup()
    }
    
    func resume() {
        if state == .resumed {
            return
        }
        state = .resumed
        timer.resume()
    }
    
    func pause() {
        self.suspend()
    }
    
    func invalidate() {
        self.cleanup()
    }
    
    func suspend() {
        if state == .suspended {
            return
        }
        state = .suspended
        timer.suspend()
    }
}
