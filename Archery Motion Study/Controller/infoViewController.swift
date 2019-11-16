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
import WatchConnectivity

class infoViewController: UIViewController {
    
    @IBOutlet var bowTypeSegment: UISegmentedControl!
    @IBOutlet var watchLocationSegment: UISegmentedControl!
    @IBOutlet var sessionTypeSegment: UISegmentedControl!
    
    let defaults = UserDefaults.standard
    let session = WCSession.default

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(updateInterface), name: Notification.Name("NewDataAvailable"), object: nil)
        
        updateInterface()
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
                print(error!)
            } else {
                print("HealthKit successfully authorized!")
            }
        }
        
    }
    
    @objc func updateInterface(){
        
        let bowTypeIndex = K.categoryValues.firstIndex(of: defaults.value(forKey: K.bowTypeKey)! as! String)!
        let watchLocationIndex = K.handValues.firstIndex(of: defaults.value(forKey: K.handKey)! as! String)!
        let sessionTypeIndex = K.sessionValues.firstIndex(of: defaults.value(forKey: K.sessionTypeKey)! as! String)!
        
        DispatchQueue.main.async {
            self.bowTypeSegment.selectedSegmentIndex = bowTypeIndex
            self.watchLocationSegment.selectedSegmentIndex = watchLocationIndex
            self.sessionTypeSegment.selectedSegmentIndex = sessionTypeIndex
        }
        
    }
    
    @IBAction func bowTypeSwithed(_ sender: Any) {
        
        let segment = sender as! UISegmentedControl
        let index = segment.selectedSegmentIndex
        defaults.setValue(K.categoryValues[index], forKey: K.bowTypeKey)
        syncDefaults()
        
    }
    
    @IBAction func watchLocationSwitched(_ sender: Any) {
        
       let segment = sender as! UISegmentedControl
        let index = segment.selectedSegmentIndex
        defaults.setValue(K.handValues[index], forKey: K.handKey)
        syncDefaults()
        
    }
    @IBAction func sessionTypeSwitched(_ sender: Any) {
        
        let segment = sender as! UISegmentedControl
        let index = segment.selectedSegmentIndex
        defaults.setValue(K.sessionValues[index], forKey: K.sessionTypeKey)
        syncDefaults()
        
    }
    
    func syncDefaults(){
        let info = [K.bowTypeKey:defaults.value(forKey: K.bowTypeKey)!, K.handKey : defaults.value(forKey: K.handKey)!, K.sessionTypeKey:defaults.value(forKey: K.sessionTypeKey)!]
        session.transferUserInfo(info)
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
