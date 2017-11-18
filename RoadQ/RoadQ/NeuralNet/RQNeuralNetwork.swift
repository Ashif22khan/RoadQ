//
//  SNeuralNetwork.swift
//  MotionHump
//
//  Created by Ashif Khan on 17/07/16.
//  Copyright © 2016 Local. All rights reserved.
//

import Accelerate
import Foundation
import CoreMotion

protocol RQNeuralNetworkDelegate{
    func significantConfidence(confidence:Double, arr:[Double]);
    func predictionStream(confidence:Double);
    func networkCompletedLoadingWeights();
}

class RQNeuralNetwork : NSObject{
    private let patternSize = 50
    private let weightVectors: [[Double]]
    private var azQ = Queue<Double>(cap: 50)
    var delegate:RQNeuralNetworkDelegate?
    private var operationQueue:OperationQueue
    private let weightsFileName: String
    
    init(delegate:SNeuralNetworkDelegate) {
        self.delegate = delegate
        self.weightsFileName = "Model23"
        self.weightVectors = RQNeuralNetworkWeightFileProcessor().loadWeights(weightsFileName: weightsFileName)
        self.delegate?.networkCompletedLoadingWeights()
        self.operationQueue = OperationQueue();
    }
    
    func feedPredictor(az:Double){
        self.azQ.enqueue(element: az)
        if self.azQ.count > 49 {
            var arrParams = [Double]()
            var counter = 49
            repeat{
                arrParams.append( self.azQ.arrayFromQueue()[counter])
                counter -= 1
            }while counter >= 0
            self.operationQueue.addOperation({
                let prediction  = self.predict(X: arrParams)[0]
                
                DispatchQueue.main.async {
                    self.delegate?.predictionStream(confidence: prediction)
                }
                 DispatchQueue.main.async{
                    self.delegate?.predictionStream(confidence: prediction)
                }
                print(prediction)
                if prediction >= 0.9 {
                    DispatchQueue.main.async {
                        self.delegate?.significantConfidence(confidence: prediction, arr: arrParams)
                    }
                    if prediction >= 1.25 && prediction < 1.99  {
                        for _ in 1...5 {
                            self.azQ.dequeue()
                        }
                    }else if prediction > 1.99 {
                        for _ in 1...10 {
                            self.azQ.dequeue()
                        }
                    }
                }
            })
        }
    }
    
    /*
    vDSP_mmulD( matrixA, 1, matrixB, 1, matrixAB, 1, X, Y, Z )
    
    the 1s should be left alone in most situations
    X - the number of rows in matrix A
    Y - the number of columns in matrix B
    Z - the number of columns in matrix A and the number of rows in matrix B.
    */
    
