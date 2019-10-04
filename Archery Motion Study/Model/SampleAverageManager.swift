//
//  SampleAverageManager.swift
//  Archery Motion Study
//
//  Created by Juan Ignacio Rodríguez Liébana on 03/10/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import Foundation

class SampleAverageManager : NSObject {
    
    var nSamples : Int = 0
    
    var currentValue : Double
    
    private var samples : [Double]
    
    init(nSamples : Int){
        
        self.nSamples = nSamples
        self.samples = Array(repeating: 0.0, count: nSamples)
        self.currentValue = 0

    }
    
    func calculateNewAverage(newSample: Double) -> Double {
        
        addNewSampleToArray(newSample: newSample)
        let sum = samples.reduce(0, { x, y in
            x + y
        })
        
        currentValue = sum / Double(nSamples)
        
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
    
    
}
