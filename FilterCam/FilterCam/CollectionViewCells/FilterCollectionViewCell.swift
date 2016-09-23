//
//  FilterCollectionViewCell.swift
//  FilterCam
//
//  Created by Shreesha on 31/08/16.
//  Copyright © 2016 YML. All rights reserved.
//

import UIKit

class FilterCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var filterImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!

    var filter: Filters? {
        didSet {
            applyFilter(filter: filter)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    private func applyFilter(filter: Filters?) {
        if let filter = filter {
            let cgimage = filterImageView.image?.cgImage
            if let cgimage = cgimage {
                let ciimage = CIImage(cgImage: cgimage)

                let filteredImage = filter.filter()(ciimage)
                if let filteredImage = filteredImage {
                    let uiimage = UIImage(ciImage: filteredImage)
                    filterImageView.image = uiimage
                }
            }
        }
    }
}
