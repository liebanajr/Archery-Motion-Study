//
//  AppDelegate.swift
//  Archery Motion Study
//
//  Created by Juan Ignacio Rodríguez Liébana on 13/09/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import UIKit
import WatchConnectivity
import Foundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate {
    

    let session = WCSession.default
    let fileManager = FileManager()
    let defaults = UserDefaults.standard
    
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
    var documentDir :String = ""

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
//        Set path for storing motion data
        documentDir = paths.firstObject as! String + "/MotionData"
//        Set WCSession
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
//        Set user defaults to tag motion data with archer info
        if defaults.string(forKey: "Category") == nil || defaults.string(forKey: "Hand") == nil{
            defaults.set("Recurve", forKey: "Category")
            defaults.set("Bow", forKey: "Hand")
            print("Setting user defaults: Category = \(defaults.string(forKey: "Category")!) Hand = \(defaults.string(forKey: "Hand")!)")
        }
        
        return true
    }
    
//    MARK: Watch Connectivity methods
    
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        
        do{
            print("File transfer finished successfully")
            
            let srcURL = file.fileURL
            
//          Set filename according to archer settings and date
            let formatter = DateFormatter()
            formatter.dateFormat = "dd-MM-yy'T'HH:mm:ss"
            let date = formatter.string(from: Date())
            let category = defaults.string(forKey: "Category")!
            let hand = defaults.string(forKey: "Hand")! + "Hand"
            let fileName = "\(category)_\(hand)_\(date).csv"
            
            let dstURL = URL(fileURLWithPath: documentDir + "/" + fileName)
            
            if !fileManager.fileExists(atPath: documentDir){
                print("Attempting to create directory MotionData")
                try fileManager.createDirectory(at: URL(fileURLWithPath: documentDir), withIntermediateDirectories: false, attributes: nil)
            }
            
            print("Attemmpting to move \(srcURL.absoluteString) to \(dstURL.absoluteString)")
            try fileManager.moveItem(at: srcURL, to: dstURL)

        } catch {
            print("Error while moving transfered file: \(error)")
        }
        
    }
    
    
    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        if error != nil {
            print("Error while transfering file: \(error)")
            return
        }
        
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
        if activationState != .activated {
            print(error)
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

