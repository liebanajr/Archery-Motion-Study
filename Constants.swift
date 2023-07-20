//
//  Constants.swift
//  Archery Motion Study
//
//  Created by Juan I Rodriguez on 13/11/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import Foundation

struct K {
        
    #if DEBUG
    static let isAdmin = true
    static let isSaveWorkoutActive = false
    #if targetEnvironment(simulator)
    static let isMockup = true
    #else
    static let isMockup = false
    #endif
    #else
    static let isAdmin = false
    static let isSaveWorkoutActive = true
    static let isMockup = false
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
    
    static let fireBaseFolder : String = "V3/"
    
    static let categoryValues = ["Recurve","Compund"]
    static let handValues = ["Bow Hand", "String Hand"]
    static let sessionValues = ["Shooting", "Aborting", "Other", "Walk"]
    
    static let feedbackEmail = "shotsarcheryapp@gmail.com"
    static let feedbackEmailSubject = "Comments on ArrowSense App"
    static let twitterURL = URL(string: "https://twitter.com/liebana_jr")
    static let instagramURL = URL(string: "https://www.instagram.com/liebana.jr/")
    
}

struct F {
    static func calculateRecordingFileName() -> String{
        let defaults = UserDefaults.standard
        
        let formatter = DateFormatter()
        let timeZone = TimeZone(identifier: "Europe/Paris")
        formatter.timeZone = .some(timeZone!)
        formatter.dateFormat = "yyyyMMdd_HHmm"
        let date = formatter.string(from: Date())
        let randNum = Int.random(in: 0...9999)
        let id = "\(randNum)"
        let category = defaults.string(forKey: K.bowTypeKey) ?? "no_category"
        let hand = (defaults.string(forKey: K.handKey) ?? "no_hand").replacingOccurrences(of: " ", with: "")
        let sessionType = defaults.value(forKey: K.sessionTypeKey) as? String ?? "no_sessionType"
        
        var productor = "Unknown"
        
        if K.isAdmin {
            productor = "Admin"
        } else if defaults.value(forKey: K.friendsKey) != nil{
            productor = "Friend"
            if let name = defaults.value(forKey: K.nameKey) as? String {
                productor += "_\(name)"
            }
        }
        
        return "\(productor)_\(sessionType)_\(hand)_\(category)_\(date)_\(id).csv"
    }
    
    static func readDictionaryFrom(plist name: String) -> NSDictionary? {
        if let path = Bundle.main.path(forResource: name, ofType: "plist") {
            if let resourceFileDictionaryContent = NSDictionary(contentsOfFile: path) {
                print(resourceFileDictionaryContent)
                return resourceFileDictionaryContent
            }
        }
        return nil
    }
}
