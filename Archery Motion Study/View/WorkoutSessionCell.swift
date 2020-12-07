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
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var calorieLabel: UILabel!
    @IBOutlet var avgHRLabel: UILabel!
    @IBOutlet var endsLabel: UILabel!
    @IBOutlet var durationLabel: UILabel!
    @IBOutlet var maxHRLabel: UILabel!
    @IBOutlet var minHRLabel: UILabel!
    
    @IBOutlet var sessionTypeLabel: UILabel!
    @IBOutlet var watchLocationLabel: UILabel!
    
    @IBOutlet weak var topLine: UIView!
    @IBOutlet weak var bottomLine: UIView!
    
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var editButtonParentView: UIView!
    @IBOutlet weak var viewButtonParentView: UIView!
    var delegate : SessionCellDelegate?
    var currentCellIndex : Int?
    var cellSession : Session?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        editButtonParentView.layer.cornerRadius = editButtonParentView.frame.height / 2
        viewButtonParentView.layer.cornerRadius = viewButtonParentView.frame.height / 2
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
    
    @IBAction func viewButtonPressed(_ sender: Any) {
        self.setSelected(true, animated: true)
    }
    
}
