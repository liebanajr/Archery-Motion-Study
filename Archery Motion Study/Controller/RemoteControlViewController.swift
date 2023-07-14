//
//  RemoteControlViewController.swift
//  Archery Motion Study
//
//  Created by Juan Rodríguez on 13/12/20.
//  Copyright © 2020 liebanajr. All rights reserved.
//

import UIKit
import iOSUtils

class RemoteControlViewController: UIViewController, RCControllerDelegate {
    
    @IBOutlet weak var messageLabel: UILabel!
    
    let rcController = RCController.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()

        rcController.delegate = self
    }
    
    @IBAction func registerClassButtonPressed(_ sender: Any) {
        if let button = sender as? UIButton {
            let tag = button.tag
            Log.info("Pressed button with tag \(tag)")
            let type = getSessionType(for: tag)
            rcController.registerClass(class: type)
        }
    }
    
    @IBAction func startStopButtonPressed(_ sender: Any) {
        let button = sender as! UIButton
        if rcController.isRecording {
            rcController.isRecording = false
            button.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        } else {
            rcController.isRecording = true
            button.setImage(UIImage(systemName: "stop.circle.fill"), for: .normal)
        }
        
    }
    func getSessionType(for tag: Int) -> String{
        switch tag {
        case 0:
            return "shot"
        case 1:
            return "letdown"
        case 2:
            return "walk"
        case 3:
            return "other"
        default:
            return "other"
        }
    }
    
    func didFinishUploadingFile(_ message: String) {
        messageLabel.text = message
    }
    
    func didRegisterClass(_ named: String, at time: String) {
        messageLabel.text = "\(named) at \(time)"
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
