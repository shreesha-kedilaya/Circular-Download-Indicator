//
//  VideoPreviewViewController.swift
//  FilterCam
//
//  Created by Shreesha on 31/08/16.
//  Copyright © 2016 YML. All rights reserved.
//

import UIKit
import AVFoundation

class VideoPreviewViewController: UIViewController {

    @IBOutlet weak var frameCollectionView: UIView!
    @IBOutlet weak var videoPreviewView: UIView!
    @IBOutlet weak var playButton: UIButton!

    var playingAsset: AVAsset?
    private var playing = false

    private lazy var videoPlayer = AVPlayer()
    private var videoPlayerLayer: AVPlayerLayer!

    private lazy var viewModel = VideoPreviewViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        videoPlayerLayer = AVPlayerLayer(player: videoPlayer)
        videoPreviewView.layer.insertSublayer(videoPlayerLayer, atIndex: 0)

        let playerItem = AVPlayerItem(asset: playingAsset!)
        videoPlayer.replaceCurrentItemWithPlayerItem(playerItem)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func playButtonTapped(sender: AnyObject) {
        playing = !playing
        if !playing {
            videoPlayer.play()
        }
    }
}
