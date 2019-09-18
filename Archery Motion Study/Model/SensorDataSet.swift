//
//  SensorDataSet.swift
//  Archery Motion Study
//
//  Created by Juan Ignacio Rodríguez Liébana on 18/09/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import UIKit

class SensorDataSet: NSObject {
    
    var label : String
    var data : [Double]
    
    init(labelName: String) {
        label = labelName
        data = []
    }
    
    func appendDataPoint(value: String){
        if let doubleValue = Double(value){
            data.append(doubleValue)
            return
        }
        data.append(0)
    }

}
