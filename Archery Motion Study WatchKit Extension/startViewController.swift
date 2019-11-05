//
//  InterfaceController.swift
//  Archery Motion Study WatchKit Extension
//
//  Created by Juan Ignacio Rodríguez Liébana on 13/09/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import WatchKit
import Foundation
import CoreMotion
import WatchConnectivity
import HealthKit

class startViewController: WKInterfaceController, WCSessionDelegate, HKWorkoutSessionDelegate {
    
    @IBOutlet weak var startButton: WKInterfaceButton!
    
    let motionManager = CMMotionManager()
    
    let healthStore = HKHealthStore()
    var workoutSession : HKWorkoutSession?
    
    let queue = OperationQueue()
    let fileManager = FileManager()
    let session = WCSession.default
    let defaults = UserDefaults.standard
    
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
    var documentDir :String = ""
    
    let csvTextHeader = "Timestamp;Accelerometer X;Accelerometer Y;Accelerometer Z;Gyroscope X;Gyroscope Y;Gyroscope Z\n"
    var csvText = ""
    var fileReadyForTransfer = URL(fileURLWithPath: "")
    
    let sampleInterval = 1.0/20.0
    
    override func awake(withContext context: Any?) {
        
        super.awake(withContext: context)
        
        if #available(watchOSApplicationExtension 6.0, *) {
            startButton.setBackgroundImage(UIImage(systemName: "play.circle.fill"))
        }
                
        motionManager.showsDeviceMovementDisplay = true
        motionManager.deviceMotionUpdateInterval = sampleInterval
        
        documentDir = paths.firstObject as! String
        print("Document directory: \(documentDir)")
        
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
        
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        
    }
    
    func userDefaultsExists () -> Bool {
        
        if defaults.string(forKey: "Category") == nil || defaults.string(forKey: "Hand") == nil {
                    
            defaults.set("Recurve", forKey: "Category")
            defaults.set("Bow", forKey: "Hand")
            
            let action1 = WKAlertAction.init(title: "OK", style:.default) {
                       print("Okayed nil defaults message")
                   }
            
            let message = "Por favor, antes de comenzar, comprueba que los ajustes son correctos deslizando hacia la izquierda."

            presentAlert(withTitle: "Ajustes iniciales", message: message, preferredStyle:.alert, actions: [action1])
            return false
        }
        return true
        
    }
    
//    Mark: Motion and UI
    
    func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
        workoutSession?.end()
        workoutSession = nil
        if #available(watchOSApplicationExtension 6.0, *) {
            startButton.setBackgroundImage(UIImage(systemName: "play.circle.fill"))
        } else {
            // Fallback on earlier versions
            startButton.setBackgroundImage(UIImage(named: "play"))
        }

        let formatter = DateFormatter()
        let timeZone = TimeZone(abbreviation: "UTC+2")
        formatter.timeZone = .some(timeZone!)
        formatter.dateFormat = "ddMMyy'T'HHmmss"
        let date = formatter.string(from: Date())
        let category = defaults.string(forKey: "Category")!
        let hand = defaults.string(forKey: "Hand")! + "Hand"
        let fileName = "\(category)_\(hand)_\(date).csv"
        
        saveDataLocally(dataString: csvText, fileName: fileName)
        sendDataToiPhone()
    }
    
    func startMotionUpdates(){
        if #available(watchOSApplicationExtension 6.0, *) {
            startButton.setBackgroundImage(UIImage(systemName: "pause.circle.fill"))
        } else {
            // Fallback on earlier versions
            startButton.setBackgroundImage(UIImage(named: "pause"))
        }

        var timeStamp : Double = 0.0
        
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .archery
        workoutConfiguration.locationType = .outdoor
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration)
           } catch {
               fatalError("Unable to create the workout session!")
           }
        
        workoutSession?.prepare()
        workoutSession?.startActivity(with: nil)
        
        motionManager.startDeviceMotionUpdates(to: self.queue) { (deviceMotion, error) in
            
            let motion = deviceMotion!

            let accX = String(format: "%.3f", motion.userAcceleration.x * 100)
            let accY = String(format: "%.3f", motion.userAcceleration.y * 100)
            let accZ = String(format: "%.3f", motion.userAcceleration.z * 100)

            let girX = String(format: "%.3f", motion.rotationRate.x * 100)
            let girY = String(format: "%.3f", motion.rotationRate.y * 100)
            let girZ = String(format: "%.3f", motion.rotationRate.z * 100)


            let motionDataString = "\(String(format: "%.2f",timeStamp));\(accX);\(accY);\(accZ);\(girX);\(girY);\(girZ)\n"

            timeStamp += self.sampleInterval

            self.csvText.append(contentsOf: motionDataString)

        }
    }
    
    @IBAction func startButtonPressed() {
        
        print("Start button pressed!")
        
        if !userDefaultsExists() {
            return
        }
        
        presentController(withName: "WorkoutInterfaceController", context: self)
        return
                
        if motionManager.isDeviceMotionActive {
            
            print("Device motion is already active. Stopping updates...")
            stopMotionUpdates()

        } else {
            
            if motionManager.isDeviceMotionAvailable {
                resetData()
                print("Starting Device Motion Updates...")
                startMotionUpdates()
            }
        }
    }
    
//    Mark: data management functions
    func resetData() {
        print("Resetting data...")
        csvText = csvTextHeader
        fileReadyForTransfer = URL(fileURLWithPath: "")
    }
    
    func saveDataLocally(dataString: String, fileName: String){
        
        let url = URL(fileURLWithPath: documentDir + "/" + fileName)
        print("Guardando datos en: \(url.absoluteString)")
        
        do{
            try dataString.write(to: url, atomically: true, encoding: .utf8)
            fileReadyForTransfer = url
        } catch {
            print("Error guardando datos: \(error)")
        }
        
    }
    
    func sendDataToiPhone(){
        if session.activationState == .activated {
            print("Sending \(fileReadyForTransfer.absoluteString) to iPhone...")
            session.transferFile(fileReadyForTransfer, metadata: nil)
        } else {
            print("Unable to transfer files because WC Session is inactive")
        }
    }
    
    @IBAction func deleteButtonPressed() {
        do {
            let directoryContents : NSArray = try fileManager.contentsOfDirectory(atPath: documentDir) as NSArray
            print(directoryContents)
            
            for path in directoryContents {
                try fileManager.removeItem(atPath: documentDir + "/" + (path as! String))
            }
            
            resetData()
            
        } catch {
            print("Error deleting files: \(error)")
        }
        
    }
    
//    Mark - WatchConnectivity Methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if error != nil {
            print("Activation error: \(error!)")
        }
    }
    
//    Mark: HealthKit delegate methods
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print("Workout session changed to \(toState)")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error)")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didGenerate event: HKWorkoutEvent) {
        print("Generated workout event \(event)")
    }
}