    func predict(X: [Double]) -> [Double] {
        let hiddenLayerSizes = [140,130,120,110,100,90,80,70,60,50]
        
        // X
        var Xbiased = [Double](X)
        Xbiased.insert(1.0, at: 0)
        
        let X_rows = 1
        let ϴ1 = self.weightVectors[0]
        let ϴ1_rows = ϴ1.count / hiddenLayerSizes[0]
        let ϴ1_cols = ϴ1.count / ϴ1_rows
        var a1 = [Double](repeating: 0.0, count: X_rows * ϴ1_cols)
        vDSP_mmulD(Xbiased, 1, ϴ1, 1, &a1, 1, vDSP_Length(X_rows), vDSP_Length(ϴ1_cols), vDSP_Length(ϴ1_rows))
        var h1 = vSigmoid(vz: a1)
        
        h1.insert(1.0, at: 0)
        let h1_rows = 1
        let ϴ2 = self.weightVectors[1]
        let ϴ2_rows = ϴ2.count / hiddenLayerSizes[1]
        let ϴ2_cols = ϴ2.count / ϴ2_rows
        var a2 = [Double](repeating: 0.0, count: h1_rows * ϴ2_cols)
        vDSP_mmulD(h1, 1, ϴ2, 1, &a2, 1, vDSP_Length(h1_rows), vDSP_Length(ϴ2_cols), vDSP_Length(ϴ2_rows))
        var h2 = vSigmoid(vz: a2)
        
        h2.insert(1.0, at: 0)
        let h2_rows = 1
        let ϴ3 = self.weightVectors[2]
        let ϴ3_rows = ϴ3.count / hiddenLayerSizes[2]
        let ϴ3_cols = ϴ3.count / ϴ3_rows
        var a3 = [Double](repeating: 0.0, count: h2_rows * ϴ3_cols)
        vDSP_mmulD(h2, 1, ϴ3, 1, &a3, 1, vDSP_Length(h2_rows), vDSP_Length(ϴ3_cols), vDSP_Length(ϴ3_rows))
        var h3 = vSigmoid(vz: a3)
        
        h3.insert(1.0, at: 0)
        let h3_rows = 1
        let ϴ4 = self.weightVectors[3]
        let ϴ4_rows = ϴ4.count / hiddenLayerSizes[3]
        let ϴ4_cols = ϴ4.count / ϴ4_rows
        var a4 = [Double](repeating: 0.0, count: h3_rows * ϴ4_cols)
        vDSP_mmulD(h3, 1, ϴ4, 1, &a4, 1, vDSP_Length(h3_rows), vDSP_Length(ϴ4_cols), vDSP_Length(ϴ4_rows))
        var h4 = vSigmoid(vz: a4)
        
        // hidden layer 5 -> output layer
        // 7 neurons -> 1 output node
        h4.insert(1.0, at: 0)
        let h4_rows = 1
        let ϴ5 = self.weightVectors[4]
        let ϴ5_rows = ϴ5.count / hiddenLayerSizes[4]
        let ϴ5_cols = ϴ5.count / ϴ5_rows
        var a5 = [Double](repeating: 0.0, count: h4_rows * ϴ5_cols)
        vDSP_mmulD(h4, 1, ϴ5, 1, &a5, 1, vDSP_Length(h4_rows), vDSP_Length(ϴ5_cols), vDSP_Length(ϴ5_rows))
        
        var h5 = vSigmoid(vz: a5)
        
        // hidden layer 6 -> output layer
        // 7 neurons -> 1 output node
        h5.insert(1.0, at: 0)
        let h5_rows = 1
        let ϴ6 = self.weightVectors[5]
        let ϴ6_rows = ϴ6.count / hiddenLayerSizes[5]
        let ϴ6_cols = ϴ6.count / ϴ6_rows
        var a6 = [Double](repeating: 0.0, count: h5_rows * ϴ6_cols)
        vDSP_mmulD(h5, 1, ϴ6, 1, &a6, 1, vDSP_Length(h5_rows), vDSP_Length(ϴ6_cols), vDSP_Length(ϴ6_rows))
        var h6 = vSigmoid(vz: a6)
        
        h6.insert(1.0, at: 0)
        let h6_rows = 1
        let ϴ7 = self.weightVectors[6]
        let ϴ7_rows = ϴ7.count / hiddenLayerSizes[6]
        let ϴ7_cols = ϴ7.count / ϴ7_rows
        var a7 = [Double](repeating: 0.0, count: h6_rows * ϴ7_cols)
        vDSP_mmulD(h6, 1, ϴ7, 1, &a7, 1, vDSP_Length(h6_rows), vDSP_Length(ϴ7_cols), vDSP_Length(ϴ7_rows))
        
        var h7 = vSigmoid(vz: a7)
        
        h7.insert(1.0, at: 0)
        let h7_rows = 1
        let ϴ8 = self.weightVectors[7]
        let ϴ8_rows = ϴ8.count / hiddenLayerSizes[7]
        let ϴ8_cols = ϴ8.count / ϴ8_rows
        var a8 = [Double](repeating: 0.0, count: h7_rows * ϴ8_cols)
        vDSP_mmulD(h7, 1, ϴ8, 1, &a8, 1, vDSP_Length(h7_rows), vDSP_Length(ϴ8_cols), vDSP_Length(ϴ8_rows))
        
        var h8 = vSigmoid(vz: a8)
        
        h8.insert(1.0, at: 0)
        let h8_rows = 1
        let ϴ9 = self.weightVectors[8]
        let ϴ9_rows = ϴ9.count / hiddenLayerSizes[8]
        let ϴ9_cols = ϴ9.count / ϴ9_rows
        var a9 = [Double](repeating: 0.0, count: h8_rows * ϴ9_cols)
        vDSP_mmulD(h8, 1, ϴ9, 1, &a9, 1, vDSP_Length(h8_rows), vDSP_Length(ϴ9_cols), vDSP_Length(ϴ9_rows))
        
        var h9 = vSigmoid(vz: a9)
        
        h9.insert(1.0, at: 0)
        let h9_rows = 1
        let ϴ10 = self.weightVectors[9]
        let ϴ10_rows = ϴ10.count / hiddenLayerSizes[9]
        let ϴ10_cols = ϴ10.count / ϴ10_rows
        var a10 = [Double](repeating: 0.0, count: h9_rows * ϴ10_cols)
        vDSP_mmulD(h9, 1, ϴ10, 1, &a10, 1, vDSP_Length(h9_rows), vDSP_Length(ϴ10_cols), vDSP_Length(ϴ10_rows))
        
        var h10 = vSigmoid(vz: a10)
        
        h10.insert(1.0, at: 0)
        let h10_rows = 1
        let ϴ11 = self.weightVectors[10]
        let ϴ11_rows = ϴ11.count / 1 //hiddenLayerSizes[9]
        let ϴ11_cols = ϴ11.count / ϴ11_rows
        var a11 = [Double](repeating: 0.0, count: h10_rows * ϴ11_cols)
        vDSP_mmulD(h10, 1, ϴ11, 1, &a11, 1, vDSP_Length(h10_rows), vDSP_Length(ϴ11_cols), vDSP_Length(ϴ11_rows))
        let h11 = a11
        
        return h11
        
    }

    
    private func vSigmoid(vz: [Double]) -> [Double] {
        // formula: g = 1.0 ./ (1.0 + exp(-z))
        
        // compute (1.0 + exp(-z)
        var vexpZ_plus1 = [Double]()
        for z in vz {
            vexpZ_plus1.append(1.0 + exp(-z))
        }
        
        let vOnes = [Double](repeating: 1.0, count: vz.count)
        var vg = [Double](repeating: 0.0, count: vz.count)
        
        // compute 1.0 ./ vexpZ_plus1
        vDSP_vdivD(vexpZ_plus1, 1, vOnes, 1, &vg, 1, vDSP_Length(vg.count))
        
        return vg
    }
}
