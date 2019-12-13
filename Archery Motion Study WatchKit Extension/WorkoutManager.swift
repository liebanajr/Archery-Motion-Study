//
//  WorkoutController.swift
//  Archery Motion Study WatchKit Extension
//
//  Created by Juan I Rodriguez on 12/12/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import UIKit
import HealthKit

protocol WorkoutManagerDelegate {
    
    func didReceiveWorkoutData(_ workoutData: WorkoutSessionDetails)
    
}

class WorkoutManager: NSObject {
    
    var delegate: WorkoutManagerDelegate?

    var workoutData : WorkoutSessionDetails?
    
    var workoutSession : HKWorkoutSession?
    var builder : HKLiveWorkoutBuilder?
    var healthStore : HKHealthStore?
    var workoutConfiguration : HKWorkoutConfiguration?
    
    var motionManager: MotionManager?
    var filesManager : FilesManager?
    
    override init() {
        
        super.init()
        
        let formatter = DateFormatter()
        let timeZone = TimeZone(abbreviation: "UTC+2")
        formatter.timeZone = .some(timeZone!)
        formatter.dateFormat = K.dateFormat
        let id = formatter.string(from: Date())
        
        workoutData = WorkoutSessionDetails(sessionId: id)
        
        filesManager = FilesManager()
        
        healthStore = HKHealthStore()
        workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration!.activityType = .archery
        workoutConfiguration?.locationType = .outdoor
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
    
//   MARK: Workout lifecycle
    
    func startWorkout(){
        
        workoutSession!.startActivity(with: Date())
        builder!.beginCollection(withStart: Date()) { (success, error) in
            guard success else {
                fatalError("Error collecting workout data: \(error!)")
            }
        }
        motionManager = MotionManager()
        motionManager!.startMotionUpdates()
        
    }
    
    func pauseWorkout(){
        
        workoutSession!.pause()
        saveWorkout()
        
    }
    
    func resumeWorkout(){
        
        workoutSession!.resume()
        motionManager = MotionManager()
        motionManager!.startMotionUpdates()
        workoutData!.endCounter += 1
    }
    
    func endWorkout(){
        
        workoutSession!.end()
        builder!.endCollection(withEnd: Date()) { (success, error) in
            guard success else {
                fatalError("Couldn't finish collection: \(error!)")
            }
            if K.saveWorkoutData {
                self.builder!.finishWorkout { (_, error) in
                    if error != nil {
                        fatalError("Couldn't finish workout: \(error!)")
                    }
                }
            }
        }
        
        if motionManager != nil {
            
            saveWorkout()
            
        }
        
    }
    
//    MARK: Other functions
    
    func saveWorkout(){
        
        motionManager!.stopMotionUpdates()
        DispatchQueue.global(qos: .utility).async {
            let csv = self.motionManager!.toCSVString()
            let url = self.filesManager!.saveDataLocally(dataString: csv)!
            self.filesManager!.sendDataToiPhone(url, with: self.workoutData!)
            self.motionManager = nil
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
            
            delegate!.didReceiveWorkoutData(workoutData!)
        }
    }
    
    func updateWorkoutForQuantityType(_ quantityType: HKQuantityType, _ statistics: HKStatistics){
                    
        switch quantityType {
            case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning):
                let value = Int(statistics.sumQuantity()!.doubleValue(for: HKUnit.meter()))
                workoutData!.cumulativeDistance = value
                return
            case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                let value = Int(statistics.sumQuantity()!.doubleValue(for: HKUnit.kilocalorie()))
                workoutData!.cumulativeCaloriesBurned = value
                return
            case HKQuantityType.quantityType(forIdentifier: .heartRate):
                let value = Int(statistics.mostRecentQuantity()!.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())))
                let maxValue = Int(statistics.maximumQuantity()!.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())))
                let avgValue = Int(statistics.averageQuantity()!.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())))
                
                workoutData!.currentHeartRate = value
                workoutData!.maxHeartRate = maxValue
                workoutData!.averageHeartRate = avgValue
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
    }
    
    
    
    
}
