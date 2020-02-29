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

enum SessionState {
    case workoutRunning
    case workoutPaused
    
}

class WorkoutInterfaceController: WKInterfaceController, WorkoutManagerDelegate {
    
    @IBOutlet weak var timer: WKInterfaceTimer!
    @IBOutlet weak var calorieLabel: WKInterfaceLabel!
    @IBOutlet weak var heartRateLabel: WKInterfaceLabel!
    @IBOutlet weak var endLabel: WKInterfaceLabel!
    @IBOutlet var addButton: WKInterfaceButton!
    @IBOutlet var endButton: WKInterfaceButton!
    
    var arrowCount : Int = 0
    
    var workoutManager : WorkoutManager?
    
    var timerStopInterval : TimeInterval?
    var timerRestartDate : Date?
    var timerStartDate : Date?
    
    var sessionState : SessionState?
    
    var previousSessionState : SessionState?
        
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(enableButtons), name: Notification.Name("saveTaskFinished"), object: nil)
        nc.addObserver(self, selector: #selector(disableButtons), name: Notification.Name("saveTaskStarted"), object: nil)
        
        let model = WKInterfaceDevice.current().name
        
        let start = model.index(model.endIndex, offsetBy: -4)
        let end = model.index(model.endIndex, offsetBy: -2)
        let range = start..<end
         
        let modelSize = Int(model[range])
        
        switch modelSize {
        case 40:
            addButton.setWidth(52)
            endButton.setWidth(52)
        case 42:
            addButton.setWidth(55)
            endButton.setWidth(55)
        case 44:
            addButton.setWidth(60)
            endButton.setWidth(60)
        default:
            print("Watch model not supported")
        }
        
        sessionState = .workoutRunning

        workoutManager = WorkoutManager()
        workoutManager!.delegate = self
        workoutManager!.startWorkout()
        
        
        timerStopInterval = 0.0
        timerStartDate = Date(timeIntervalSinceNow : timerStopInterval!)
        timerRestartDate = timerStartDate
        timer.setDate(timerStartDate!)
        timer.start()
                
    }
    
    @objc func enableButtons(){
        print("Task finished. Enabling buttons")
        DispatchQueue.main.async {
            self.addButton.setEnabled(true)
            self.endButton.setEnabled(true)
        }
        
    }
    
    @objc func disableButtons(){
        print("Task starting. Disabling buttons")
        DispatchQueue.main.async {
            self.addButton.setEnabled(false)
            self.endButton.setEnabled(false)
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
                restartTimer()
                workoutManager!.resumeWorkout()
            } else if previous == .workoutPaused {
                
            }
        }
        previousSessionState = nil
        
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
        
        if sessionState! == .workoutRunning {
            
            sessionState = .workoutPaused
            addButton.setBackgroundImage(UIImage(systemName: "play"))
            addButton.setBackgroundColor(#colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1))
            stopTimer()
            workoutManager!.pauseWorkout()
            workoutManager!.saveWorkout()
            
            
        } else if sessionState! == .workoutPaused {
            
            sessionState = .workoutRunning
            addButton.setBackgroundColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
            addButton.setBackgroundImage(UIImage(systemName: "plus"))
            workoutManager!.resumeWorkout()
            workoutManager!.workoutData!.endCounter += 1
            endLabel.setText("\(workoutManager!.workoutData!.endCounter)")
            restartTimer()
        }
        
    }
    
    @IBAction func endButtonPressed() {
        
//        let action2 = WKAlertAction.init(title: NSLocalizedString("finish", comment: ""), style:.destructive) {
//            self.timer.stop()
//            self.workoutManager!.endWorkout()
//            DispatchQueue.main.async {
//                self.dismiss()
//            }
//        }
//
//        let action1 = WKAlertAction.init(title: NSLocalizedString("goOn", comment: ""), style:.default) {
//
//        }
        previousSessionState = sessionState!
        if sessionState! == .workoutRunning {
            sessionState = .workoutPaused
            stopTimer()
            workoutManager!.pauseWorkout()
        } else if sessionState! == .workoutPaused {
            previousSessionState = .workoutPaused
        }
        presentController(withName: "arrowNumberPicker", context: self)
//        presentAlert(withTitle: NSLocalizedString("endWorkoutTitle", comment: ""), message: NSLocalizedString("endWorkoutMessage", comment: ""), preferredStyle:.alert, actions: [action1,action2])
    }
    
    func didEndWorkout(){
        stopTimer()
        self.workoutManager!.workoutData!.arrowCounter = arrowCount
        self.workoutManager!.endWorkout()
        self.dismiss()
        self.dismiss()
//        DispatchQueue.main.async {
//            self.dismiss()
//            self.dismiss()
//        }
    }
    
    func didReceiveWorkoutData(_ workoutData: WorkoutSessionDetails) {
        
        DispatchQueue.main.async {
            self.calorieLabel.setText(String(workoutData.cumulativeCaloriesBurned))
            self.heartRateLabel.setText(String(workoutData.currentHeartRate))
        }
        
    }
    
}
