//
//  SettingsRowController.swift
//  Archery Motion Study WatchKit Extension
//
//  Created by Juan I Rodriguez on 15/11/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import WatchKit


class SettingsRowController: NSObject {
    
    @IBOutlet var titleLabel: WKInterfaceLabel!
    @IBOutlet var selectedAccesory: WKInterfaceImage!
    
}

class NavigationRowController: NSObject {
    
    @IBOutlet var titleLabel: WKInterfaceLabel!
    var destinationKey : String?
    
}
