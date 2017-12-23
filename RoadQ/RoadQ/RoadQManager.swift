//
//  RoadConditionsManager.swift
//  RoadConditions
//
//  Created by Ashif Khan on 16/01/17.
//  Copyright © 2017 Local. All rights reserved.
//

import UIKit
import CoreMotion
import CoreData

// MARK: - Protocol for manager
@objc public protocol RoadQManagerDelegate {
    func significantConfidence(confidence:Double, data:[String:String])
    func predictionStream(confidence:Double)
    func networkReady()
}

// MARK: - Manager
@objc public class RoadQManager: NSObject, SNeuralNetworkDelegate {
    
    
    // MARK: - Private Properties
    private var rcRecord:RCData?
    static private let instance = RoadQManager()
    private let filter:LowpassFilter = LowpassFilter(sampleRate: 25.0, cutoffFrequency: 6.0)
    private var network:SNeuralNetwork?
    private var waitUntill:Double = NSDate().timeIntervalSinceReferenceDate
    private var motionManager:CMMotionManager?
    private var _shouldCapture:Bool = false
    
    
    // MARK: - Public Properties
    public var shouldCapture:Bool{
        set{
            self._shouldCapture = newValue
            self.prepareMotionManager()
        }
        get{
            return self._shouldCapture
        }
    }
    public var tripId:String = ""
    public var lattitude:Float = 0.0
    public var longitude:Float = 0.0
    public var course:Float = 0.0
    public weak var delegate:RoadQManagerDelegate?
    
    private override init() {
        self.filter.isAdaptive = false
    }
    
    // MARK: - Public Methods
    @objc public class func sharedManager() -> RoadQManager{
        return instance;
    }
    
    @objc public func start(){
        DispatchQueue.global().async {
            self.network = SNeuralNetwork(delegate: self)
        }
    }
    @objc public func addMotionData(motionData: CMDeviceMotion) {
        /////here add the code related to cancelling noise
        //let attitude = self.magnitude(from: motionData.attitude)
        ////// Avoid pridiction for next four second if the orientation is unknown
        if self.shouldCapture {
            if self.isGyroActive(rotationRate: motionData.rotationRate) {
                self.network?.feedPredictor(az: 0.0)
                self.waitUntill = NSDate().timeIntervalSinceReferenceDate + 4.0
            }else if self.waitUntill < NSDate().timeIntervalSinceReferenceDate {
                self.filter.add(motionData.userAcceleration)
                let k = 1 - exp(-2.0 * .pi * 1.0);
                let z = k * self.filter.z + (1.0 - k) * motionData.userAcceleration.z;
                let az = Double(round(100 * z)/100);
                self.network?.feedPredictor(az: az)
            }
        }
    }
    
    // MARK: - Internal Methods
    internal func significantConfidence(confidence:Double, arr:[Double]){
        
        if self.shouldCapture && confidence >= 1.1 {
            self.rcRecord = NSEntityDescription.insertNewObject(forEntityName: "RCData", into: self.managedObjectContext) as? RCData
            self.rcRecord?.location = "\(self.lattitude):\(self.longitude)";
            
            ///Only for temp purpose
            var dataToSend:[String:String] = [String:String]()
            dataToSend["latitude"] = String(self.lattitude);
            dataToSend["longitude"] = String(self.longitude);
            let predictionConfidence = confidence * 100;
            if confidence > 1.1 && confidence < 1.99{
                self.rcRecord?.type = "Rough";
                dataToSend["type"] = "Rough";
            }else if confidence >= 1.99 {
                self.rcRecord?.type = "Hump";
                dataToSend["type"] = "Hump";
                self.waitUntill = NSDate().timeIntervalSinceReferenceDate + 2.0
            }
            self.rcRecord?.tripId = self.tripId
            self.rcRecord?.confidence = NSNumber(value: confidence)
            let stringArray = arr.map{ String($0)}
            self.rcRecord?.pattern = stringArray.joined(separator: ",")
            self.rcRecord?.timestamp = NSNumber(value: NSDate().timeIntervalSinceReferenceDate)
            self.rcRecord?.course = "\(self.course)"
            self.saveContext()
            self.delegate?.significantConfidence(confidence: predictionConfidence, data: dataToSend)
        }
    }
    internal func predictionStream(confidence stream:Double){
        self.delegate?.predictionStream(confidence: stream)
    }
    internal func networkCompletedLoadingWeights(){
        self.prepareMotionManager()
        self.delegate?.networkReady()
    }
    
    
    // MARK: - Private Methods
    private func isGyroActive(rotationRate:CMRotationRate) -> Bool{
        /*if rotationRate.x > 0.4 && rotationRate.y > 0.4{
            return true
        }
        if rotationRate.x > 0.4 && rotationRate.z > 0.4{
            return true
        }
        if rotationRate.y > 0.4 && rotationRate.z > 0.4{
            return true
        }*/
        let gyroChanges = sqrt(pow(rotationRate.x, 2.0) + pow(rotationRate.y, 2.0) + pow(rotationRate.z, 2.0) )
        if gyroChanges > 1.0 {
            return true
        }
        return false
    }
    private func magnitude(from attitude: CMAttitude) -> Double {
        return sqrt(pow(attitude.roll, 2) + pow(attitude.yaw, 2) + pow(attitude.pitch, 2))
    }
    
