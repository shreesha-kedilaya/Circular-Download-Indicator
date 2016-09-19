//
//  FilterViewController.swift
//  FilterCam
//
//  Created by Shreesha on 01/09/16.
//  Copyright © 2016 YML. All rights reserved.
//

import UIKit

class FilterViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var filterCollectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Filter"
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 5
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterCollectionViewCell", for: indexPath) as? FilterCollectionViewCell
        cell?.nameLabel.text = "Filter"
        cell?.filterImageView.image = UIImage(named: "placeHolderVideo")
        return cell!
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 150, height: 175)
    }
}
