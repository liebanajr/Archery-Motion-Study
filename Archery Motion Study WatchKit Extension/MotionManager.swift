//
//  WorkoutManager.swift
//  Archery Motion Study WatchKit Extension
//
//  Created by Juan I Rodriguez on 12/12/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import UIKit
import CoreMotion

struct MotionDataPoint {
    
    var accX : Double
    var accY : Double
    var accZ : Double
    var gyrX : Double
    var gyrY : Double
    var gyrZ : Double
    var timeStamp : Double
    
    init(){
        
        accX = 0.0
        accY = 0.0
        accZ = 0.0
        gyrX = 0.0
        gyrY = 0.0
        gyrZ = 0.0
        timeStamp = 0.0
        
    }
    
}

class MotionManager: NSObject {
    
    var motionDataPoints : Array<MotionDataPoint>
    var motion : CMMotionManager?
    let motionUpdatesQueue : OperationQueue
    
    override init() {
        
        motionDataPoints = []
        motionUpdatesQueue = OperationQueue()
        
    }
    
//    MARK: Managing data
    
    func toCSVString() -> String{
        
        var resultString = K.csvTextHeader
        
        for dataPoint in motionDataPoints {
            
            resultString.append(String(format: K.timeStampPrecision, dataPoint.timeStamp) + K.csvSeparator)
            resultString.append(String(format: K.sensorPrecision, dataPoint.accX * K.sensorScaleFactor) + K.csvSeparator)
            resultString.append(String(format: K.sensorPrecision, dataPoint.accY * K.sensorScaleFactor) + K.csvSeparator)
            resultString.append(String(format: K.sensorPrecision, dataPoint.accZ * K.sensorScaleFactor) + K.csvSeparator)
            resultString.append(String(format: K.sensorPrecision, dataPoint.gyrX * K.sensorScaleFactor) + K.csvSeparator)
            resultString.append(String(format: K.sensorPrecision, dataPoint.gyrY * K.sensorScaleFactor) + K.csvSeparator)
            resultString.append(String(format: K.sensorPrecision, dataPoint.gyrZ * K.sensorScaleFactor) + "\n")
            
        }
        
        return resultString
        
    }
    
//    MARK: Managing device motion data
    
    func storeDeviceMotion(_ deviceMotion: CMDeviceMotion, _ timeStamp: Double) {
        
        var motionData = MotionDataPoint()
        motionData.accX = deviceMotion.userAcceleration.x
        motionData.accY = deviceMotion.userAcceleration.y
        motionData.accZ = deviceMotion.userAcceleration.z
        motionData.gyrX = deviceMotion.rotationRate.x
        motionData.gyrY = deviceMotion.rotationRate.y
        motionData.gyrZ = deviceMotion.rotationRate.z
        motionData.timeStamp = timeStamp
        
        motionDataPoints.append(motionData)
        
    }
    
    func startMotionUpdates(){
        
        motion = CMMotionManager()
        motion!.deviceMotionUpdateInterval = K.sampleInterval
        
        if motion!.isDeviceMotionAvailable {
            
            print("Starting motion updates...")
            var timeStamp = 0.0
            motion!.startDeviceMotionUpdates(to: motionUpdatesQueue) { (deviceMotion, error) in
                if error != nil {
                   print("Encountered error while starting device motion updates: \(error!)")
                }
                if deviceMotion != nil {
                   self.storeDeviceMotion(deviceMotion!, timeStamp)
                    timeStamp += K.sampleInterval
                }
            }
            
        } else {
            print("Device motion not available")
        }
        
    }
    
    func stopMotionUpdates() {
        
        print("Stopping motion updates...")
        motion!.stopDeviceMotionUpdates()
        motion = nil
        
    }

}
