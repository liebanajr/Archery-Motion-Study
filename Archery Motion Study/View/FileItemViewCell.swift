//
//  FileItemViewCell.swift
//  Archery Motion Study
//
//  Created by Juan Ignacio Rodríguez Liébana on 18/09/2019.
//  Copyright © 2019 liebanajr. All rights reserved.
//

import UIKit

class FileItemViewCell: UITableViewCell {

    
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var uploadedCheckmark: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
