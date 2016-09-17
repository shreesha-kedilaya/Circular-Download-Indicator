//
//  GaleryCollectionViewController.swift
//  FilterCam
//
//  Created by Shreesha on 31/08/16.
//  Copyright © 2016 YML. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

private let reuseIdentifier = "GaleryCollectionViewCell"

class GaleryCollectionViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    @IBOutlet weak var videoCollectionView: UICollectionView!
    private lazy var viewModel = GaleryCollectionViewModel()

    private var permissionService: PermissionService?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Gallery"

        permissionService = PermissionType.Photos.permissionService
        permissionService?.requestPermission({ (status) in
            switch status {
            case .Authorized:
                self.viewModel.fetchLibraryAssets {
                    Async.main{
                        self.videoCollectionView.reloadData()
                        print("collection view reloaded \n\n\n")
                    }
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
        return viewModel.libraryInfo.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! GaleryCollectionViewCell
        cell.videoURL = viewModel.libraryInfo[indexPath.item].1
        cell.applyThumbnailImage()
        return cell
    }

    // MARK: UICollectionViewDelegate

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: 150, height: 150)
    }
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 25
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let previewVC = storyboard?.instantiateViewControllerWithIdentifier("VideoPreviewViewController") as! VideoPreviewViewController
        previewVC.playingPhAsset = viewModel.libraryInfo[indexPath.item].0
        navigationController?.pushViewController(previewVC, animated: true)
    }
}
