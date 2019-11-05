//
//  InterfaceController.swift
//  Archery Motion Study WatchKit Extension
//
//  Created by Juan Ignacio Rodríguez Liébana on 13/09/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import WatchKit
import Foundation


class startViewController: WKInterfaceController {
    
    @IBOutlet weak var startButton: WKInterfaceButton!
    
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
    var documentDir :String = ""
    let defaults = UserDefaults.standard
    let fileManager = FileManager()
    
    override func awake(withContext context: Any?) {
        
        super.awake(withContext: context)
        
        if #available(watchOSApplicationExtension 6.0, *) {
            startButton.setBackgroundImage(UIImage(systemName: "play.circle.fill"))
        }
        
        documentDir = paths.firstObject as! String
        print("Document directory: \(documentDir)")
        
        deleteAllLocalData()
        
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        
    }
    
    func userDefaultsExists () -> Bool {
        
        if defaults.string(forKey: "Category") == nil || defaults.string(forKey: "Hand") == nil {
                    
            defaults.set("Recurve", forKey: "Category")
            defaults.set("Bow", forKey: "Hand")
            
            let action1 = WKAlertAction.init(title: "OK", style:.default) {
                       print("Okayed nil defaults message")
                   }
            
            let message = "Por favor, antes de comenzar, comprueba que los ajustes son correctos deslizando hacia la izquierda."

            presentAlert(withTitle: "Ajustes iniciales", message: message, preferredStyle:.alert, actions: [action1])
            return false
        }
        return true
        
    }
    
    @IBAction func startButtonPressed() {
        
        print("Start button pressed!")
        
        if !userDefaultsExists() {
            return
        }
        
        presentController(withName: "WorkoutInterfaceController", context: self)
        
    }
    
    @IBAction func deleteButtonPressed() {
        self.deleteAllLocalData()
    }
    
    func deleteAllLocalData(){
        do {
            let directoryContents : NSArray = try fileManager.contentsOfDirectory(atPath: documentDir) as NSArray
            print(directoryContents)
            
            for path in directoryContents {
                try fileManager.removeItem(atPath: documentDir + "/" + (path as! String))
            }
                        
        } catch {
            print("Error deleting files: \(error)")
        }
    }
}
