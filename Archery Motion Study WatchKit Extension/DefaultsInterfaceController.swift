//
//  DefaultsInterfaceController.swift
//  Archery Motion Study WatchKit Extension
//
//  Created by Juan I Rodriguez on 16/11/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity


class DefaultsInterfaceController: WKInterfaceController {

    @IBOutlet var defaultsTable: WKInterfaceTable!
    
    let session = WCSession.default
    let defaults = UserDefaults.standard
    
    var actualValues : [String]?
    var actualKey : String?
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        actualKey = context as? String
        
        switch actualKey {
            case K.bowTypeKey:
                actualValues = K.categoryValues
            case K.handKey:
                actualValues = K.handValues
            case K.sessionTypeKey:
                actualValues = K.sessionValues
            default:
                actualValues = nil
        }
        
        defaultsTable.setNumberOfRows(actualValues!.count, withRowType: "simpleRow")
        
        
        setInitialDefaults()
        updateTable()
        
    }
    
    func setInitialDefaults() {
        
        if defaults.value(forKey: K.bowTypeKey) == nil {
            defaults.setValue(K.categoryValues[0], forKey: K.bowTypeKey)
            defaults.setValue(K.handValues[0], forKey: K.handKey)
            defaults.setValue(K.sessionValues[0], forKey: K.sessionTypeKey)
            syncUserDefaults()
        }
        
    }
    
    func updateTable() {
        
        let currentDefaultValue = defaults.value(forKey: actualKey!) as? String
        
        for (index, value) in actualValues!.enumerated() {
            
            let row = defaultsTable.rowController(at: index) as! SettingsRowController
            row.titleLabel.setText(NSLocalizedString(value, comment: ""))
            row.selectedAccesory.setHidden(true)
            
            if value == currentDefaultValue {
                row.selectedAccesory.setHidden(false)
            }
            
        }
        
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        let value = actualValues![rowIndex]
        defaults.setValue(value, forKey: actualKey!)
        updateTable()
        self.syncUserDefaults()
    }
    
    func syncUserDefaults(){
        
        let info = [K.bowTypeKey:defaults.value(forKey: K.bowTypeKey)!, K.handKey : defaults.value(forKey: K.handKey)!, K.sessionTypeKey:defaults.value(forKey: K.sessionTypeKey)!]
        session.transferUserInfo(info)
        
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
