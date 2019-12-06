//
//  Constants.swift
//  Archery Motion Study WatchKit Extension
//
//  Created by Juan I Rodriguez on 14/11/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import Foundation

struct K {
    
    static let bowTypeKey : String = "bowType"
    static let handKey : String = "hand"
    static let sessionTypeKey : String = "sessionType"
    
    static let categoryValues = ["Recurve","Compund"]
    static let handValues = ["Bow Hand", "String Hand"]
    static let sessionValues = ["Shooting", "Aborting", "Other"]
    
    static let dateFormat : String = "ddMMyy'T'HHmmss"
    static let sampleInterval = 1.0/20.0
    static let sensorScaleFactor = 1.0
    static let sensorPrecision : String = "%.8f"
    static let timeStampPrecision : String  = "%.2f"
    static let csvSeparator = ","
    static let csvTextHeader = "Time Stamp,Accelerometer X,Accelerometer Y,Accelerometer Z,Gyroscope X,Gyroscope Y,Gyroscope Z\n"
    static let saveWorkoutData : Bool = false
    
}
