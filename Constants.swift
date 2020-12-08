//
//  Constants.swift
//  Archery Motion Study
//
//  Created by Juan I Rodriguez on 13/11/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import Foundation

struct K {
    
    #warning("CHECK ADMIN STATUS BEFORE BUILDING")
    static let isAdmin = true
    
    #if DEBUG
    static let minLogLevel : LOGLEVEL = .TRACE
    static let isSaveWorkoutActive = false
    #else
    static let minLogLevel : LOGLEVEL = .WARNING
    static let isSaveWorkoutActive = true
    #endif
    
    static let dateFormat : String = "ddMMyy'T'HHmmss"
    static let graphSmootherSamples : Int = 30
    static let graphSmootherFilterLevel : Int = 3
    static let motionDataFolder : String = "/MotionData"
    static let motionDataFolderDownloads : String = motionDataFolder + "/Downloads"
    
    static let bowTypeKey : String = "bowType"
    static let handKey : String = "hand"
    static let sessionTypeKey : String = "sessionType"
    static let healthkitKey : String = "isHealthkitAuthorized"
    static let friendsKey : String = "isFriend"
    static let freshKey : String = "isFreshStart"
    static let nameKey : String = "friendName"
    
    static let firebaseFoldersAdmin : [String : String] = [sessionValues[0] : "Shot-admin/", sessionValues[1] : "Abort-admin/", sessionValues[2] : "Other-admin/", sessionValues[3] : "Walk-admin/"]
    static let firebaseFoldersBase : [String : String] = [sessionValues[0] : "Shot/", sessionValues[1] : "Abort/", sessionValues[2] : "Other/", sessionValues[3] : "Walk/"]
    static let firebaseFoldersFriends : [String : String] = [sessionValues[0] : "Shot-friends/", sessionValues[1] : "Abort-friends/", sessionValues[2] : "Other-friends/", sessionValues[3] : "Walk-friends/"]
    
    static let firebaseFoldersPrefix : String = "30hz/"
    
//    static var firebaseFolders : [String : String]  {
//        if self.isAdmin {
//            return self.firebaseFoldersAdmin
//        } else {
//            return self.firebaseFoldersBase
//        }
//        
//    }
    
    static let categoryValues = ["Recurve","Compund"]
    static let handValues = ["Bow Hand", "String Hand"]
    static let sessionValues = ["Shooting", "Aborting", "Other", "Walk"]
    
    static let collaboratorCode = "archeryproject"
    static let feedbackEmail = "feedback.juan@icloud.com"
    static let feedbackEmailSubject = "Comments on Archer Motion App"
    static let twitterURL = URL(string: "https://twitter.com/JuanIRL")
    static let instagramURL = URL(string: "https://www.instagram.com/liebana.jr/")
    
    static let sampleInterval = 1.0/30.0
    static let sensorScaleFactor = 1.0
    static let sensorPrecision : String = "%.3f"
    static let timeStampPrecision : String  = "%.2f"
    static let csvSeparator = ","
    static let csvTextHeader = "Time Stamp,Accelerometer X,Accelerometer Y,Accelerometer Z,Gyroscope X,Gyroscope Y,Gyroscope Z,Transformed accelerometer X,Transformed accelerometer Y,Transformed accelerometer Z,Gravity X,Gravity Y,Gravity Z\n"
    
    
}
