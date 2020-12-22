//
//  ExtensionDelegate.swift
//  Archery Motion Study WatchKit Extension
//
//  Created by Juan Ignacio Rodríguez Liébana on 13/09/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import WatchKit
import WatchConnectivity
import ShotsWorkoutManager

class ExtensionDelegate: NSObject, WKExtensionDelegate, WCSessionDelegate {
    
    let defaults = UserDefaults.standard
    let session = WCSession.default
    
    let workoutManager = ShotsWorkoutManager.shared
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState != .activated {
            print("WC Session is not active: \(error!)")
        }
    }
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        
        if let remoteNotification = userInfo[REMOTE_CONTROL.NOTIFICATION.rawValue] as? String {
            manageRemoteControlNotification(remoteNotification)
            return
        }
        
        for element in userInfo {
            print("Key: \(element.key)   Value: \(element.value)")
        }
        
        defaults.setValuesForKeys(userInfo)
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name("NewDataAvailable"), object: nil)
    }

    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        } else {
            print("WCSession not supported")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let message = message[REMOTE_CONTROL.NOTIFICATION.rawValue] as? String {
            manageRemoteControlNotification(message)
        }
    }
    
    func manageRemoteControlNotification(_ message: String) {
        Log.info("Did receive remote notification: \(message)")
        switch message {
            case REMOTE_CONTROL.START.rawValue:
                workoutManager.startWorkout(id: "remote_workout", type: .FREE)
                respondToRemoteNotification()
            case REMOTE_CONTROL.STOP.rawValue:
                workoutManager.stopWorkout()
                respondToRemoteNotification()
            case REMOTE_CONTROL.PAUSE.rawValue:
                workoutManager.pauseWorkout()
                respondToRemoteNotification()
            case REMOTE_CONTROL.RESUME.rawValue:
                workoutManager.resumeWorkout()
                respondToRemoteNotification()
            case REMOTE_CONTROL.SYNC.rawValue:
                respondToRemoteNotification()
            default:
                let messageContent = "Remote notification [\(message)] not recognized."
                session.sendMessage([REMOTE_CONTROL.NOTIFICATION.rawValue : messageContent], replyHandler: nil, errorHandler: nil)
                Log.error(messageContent)
        }
    }
    
    func respondToRemoteNotification() {
        Log.info("Checking workout state for syncing")
        
        switch workoutManager.isWorkoutRunning {
            case nil:
                session.sendMessage([REMOTE_CONTROL.NOTIFICATION.rawValue : REMOTE_CONTROL.RESPONSE_STOPPED.rawValue], replyHandler: nil, errorHandler: nil)
            case true:
                session.sendMessage([REMOTE_CONTROL.NOTIFICATION.rawValue : REMOTE_CONTROL.RESPONSE_RUNNING.rawValue], replyHandler: nil, errorHandler: nil)

            case false:
                session.sendMessage([REMOTE_CONTROL.NOTIFICATION.rawValue : REMOTE_CONTROL.RESPONSE_PAUSED.rawValue], replyHandler: nil, errorHandler: nil)

            default:
                let messageContent = "Error: Workout state not recognized"
                session.sendMessage([REMOTE_CONTROL.NOTIFICATION.rawValue : messageContent], replyHandler: nil, errorHandler: nil)

        }
        
    }

    func applicationDidBecomeActive() {
        print("Resuming application...")
    }
    
    func applicationWillResignActive() {
        print("Entering background...")
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                backgroundTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                // Be sure to complete the relevant-shortcut task once you're done.
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                // Be sure to complete the intent-did-run task once you're done.
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
    
    func handleActiveWorkoutRecovery() {
//        TODO: Recuperar de crashes
    }

}
