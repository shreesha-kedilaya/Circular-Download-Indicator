//
//  GaleryCollectionViewController.swift
//  FilterCam
//
//  Created by Shreesha on 31/08/16.
//  Copyright © 2016 YML. All rights reserved.
//

import UIKit

private let reuseIdentifier = "GaleryCollectionViewCell"

class GaleryCollectionViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    @IBOutlet weak var videoCollectionView: UICollectionView!
    private lazy var viewModel = GaleryCollectionViewModel()

    private var permissionService: PermissionService?

    override func viewDidLoad() {
        super.viewDidLoad()

        permissionService = PermissionType.Photos.permissionService
        permissionService?.requestPermission({ (status) in
            switch status {
            case .Authorized:
                self.viewModel.fetchLibraryAssets {
                    self.videoCollectionView.reloadData()
                }
            default:()
            }
        })
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)


    }

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.libraryUrls.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! GaleryCollectionViewCell
        cell.videoImageView.image = viewModel.getThumbnailImageFor(viewModel.libraryUrls[indexPath.row])
        return cell
    }

    // MARK: UICollectionViewDelegate

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: 100, height: 100)
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let previewVC = storyboard?.instantiateViewControllerWithIdentifier("VideoPreviewViewController") as! VideoPreviewViewController
        navigationController?.pushViewController(previewVC, animated: true)
    }
}
