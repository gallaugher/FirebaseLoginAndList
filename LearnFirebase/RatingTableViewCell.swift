//
//  RatingTableViewCell.swift
//  LearnFirebase
//
//  Created by John Gallaugher on 5/1/17.
//  Copyright © 2017 Gallaugher. All rights reserved.
//

import UIKit

class RatingTableViewCell: UITableViewCell {
    
    @IBOutlet weak var ratingHeadlineLabel: UILabel!
    @IBOutlet weak var reviewTextLabel: UILabel!
    @IBOutlet weak var reviewByLabel: UILabel!
    @IBOutlet weak var ratingControl: RatingControl!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
