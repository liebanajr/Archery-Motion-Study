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
        self.samples = [Double]()
        self.currentValue = 0
        
        for i in 0...(nSamples-1) {
            
            self.samples[i] = 0
            
        }
    }
    
    
    
}
