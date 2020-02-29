//
//  ArrowNumberPickerInterfaceController.swift
//  Archery Motion Study WatchKit Extension
//
//  Created by Juan I Rodriguez on 28/02/2020.
//  Copyright © 2020 liebanajr. All rights reserved.
//

import WatchKit
import Foundation


class ArrowNumberPickerInterfaceController: WKInterfaceController, WKCrownDelegate {

    var arrowValue = 0
    var cumulativeDelta = 0.0
    var workoutInterfaceController : WorkoutInterfaceController?
    @IBOutlet var arrowNumberLabel: WKInterfaceLabel!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        crownSequencer.delegate = self
        workoutInterfaceController = context as? WorkoutInterfaceController
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
        workoutInterfaceController!.didEndWorkout()
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
