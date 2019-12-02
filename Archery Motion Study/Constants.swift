//
//  Constants.swift
//  Archery Motion Study
//
//  Created by Juan I Rodriguez on 13/11/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import Foundation

struct K {
    
    static let dateFormat : String = "ddMMyy'T'HHmmss"
    static let graphSmootherSamples : Int = 20
    static let graphSmootherFilterLevel : Int = 3
    static let motionDataFolder : String = "/MotionData/"
    static let motionDataFolderDownloads : String = motionDataFolder + "/Downloads/"
    
    static let bowTypeKey : String = "bowType"
    static let handKey : String = "hand"
    static let sessionTypeKey : String = "sessionType"
    
    static let firebaseFoldersAdmin : [String : String] = [sessionValues[0] : "Shot-admin/", sessionValues[1] : "Abort-admin/", sessionValues[2] : "Other-admin/"]
//    static let firebaseFolders : [String : String] = [sessionValues[0] : "Shot/", sessionValues[1] : "Abort/", sessionValues[2] : "Other/"]
    static let firebaseFolders = firebaseFoldersAdmin
    
    static let categoryValues = ["Recurve","Compund"]
    static let handValues = ["Bow Hand", "String Hand"]
    static let sessionValues = ["Shooting", "Aborting", "Other"]
    
}
