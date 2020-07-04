//
//  ChartSelectionCell.swift
//  Archery Motion Study
//
//  Created by Juan Rodríguez on 04/07/2020.
//  Copyright © 2020 liebanajr. All rights reserved.
//

import UIKit

class ChartSelectionCell: UITableViewCell {
    @IBOutlet weak var selectionImageView: UIImageView!
    @IBOutlet weak var selectionTitleLabel: UILabel!
    
    var colorArray : [UIColor]?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func style(at indexPath: IndexPath, for selectionState: Bool) {
        if selectionState {
            Log.info("Styling \(self.selectionTitleLabel.text!) for selected")
            self.selectionImageView.tintColor = colorArray?[indexPath.row]
            self.selectionImageView.image = UIImage(systemName: "checkmark.circle.fill")
            self.selectionImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(scale: .large)
        } else {
            Log.info("Styling \(self.selectionTitleLabel.text!) for not selected")
            self.selectionImageView.tintColor = UIColor.label
            self.selectionImageView.image = UIImage(systemName: "circle")
            self.selectionImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(scale: .large)
        }
    }

}
