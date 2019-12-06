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
    @IBOutlet var healthkitButton: UIButton!
    
    let defaults = UserDefaults.standard
    let session = WCSession.default
    
    let healthStore = HKHealthStore()

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(updateInterface), name: Notification.Name("NewDataAvailable"), object: nil)
        setInitialDefaults()
        
        if defaults.value(forKey: K.healthkitKey) != nil {
        
            healthkitButton.isEnabled = false
            healthkitButton.setTitle(NSLocalizedString("healthkitButton", comment: ""), for: .normal)
            healthkitButton.backgroundColor = UIColor(displayP3Red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0)
            healthkitButton.setTitleColor(.systemGreen, for: .normal)
            
        }
        
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
        
        healthStore.requestAuthorization(toShare: types, read: types) { (success, error) in
            if !success {
                print(error!)
            } else {
                print("HealthKit successfully authorized!")
                self.defaults.setValue(true, forKey: K.healthkitKey)
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
    
    func setInitialDefaults() {
        
        if defaults.value(forKey: K.bowTypeKey) == nil {
            defaults.setValue(K.categoryValues[0], forKey: K.bowTypeKey)
            defaults.setValue(K.handValues[0], forKey: K.handKey)
            defaults.setValue(K.sessionValues[0], forKey: K.sessionTypeKey)
            syncDefaults()
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
