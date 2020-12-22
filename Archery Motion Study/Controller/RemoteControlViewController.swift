//
//  RemoteControlViewController.swift
//  Archery Motion Study
//
//  Created by Juan Rodríguez on 13/12/20.
//  Copyright © 2020 liebanajr. All rights reserved.
//

import UIKit
import WatchConnectivity

class RemoteControlViewController: UIViewController {

    @IBOutlet weak var messageLabel: UILabel!
    let wcSession = WCSession.default
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(updateLabelWithMessage), name: Notification.Name(REMOTE_CONTROL.NOTIFICATION.rawValue), object: nil)
            
        self.syncButtonPressed(self)
    }
    
    @objc func updateLabelWithMessage(_ notification: NSNotification){
        if let message = notification.object as? String {
            DispatchQueue.main.async {
                self.messageLabel.text = message
            }
        }
        
    }
    
    @IBAction func startButtonPressed(_ sender: Any) {
        Log.info("Requesting remote workout start")
//        wcSession.sendMessage([REMOTE_CONTROL.NOTIFICATION.rawValue : REMOTE_CONTROL.START.rawValue], replyHandler: nil, errorHandler: { error in
//            Log.error(error.localizedDescription)
//            let nc = NotificationCenter.default
//            nc.post(name: Notification.Name(REMOTE_CONTROL.NOTIFICATION.rawValue), object: error.localizedDescription)
//        })
        wcSession.transferUserInfo([REMOTE_CONTROL.NOTIFICATION.rawValue : REMOTE_CONTROL.START.rawValue])
    }
    @IBAction func pauseButtonPressed(_ sender: Any) {
        Log.info("Requesting remote workout pause")
//        wcSession.sendMessage([REMOTE_CONTROL.NOTIFICATION.rawValue : REMOTE_CONTROL.PAUSE.rawValue], replyHandler: nil, errorHandler:  { error in
//            Log.error(error.localizedDescription)
//            let nc = NotificationCenter.default
//            nc.post(name: Notification.Name(REMOTE_CONTROL.NOTIFICATION.rawValue), object: error.localizedDescription)
//        })
        wcSession.transferUserInfo([REMOTE_CONTROL.NOTIFICATION.rawValue : REMOTE_CONTROL.PAUSE.rawValue])
    }
    @IBAction func stopButtonPressed(_ sender: Any) {
        Log.info("Requesting remote workout stop")
//        wcSession.sendMessage([REMOTE_CONTROL.NOTIFICATION.rawValue : REMOTE_CONTROL.STOP.rawValue], replyHandler: nil, errorHandler:  { error in
//            Log.error(error.localizedDescription)
//            let nc = NotificationCenter.default
//            nc.post(name: Notification.Name(REMOTE_CONTROL.NOTIFICATION.rawValue), object: error.localizedDescription)
//        })
        wcSession.transferUserInfo([REMOTE_CONTROL.NOTIFICATION.rawValue : REMOTE_CONTROL.STOP.rawValue])
    }
    @IBAction func syncButtonPressed(_ sender: Any) {
        Log.info("Requesting remote workout sync")
//        wcSession.sendMessage([REMOTE_CONTROL.NOTIFICATION.rawValue : REMOTE_CONTROL.SYNC.rawValue], replyHandler: nil, errorHandler:  { error in
//            Log.error(error.localizedDescription)
//            let nc = NotificationCenter.default
//            nc.post(name: Notification.Name(REMOTE_CONTROL.NOTIFICATION.rawValue), object: error.localizedDescription)
//        })
        wcSession.transferUserInfo([REMOTE_CONTROL.NOTIFICATION.rawValue : REMOTE_CONTROL.SYNC.rawValue])
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
