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
    fileprivate lazy var viewModel = GaleryCollectionViewModel()

    fileprivate var permissionService: PermissionService?

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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.libraryInfo.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! GaleryCollectionViewCell
        cell.videoURL = viewModel.libraryInfo[(indexPath as NSIndexPath).item].1
        cell.applyThumbnailImage()
        return cell
    }

    // MARK: UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 150, height: 150)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 25
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let previewVC = storyboard?.instantiateViewController(withIdentifier: "VideoPreviewViewController") as! VideoPreviewViewController
        previewVC.playingPhAsset = viewModel.libraryInfo[(indexPath as NSIndexPath).item].0
        navigationController?.pushViewController(previewVC, animated: true)
    }
}
