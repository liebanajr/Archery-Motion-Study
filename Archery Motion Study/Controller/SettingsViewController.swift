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
import MessageUI

class SettingsViewController: UIViewController, UITextFieldDelegate, MFMailComposeViewControllerDelegate {
    
    @IBOutlet var bowTypeSegment: UISegmentedControl!
    @IBOutlet var watchLocationSegment: UISegmentedControl!
    @IBOutlet var sessionTypeSegment: UISegmentedControl!
    @IBOutlet var healthkitButton: UIButton!
    @IBOutlet var collaboratorsTextField: UITextField!
    @IBOutlet var collaboratorsSendButton: UIButton!
    @IBOutlet var sessionTypeLabel: UILabel!
    @IBOutlet var sessionTypeInfoLabel: UILabel!
    @IBOutlet weak var appVersionLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var nameSendButton: UIButton!
    
    let defaults = UserDefaults.standard
    let session = WCSession.default
    
    let healthStore = HKHealthStore()

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appVersionLabel.text = "Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String)"
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(updateInterface), name: Notification.Name("NewDataAvailable"), object: nil)
        setInitialDefaults()
        
        healthkitButton.layer.cornerCurve = .continuous
        healthkitButton.layer.cornerRadius = healthkitButton.frame.height / 2
        
        if defaults.value(forKey: K.healthkitKey) as! Bool {
            disableHealthkitButton()
        }
        
        updateInterface()
        
        self.collaboratorsTextField.delegate = self
        self.nameTextField.delegate = self
        disableCollaboratorsTextField()
        
    }
    @IBAction func authorizeHealthkitButtonPressed(_ sender: Any) {
        
        authorizeHealthKit()
        
    }
    
    func disableHealthkitButton(){
        
        healthkitButton.isEnabled = false
        healthkitButton.setTitle(NSLocalizedString("healthkitButton", comment: ""), for: .normal)
        healthkitButton.backgroundColor = UIColor(displayP3Red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0)
        healthkitButton.setTitleColor(.systemGreen, for: .normal)
        healthkitButton.titleLabel?.numberOfLines = 0
        healthkitButton.titleLabel?.lineBreakMode = .byWordWrapping
        
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
                DispatchQueue.main.async {
                    self.disableHealthkitButton()
                }
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
            if self.defaults.value(forKey: K.healthkitKey) as! Bool {
            
                self.disableHealthkitButton()
                
            }
            let friendName = self.defaults.value(forKey: K.nameKey) as? String
            self.nameTextField.text = friendName
            
            if let name = self.defaults.value(forKey: K.nameKey) as? String, name != "" || K.isAdmin {
                self.nameTextField.isHidden = false
                self.sessionTypeSegment.isHidden = false
                self.sessionTypeLabel.isHidden = false
                self.sessionTypeInfoLabel.isHidden = false
            } else {
                #if DEBUG
                self.nameTextField.isHidden = false
                #endif
                self.sessionTypeSegment.isHidden = true
                self.sessionTypeLabel.isHidden = true
                self.sessionTypeInfoLabel.isHidden = true
            }
            self.view.layoutIfNeeded()
        }
        
    }
    
    func setInitialDefaults() {
                
        if defaults.value(forKey: K.bowTypeKey) == nil {
            defaults.setValue(K.categoryValues[0], forKey: K.bowTypeKey)
            defaults.setValue(K.handValues[0], forKey: K.handKey)
            defaults.setValue(K.sessionValues[0], forKey: K.sessionTypeKey)
            defaults.setValue(false, forKey: K.healthkitKey)
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
        var info = [K.bowTypeKey:defaults.value(forKey: K.bowTypeKey)!, K.handKey : defaults.value(forKey: K.handKey)!, K.sessionTypeKey:defaults.value(forKey: K.sessionTypeKey)!]
        if let friends = defaults.value(forKey: K.friendsKey) {
            info[K.friendsKey] = friends
        }
        
        if let name = defaults.value(forKey: K.nameKey) {
            info[K.nameKey] = name
        }
        session.transferUserInfo(info)
    }
    
    func disableCollaboratorsTextField(){
        
        if defaults.value(forKey: K.friendsKey) != nil {
            collaboratorsTextField.isEnabled = false
            collaboratorsTextField.text = NSLocalizedString("isFriend", comment: "")
            collaboratorsTextField.placeholder = ""
            collaboratorsTextField.borderStyle = .none
            collaboratorsTextField.textColor = .systemGreen
            collaboratorsTextField.textAlignment = .center
            collaboratorsSendButton.setBackgroundImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
            collaboratorsSendButton.tintColor = .systemGreen
            collaboratorsSendButton.isHidden = true
        }
        
    }
    
    @IBAction func sendCollaboratorsCodeButtonPressed(_ sender: Any) {
        print("Send button pressed")
        collaboratorsTextField.resignFirstResponder()
        if collaboratorsTextField.text == K.collaboratorCode {
            defaults.set(true, forKey: K.friendsKey)
            disableCollaboratorsTextField()
        }
        
        syncDefaults()
        
    }
    @IBAction func saveNameButtonPressed(_ sender: Any) {
        nameTextField.resignFirstResponder()
        let name = nameTextField.text ?? ""
        defaults.set(name, forKey: K.nameKey)
        self.updateInterface()
        syncDefaults()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == collaboratorsTextField {
            self.sendCollaboratorsCodeButtonPressed(textField)
        }
        
        if textField == nameTextField {
            self.saveNameButtonPressed(textField)
        }
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == collaboratorsTextField {
            collaboratorsSendButton.isHidden = true
        }
        
        if textField == nameTextField {
            nameSendButton.isHidden = true
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == collaboratorsTextField {
            collaboratorsSendButton.isHidden = false
        }
        
        if textField == nameTextField {
            nameSendButton.isHidden = false
        }
    }
    
//    MARK: - Feedback and social
    
    @IBAction func feedbackButtonPressed(_ sender: Any) {
        
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients([K.feedbackEmail])
            mail.setSubject(K.feedbackEmailSubject)

            present(mail, animated: true)
        } else {
            print("Failed while trying to send email")
        }

        
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    
    @IBAction func twitterButtonPressed(_ sender: Any) {

        if let url = K.twitterURL {
            UIApplication.shared.open(url)
        }
        
    }
    @IBAction func instagramButtonPressed(_ sender: Any) {
        
        if let url = K.instagramURL {
            UIApplication.shared.open(url)
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
