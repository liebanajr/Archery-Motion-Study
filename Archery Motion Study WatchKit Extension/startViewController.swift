//
//  InterfaceController.swift
//  Archery Motion Study WatchKit Extension
//
//  Created by Juan Ignacio Rodríguez Liébana on 13/09/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit
import WatchConnectivity
import ShotsWorkoutManager
import watchOSUtils

class startViewController: WKInterfaceController {
    
    @IBOutlet weak var startButton: WKInterfaceButton!
    @IBOutlet weak var settingsiOS14Button: WKInterfaceButton!
    @IBOutlet weak var buttonsGroup: WKInterfaceGroup!
    
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
    var documentDir :String = ""
    let defaults = UserDefaults.standard
    let fileManager = FileManager()
    
    let session = WCSession.default
    
    var workoutManager = ShotsWorkoutManager.shared
    
    
    override func awake(withContext context: Any?) {
        
        super.awake(withContext: context)
        
        documentDir = paths.firstObject as! String
        print("Document directory: \(documentDir)")
        
        if #available(watchOS 7.0, *) {
            settingsiOS14Button.setHidden(false)
            settingsiOS14Button.setTitle(NSLocalizedString("Settings", comment: ""))
        } else {
            buttonsGroup.sizeToFitHeight()
        }
        
        setInitialDefaults()
        deleteAllLocalData()
        authorizeHealthKit()
                
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        
    }
    
    override func didAppear() {
        if let isRunning = workoutManager.isWorkoutRunning, isRunning {
            workoutManager.stopWorkout()
        }
    }
    
    func authorizeHealthKit() {
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("Health data already available")
            return
        }
        
        let types = Set([HKObjectType.workoutType(),
                         HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
                         HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
                         HKObjectType.quantityType(forIdentifier: .heartRate)!
                        ])
        let healthStore = HKHealthStore()
        
        healthStore.requestAuthorization(toShare: types, read: types) { (success, error) in
            if !success {
                print(error!)
            } else {
                print("HealthKit successfully authorized!")
                self.defaults.setValue(true, forKey: K.healthkitKey)
                self.syncUserDefaults()
            }
        }
        
    }
    
    func setInitialDefaults(){
        
        if defaults.value(forKey: K.bowTypeKey) == nil {
            defaults.set(K.categoryValues[0], forKey: K.bowTypeKey)
            defaults.set(K.handValues[0], forKey: K.handKey)
            defaults.set(K.sessionValues[0], forKey: K.sessionTypeKey)
            defaults.set(false, forKey: K.healthkitKey)
        }
        
    }
    
    func userDefaultsExists () -> Bool {
        
        if defaults.string(forKey: K.bowTypeKey) == nil || defaults.string(forKey: K.handKey) == nil {
                    
            defaults.set("Recurve", forKey: K.bowTypeKey)
            defaults.set("Bow", forKey: K.handKey)
            defaults.set("Shot", forKey: K.sessionTypeKey)
            
            let action1 = WKAlertAction.init(title: "OK", style:.default) {
                print("Okayed nil defaults message. Setting default values")
                self.defaults.set(K.categoryValues[0], forKey: K.bowTypeKey)
                self.defaults.set(K.handValues[0], forKey: K.handKey)
                self.defaults.set(K.sessionValues[0], forKey: K.sessionTypeKey)
                self.syncUserDefaults()
           }
            
            let message = NSLocalizedString("userDefaultsAlert", comment: "")
            
            presentAlert(withTitle: NSLocalizedString("Initial settings", comment: ""), message: message, preferredStyle:.alert, actions: [action1])
            return false
        }
        return true
        
    }
    
    @IBAction func startButtonPressed() {
        
        print("Start button pressed!")
        
        if !userDefaultsExists() {
            return
        } else {
//            pushController(withName: "goToWorkout", context: self)
            presentController(withName: "page2", context: self)
//            WKInterfaceController.reloadRootPageControllers(withNames: ["page1","page2","page3"], contexts: nil, orientation: .horizontal, pageIndex: 1)
        }
        
    }
    
    @IBAction func deleteButtonPressed() {
        self.deleteAllLocalData()
    }
    @IBAction func settingsButtonPressed() {
        
        pushController(withName: "settingsInterfaceController", context: nil)
        
    }
    
    func syncUserDefaults(){
        
        let info = [K.bowTypeKey:defaults.value(forKey: K.bowTypeKey)!, K.handKey : defaults.value(forKey: K.handKey)!, K.sessionTypeKey:defaults.value(forKey: K.sessionTypeKey)!, K.healthkitKey: defaults.value(forKey: K.healthkitKey)!]
        session.transferUserInfo(info)
        
    }
    
    func deleteAllLocalData(){
        do {
            let directoryContents : NSArray = try fileManager.contentsOfDirectory(atPath: documentDir) as NSArray
            print(directoryContents)
            
            for path in directoryContents {
                let filePath = documentDir + "/" + (path as! String)
                if filePath.contains(".csv") {
                    Log.info("Deleting \(filePath)")
                    try fileManager.removeItem(atPath: filePath)
                }
            }
                        
        } catch {
            print("Error deleting files: \(error)")
        }
    }
}