    private func prepareMotionManager(){
        if self.motionManager == nil && self._shouldCapture {
            self.motionManager = CMMotionManager()
            self.motionManager?.deviceMotionUpdateInterval = 0.04
            self.motionManager?.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical, to: OperationQueue.main, withHandler: { [weak self] (data: CMDeviceMotion?, error: Error?) in
                guard let data = data else { return }
                self?.addMotionData(motionData: data)
            })
        }else {
            self.motionManager?.stopDeviceMotionUpdates()
            self.motionManager = nil
        }
    }
    
    deinit{
        if self.motionManager != nil{
            self.motionManager?.stopDeviceMotionUpdates()
            self.motionManager = nil
        }
        if self.network != nil {
            self.network = nil
        }
    }
    
    // MARK: - Core Data stack
    
    private lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "Local.Test" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1] as NSURL
    }()
    
    private lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle(for: type(of: self).self).url(forResource: "RoadQ", withExtension: "momd")!
        print(modelURL)
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("RoadQCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    private lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    private func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    // MARK: - Core Data CSV support
    @objc public func getDetectionsCSV( tripId:String?, callback:@escaping (_ data:String, _ error:NSError?)-> Void) {
        DispatchQueue.global().async {
            let objectsTemp:[RCData]? = self.fetchDetections(tripId: tripId) as? [RCData]
            guard let objects = objectsTemp else{
                 DispatchQueue.main.async {
                    let error = NSError(domain: "No road conditons data found for trip", code: 404, userInfo: nil)
                    callback("", error)
                }
                return
            }
            /* We assume that all objects are of the same type */
            guard objects.count > 0 else {
                DispatchQueue.main.async  {
                    let error = NSError(domain: "No road conditons data found for trip", code: 404, userInfo: nil)
                    callback("", error)
                }
                return
            }
            let firstObject = objects[0]
            let final = self.getUniqueResults(objects: objects)
            let attribs = Array(firstObject.entity.attributesByName.keys)
            let csvHeaderString = (attribs.reduce("",{($0 as String) + ":" + $1 }) as NSString).substring(from: 1) + "\n"
            let csvArray = final.map({object in
                (attribs.map({((object.value(forKey: $0) ?? "<null>") as AnyObject).description}).reduce("",{$0 + ":" + $1}) as NSString).substring(from: 1) + "\n"
            })
            let csvString = csvArray.reduce("", +)
            //dispatch_async(dispatch_get_main_queue()) {
            callback(csvHeaderString+csvString, nil)
            //}
        }
    }
    private func fetchDetections( tripId:String?) -> [NSManagedObject]? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "RCData")
        if tripId != nil {
            let predicate = NSPredicate(format: "tripId=\(tripId!)")
            fetchRequest.predicate = predicate
        }
        do {
            let result = try self.managedObjectContext.fetch(fetchRequest) as? [NSManagedObject]
            return result;
        } catch {
            return nil;
        }
    }
    private func getUniqueResults(objects:[RCData]) -> [RCData]{
        var final = [RCData]()
        for i in 1...objects.count-1 {
            var notFound = true
            if i == 1 {
                final.append(objects[i])
            }else{
                for j in 0...final.count-1 {
                    if final[j].type == objects[i].type && final[j].location == objects[i].location {
                        notFound = false
                    }
                }
            }
            if notFound {
                final.append(objects[i])
            }
        }
        return final
    }
    // MARK: - Core Data CSV support
    @objc public func getDetectionsArray( tripId:String?, callback:@escaping (_ data:[RCModel]?, _ error:NSError?)-> Void) {
   // dispatch_async(DispatchQueue.global(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)){
        DispatchQueue.global().async {

            let objectsTemp:[RCData]? = self.fetchDetections(tripId: tripId) as? [RCData]
            guard let objects = objectsTemp else{
                DispatchQueue.main.async {
                    let error = NSError(domain: "No road conditons data found for trip", code: 404, userInfo: nil)
                    callback(nil, error)
                }
                return
            }
            /* We assume that all objects are of the same type */
            guard objects.count > 0 else {
                DispatchQueue.main.async{
                    let error = NSError(domain: "No road conditons data found for trip", code: 404, userInfo: nil)
                    callback(nil, error)
                }
                return
            }
            let final = self.getUniqueResults(objects: objects)
            var finalResult = [RCModel]()
            for i in 1...final.count-1 {
                let object = RCModel()
                object.confidence = Float(truncating: objects[i].confidence!)
                object.course = Float(objects[i].course!)!
                object.timestamp = Float(truncating: objects[i].timestamp!)
                object.pattern = String(objects[i].pattern!)
                if objects[i].tripId == nil {
                    object.tripID = ""
                }else{
                    object.tripID = String(objects[i].tripId!)
                }
                if objects[i].type! == "Hump" {
                    object.type = .Hump
                }else if objects[i].type! == "Rough" {
                    object.type = .Rough
                }else{
                    object.type = .Smooth
                }
                object.latitude = Float(objects[i].location!.components(separatedBy: ":")[0])!
                object.longitude = Float(objects[i].location!.components(separatedBy: ":" )[1])!
                finalResult.append(object)
            }
            print(finalResult)
            //dispatch_async(dispatch_get_main_queue()) {
            callback(finalResult, nil)
            //}
        }
    }
    // MARK: - Core Data Update support
    @objc public func deleteDataForTrip( tripId:String) -> Bool {
        let objectsTemp:[RCData]? = self.fetchDetections(tripId: tripId) as? [RCData]
        guard let objects = objectsTemp else{
            //// No records found that means no data to delete
            return false
        }
        guard objects.count > 0 else {
            //// No records found that means no data to delete
            return false
        }
        for i in 0...objects.count - 1 {
            self.managedObjectContext.delete(objects[i])
        }
        self.saveContext()
        return true
    }
}
