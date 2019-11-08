//
//  infoViewController.swift
//  Archery Motion Study
//
//  Created by Juan I Rodriguez on 05/11/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import UIKit
import HealthKit
import HealthKitUI

class infoViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    @IBAction func authorizeHealthkitButtonPressed(_ sender: Any) {
        
        authorizeHealthKit()
        
    }
    
    func authorizeHealthKit() {
        
        let types = Set([HKObjectType.workoutType(),
                         HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
                         HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
                         HKObjectType.quantityType(forIdentifier: .heartRate)!
                        ])
        let healthStore = HKHealthStore()
        
        healthStore.requestAuthorization(toShare: types, read: types) { (success, error) in
            if !success {
                print(error)
            } else {
                print("HealthKit successfully authorized!")
            }
        }
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
