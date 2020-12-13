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

class WorkoutInterfaceController: WKInterfaceController, ShotsWorkoutDelegate {
    
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
    var asyncDataMotionManager : ShotsMotionManager?
    let wcSession = WCSession.default
    
    let filesManager = FilesManager()
    
    var timerStopInterval : TimeInterval?
    var timerRestartDate : Date?
    var timerStartDate : Date?
    
    var sessionState : SessionState?
    
    var previousSessionState : SessionState?
    
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
        
        sessionState = .workoutRunning
        

        workoutManager.delegate = self
        workoutManager.startWorkout(id: "no_id", type: nil)
        workoutManager.isSaveWorkoutActive = K.isSaveWorkoutActive
        
        startController!.workoutManager = workoutManager
        startController!.sessionState = sessionState!
                
        timerStopInterval = 0.0
        timerStartDate = Date(timeIntervalSinceNow : timerStopInterval!)
        timerRestartDate = timerStartDate
        timer.setDate(timerStartDate!)
        timer.start()
                
    }
    
    @objc func didFinishSaveTasks(){
        print("Task finished. Enabling buttons")
        DispatchQueue.main.async {
            self.addButton.setEnabled(true)
            self.addButtonBackground.setAlpha(1.0)
            self.endButton.setEnabled(true)
            self.endButtonBackground.setAlpha(1.0)
        }
        
        if sessionState == .workoutFinished {
            print("Task finished. Workout finished. Dismissing controller")
            DispatchQueue.main.async {
                self.dismiss()
            }
        }
        
    }
    
    @objc func didStartSaveTasks(){
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
    
    override func didAppear() {
        
        print("Appeared")
        
        if let previous = previousSessionState {
            if previous == .workoutRunning {
                print("Workout was preivously running. Resuming timer and workout")
                sessionState = .workoutRunning
                startController!.sessionState = sessionState!
                restartTimer()
                workoutManager.resumeWorkout()
            } else if previous == .workoutPaused {
                
            }
        }
        previousSessionState = nil
        
    }
    
    @IBAction func addButtonPressed() {
        
        if sessionState! == .workoutRunning {
            
            sessionState = .workoutPaused
            startController!.sessionState = sessionState!
            addButton.setBackgroundImage(UIImage(systemName: "play.fill"))
            stopTimer()
            workoutManager.pauseWorkout()
            self.saveWorkout()
            
            
        } else if sessionState! == .workoutPaused {
            
            sessionState = .workoutRunning
            startController!.sessionState = sessionState!
            addButton.setBackgroundImage(UIImage(systemName: "plus"))
            workoutManager.resumeWorkout()
            workoutManager.sessionData!.endCounter += 1
            endLabel.setText("\(workoutManager.sessionData!.endCounter)")
            restartTimer()
        }
        
    }
    
    @IBAction func endButtonPressed() {
        previousSessionState = sessionState!
        if sessionState! == .workoutRunning {
            sessionState = .workoutPaused
            startController!.sessionState = sessionState!
            stopTimer()
            workoutManager.pauseWorkout()
            self.saveWorkout()
        } else if sessionState! == .workoutPaused {
            previousSessionState = .workoutPaused
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
        self.sessionState = .workoutFinished
        startController!.sessionState = sessionState!
        self.previousSessionState = .workoutFinished
        self.sendArrowCount()
        print("Calling end workout in workout interface")
    }
    func workoutManager(didLockScreen withData: ShotsSessionDetails?) {
//        Nothing to do
    }
    func workoutManager(didStartWorkout withData: ShotsSessionDetails) {
//        Nothing to do
    }
    func workoutManager(didPauseWorkout withData: ShotsSessionDetails) {
//        Nothing to do
    }
    func workoutManager(didResumeWorkout withData: ShotsSessionDetails) {
//        Nothing to do
    }
    
    func didEndWorkout(){
        workoutManager.stopWorkout()
    }
    
    func saveWorkout(){
        print("Saving workout")
        self.didStartSaveTasks()
        asyncDataMotionManager = workoutManager.motionManager
        DispatchQueue.global(qos: .utility).async {
            let csv = self.asyncDataMotionManager!.toCSVString()
            if let url = self.filesManager.saveDataLocally(dataString: csv) {
                self.filesManager.sendDataToiPhone(url, with: self.workoutManager.sessionData!)
            }
            self.didFinishSaveTasks()
        }
        
    }
    
    func sendArrowCount() {
        wcSession.sendMessage(["arrowCount":workoutManager.sessionData!.arrowCounter,"sessionId" : workoutManager.sessionData!.sessionId], replyHandler: nil, errorHandler: nil)
        self.didFinishSaveTasks()
    }
    
    
}
