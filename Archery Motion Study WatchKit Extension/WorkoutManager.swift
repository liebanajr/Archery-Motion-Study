//
//  WorkoutController.swift
//  Archery Motion Study WatchKit Extension
//
//  Created by Juan I Rodriguez on 12/12/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import UIKit
import HealthKit
import WatchConnectivity
import WatchKit

protocol WorkoutManagerDelegate {
    
    func didReceiveWorkoutData(_ workoutData: WorkoutSessionDetails)
    func didStartSaveTasks()
    func didFinishSaveTasks()
}

class WorkoutManager: NSObject {
    
    var delegate: WorkoutManagerDelegate?

    var workoutData : WorkoutSessionDetails
    
    var workoutSession : HKWorkoutSession?
    var builder : HKLiveWorkoutBuilder?
    var healthStore : HKHealthStore?
    var workoutConfiguration : HKWorkoutConfiguration?
    
    var motionManager: MotionManager?
    var asyncDataMotionManager : MotionManager?
    let filesManager = FilesManager()
    
    let wcSession = WCSession.default
        
    override init() {
        
        let formatter = DateFormatter()
        let timeZone = TimeZone(abbreviation: "UTC+2")
        formatter.timeZone = .some(timeZone!)
        formatter.dateFormat = K.dateFormat
        let id = formatter.string(from: Date())
        
        workoutData = WorkoutSessionDetails(sessionId: id)
                
        super.init()
        
        if K.isSaveWorkoutActive {
            healthStore = HKHealthStore()
            workoutConfiguration = HKWorkoutConfiguration()
            workoutConfiguration!.activityType = .archery
            workoutConfiguration!.locationType = .outdoor
            
            do {
                workoutSession = try HKWorkoutSession(healthStore: healthStore!, configuration: workoutConfiguration!)
                builder = workoutSession!.associatedWorkoutBuilder()
                builder!.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore!, workoutConfiguration: workoutConfiguration!)
                
                workoutSession!.delegate = self
                builder!.delegate = self
            } catch {
                print("Unable to create workout session")
            }
        }
    }
    
//   MARK: Workout lifecycle
    
    func startWorkout(){
        
//        WE don't create workout and helathkit objects if no workout save is needed (development)
        if K.isSaveWorkoutActive {
            do {
                workoutSession = try HKWorkoutSession(healthStore: healthStore!, configuration: workoutConfiguration!)
                builder = workoutSession!.associatedWorkoutBuilder()
                builder!.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore!, workoutConfiguration: workoutConfiguration!)

                workoutSession!.delegate = self
                builder!.delegate = self
            } catch {
                Log.warning("Unable to create workout session: \(error)")
            }
        } else {
            Log.warning("No healthkit objects are being created")
        }
        
        workoutSession?.startActivity(with: Date())
        builder?.beginCollection(withStart: Date()) { (success, error) in
            guard success else {
                fatalError("Error collecting workout data: \(error!)")
            }
        }
        motionManager = MotionManager()
        
        if WKInterfaceDevice.current().crownOrientation == .left {
            Log.info("Inverting XY for crown left")
            motionManager?.isCrownInverted = true
        }
        if WKInterfaceDevice.current().wristLocation == .right {
            Log.info("Inverting XY for Watch on right hand")
            motionManager?.isWatchHandInverted = true
        }
//        if UserDefaults.standard.value(forKey: K.handKey) as? String == K.handValues.last {
//            Log.info("Inverting XY for watch on String hand")
//            motionManager?.isWatchLocationInverted = true
//        }
        
        motionManager?.startMotionUpdates()
        
    }
    
    func pauseWorkout(){
        
        workoutSession?.pause()
        motionManager?.pauseMotionUpdates()
        workoutData.elapsedSeconds = Int(motionManager!.timeStamp)
        
    }
    
    func resumeWorkout(){
        
        workoutSession?.resume()
        motionManager?.resumeMotionUpdates()
    }
    
    func endWorkout(){
        
        Log.trace("Trying to end workout")
        workoutSession?.end()
        workoutData.endDate = Date()
        builder?.endCollection(withEnd: Date()) { (success, error) in
            guard success else {
                Log.error("Couldn't finish collection: \(error!)")
                return
            }
            self.builder?.finishWorkout { (_, error) in
                if error != nil {
                    Log.error("Couldn't finish workout: \(error!)")
                }
            }
        }
        
    }
    
    func sendArrowCount() {
        wcSession.sendMessage(["arrowCount":workoutData.arrowCounter,"sessionId" : workoutData.sessionId], replyHandler: nil, errorHandler: nil)
        delegate?.didFinishSaveTasks()
    }
    
//    MARK: Other functions
    
    func saveWorkout(){
        print("Saving workout")
//        let nc = NotificationCenter.default
//        nc.post(name: Notification.Name("saveTaskStarted"), object: nil)
        delegate?.didStartSaveTasks()
        asyncDataMotionManager = motionManager
        DispatchQueue.global(qos: .utility).async {
            let csv = self.asyncDataMotionManager!.toCSVString()
            if let url = self.filesManager.saveDataLocally(dataString: csv) {
                self.workoutData.elapsedSeconds = Int(self.motionManager!.timeStamp)
                self.filesManager.sendDataToiPhone(url, with: self.workoutData)
            }
//            let nc = NotificationCenter.default
//            nc.post(name: Notification.Name("saveTaskFinished"), object: nil)
            self.delegate?.didFinishSaveTasks()
        }
        
    }
    
}

// MARK: HKLiveWorkoutBuilderDelegate methods

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {
                return // Nothing to do.
            }
            
            // Calculate statistics for the type.
            let statistics = workoutBuilder.statistics(for: quantityType)!
            self.updateWorkoutForQuantityType(quantityType, statistics)
            
            delegate!.didReceiveWorkoutData(workoutData)
        }
    }
    
    func updateWorkoutForQuantityType(_ quantityType: HKQuantityType, _ statistics: HKStatistics){
                    
        switch quantityType {
            case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning):
                let value = Int(statistics.sumQuantity()!.doubleValue(for: HKUnit.meter()))
                workoutData.cumulativeDistance = value
                return
            case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                let value = Int(statistics.sumQuantity()!.doubleValue(for: HKUnit.kilocalorie()))
                workoutData.cumulativeCaloriesBurned = value
                return
            case HKQuantityType.quantityType(forIdentifier: .heartRate):
                let value = Int(statistics.mostRecentQuantity()!.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())))
                let maxValue = Int(statistics.maximumQuantity()!.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())))
                let minValue = Int(statistics.minimumQuantity()!.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())))
                let avgValue = Int(statistics.averageQuantity()!.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())))
                
                workoutData.currentHeartRate = value
                if maxValue > workoutData.maxHeartRate {
                    workoutData.maxHeartRate = maxValue
                    workoutData.maxHRAtEnd = workoutData.endCounter
                }
                if minValue < workoutData.minHeartRate {
                    workoutData.minHeartRate = minValue
                    workoutData.minHRAtEnd = workoutData.endCounter
                }
                workoutData.averageHeartRate = avgValue
                return
            default:
                return
        }
            
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        
    }
    
}

//    MARK: HKWorkoutSessionDelegate methods

extension WorkoutManager: HKWorkoutSessionDelegate {
    
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
        print("Workout session failed with error: \(error)")
        wcSession.sendMessage(["errorMessage":error], replyHandler: nil, errorHandler: nil)
    }
    
    
    
    
}
