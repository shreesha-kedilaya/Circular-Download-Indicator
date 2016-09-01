//
//  VideoPreviewViewController.swift
//  FilterCam
//
//  Created by Shreesha on 31/08/16.
//  Copyright © 2016 YML. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class VideoPreviewViewController: UIViewController {

    @IBOutlet weak var frameCollectionView: UIView!
    @IBOutlet weak var videoPreviewView: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var videoButton: UIImageView!

    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var endLabel: UILabel!
    private var playingAsset: AVAsset?
    private var currentPlayerItem: AVPlayerItem?
    
    @IBOutlet weak var startLabel: UILabel!
    private var playing = false
    private var totalDuration: Double = 0
    private var currentDuration: Double = 0

    private var periodicObserver: AnyObject?

    private lazy var videoPlayer = AVPlayer()
    private var videoPlayerLayer: AVPlayerLayer!

    private lazy var viewModel = VideoPreviewViewModel()

    var playingPhAsset: PHAsset?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Video Preview"
        videoPlayerLayer = AVPlayerLayer(player: videoPlayer)
        videoPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspect
        videoPreviewView.layoutIfNeeded()
        videoPlayerLayer.frame = videoPreviewView.frame
        progressView.setProgress(0, animated: false)
        startLabel.text = "0"
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        addPlayerItemToPlayer()

    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }

    private func addPlayerItemToPlayer() {

        videoPreviewView.layer.insertSublayer(videoPlayerLayer, atIndex: 0)

        if let playingPhAsset = playingPhAsset {
            PHCachingImageManager.defaultManager().requestAVAssetForVideo(playingPhAsset, options: nil) { (asset, audio, doctionaryObject) in
                Async.main{
                    self.playingAsset = asset
                    self.currentPlayerItem = AVPlayerItem(asset: self.playingAsset!)
                    self.totalDuration = CMTimeGetSeconds(self.playingAsset!.duration)
                    self.videoPlayer.replaceCurrentItemWithPlayerItem(self.currentPlayerItem!)
                    let interval = CMTimeMakeWithSeconds(0.5, Int32(NSEC_PER_SEC))
                    self.periodicObserver = self.videoPlayer.addPeriodicTimeObserverForInterval(interval, queue: nil, usingBlock: { (time) in
                        self.reloadTimeAndProgress(time)
                    })
                    self.currentPlayerItem?.addObserver(self, forKeyPath: "status", options: [NSKeyValueObservingOptions.New, NSKeyValueObservingOptions.Initial], context: nil)
                    self.currentPlayerItem?.addObserver(self, forKeyPath: "rate", options: [NSKeyValueObservingOptions.New], context: nil)
                    self.currentPlayerItem?.addObserver(self, forKeyPath: "playbackBufferEmpty", options: [NSKeyValueObservingOptions.New, NSKeyValueObservingOptions.Initial], context: nil)
                    self.currentPlayerItem?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: [NSKeyValueObservingOptions.New, NSKeyValueObservingOptions.Initial], context: nil)
                    self.videoPlayer.actionAtItemEnd = .Pause
                    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(VideoPreviewViewController.handlePlayerItemOperation(_:)), name: AVPlayerItemDidPlayToEndTimeNotification, object: self.videoPlayer.currentItem)
                }
            }
        }
    }

    func handlePlayerItemOperation(notification: NSNotification) {

        let object = notification.object as? AVPlayerItem
        self.playing = false
        object?.seekToTime(kCMTimeZero, completionHandler: { (flag) in
            Async.main{
                self.videoPlayer.pause()
                self.videoButton.hidden = false
            }
        })

        print("handlePlayerItemOperation")
    }

    func reloadTimeAndProgress(time: CMTime) {

        if playing {
            let timeInSeconds = CMTimeGetSeconds(time)
            let progress = 1 - (Double(totalDuration) - timeInSeconds) / totalDuration
            currentDuration = Double(timeInSeconds)
            progressView.setProgress(Float(progress), animated: true)
            let string = String(format: "%0.0f", Float(timeInSeconds))
            endLabel.text = "\(string)"
            print("progress \(progress)")
        }
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if let periodicObserver = periodicObserver {
            videoPlayer.removeTimeObserver(periodicObserver)
        }
        currentPlayerItem?.removeObserver(self, forKeyPath: "status")
        currentPlayerItem?.removeObserver(self, forKeyPath: "rate")
        currentPlayerItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty")
        currentPlayerItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard let keyPath = keyPath else{
            return
        }
        guard let currentPlayerItem = currentPlayerItem else {
            return
        }
        switch keyPath {
        case AVPlayerItemDidPlayToEndTimeNotification:
            videoPlayer.pause()
            playing = false
        case AVPlayerItemTimeJumpedNotification:()
        case "status":()
        case "rate":()
        case "playbackBufferEmpty":
            if currentPlayerItem.playbackBufferEmpty {
                playing = false
                videoPlayer.pause()
            }
        case "playbackLikelyToKeepUp":()
        default: ()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func playButtonTapped(sender: AnyObject) {

        if !playing && videoPlayer.status == .ReadyToPlay{
            videoPlayer.play()
            videoButton.hidden = true
        } else {
            videoPlayer.pause()
            videoButton.hidden = false
        }
        playing = !playing
    }

    private func reloadAllSubviews() {
        videoPreviewView.layoutIfNeeded()
        videoPlayerLayer.frame = videoPreviewView.frame
    }

    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        self.reloadAllSubviews()
    }

    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        UIView.animateWithDuration(duration) { 
            self.reloadAllSubviews()
        }
    }
}
