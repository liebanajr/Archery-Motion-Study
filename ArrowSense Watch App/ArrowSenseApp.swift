//
//  ArrowSenseApp.swift
//  ArrowSense Watch App
//
//  Created by Juan Rodríguez on 16/7/23.
//  Copyright © 2023 liebanajr. All rights reserved.
//

import SwiftUI
import WatchConnectivity

@main
struct ArrowSense_Watch_AppApp: App {
    
    @StateObject private var wcManager = WatchConnectivityManager()
    
    private let session = WCSession.default
    
    var body: some Scene {
        WindowGroup {
            StartView()
                .task {
                    if WCSession.isSupported() {
                        session.delegate = wcManager
                        session.activate()
                    } else {
                        print("WCSession not supported")
                    }
                }
        }
    }
}

class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState != .activated {
            print("WC Session is not active: \(error!)")
        }
    }
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        
        for element in userInfo {
            print("Key: \(element.key)   Value: \(element.value)")
        }
        
        UserDefaults.standard.setValuesForKeys(userInfo)
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name("NewDataAvailable"), object: nil)
    }
}
