//
//  Entity+CoreDataProperties.swift
//  RoadQ
//
//  Created by ashif khan on 18/11/17.
//  Copyright © 2017 ashif khan. All rights reserved.
//
//

import Foundation
import CoreData


extension Entity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Entity> {
        return NSFetchRequest<Entity>(entityName: "Entity")
    }

    @NSManaged public var confidence: Double
    @NSManaged public var course: String?
    @NSManaged public var location: String?
    @NSManaged public var pattern: String?
    @NSManaged public var timestamp: Double
    @NSManaged public var tripId: String?
    @NSManaged public var type: String?

}
