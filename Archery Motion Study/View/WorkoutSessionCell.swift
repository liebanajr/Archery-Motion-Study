//
//  WorkoutSessionCell.swift
//  Archery Motion Study
//
//  Created by Juan I Rodriguez on 08/11/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import UIKit

protocol SessionCellDelegate {
    
    func deleteSelectedCell(atIndex index: IndexPath)
}

class WorkoutSessionCell: UITableViewCell {
    
    @IBOutlet var background: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var calorieLabel: UILabel!
    @IBOutlet var avgHRLabel: UILabel!
    @IBOutlet var endsLabel: UILabel!
    
    var delegate : SessionCellDelegate?
    var currentCellIndex : IndexPath?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        background.layer.cornerRadius = 10
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        
        print("Cell number \(currentCellIndex!.row) delete button pressed")
        delegate!.deleteSelectedCell(atIndex: currentCellIndex!)
        
    }
    
    
}
