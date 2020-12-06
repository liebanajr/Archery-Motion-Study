//
//  EditSessionViewController.swift
//  Archery Motion Study
//
//  Created by Juan Rodríguez on 4/12/20.
//  Copyright © 2020 liebanajr. All rights reserved.
//

import UIKit
import CoreData

class EditSessionViewController: UIViewController {
    
    var sessionToEdit : Session?
    @IBOutlet weak var arrowsShotTextField: UITextField!
    @IBOutlet weak var sessionDurationDatePicker: UIDatePicker!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var arrowsLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    
    var sessionsViewController : WorkoutSessionsViewController?
    
    let fileManager = FileManager()
    
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
    var documentDir :String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        documentDir = paths.firstObject as! String + K.motionDataFolder
        
        saveButton.layer.cornerCurve = .continuous
        saveButton.layer.cornerRadius = saveButton.frame.height / 2
        saveButton.setTitle(NSLocalizedString("Save", comment: ""), for: .normal)
        deleteButton.layer.cornerCurve = .continuous
        deleteButton.layer.cornerRadius = deleteButton.frame.height / 2
        deleteButton.setTitle(NSLocalizedString("Delete session", comment: ""), for: .normal)
        titleLabel.text = NSLocalizedString("Edit session", comment: "")
        arrowsLabel.text = NSLocalizedString("Arrows shot", comment: "")
        durationLabel.text = NSLocalizedString("Session duration", comment: "")
        
        if let session = sessionToEdit {
            let elapsedTime = session.duration
            let timeInterval = TimeInterval(elapsedTime)
            print("Session found. \(session.arrowCount) arrows. \(session.duration) duration")
            sessionDurationDatePicker.countDownDuration = timeInterval
            arrowsShotTextField.text = "\(session.arrowCount)"
        } else {
            print("No session found")
            self.dismiss(animated: true, completion: nil)
        }
        
        //Looks for single or multiple taps.
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)

    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        let textValue = arrowsShotTextField.text ?? "0"
        let arrowCount = Int64(textValue)
        let duration = Int64(sessionDurationDatePicker.countDownDuration)
        
        sessionToEdit?.arrowCount = arrowCount ?? 0
        sessionToEdit?.duration = duration
        do {
            try sessionToEdit?.managedObjectContext?.save()
        } catch {
            print("Error saving edited session: \(error)")
        }
        sessionsViewController?.reloadTableWithNewData()
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func deleteButtonPressed(_ sender: Any) {
        
        let deleteAction = UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .destructive) { (action) in
            self.sessionsViewController?.deleteSession(fromSessionObject: self.sessionToEdit!)
            self.sessionsViewController?.reloadTableWithNewData()
            self.dismiss(animated: true, completion: nil)
        }
        
        let dismissAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { (action) in
            
        }
        
        let alert = UIAlertController(title: NSLocalizedString("Delete session", comment: "")+"?", message: nil, preferredStyle: .actionSheet)
        alert.addAction(deleteAction)
        alert.addAction(dismissAction)
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
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
