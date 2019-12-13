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


class WorkoutInterfaceController: WKInterfaceController, WorkoutManagerDelegate {
    
    @IBOutlet weak var timer: WKInterfaceTimer!
    @IBOutlet weak var calorieLabel: WKInterfaceLabel!
    @IBOutlet weak var heartRateLabel: WKInterfaceLabel!
    @IBOutlet weak var endLabel: WKInterfaceLabel!
    @IBOutlet var addButton: WKInterfaceButton!
    
    var workoutManager : WorkoutManager?
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        workoutManager = WorkoutManager()
        workoutManager!.delegate = self
        workoutManager!.startWorkout()
        
        timer.setDate(Date(timeIntervalSinceNow: 0.0))
        timer.start()
                
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
        
        if workoutManager!.workoutSession!.state == .running {
            
            addButton.setBackgroundImage(UIImage(systemName: "play"))
            addButton.setBackgroundColor(#colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1))
            workoutManager!.pauseWorkout()
            timer.stop()
            
        } else if workoutManager!.workoutSession!.state == .paused {
            
            addButton.setBackgroundColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
            workoutManager!.resumeWorkout()
            endLabel.setText("\(workoutManager!.workoutData!.endCounter)")
            timer.start()
            addButton.setBackgroundImage(UIImage(systemName: "plus"))
        }
        
    }
    
    @IBAction func endButtonPressed() {
        
        timer.stop()
        workoutManager!.endWorkout()
        self.dismiss()
        
    }
    
    func didReceiveWorkoutData(_ workoutData: WorkoutSessionDetails) {
        
        DispatchQueue.main.async {
            self.calorieLabel.setText(String(workoutData.cumulativeCaloriesBurned))
            self.heartRateLabel.setText(String(workoutData.currentHeartRate))
        }
        
    }
    
}
