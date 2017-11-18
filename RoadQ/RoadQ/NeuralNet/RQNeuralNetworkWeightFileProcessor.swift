//
//  NeuralNetworkWeightFileProcessor.swift
//  MotionHump
//
//  Created by Ashif Khan on 17/07/16.
//  Copyright © 2016 Local. All rights reserved.
//

import Foundation

class RQNeuralNetworkWeightFileProcessor {
    
    /*class func loadWeights(weightsFileName: String) -> [[Double]] {
        guard let weightRawStrings = rawWeightStringsFromContentsOfFileWithName(weightsFileName) else {
            print("could not load raw weight vector data from file \(weightsFileName).dat")
            return [[Double]]()
        }
        var weightVectors = [[Double]]()
        for weightRawString in weightRawStrings {
            var weights = [Double]()
            let rawValues = weightRawString.characters.split{$0 == " "}.map(String.init)
            for rawValue in rawValues {
                let weight = Double(rawValue.stringByReplacingOccurrencesOfString("\r", withString: ""))!
                weights.append(weight)
            }
            weightVectors.append(weights)
        }
        printLoadedWeightVectorsInfo(weightVectors)
        return weightVectors
    }
    
    class func printLoadedWeightVectorsInfo(weightVectors: [[Double]]) {
        print("loaded ϴ weight vectors:")
        var i = 1
        for weightVector in weightVectors {
            print("ϴ\(i += 1) weight vector length: \(weightVector.count)")
        }
    }
    
    class func rawWeightStringsFromContentsOfFileWithName(fileName: String) -> [String]? {
        let bundle = NSBundle(identifier: "com.pixel.mavericks.VideoAnalytics.RoadConditions")!
        guard let path = bundle.pathForResource(fileName, ofType: "dat") else {
            return nil
        }
        do {
            let content = try String(contentsOfFile:path, encoding: NSUTF8StringEncoding)
            return content.componentsSeparatedByString("\n")
        } catch _ as NSError {
            return nil
        }
    }*/
    internal func loadWeights(weightsFileName: String) -> [[Double]] {
        guard let weightRawStrings = rawWeightStringsFromContentsOfFileWithName(fileName: weightsFileName) else {
            print("could not load raw weight vector data from file \(weightsFileName).dat")
            return [[Double]]()
        }
        var weightVectors = [[Double]]()
        for weightRawString in weightRawStrings {
            var weights = [Double]()
            let rawValues = weightRawString.characters.split{$0 == " "}.map(String.init)
            for rawValue in rawValues {
                let weight = Double(rawValue.replacingOccurrences(of: "\r", with: ""))!
                weights.append(weight)
            }
            weightVectors.append(weights)
        }
        printLoadedWeightVectorsInfo(weightVectors: weightVectors)
        return weightVectors
    }
    
    private func printLoadedWeightVectorsInfo(weightVectors: [[Double]]) {
        print("loaded ϴ weight vectors:")
        var i = 1
        for weightVector in weightVectors {
            print("ϴ\(i += 1) weight vector length: \(weightVector.count)")
        }
    }
    
    private func rawWeightStringsFromContentsOfFileWithName(fileName: String) -> [String]? {
        //let bundle = NSBundle(identifier: "com.pixel.mavericks.VideoAnalytics.RoadConditions")!
        let bundle = Bundle(for: type(of: self).self)
        guard let path = bundle.path(forResource: fileName, ofType: "dat") else {
            return nil
        }
        do {
            let content = try String(contentsOfFile:path, encoding: String.Encoding.utf8)
            return content.components(separatedBy: "\n")
        } catch _ as NSError {
            return nil
        }
    }
    
    
    
}
