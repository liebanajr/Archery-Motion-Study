//
//  SensorDataSet.swift
//  Archery Motion Study
//
//  Created by Juan Ignacio Rodríguez Liébana on 18/09/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import UIKit
#if os(iOS)
import iOSUtils
#elseif os(watchOS)
import watchOSUtils
#endif

class SensorDataSet: NSObject {
    
    var label : String
    var data : [Double]
    
    init(labelName: String) {
        label = labelName
        data = []
    }
    
    func appendDataPoint(value: String){
        if let doubleValue = Double(value){
//            Log.trace("Appending \(self.label) - \(doubleValue)")
            data.append(doubleValue)
            return
        }
        data.append(0.0)
    }
    
    func setData(values: [String]){
        let doublesArray = values.map { (string) -> Double in
            return Double(string) ?? Double.infinity
        }
        
        data = doublesArray
    }

}
