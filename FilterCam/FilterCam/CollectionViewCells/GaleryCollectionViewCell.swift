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

    var videoURL: NSURL?

    override func awakeFromNib() {
        super.awakeFromNib()
        playButton.userInteractionEnabled = false
        videoImageView.image = UIImage(named: "placeHolderVideo")
    }

    func applyThumbnailImage() {
        print("applyThumbnailImage called")
        videoImageView.image = UIImage(named: "placeHolderVideo")
        if let videoURL = videoURL {
            Async.global(DISPATCH_QUEUE_PRIORITY_BACKGROUND) {
                let image = self.getThumbnailImageFor(videoURL)
                Async.main{
                    self.videoImageView.image = image
                }
            }
        }
    }

    func getThumbnailImageFor(URL: NSURL) -> UIImage {

        let asset = AVURLAsset(URL: URL, options: nil)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = UIScreen.mainScreen().bounds.size

        let cgImage = try! imageGenerator.copyCGImageAtTime(CMTimeMakeWithSeconds(2, 1), actualTime: nil)
        var thumbnailImage = UIImage(CGImage: cgImage)
        thumbnailImage = thumbnailImage.imageWithRenderingMode(.AlwaysOriginal)

        return thumbnailImage
    }
}
