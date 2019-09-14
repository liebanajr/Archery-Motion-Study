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

class InterfaceController: WKInterfaceController, WCSessionDelegate {
    
    @IBOutlet weak var startButton: WKInterfaceButton!
    @IBOutlet weak var sendButton: WKInterfaceButton!
    
    let motionManager = CMMotionManager()
    let queue = OperationQueue()
    let fileManager = FileManager()
    let session = WCSession.default
    
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
    var documentDir :String = ""
    
    var csvText = "Timestamp,Accelerometer X,Accelerometer Y,Accelerometer Z,Gyroscope X,Gyroscope Y,Gyroscope Z"
    var fileReadyForTransfer = URL(fileURLWithPath: "")
    
    override func awake(withContext context: Any?) {
        
        super.awake(withContext: context)
        motionManager.showsDeviceMovementDisplay = true
        motionManager.deviceMotionUpdateInterval = 0.5
        
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
    @IBAction func startButtonPressed() {
        
        print("Start button pressed!")
        if motionManager.isDeviceMotionActive {
            print("Device motion is already active. Stopping updates...")
            motionManager.stopDeviceMotionUpdates()
            startButton.setTitle("Start")
            sendButton.setEnabled(true)
            
            let fileName = "MotionData\(Date()).csv"
            saveDataLocally(dataString: csvText, fileName: fileName)
            
            
        } else {
            
            resetData()
            
            if motionManager.isDeviceMotionAvailable {
                print("Starting Device Motion Updates...")
                startButton.setTitle("Stop")
                
                motionManager.startDeviceMotionUpdates(to: self.queue) { (deviceMotion, error) in
                                                                                
                    let accX = deviceMotion?.userAcceleration.x
                    let accY = deviceMotion?.userAcceleration.y
                    let accZ = deviceMotion?.userAcceleration.z
                    
                    let girX = deviceMotion?.rotationRate.x
                    let girY = deviceMotion?.rotationRate.y
                    let girZ = deviceMotion?.rotationRate.z
                    
                    let motionDataString = "\(accX!),\(accY!),\(accZ!),\(girX!),\(girY!),\(girZ!)"
                    
                    self.csvText.append(contentsOf: motionDataString)
                                        
//                    DispatchQueue.main.async {
//
//                        TODO : Update UI and save device motion data
//
//                    }
                    
                }
            }
        }
    }
    
    func resetData() {
        print("Resetting data...")
        csvText = "Timestamp,Accelerometer X,Accelerometer Y,Accelerometer Z,Gyroscope X,Gyroscope Y,Gyroscope Z"
        fileReadyForTransfer = URL(fileURLWithPath: "")
        sendButton.setEnabled(false)
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
    
    func sendDataToiPhone() -> Bool{
        if session.activationState == .activated {
            print("Sending \(fileReadyForTransfer.absoluteString) to iPhone...")
            session.transferFile(fileReadyForTransfer, metadata: nil)
            return true
        } else {
            print("Unable to transfer files because WC Session is inactive")
            return false
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
    @IBAction func sendButtonPressed() {
        
        if sendDataToiPhone() {
            sendButton.setEnabled(false)
        }
        
    }
    
//    Mark - WatchConnectivity Methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if error != nil {
            print("Activation error: \(error)")
        }
    }
    
}
