//
//  settingsViewControllerInterfaceController.swift
//  Archery Motion Study WatchKit Extension
//
//  Created by Juan Ignacio Rodríguez Liébana on 15/09/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import WatchKit
import Foundation


class settingsInterfaceController: WKInterfaceController {

    @IBOutlet weak var categoryPicker: WKInterfacePicker!
    @IBOutlet weak var handPicker: WKInterfacePicker!
    
    let defaults = UserDefaults.standard
    
    var categoryPickerItems = [WKPickerItem]()
    var handPickerItems = [WKPickerItem]()
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
                
        let categoryItem1 = WKPickerItem()
        categoryItem1.title = "Recurve"
        let categoryItem2 = WKPickerItem()
        categoryItem2.title = "Compound"
        
        let handItem1 = WKPickerItem()
        handItem1.title = "Bow"
        let handItem2 = WKPickerItem()
        handItem2.title = "String"
        
        categoryPickerItems = [categoryItem1,categoryItem2]
        handPickerItems = [handItem1,handItem2]
        
        categoryPicker.setItems(categoryPickerItems)
//        categoryPicker.focus()
        handPicker.setItems(handPickerItems)
        
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
    
    @IBAction func categoryPickerAction(_ value: Int) {
        
        defaults.set(categoryPickerItems[value].title, forKey: "Category")
        print("Setting user defaults: [Category : \(categoryPickerItems[value].title!)]")
        
    }
    @IBAction func handPickerAction(_ value: Int) {
        
        defaults.set(categoryPickerItems[value].title, forKey: "Hand")
        print("Setting user defaults: [Hand : \(handPickerItems[value].title!)]")
        
    }
    

}
