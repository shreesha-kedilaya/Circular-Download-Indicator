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

enum VideoPreviewType {
    case videoPreview
    case galleryVideoPreview
}

class VideoPreviewViewController: UIViewController {

    @IBOutlet weak var frameCollectionView: UIView!
    @IBOutlet weak var videoPreviewView: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var videoButton: UIImageView!

    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var endLabel: UILabel!
    fileprivate var playingAsset: AVAsset?
    fileprivate var currentPlayerItem: AVPlayerItem?
    
    @IBOutlet weak var discardButton: UIButton!
    @IBOutlet weak var startLabel: UILabel!
    fileprivate var playing = false
    fileprivate var totalDuration: Double = 0
    fileprivate var currentDuration: Double = 0
    fileprivate var fileNumber = 0

    fileprivate var periodicObserver: AnyObject?

    fileprivate lazy var videoPlayer = AVPlayer()
    fileprivate var videoPlayerLayer: AVPlayerLayer!

    fileprivate lazy var viewModel = VideoPreviewViewModel()

    var playingPhAsset: PHAsset?
    var savedTempUrl: URL?
    var videoPreviewType = VideoPreviewType.videoPreview

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Video Preview"
        videoPlayerLayer = AVPlayerLayer(player: videoPlayer)
        videoPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspect
        videoPreviewView.layoutIfNeeded()
        videoPlayerLayer.frame = videoPreviewView.frame
        progressView.setProgress(0, animated: false)
        startLabel.text = "0"

        saveButton.isHidden = videoPreviewType == .galleryVideoPreview ? false : true
        discardButton.isHidden = videoPreviewType == .galleryVideoPreview ? false : true
    }

    @IBAction func discardButtonDidClick(_ sender: AnyObject) {

        let fileManager = FileManager.default
        do {
            if let savedTempUrl = savedTempUrl {
                try fileManager.removeItem(at: savedTempUrl)
            }
        }catch {
            print("could not delete the video.")
        }
    }

    @IBAction func saveButtonDidClick(_ sender: AnyObject) {
        saveVideoToLibrary()
    }

    func saveVideoToLibrary() {

        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentDirectory = paths.first
        let dataPath = (documentDirectory)! + "FilterCam \(fileNumber).mov"

        fileNumber += 1

        guard let savedTempUrl = savedTempUrl else{
            return
        }
        guard let exporter = AVAssetExportSession(asset: AVURLAsset(url: savedTempUrl), presetName: AVAssetExportPresetHighestQuality) else {
            return
        }
        exporter.outputURL = URL(string: dataPath)
        exporter.outputFileType = AVFileTypeQuickTimeMovie
        exporter.shouldOptimizeForNetworkUse = true

        exporter.exportAsynchronously() {
            DispatchQueue.main.async { _ in
                let alertController = UIAlertController(title: "Saved", message: "Video successfully saved", preferredStyle: .alert)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addPlayerItemToPlayer()

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    fileprivate func addPlayerItemToPlayer() {

        videoPreviewView.layer.insertSublayer(videoPlayerLayer, at: 0)

        if let playingPhAsset = playingPhAsset {
            PHCachingImageManager.default().requestAVAsset(forVideo: playingPhAsset, options: nil) { (asset, audio, doctionaryObject) in
                Async.main{
                    self.setupThePlayerItem(asset)
                }
            }
        } else if let savedTempUrl = savedTempUrl{
            let asset = AVURLAsset(url: savedTempUrl, options: nil)
            setupThePlayerItem(asset)
        }
    }

    fileprivate func setupThePlayerItem(_ asset: AVAsset?) {
        self.playingAsset = asset
        self.currentPlayerItem = AVPlayerItem(asset: self.playingAsset!)
        self.totalDuration = CMTimeGetSeconds(self.playingAsset!.duration)
        self.videoPlayer.replaceCurrentItem(with: self.currentPlayerItem!)
        let interval = CMTimeMakeWithSeconds(0.5, Int32(NSEC_PER_SEC))
        self.periodicObserver = self.videoPlayer.addPeriodicTimeObserver(forInterval: interval, queue: nil, using: { (time) in
            self.reloadTimeAndProgress(time)
        }) as AnyObject?
        self.currentPlayerItem?.addObserver(self, forKeyPath: "status", options: [NSKeyValueObservingOptions.new, NSKeyValueObservingOptions.initial], context: nil)
        self.currentPlayerItem?.addObserver(self, forKeyPath: "rate", options: [NSKeyValueObservingOptions.new], context: nil)
        self.currentPlayerItem?.addObserver(self, forKeyPath: "playbackBufferEmpty", options: [NSKeyValueObservingOptions.new, NSKeyValueObservingOptions.initial], context: nil)
        self.currentPlayerItem?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: [NSKeyValueObservingOptions.new, NSKeyValueObservingOptions.initial], context: nil)
        self.videoPlayer.actionAtItemEnd = .pause
        NotificationCenter.default.addObserver(self, selector: #selector(VideoPreviewViewController.handlePlayerItemOperation(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.videoPlayer.currentItem)
    }

    func handlePlayerItemOperation(_ notification: Notification) {

        let object = notification.object as? AVPlayerItem
        self.playing = false
        object?.seek(to: kCMTimeZero, completionHandler: { (flag) in
            Async.main{
                self.videoPlayer.pause()
                self.videoButton.isHidden = false
            }
        })

        print("handlePlayerItemOperation")
    }

    func reloadTimeAndProgress(_ time: CMTime) {

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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let periodicObserver = periodicObserver {
            videoPlayer.removeTimeObserver(periodicObserver)
        }
        currentPlayerItem?.removeObserver(self, forKeyPath: "status")
        currentPlayerItem?.removeObserver(self, forKeyPath: "rate")
        currentPlayerItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty")
        currentPlayerItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        NotificationCenter.default.removeObserver(self)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath else{
            return
        }
        guard let currentPlayerItem = currentPlayerItem else {
            return
        }

        if currentPlayerItem.isPlaybackBufferEmpty {
            if currentPlayerItem.isPlaybackBufferEmpty {
                playing = false
                videoPlayer.pause()
            }
        }

        if currentPlayerItem.isPlaybackLikelyToKeepUp {

        }
        switch NSNotification.Name(keyPath) {
        case NSNotification.Name.AVPlayerItemDidPlayToEndTime:
            videoPlayer.pause()
            playing = false
        case NSNotification.Name.AVPlayerItemTimeJumped:()
        default: ()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func playButtonTapped(_ sender: AnyObject) {

        if !playing && videoPlayer.status == .readyToPlay{
            videoPlayer.play()
            videoButton.isHidden = true
        } else {
            videoPlayer.pause()
            videoButton.isHidden = false
        }
        playing = !playing
    }

    fileprivate func reloadAllSubviews() {
        videoPreviewView.layoutIfNeeded()
        videoPlayerLayer.frame = videoPreviewView.frame
    }

    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        self.reloadAllSubviews()
    }

    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        UIView.animate(withDuration: duration, animations: { 
            self.reloadAllSubviews()
        }) 
    }
}
