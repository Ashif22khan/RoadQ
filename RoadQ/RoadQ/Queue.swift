//
//  Queue.swift
//  MotionHump
//
//  Created by Ashif Khan on 24/07/16.
//  Copyright © 2016 Local. All rights reserved.
//

import Foundation
public struct Queue<T> {
    private var array = [T]()
    //private let accessQueue = dispatch_queue_create("SynchronizedQueueAccess", DISPATCH_QUEUE_SERIAL)

    private var _cap:Int
    public var capacity:Int{
        set{
            _cap = newValue
        }
        get{
            return _cap
        }
    }
    public var count: Int {
        return array.count
    }
    
    public var isEmpty: Bool {
        return array.isEmpty
    }
    
    public mutating func enqueue(element: T) {
        array.append(element)
        if array.count > _cap {
            let _ = self.dequeue()
        }
    }
    
    public mutating func dequeue() -> T? {
        if isEmpty {
            return nil
        } else {
            return array.removeFirst()
        }
    }
    public init(cap:Int){
        self._cap = cap;
    }
    public func peek() -> T? {
        return array.first
    }
    public func arrayFromQueue() -> [T] {
        return array
    }
}
