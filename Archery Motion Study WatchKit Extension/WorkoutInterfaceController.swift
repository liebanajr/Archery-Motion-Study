//
//  workoutInterfaceController.swift
//  Archery Motion Study WatchKit Extension
//
//  Created by Juan I Rodriguez on 05/11/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import WatchKit
import Foundation
import CoreMotion
import WatchConnectivity
import HealthKit


class WorkoutInterfaceController: WKInterfaceController, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    
    
    @IBOutlet weak var timer: WKInterfaceTimer!
    @IBOutlet weak var calorieLabel: WKInterfaceLabel!
    @IBOutlet weak var heartRateLabel: WKInterfaceLabel!
    @IBOutlet weak var endLabel: WKInterfaceLabel!
    
    
    let motionManager = CMMotionManager()
    let healthStore = HKHealthStore()
    var workoutSession : HKWorkoutSession!
    var builder : HKLiveWorkoutBuilder!
    
    let queue = OperationQueue()
    let fileManager = FileManager()
    let session = WCSession.default
    let defaults = UserDefaults.standard
    
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
    var documentDir :String = ""
    
    var csvText = ""
    var fileReadyForTransfer : URL?
    var workoutInfo : WorkoutSessionDetails?
    
    let sampleInterval = K.sampleInterval

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        documentDir = paths.firstObject as! String
        print("Document directory: \(documentDir)")
        
        resetData()
        startWorkout()
        
