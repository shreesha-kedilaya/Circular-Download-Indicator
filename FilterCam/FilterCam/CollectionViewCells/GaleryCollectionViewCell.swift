//
//  GaleryCollectionViewCell.swift
//  FilterCam
//
//  Created by Shreesha on 31/08/16.
//  Copyright © 2016 YML. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class GaleryCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var videoImageView: UIImageView!
    @IBOutlet weak var playButton: UIButton!

    var videoURL: URL?

    override func awakeFromNib() {
        super.awakeFromNib()
        playButton.isUserInteractionEnabled = false
        videoImageView.image = UIImage(named: "placeHolderVideo")
    }

    func applyThumbnailImage() {
        print("applyThumbnailImage called")
        videoImageView.image = UIImage(named: "placeHolderVideo")
        if let videoURL = videoURL {
            Async.global(DispatchQoS.QoSClass.background) {
                let image = self.getThumbnailImageFor(videoURL)
                Async.main{
                    self.videoImageView.image = image
                }
            }
        }
    }

    func getThumbnailImageFor(_ URL: Foundation.URL) -> UIImage {

        let asset = AVURLAsset(url: URL, options: nil)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = UIScreen.main.bounds.size

        let cgImage = try! imageGenerator.copyCGImage(at: CMTimeMakeWithSeconds(2, 1), actualTime: nil)
        var thumbnailImage = UIImage(cgImage: cgImage)
        thumbnailImage = thumbnailImage.withRenderingMode(.alwaysOriginal)

        return thumbnailImage
    }
}
