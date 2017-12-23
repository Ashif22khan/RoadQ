//
//  RCModel.swift
//  RoadConditions
//
//  Created by Khan, Ashif on 2/24/17.
//  Copyright © 2017 Local. All rights reserved.
//

import Foundation
@objc public enum RCType: Int{
    case Smooth
    case Rough
    case Hump
}
@objc public class RCModel : NSObject {
    public var type: RCType = .Smooth
    public var tripID: String = ""
    public var pattern: String = ""
    public var confidence: Float = 0.0
    public var course: Float = 0.0
    public var latitude: Float = 0.0
    public var longitude: Float = 0.0
    public var timestamp: Float = 0.0
}