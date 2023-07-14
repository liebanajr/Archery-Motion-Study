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
import Firebase
import FirebaseStorage
import CoreData
import IQKeyboardManagerSwift
import iOSUtils

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate {
    

    let session = WCSession.default
    let fileManager = FileManager()
    
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
    var documentDir : String!
    
    let defaults = UserDefaults.standard

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
//        Set path for storing motion data
        documentDir = paths.firstObject as! String + K.motionDataFolder
//        Set WCSession
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }

        FirebaseApp.configure()
        
        IQKeyboardManager.shared.enable = true
        
        return true
    }
//    MARK: Selective autorotation
    
    var enableAllOrientation = false

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if (enableAllOrientation == true){
            return UIInterfaceOrientationMask.allButUpsideDown
        }
        return UIInterfaceOrientationMask.portrait
    }
    
//    MARK: Watch Connectivity methods
    
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        
        do{
            print("File transfer finished successfully")
            let metadata = file.metadata!
            
            let endIndex = metadata["end"]! as! Int64
            let sessionId = metadata["sessionId"]! as! String
            let calories = metadata["calories"]! as! Int64
            let maxHR = metadata["maxHR"]! as! Int64
            let maxHREnd = metadata["maxHREnd"] as? Int64
            let minHR = metadata["minHR"]! as! Int64
            let minHREnd = metadata["minHREnd"] as? Int64
            let avgHR = metadata["avgHR"]! as! Int64
            let distance = metadata["distance"]! as! Int64
            let duration = metadata["elapsedTime"]! as! Int64
            let arrowCount = metadata["arrowCount"]! as! Int64
            
            let srcURL = file.fileURL
            
            let fileName = F.calculateRecordingFileName()
            
            let dstURL = URL(fileURLWithPath: documentDir + "/" + fileName)
            
            if !fileManager.fileExists(atPath: documentDir){
                print("Attempting to create directory MotionData")
                try fileManager.createDirectory(at: URL(fileURLWithPath: documentDir), withIntermediateDirectories: false, attributes: nil)
            }
            
//            print("Attemmpting to move \(srcURL.absoluteString) to \(dstURL.absoluteString)")
            try fileManager.moveItem(at: srcURL, to: dstURL)
            print("File moved successfully!")
            
            print("Attempting to save data about the file...")
            let context = persistentContainer.viewContext
            let motionDataFileItem = MotionDataFile(context: context)
            motionDataFileItem.fileName = fileName
            motionDataFileItem.endIndex = endIndex
            motionDataFileItem.sessionId = sessionId
            motionDataFileItem.isUploaded = false
            motionDataFileItem.endMinHR = minHR
            motionDataFileItem.endMaxHR = maxHR
//            SELECTING FOLDER TYPE DEPENDING ON USER
            let folderName = "\(K.fireBaseFolder)"

            motionDataFileItem.firebaseLocation = folderName
            
            let sessionRequest = NSFetchRequest<Session>(entityName: "Session")
            sessionRequest.predicate = NSPredicate(format: "sessionId = %@", argumentArray: [sessionId])
            do {
                let result = try context.fetch(sessionRequest)
//                print("Fetch request result: \(result)")
                var workoutSession : Session
                if result.isEmpty {
//                    print("Session does not exist. Creating new workout session with id: \(sessionId)")
                    workoutSession = Session(context: context)
                    workoutSession.bowType = defaults.value(forKey: K.bowTypeKey) as? String
                    workoutSession.watchLocation = defaults.value(forKey: K.handKey) as? String
                    workoutSession.sessionType = defaults.value(forKey: K.sessionTypeKey) as? String
                    workoutSession.dateFinished = Date()
                    workoutSession.duration = 0
                } else {
//                    print("Session exists. Updating session with id: \(sessionId)")
                    workoutSession = result.first!
                }
                workoutSession.sessionId = sessionId
                workoutSession.averageHeartRate = avgHR
                workoutSession.caloriesBurned = calories
                workoutSession.maxHeartRate = maxHR
                workoutSession.maxHeartRateEnd = maxHREnd!
                workoutSession.minHeartRate = minHR
                workoutSession.minHeartRateEnd = minHREnd!
                workoutSession.distanceWalked = distance
                workoutSession.arrowCount = arrowCount
                Log.info("Arrow count = \(arrowCount)")
                
//                Duration needs special treatment so it's separated and calculated before saving
                motionDataFileItem.endDuration = duration - workoutSession.duration
                workoutSession.duration = duration
                
            } catch {
                print("Error fetching existing Session: \(error)")
            }
            self.saveContext()
            print("Data saved successfully!")
            
            let rcController = RCController.shared
            rcController.saveRecording(for: fileName)
            
//            print("Attempting to store \(fileName) in folder \(folderName) in Firebase cloud storage")
            let storage = Storage.storage()
            let storageRef = storage.reference()
            let motionDataDestination = storageRef.child(folderName + fileName)

            let uploadTask = motionDataDestination.putFile(from: dstURL, metadata: nil) { metadata, error in
                if error != nil {
                  // Uh-oh, an error occurred!
                    print("Error uploading file: \(error!)")
                    return
                }
            }

            uploadTask.observe(.success) { (snapshot) in
                print("File uploaded successfully!!")
                motionDataFileItem.setValue(true, forKey: "isUploaded")
                self.saveContext()
                let nc = NotificationCenter.default
                nc.post(name: Notification.Name("NewDataAvailable"), object: nil)

            }
            
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name("NewDataAvailable"), object: nil)

        } catch {
            print("Error while moving transfered file: \(error)")
        }
        
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        for element in userInfo {
            print("Key: \(element.key)   Value: \(element.value)")
        }
        defaults.setValuesForKeys(userInfo)
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name("NewDataAvailable"), object: nil)
    }
    
    
    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        if error != nil {
            print("Error while transfering file: \(error!)")
            return
        }
        
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
        if activationState != .activated {
            print("WC Session is not active")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let error = message["errorMessage"]{
            print("Error de Apple Watch en WorkoutManager: \(error)")
        }
        
        if let arrowCount = message["arrowCount"], let sessionId = message["sessionId"] as? String {
            let sessionRequest = NSFetchRequest<Session>(entityName: "Session")
            sessionRequest.predicate = NSPredicate(format: "sessionId = %@", argumentArray: [sessionId])
            let context = persistentContainer.viewContext
            do {
                let result = try context.fetch(sessionRequest)
    //                print("Fetch request result: \(result)")
                var workoutSession : Session
                if let firstResult = result.first {
                    workoutSession = firstResult
                    workoutSession.arrowCount = arrowCount as! Int64
                    
                    self.saveContext()
                    print("Data saved successfully!")
                    let nc = NotificationCenter.default
                    nc.post(name: Notification.Name("NewDataAvailable"), object: nil)
                }
                                
            } catch {
                print("Error fetching existing Session: \(error)")
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }

    // MARK: UISceneSession Lifecycle

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "Model")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }


}


