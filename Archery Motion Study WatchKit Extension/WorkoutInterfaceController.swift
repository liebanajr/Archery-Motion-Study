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
import ShotsWorkoutManager

enum SessionState {
    case workoutRunning
    case workoutPaused
    case workoutFinished
    
}

class WorkoutInterfaceController: WKInterfaceController, ShotsWorkoutDelegate, SyncWorkoutManagerDelegate {
    
    @IBOutlet weak var timer: WKInterfaceTimer!
    @IBOutlet weak var calorieLabel: WKInterfaceLabel!
    @IBOutlet weak var heartRateLabel: WKInterfaceLabel!
    @IBOutlet weak var endLabel: WKInterfaceLabel!
    @IBOutlet var addButton: WKInterfaceButton!
    @IBOutlet var addButtonBackground: WKInterfaceGroup!
    @IBOutlet var endButton: WKInterfaceButton!
    @IBOutlet var endButtonBackground: WKInterfaceGroup!
    
    var arrowCount : Int = 0
    
    var workoutManager = ShotsWorkoutManager.shared
    let syncManager = SyncWorkoutManager.shared
    
    var timerStopInterval : TimeInterval?
    var timerRestartDate : Date?
    var timerStartDate : Date?
    
    var startController : startViewController?
        
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        startController = context as? startViewController

        
        let modelWidth = WKInterfaceDevice.current().screenBounds.width*2
        
        switch modelWidth {
        case 272.0:
                endButtonBackground.setWidth(68)
                endButtonBackground.setHeight(45)
                addButtonBackground.setWidth(68)
                addButtonBackground.setHeight(45)
        case 312.0:
                endButtonBackground.setWidth(75)
                endButtonBackground.setHeight(50)
                addButtonBackground.setWidth(75)
                addButtonBackground.setHeight(50)
        case 324.0:
                endButtonBackground.setWidth(80)
                endButtonBackground.setHeight(55)
                addButtonBackground.setWidth(80)
                addButtonBackground.setHeight(55)
        case 368.0:
                endButtonBackground.setWidth(85)
                endButtonBackground.setHeight(60)
                addButtonBackground.setWidth(80)
                addButtonBackground.setHeight(60)
            default:
                print("Watch model not supported")
        }

        workoutManager.delegate = self
        workoutManager.isSaveWorkoutActive = K.isSaveWorkoutActive
        let formatter = DateFormatter()
        let timeZone = TimeZone(identifier: "Europe/Paris")
        formatter.timeZone = .some(timeZone!)
        formatter.dateFormat = K.dateFormat
        let id = formatter.string(from: Date())
        workoutManager.startWorkout(id: id, type: .FREE)
        
        syncManager.delegate = self
                
        timerStopInterval = 0.0
        timerStartDate = Date(timeIntervalSinceNow : timerStopInterval!)
        timerRestartDate = timerStartDate
        timer.setDate(timerStartDate!)
        timer.start()
                
    }
    
    func didFinishSaveTasks(){
        print("Task finished. Enabling buttons")
        DispatchQueue.main.async {
            self.addButton.setEnabled(true)
            self.addButtonBackground.setAlpha(1.0)
            self.endButton.setEnabled(true)
            self.endButtonBackground.setAlpha(1.0)
        }
        
        if workoutManager.isWorkoutRunning == nil {
            print("Task finished. Workout finished. Dismissing controller")
            DispatchQueue.main.async {
                self.dismiss()
            }
        }
        
    }
    
    func didStartSaveTasks(){
        print("Task starting. Disabling buttons")
        DispatchQueue.main.async {
            self.addButton.setEnabled(false)
            self.addButtonBackground.setAlpha(0.5)
            self.endButton.setEnabled(false)
            self.endButtonBackground.setAlpha(0.5)
        }
        
    }
    
    func restartTimer(){

        timer.setDate(Date(timeIntervalSinceNow: timerStopInterval!))
        timerRestartDate = Date(timeIntervalSinceNow: 0.0)
        timer.start()
    }
    
    func stopTimer(){
        timerStopInterval = timerRestartDate!.timeIntervalSince(Date(timeIntervalSinceNow: 0.0)) + timerStopInterval!
        print("Stopping timer with interval \(timerStopInterval!)")
        timer.stop()
    }
    
    @IBAction func addButtonPressed() {
        
        if let isRunning = workoutManager.isWorkoutRunning {
            if isRunning {
                workoutManager.pauseWorkout()
            } else {
                workoutManager.resumeWorkout()
                workoutManager.sessionData!.endCounter += 1
                endLabel.setText("\(workoutManager.sessionData!.endCounter)")
            }
        } else {
            Log.error("Workout was stopped when trying to add end")
        }
        
    }
    
    @IBAction func endButtonPressed() {
        if let isRunning = workoutManager.isWorkoutRunning, isRunning {
            workoutManager.pauseWorkout()
        }
        
        presentController(withName: "arrowNumberPicker", context: self)
    }
    
    func workoutManager(didUpdateSession data: ShotsSessionDetails) {
        DispatchQueue.main.async {
            self.calorieLabel.setText(String(data.cumulativeCaloriesBurned))
            self.heartRateLabel.setText(String(data.currentHeartRate))
        }
    }
    
    func workoutManager(didStopWorkout withData: ShotsSessionDetails) {
        stopTimer()
        syncManager.sendArrowCount()
        DispatchQueue.main.async {
            self.dismiss()
        }
    }
    func workoutManager(didLockScreen withData: ShotsSessionDetails?) {
//        Nothing to do
    }
    func workoutManager(didStartWorkout withData: ShotsSessionDetails) {
//        Nothing to do
    }
    func workoutManager(didPauseWorkout withData: ShotsSessionDetails) {
        addButton.setBackgroundImage(UIImage(systemName: "play.fill"))
        stopTimer()
        syncManager.saveWorkout()
    }
    func workoutManager(didResumeWorkout withData: ShotsSessionDetails) {
        addButton.setBackgroundImage(UIImage(systemName: "plus"))
        endLabel.setText("\(workoutManager.sessionData!.endCounter)")
        restartTimer()
    }
    
    func didEndWorkout(){
        workoutManager.stopWorkout()
    }
    
    
}
