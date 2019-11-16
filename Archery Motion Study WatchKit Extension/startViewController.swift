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

class startViewController: WKInterfaceController {
    
    @IBOutlet weak var startButton: WKInterfaceButton!
    
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
    var documentDir :String = ""
    let defaults = UserDefaults.standard
    let fileManager = FileManager()
    
    override func awake(withContext context: Any?) {
        
        super.awake(withContext: context)
        
        if #available(watchOSApplicationExtension 6.0, *) {
            startButton.setBackgroundImage(UIImage(systemName: "play.circle.fill"))
        }
        
        documentDir = paths.firstObject as! String
        print("Document directory: \(documentDir)")
        
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
                print(error)
            } else {
                print("HealthKit successfully authorized!")
            }
        }
        
    }
    
    func userDefaultsExists () -> Bool {
        
        if defaults.string(forKey: K.bowTypeKey) == nil || defaults.string(forKey: K.handKey) == nil {
                    
            defaults.set("Recurve", forKey: K.bowTypeKey)
            defaults.set("Bow", forKey: K.handKey)
            defaults.set("Shot", forKey: K.sessionTypeKey)
            
            let action1 = WKAlertAction.init(title: "OK", style:.default) {
                       print("Okayed nil defaults message")
                   }
            
            let message = "Por favor, antes de comenzar, comprueba que los ajustes son correctos deslizando hacia la izquierda."

            presentAlert(withTitle: "Ajustes iniciales", message: message, preferredStyle:.alert, actions: [action1])
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
            presentController(withName: "WorkoutInterfaceController", context: self)
        }
        
    }
    
    @IBAction func deleteButtonPressed() {
        self.deleteAllLocalData()
    }
    @IBAction func settingsButtonPressed() {
        
        presentController(withName: "settingsInterfaceController", context: self)
        
    }
    
    func deleteAllLocalData(){
        do {
            let directoryContents : NSArray = try fileManager.contentsOfDirectory(atPath: documentDir) as NSArray
            print(directoryContents)
            
            for path in directoryContents {
                try fileManager.removeItem(atPath: documentDir + "/" + (path as! String))
            }
                        
        } catch {
            print("Error deleting files: \(error)")
        }
    }
}
