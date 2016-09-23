//
//  FilterViewController.swift
//  FilterCam
//
//  Created by Shreesha on 01/09/16.
//  Copyright © 2016 YML. All rights reserved.
//

import UIKit

protocol FilterViewControllerDelegate: class {
    func filterViewController(viewController: FilterViewController, didSelectFilter filter:@escaping Filter)
}

class FilterViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var filterCollectionView: UICollectionView!

    @IBOutlet weak var selectButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var previewImageView: UIImageView!
    var filter: Filter?
    var image: UIImage?
    var allFilters: [Filters]!
    private var currentSelectedIndex = 0

    weak var delegate: FilterViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Filter"
        allFilters = filters()
        cancelButton.isHidden = true
        previewImageView.isHidden = true
        selectButton.isHidden = true

    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let allFilters = allFilters {
            return allFilters.count
        }
        return 0
    }

    @IBAction func selectButtonDidClick(_ sender: AnyObject) {
        let filter = allFilters[currentSelectedIndex].filter()
        delegate?.filterViewController(viewController: self, didSelectFilter: filter)
    }
    
    @IBAction func cancelButtonDidClick(_ sender: AnyObject) {
        for view in view.subviews {
            view.isHidden = false
        }
        previewImageView.isHidden = true
        cancelButton.isHidden = true
        selectButton.isHidden = true
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterCollectionViewCell", for: indexPath) as? FilterCollectionViewCell
        cell?.nameLabel.text = "Filter"
        if let image = image {
            cell?.filterImageView.image = image
        } else {
            cell?.filterImageView.image = UIImage(named: "placeHolderVideo")
        }

        cell?.filter = allFilters[indexPath.row]

        return cell!
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 150, height: 175)
    }

    func filters() -> [Filters] {

        let array = [Filters.blur(radius: 5), .hueAdjust(angleInRadians: 0.5), .kaleidoscope, .pixellate(scale: 20)]

        return array
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        currentSelectedIndex = indexPath.item
        let cell = collectionView.cellForItem(at: indexPath) as! FilterCollectionViewCell
        previewImageView.image = cell.filterImageView.image
        hideAllSubviews()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }

    private func hideAllSubviews() {
        
        for view in view.subviews {
            view.isHidden = true
        }
        previewImageView.isHidden = false
        cancelButton.isHidden = false
        selectButton.isHidden = false
    }
}
