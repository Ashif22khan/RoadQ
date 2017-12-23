//
//  RCData+CoreDataProperties.swift
//  RoadConditions
//
//  Created by Khan, Ashif on 2/15/17.
//  Copyright © 2017 Local. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension RCData {

    @NSManaged var confidence: NSNumber?
    @NSManaged var location: String?
    @NSManaged var course: String?
    @NSManaged var pattern: String?
    @NSManaged var tripId: String?
    @NSManaged var type: String?
    @NSManaged var timestamp: NSNumber?

}
