//
//  GaleryCollectionViewCell.swift
//  FilterCam
//
//  Created by Shreesha on 31/08/16.
//  Copyright © 2016 YML. All rights reserved.
//

import UIKit

class GaleryCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var videoImageView: UIImageView!
    @IBOutlet weak var playButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        playButton.userInteractionEnabled = false
    }
}
