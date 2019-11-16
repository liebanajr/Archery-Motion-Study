//
//  settingsViewControllerInterfaceController.swift
//  Archery Motion Study WatchKit Extension
//
//  Created by Juan Ignacio Rodríguez Liébana on 15/09/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class settingsInterfaceController: WKInterfaceController {

    @IBOutlet var settingsTable: WKInterfaceTable!
    
    let defaults = UserDefaults.standard
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        settingsTable.setNumberOfRows(3, withRowType: "navigationRow")
        
        let row = settingsTable.rowController(at: 0) as! NavigationRowController
        row.titleLabel.setText(NSLocalizedString("Bow type", comment: ""))
        row.destinationKey = K.bowTypeKey
        let row2 = settingsTable.rowController(at: 1) as! NavigationRowController
        row2.titleLabel.setText(NSLocalizedString("Watch location", comment: ""))
        row2.destinationKey = K.handKey
        let row3 = settingsTable.rowController(at: 2) as! NavigationRowController
        row3.titleLabel.setText(NSLocalizedString("Session type", comment: ""))
        row3.destinationKey = K.sessionTypeKey
        
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        let row = settingsTable.rowController(at: rowIndex) as! NavigationRowController
        let destination = row.destinationKey
        presentController(withName: "defaultsInterfaceController", context: destination)
    }
    
    

}
