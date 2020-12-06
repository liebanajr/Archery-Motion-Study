//
//  WorkoutSessionCell.swift
//  Archery Motion Study
//
//  Created by Juan I Rodriguez on 08/11/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import UIKit

protocol SessionCellDelegate {

    func didUpdateSessionData()
    
}

class WorkoutSessionCell: UITableViewCell {
    
    @IBOutlet var background: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var calorieLabel: UILabel!
    @IBOutlet var avgHRLabel: UILabel!
    @IBOutlet var endsLabel: UILabel!
    @IBOutlet var durationLabel: UILabel!
    @IBOutlet var maxHRLabel: UILabel!
    @IBOutlet var minHRLabel: UILabel!
    
    @IBOutlet var sessionTypeLabel: UILabel!
    @IBOutlet var watchLocationLabel: UILabel!
    
    
    var delegate : SessionCellDelegate?
    var currentCellIndex : IndexPath?
    var cellSession : Session?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        background.layer.cornerRadius = 10
        if self.traitCollection.userInterfaceStyle == .light {
            background.layer.backgroundColor = background.layer.backgroundColor?.copy(alpha: 0.4)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    @IBAction func editButtonPressed(_ sender: Any) {

        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "editSessionViewController") as! EditSessionViewController
        vc.sessionToEdit = cellSession
        vc.sessionsViewController = self.parentContainerViewController() as? WorkoutSessionsViewController
        self.parentContainerViewController()?.present(vc, animated: true, completion: nil)
        
    }
    
    
}