//        Create a session identifier to group ends
        let formatter = DateFormatter()
        let timeZone = TimeZone(abbreviation: "UTC+2")
        formatter.timeZone = .some(timeZone!)
        formatter.dateFormat = K.dateFormat
        let date = formatter.string(from: Date())
        workoutInfo = WorkoutSessionDetails(sessionId: date)
                
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()        
    }
    
    @IBAction func addButtonPressed() {
        
        saveDataLocally(dataString: csvText)
        sendDataToiPhone()
        resetData()
        workoutInfo!.endCounter += 1
        endLabel.setText("\(workoutInfo!.endCounter)")
        
    }
    
    @IBAction func endButtonPressed() {
        
        saveDataLocally(dataString: csvText)
        sendDataToiPhone()
        endWorkout()
        resetData()
        self.dismiss()
        
    }
    
    func startWorkout(){
        
        print("Starting workout...")
        
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .archery
        workoutConfiguration.locationType = .outdoor
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration)
            builder = (workoutSession.associatedWorkoutBuilder())
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: workoutConfiguration)
            
            builder.delegate = self
            workoutSession.delegate = self
        } catch {
            fatalError("Unable to create the workout session!")
        }
        
        workoutSession?.prepare()
        workoutSession?.startActivity(with: Date())
        
        builder!.beginCollection(withStart: Date()) { (success, error) in
            if !success {
                print("Couldn't start collection of workout data: \(error!)")
                self.endWorkout()
                return
            }
            self.setDurationTimerDate(.running)
        }
                
        if motionManager.isDeviceMotionActive {
            
            print("Device motion is already active. Stopping updates...")
            endWorkout()
            return

        } else {
            
            if motionManager.isDeviceMotionAvailable {
                resetData()
                startMotionUpdates()
            }
        }
        
    }
    
    func setDurationTimerDate(_ sessionState: HKWorkoutSessionState) {
        /// Obtain the elapsed time from the workout builder.
        /// - Tag: ObtainElapsedTime
        let timerDate = Date(timeInterval: -self.builder!.elapsedTime, since: Date())
        print("Attempting to set timer with time: \(timerDate)")
        
        // Dispatch to main, because we are updating the interface.
        DispatchQueue.main.async {
            print("Updating timer...")
            self.timer.setDate(timerDate)
        }
        
        // Dispatch to main, because we are updating the interface.
        DispatchQueue.main.async {
            /// Update the timer based on the state we are in.
            /// - Tag: UpdateTimer
            sessionState == .running ? self.timer.start() : self.timer.stop()
        }
    }
    
    func endWorkout(){
        
        print("Ending workout session...")
//        When using private build we're not storing workout data on healthkit
        if K.saveWorkoutData {
            builder.endCollection(withEnd: Date()) { (success, error) in
                guard success else {
                    print("Error when ending builder collection: \(error!)")
                    return
                }
                self.builder.finishWorkout { (workout, error) in
                    if error != nil {
                        print("Error finishing workout: \(error!)")
                    }
                }
            }
        }
        workoutSession?.end()
        workoutSession = nil
        stopMotionUpdates()
        
    }
    
    //    Mark: Motion and UI
    
    func stopMotionUpdates() {
        
        print("Stopping motion updates...")
        motionManager.stopDeviceMotionUpdates()
        
    }
    
    func startMotionUpdates(){
        
        print("Starting Device Motion Updates...")

        var timeStamp : Double = 0.0
        
        motionManager.startDeviceMotionUpdates(to: self.queue) { (deviceMotion, error) in
            
            let motion = deviceMotion!

            let accX = String(format: K.sensorPrecision, motion.userAcceleration.x * K.sensorScaleFactor)
            let accY = String(format: K.sensorPrecision, motion.userAcceleration.y * K.sensorScaleFactor)
            let accZ = String(format: K.sensorPrecision, motion.userAcceleration.z * K.sensorScaleFactor)

            let girX = String(format: K.sensorPrecision, motion.rotationRate.x * K.sensorScaleFactor)
            let girY = String(format: K.sensorPrecision, motion.rotationRate.y * K.sensorScaleFactor)
            let girZ = String(format: K.sensorPrecision, motion.rotationRate.z * K.sensorScaleFactor)


            let motionDataString = "\(String(format: K.timeStampPrecision,timeStamp))" + K.csvSeparator + "\(accX)" + K.csvSeparator + "\(accY)" + K.csvSeparator + "\(accZ)" + K.csvSeparator + "\(girX)" + K.csvSeparator + "\(girY)" + K.csvSeparator + "\(girZ)\n"

            timeStamp += self.sampleInterval

            self.csvText.append(contentsOf: motionDataString)

        }
    }
    
    
    //    Mark: data management functions
    func resetData() {
        print("Resetting data...")
        csvText = K.csvTextHeader
        fileReadyForTransfer = nil
    }
    
    func saveDataLocally(dataString: String){
        
        let formatter = DateFormatter()
        let timeZone = TimeZone(abbreviation: "UTC+2")
        formatter.timeZone = .some(timeZone!)
        formatter.dateFormat = K.dateFormat
        let date = formatter.string(from: Date())
        let randNum = Int.random(in: 0...9999)
        let id = "\(randNum)"
        let category = defaults.string(forKey: K.bowTypeKey) ?? K.categoryValues[0]
        let hand = (defaults.string(forKey: K.handKey) ?? K.handValues[0]).replacingOccurrences(of: " ", with: "")
        
        let fileName = "\(category)_\(hand)_\(date)_\(id).csv"
        
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
            if let file = fileReadyForTransfer {
                print("Sending \(file.absoluteString) to iPhone...")
                let dictionary : [String : Any] = ["end" : workoutInfo!.endCounter , "sessionId" : workoutInfo!.sessionId , "calories" : workoutInfo!.cumulativeCaloriesBurned , "avgHR" : workoutInfo!.averageHeartRate , "maxHR" : workoutInfo!.maxHeartRate , "distance" : workoutInfo!.cumulativeDistance]
                session.transferFile(file, metadata: dictionary)
            }
            
        } else {
            print("Unable to transfer files because WC Session is inactive")
        }
    }
        
    //    Mark: HealthKit delegate methods
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        var from = ""
        switch toState {
        case .ended:
             from = "Ended"
        case .notStarted:
            from = "Not started"
        case .paused:
             from = "Paused"
        case .prepared:
             from = "Prepared"
        case .running:
             from = "Running"
        case .stopped:
             from = "Stopped"
        default:
             from = "XXX"
        }
        print("Workout session changed to \(from)")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error)")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didGenerate event: HKWorkoutEvent) {
        print("Generated workout event \(event)")
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        print("Workout builder collected some data...")
        print(collectedTypes)
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {
                return // Nothing to do.
            }
            
            // Calculate statistics for the type.
            let statistics = workoutBuilder.statistics(for: quantityType)
            
            DispatchQueue.main.async() {
                self.updateLabelForQuantityType(quantityType, statistics!)
            }
        }
    }
    
    func updateLabelForQuantityType(_ quantityType: HKQuantityType, _ statistics: HKStatistics){
                
        switch quantityType {
        case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning):
            let value = Int(statistics.sumQuantity()!.doubleValue(for: HKUnit.meter()))
            workoutInfo!.cumulativeDistance = value
//            distanceLabel.setText("\(value)")
            print("Updating distance label with: \(value)")
            return
        case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
            let value = Int(statistics.sumQuantity()!.doubleValue(for: HKUnit.kilocalorie()))
            workoutInfo!.cumulativeCaloriesBurned = value
            calorieLabel.setText("\(value)")
            print("Updating calorie label with: \(value)")
            return
        case HKQuantityType.quantityType(forIdentifier: .heartRate):
            let value = Int(statistics.mostRecentQuantity()!.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())))
            heartRateLabel.setText("\(value)")
            print("Updating heart rate label with: \(value)")
            
            let maxValue = Int(statistics.maximumQuantity()!.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())))
            let avgValue = Int(statistics.averageQuantity()!.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())))
            workoutInfo!.maxHeartRate = maxValue
            workoutInfo!.averageHeartRate = avgValue
            
            return
        default:
            return
        }
        
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
//        TODO
        print("Builder received an event!")
    }
    
}
