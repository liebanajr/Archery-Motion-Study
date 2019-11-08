//
//  workoutSessionDetails.swift
//  Archery Motion Study WatchKit Extension
//
//  Created by Juan I Rodriguez on 08/11/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import Foundation

class WorkoutSessionDetails : NSObject{
    
    var cumulativeCaloriesBurned : Int
    var cumulativeDistance : Int
    var averageHeartRate : Int
    var maxHeartRate : Int
    var endCounter : Int
    
    let sessionId : String
    
    init(sessionId id: String) {
        self.cumulativeCaloriesBurned = 0
        self.cumulativeDistance = 0
        self.averageHeartRate = 0
        self.maxHeartRate = 0
        self.endCounter = 1
        
        self.sessionId = id
    }
    
}
