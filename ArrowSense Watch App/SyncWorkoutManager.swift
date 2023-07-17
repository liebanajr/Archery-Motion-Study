//
//  SyncWorkoutManager.swift
//  Archery Motion Study WatchKit Extension
//
//  Created by Juan Rodríguez on 13/12/20.
//  Copyright © 2020 liebanajr. All rights reserved.
//

import Foundation
import ShotsWorkoutManager
import WatchConnectivity
import watchOSUtils

protocol SyncWorkoutManagerDelegate {
    func didStartSaveTasks()
    func didFinishSaveTasks()
}

class SyncWorkoutManager {
    
    static let shared = SyncWorkoutManager()
    
    let wcSession = WCSession.default
    let fileManager = FileManager()
    let defaults = UserDefaults.standard
    var workoutManager = ShotsWorkoutManager.shared
    
    var delegate : SyncWorkoutManagerDelegate?
    
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
    var documentDir : String = ""
    
    init() {
        documentDir = paths.firstObject as! String
    }
    
    func saveWorkout(){
        print("Saving workout")
        delegate?.didStartSaveTasks()
        let motionManager = workoutManager.motionManager
        DispatchQueue.global(qos: .utility).async {
            let csv = motionManager.toCSVString()
            Log.debug("CSV result: \(csv)")
            if let url = self.saveDataLocally(dataString: csv) {
                self.sendDataToiPhone(url, with: self.workoutManager.sessionData)
            }
            self.delegate?.didFinishSaveTasks()
            motionManager.emptyMotionDataPoints()
        }
        
    }
    
    func sendArrowCount() {
        wcSession.sendMessage(["arrowCount":workoutManager.sessionData.arrowCounter,"sessionId" : workoutManager.sessionData.sessionId], replyHandler: nil, errorHandler: nil)
        delegate?.didFinishSaveTasks()
    }
    
    func saveDataLocally(dataString: String) -> URL?{
        
        
        
        let fileName = F.calculateRecordingFileName()
        
        let url = URL(fileURLWithPath: documentDir + "/" + fileName)
        
        do{
            try dataString.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("Error guardando datos: \(error)")
        }
        
        return nil
    }
    
    func sendDataToiPhone(_ file: URL, with workoutInfo: ShotsSessionDetails){
        if wcSession.activationState == .activated {
            Log.info("Arrow count = \(workoutInfo.arrowCounter)")
            let dictionary : [String : Any] = ["end" : workoutInfo.endCounter , "sessionId" : workoutInfo.sessionId , "calories" : workoutInfo.cumulativeCaloriesBurned , "avgHR" : workoutInfo.averageHeartRate , "maxHR" : workoutInfo.maxHeartRate ,"minHR" : workoutInfo.minHeartRate , "distance" : workoutInfo.cumulativeDistance,"elapsedTime" : workoutInfo.elapsedSeconds, "arrowCount" : workoutInfo.arrowCounter, "maxHREnd" : workoutInfo.maxHRAtEnd, "minHREnd" : workoutInfo.minHRAtEnd]
            wcSession.transferFile(file, metadata: dictionary)
            
        } else {
            print("Unable to transfer files because WC Session is inactive")
        }
    }
    
}
