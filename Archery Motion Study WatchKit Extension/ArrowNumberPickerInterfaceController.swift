//
//  ArrowNumberPickerInterfaceController.swift
//  Archery Motion Study WatchKit Extension
//
//  Created by Juan I Rodriguez on 28/02/2020.
//  Copyright © 2020 liebanajr. All rights reserved.
//

import WatchKit
import Foundation
import ShotsWorkoutManager

class ArrowNumberPickerInterfaceController: WKInterfaceController, WKCrownDelegate {

    var arrowValue = 0
    var cumulativeDelta = 0.0
    var workoutInterfaceController : WorkoutInterfaceController?
    @IBOutlet var arrowNumberLabel: WKInterfaceLabel!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)

        crownSequencer.delegate = self
        workoutInterfaceController = context as? WorkoutInterfaceController
        let arrowsPerHour = 66.0
        let arrowsPerSecond = arrowsPerHour/(60*60)
        
        let elapsedTime = -workoutInterfaceController!.timerStartDate!.timeIntervalSinceNow
        
        print("\(elapsedTime)*\(arrowsPerSecond) = \(elapsedTime * arrowsPerSecond)")
        arrowValue = Int(elapsedTime * arrowsPerSecond)
        arrowNumberLabel.setText("\(arrowValue)")
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    override func didAppear() {
        crownSequencer.focus()
    }
    @IBAction func plusButtonPressed() {
        
        arrowValue += 1
        cumulativeDelta = 0.0
        arrowNumberLabel.setText("\(arrowValue)")
    }
    @IBAction func minusButtonPressed() {
        
        arrowValue -= 1
        if arrowValue < 0 {
            arrowValue = 0
        }
        cumulativeDelta = 0.0
        arrowNumberLabel.setText("\(arrowValue)")
        
    }
    @IBAction func saveButtonPressed() {
        
        workoutInterfaceController!.arrowCount = arrowValue
        ShotsWorkoutManager.shared.sessionData?.arrowCounter = arrowValue
        workoutInterfaceController!.didEndWorkout()
        self.dismiss()
    }
    
    func crownDidRotate(_ crownSequencer: WKCrownSequencer?, rotationalDelta: Double) {
        cumulativeDelta += rotationalDelta*10
        if cumulativeDelta >= 1 {
            arrowValue += 1
            cumulativeDelta = 0
        }
        
        if cumulativeDelta <= -1 {
            arrowValue -= 1
            cumulativeDelta = 0
        }
        if arrowValue < 0 {
            arrowValue = 0
        }
        arrowNumberLabel.setText("\(arrowValue)")
    }
}
