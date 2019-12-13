//
//  FilesManager.swift
//  Archery Motion Study WatchKit Extension
//
//  Created by Juan I Rodriguez on 13/12/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import UIKit
import WatchConnectivity

class FilesManager: NSObject {
    
    let fileManager = FileManager()
    let defaults = UserDefaults.standard
    let wcSession = WCSession.default
    
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
    var documentDir : String = ""
        
    override init() {
        super.init()
        
        documentDir = paths.firstObject as! String
    }
    
    func saveDataLocally(dataString: String) -> URL?{
        
        let formatter = DateFormatter()
        let timeZone = TimeZone(abbreviation: "UTC+2")
        formatter.timeZone = .some(timeZone!)
        formatter.dateFormat = K.dateFormat
        let date = formatter.string(from: Date())
        let randNum = Int.random(in: 0...9999)
        let id = "\(randNum)"
        let category = defaults.string(forKey: K.bowTypeKey) ?? K.categoryValues[0]
        let hand = (defaults.string(forKey: K.handKey) ?? K.handValues[0]).replacingOccurrences(of: " ", with: "")
        
        let fileName = "\(category)_\(hand)_\(date)_\(id).csv"
        
        let url = URL(fileURLWithPath: documentDir + "/" + fileName)
        print("Guardando datos en: \(url.absoluteString)")
        
        do{
            try dataString.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("Error guardando datos: \(error)")
        }
        
        return nil
    }
    
    func sendDataToiPhone(_ file: URL, with workoutInfo: WorkoutSessionDetails){
        if wcSession.activationState == .activated {
            print("Sending \(file.absoluteString) to iPhone...")
            let dictionary : [String : Any] = ["end" : workoutInfo.endCounter , "sessionId" : workoutInfo.sessionId , "calories" : workoutInfo.cumulativeCaloriesBurned , "avgHR" : workoutInfo.averageHeartRate , "maxHR" : workoutInfo.maxHeartRate , "distance" : workoutInfo.cumulativeDistance]
            wcSession.transferFile(file, metadata: dictionary)
            
        } else {
            print("Unable to transfer files because WC Session is inactive")
        }
    }

}
