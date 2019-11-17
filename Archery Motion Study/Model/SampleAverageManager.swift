//
//  SampleAverageManager.swift
//  Archery Motion Study
//
//  Created by Juan Ignacio Rodríguez Liébana on 03/10/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import Foundation

class SampleAverageManager : NSObject {
    
    var nSamples : Int
    var filterLevel : Int
        
    private var samples : [Double]
    
    init(nSamples : Int, filterLevel: Int){
        
        self.nSamples = nSamples
        self.filterLevel = filterLevel
        
        self.samples = Array(repeating: 0.0, count: nSamples)

    }
    
    func averageSignal(inputSignal: [Double]) -> [Double] {
        
        var auxSignal = inputSignal
        
        for _ in 0...filterLevel-1 {
            
            auxSignal = averageSignalOnce(inputSignal: auxSignal)
            
        }
        
        return auxSignal
        
    }
    
    func averageSignalOnce(inputSignal: [Double]) -> [Double]{
        
        var outputSignal = [Double]()
        
//        Fill up first nSamples positions of the samples array
        for index in 0...nSamples-1 {
            addNewSampleToArray(newSample: inputSignal[index])
        }
        
        outputSignal.append(calculateNewAverage())
        
        for index in (nSamples)...(inputSignal.count-1) {
            
            addNewSampleToArray(newSample: inputSignal[index])
            outputSignal.append(calculateNewAverage())
            
        }
        
        resetAverages()
        
        return outputSignal
        
    }
    
    func calculateNewAverage() -> Double {
                    
        let sum = samples.reduce(0, { x, y in
            x + y
        })
        
        let currentValue = sum / Double(nSamples)
        
        return currentValue
    }
    
    func addNewSampleToArray(newSample: Double){
        
        
        for i in 0...(samples.count-2) {
            
//            Array shiftes to the left and adds new sample at the last index
            samples[i] = samples [i+1]
            
        }
//        New sample is added to the last index
        samples[samples.count-1] = newSample
        
    }
    
    func resetAverages() {
        
        self.samples = Array(repeating: 0.0, count: nSamples)
        
    }
    
    
}
