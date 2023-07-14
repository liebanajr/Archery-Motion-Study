//
//  RCController.swift
//  Archery Motion Study
//
//  Created by Juan Rodríguez on 11/1/21.
//  Copyright © 2021 liebanajr. All rights reserved.
//

import Foundation
import FirebaseStorage
import iOSUtils

protocol RCControllerDelegate {
    func didFinishUploadingFile(_ message: String)
    func didRegisterClass(_ named: String, at time: String)
}

class RCController : NSObject {
    
    static let shared = RCController()
    static let csvHeader = "class,timeStamp\n"
    
    var delegate : RCControllerDelegate?
    
    var isRecording = false
    var isDataAvailable = false
    var data = RCController.csvHeader
    
    func reset(){
        data = RCController.csvHeader
        isRecording = false
        isDataAvailable = false
    }
    
    func registerClass(class type: String) {
        if isRecording {
            let universalTimeStamp = UInt64(Date().timeIntervalSince1970 * 1000)
            data += "\(type),\(universalTimeStamp)\n"
            isDataAvailable = true
            delegate?.didRegisterClass(type, at: "\(universalTimeStamp)")
        } else {
            Log.error("Tried to register class while not recording")
        }
    }
    
    func saveRecording(for fileName: String) {
        if isDataAvailable {
            let folderName = "\(K.fireBaseFolder)"
            let timeStampFileName = fileName.replacingOccurrences(of: ".csv", with: "_timeStamps.csv")
            let storage = Storage.storage()
            let storageRef = storage.reference()
            let motionDataDestination = storageRef.child(folderName + timeStampFileName)
            
            motionDataDestination.putData(data.data(using: .utf8)!, metadata: nil) { (metadata, error) in
                if error != nil {
                    Log.error("ERROR: Error uploading timeStamp file: \(error!)")
                    self.delegate?.didFinishUploadingFile(error!.localizedDescription)
                } else {
                    Log.info("Successfully uploaded timeStamp file")
                    self.delegate?.didFinishUploadingFile("Successfully uploadede timeStampFile named: \(timeStampFileName)")
                }
            }
        } else {
            Log.warning("Tried to save file while no data was available")
            delegate?.didFinishUploadingFile("ERROR: Tried to save file while no data was available")
        }
        
        reset()

    }
}
