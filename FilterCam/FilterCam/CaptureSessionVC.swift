//
//  CaptureSessionVC.swift
//  SayBubble
//
//  Created by Ganesh on 29/08/16.
//  Copyright © 2016 Sanjay. All rights reserved.
//

import UIKit
import Photos
import AVFoundation

let mediaLimit = 4
let maxTime : Double = 30
let timeScale : Int32 = 10000
let videoLimitErrorCode = -11810

enum CaptureMode {
    
    case stillImage
    case video
    case cameraRoll
}

class CaptureSessionVC: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    
    @IBOutlet weak var mediaCollection: UICollectionView!
    
    let captureSession = AVCaptureSession()
    var captureBackCameraInput = AVCaptureDeviceInput()
    var captureFrontCameraInput = AVCaptureDeviceInput()
    var videoCaptureOutput = AVCaptureVideoDataOutput()
    var stillImageOutput = AVCaptureStillImageOutput()
    var movieFileOutput: AVCaptureMovieFileOutput?
    var previewLayer = AVCaptureVideoPreviewLayer()
    var mediaTracks = [AVMutableCompositionTrack]()
    var mediaInstructions = [AVMutableVideoCompositionLayerInstruction]()
    var captureMode = CaptureMode.video
    var devicePosition = AVCaptureDevicePosition.back
    
    var sceneView : UIImageView?
    var media = [UIImage?]()
    var videoAssets = [AVURLAsset?]()
    
    var fileNumber = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCaptureSession()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        previewLayer.frame = view.frame
        sceneView?.frame = view.bounds
    }
    
    func configureCaptureSession() {
        configureMediaInput(devicePosition)
        configureVideoOutput()
        configureStillImageOutput()
        managePreviewLayer()
        configurePreviewLayer()
        configureView()
        captureSession.startRunning()
        mediaCollection.delegate = self
//        mediaCollection.registerNib(UINib(nibName: getClassName(MediaCollectionCell), bundle: nil), forCellWithReuseIdentifier: getClassName(MediaCollectionCell))
    }
    
    func configureView() {
        
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeForPositionChange))
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeForPositionChange))
        
        leftSwipe.direction = .left
        rightSwipe.direction = .right
        
        view.addGestureRecognizer(leftSwipe)
        view.addGestureRecognizer(rightSwipe)
    }
    
    func configurePreviewLayer() {
        
        sceneView = UIImageView(image: UIImage.init(named: "Mic"))
        sceneView?.contentMode = .scaleAspectFill
        sceneView?.contentMode = UIViewContentMode.scaleAspectFill
        view.insertSubview(sceneView!, at: 0)
        sceneView?.isHidden = true
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.insertSublayer(previewLayer, at: 0)
    }
    
    func managePreviewLayer() {
        
        if devicePosition == .front {
            sceneView?.isHidden = false
        } else {
            sceneView?.isHidden = true
        }
    }
    
    func didSwipeForPositionChange(_ recognizer: UISwipeGestureRecognizer) {
        
        captureSession.beginConfiguration()
        switch devicePosition {
        case .front:
            captureSession.removeInput(captureFrontCameraInput)
            configureMediaInput(.back)
            devicePosition = .back
            managePreviewLayer()
        case .back:
            captureSession.removeInput(captureBackCameraInput)
            configureMediaInput(.front)
            devicePosition = .front
            managePreviewLayer()
        default: ()
        }
        captureSession.commitConfiguration()
    }
    
    func configureMediaInput(_ devicePosition: AVCaptureDevicePosition) {
        
        let videoDevice = getCaptureDevice(AVMediaTypeVideo, devicePosition: devicePosition)
        
        if let media : AVCaptureDeviceInput = try? AVCaptureDeviceInput.init(device: videoDevice) {
            
            if devicePosition == .back {
                captureBackCameraInput = media
            } else {
                captureFrontCameraInput = media
            }
            
            if captureSession.canAddInput(media as AVCaptureInput) {
                captureSession.addInput(media as AVCaptureDeviceInput)
            } else {
                print("Failed to add media input.")
            }
        } else {
            print("Failed to create media capture device.")
        }
    }
    
    func configureVideoOutput() {
        
        let movieFileOutput: AVCaptureMovieFileOutput = AVCaptureMovieFileOutput()
        videoCaptureOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange as UInt32)]
        videoCaptureOutput.alwaysDiscardsLateVideoFrames = true
        
        captureSession.addOutput(videoCaptureOutput)
        if captureSession.canAddOutput(movieFileOutput){
            captureSession.addOutput(movieFileOutput)
            movieFileOutput.maxRecordedDuration = CMTimeMakeWithSeconds(maxTime, timeScale)
            self.movieFileOutput = movieFileOutput
        }
    }
    
    func configureStillImageOutput() {
        
        let stillImageOutput: AVCaptureStillImageOutput = AVCaptureStillImageOutput()
        stillImageOutput.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
        self.stillImageOutput = stillImageOutput
        captureSession.addOutput(stillImageOutput)
    }
    
    func getCaptureDevice(_ deviceType: String, devicePosition: AVCaptureDevicePosition) -> AVCaptureDevice {
        var device = AVCaptureDevice.defaultDevice(withMediaType: deviceType)
        let devices : NSArray = AVCaptureDevice.devices(withMediaType: deviceType) as NSArray
        
        for dev in devices {
            if (dev as AnyObject).position == devicePosition {
                device = dev as! AVCaptureDevice
                break;
            }
        }
        
        return device!
    }
    
    @IBAction func record(_ sender: AnyObject) {
        
        switch captureMode {
        case .video:
            processVideo()
        case .stillImage:
            processImage()
        case .cameraRoll:
            break
        }
    }
    
    @IBAction func captureImage(_ sender: AnyObject) {
        
        switch captureMode {
        case .video:
            captureMode = .stillImage
            mediaCollection.isHidden = false
        case .stillImage:
            captureMode = .video
        default: ()
        }
    }
    
    @IBAction func didEndSession(_ sender: AnyObject) {
        merge(videoAssets) { (fileURL) in
//            SBMediaAlbum.sharedInstance.saveVideo(fileURL!, completion: { (saved) in
//                print("Success, video merged and saved to Photo Album")
//            })
        }
    }
    
    func merge(_ assets: [AVURLAsset?], completion: @escaping (_ fileURL: URL?) -> ()) {
        if let firstAsset = assets[0] {
            self.mediaTracks.removeAll()
            let mixComposition = AVMutableComposition()
            
            
            let firstTrack = mixComposition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
            do {
                try firstTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, firstAsset.duration), of: firstAsset.tracks(withMediaType: AVMediaTypeVideo)[0], at: kCMTimeZero)
            } catch _ {
                print("Failed to load first track")
            }
            
            mediaTracks.append(firstTrack)
            var previousDuration = kCMTimeZero
            
            for i in 1..<videoAssets.count {
                if let currentAsset = videoAssets[i], let previousAsset = videoAssets[i-1] {
                    previousDuration = CMTimeAdd(previousDuration, previousAsset.duration)
                    let track = mixComposition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
                    do {
                        try track.insertTimeRange(CMTimeRangeMake(kCMTimeZero, currentAsset.duration), of: currentAsset.tracks(withMediaType: AVMediaTypeVideo)[0], at: previousDuration)
                    } catch _ {
                        print("Failed to other tracks")
                    }
                    mediaTracks.append(track)
                }
            }
            
            
            let mainInstruction = AVMutableVideoCompositionInstruction()
            mainInstruction.timeRange.duration = kCMTimeZero
            
            mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeAdd(mainInstruction.timeRange.duration, firstAsset.duration))
            
            for index in 1..<videoAssets.count {
                if let videoAsset = videoAssets[index] {
                    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeAdd(mainInstruction.timeRange.duration, videoAsset.duration))
                }
            }
            
            for index in 0..<videoAssets.count {
                if let videoAsset = videoAssets[index] {
                    let instruction = videoCompositionInstructionForTrack(mediaTracks[index], asset: videoAsset)
//                    if index == 0 {
//                        instruction.setOpacity(0.0, atTime: videoAsset.duration)
//                    }
                    mainInstruction.layerInstructions.append(instruction)
                }
            }
            
            let mainComposition = AVMutableVideoComposition()
            mainComposition.instructions = [mainInstruction]
            mainComposition.frameDuration = CMTimeMake(1, 30)
            mainComposition.renderSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            
            if devicePosition == .front {
                let overlayLayer: CALayer = CALayer()
                let overlayImage: UIImage? = UIImage(named: "Mic")
                
                overlayLayer.contents = (overlayImage!.cgImage as AnyObject)
                overlayLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                overlayLayer.masksToBounds = true
                
                let parentLayer: CALayer = CALayer()
                let videoLayer: CALayer = CALayer()
                parentLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                videoLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                parentLayer.addSublayer(videoLayer)
                parentLayer.addSublayer(overlayLayer)
                
                mainComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
            }
            
            let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .short
            let date = dateFormatter.string(from: Date())
            let savePath = (documentDirectory as NSString).appendingPathComponent("mergeVideo-\(date).mov")
            let url = URL(fileURLWithPath: savePath)
            
            
            guard let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else {
                return
            }
            exporter.outputURL = url
            exporter.outputFileType = AVFileTypeQuickTimeMovie
            exporter.shouldOptimizeForNetworkUse = true
            exporter.videoComposition = mainComposition
            
            exporter.exportAsynchronously() {
                DispatchQueue.main.async { _ in
                    completion(exporter.outputURL)
                }
            }
        }
    }
    
    func videoCompositionInstructionForTrack(_ track: AVCompositionTrack, asset: AVURLAsset) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let assetTrack = asset.tracks(withMediaType: AVMediaTypeVideo)[0]
        
        let transform = assetTrack.preferredTransform
        let assetInfo = orientationFromTransform(transform)
        var scaleToFitRatio = UIScreen.main.bounds.width / assetTrack.naturalSize.width
        if assetInfo.isPortrait {
            scaleToFitRatio = UIScreen.main.bounds.width / assetTrack.naturalSize.height
            let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)
            instruction.setTransform(assetTrack.preferredTransform.concatenating(scaleFactor),
                                     at: kCMTimeZero)
        } else {
            scaleToFitRatio = UIScreen.main.bounds.width / assetTrack.naturalSize.width
            let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)
            instruction.setTransform(assetTrack.preferredTransform.concatenating(scaleFactor),
                                     at: kCMTimeZero)
        }
        
        return instruction
    }
    
    func orientationFromTransform(_ transform: CGAffineTransform) -> (orientation: UIImageOrientation, isPortrait: Bool) {
        var assetOrientation = UIImageOrientation.up
        var isPortrait = false
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .right
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .left
            isPortrait = true
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .up
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .down
        }
        return (assetOrientation, isPortrait)
    }
    
    func processVideo() {
        let outputFilePath  = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("SBMov" + String(fileNumber) + ".mov")
        if let movieFileOutput = movieFileOutput {
            if !movieFileOutput.isRecording {
                print("recoding")
                movieFileOutput.connection(withMediaType: AVMediaTypeVideo).videoOrientation =
                    AVCaptureVideoOrientation(rawValue: (previewLayer).connection.videoOrientation.rawValue)!
                movieFileOutput.startRecording( toOutputFileURL: outputFilePath, recordingDelegate: self)
            } else {
                print("recoding stopped")
                movieFileOutput.stopRecording()
            }
        }
        fileNumber = fileNumber + 1
    }
    
    func processImage() {
        if let videoConnection = stillImageOutput.connection(withMediaType: AVMediaTypeVideo) {
            stillImageOutput.captureStillImageAsynchronously(from: videoConnection) {
                (imageDataSampleBuffer, error) -> Void in
                let image = UIImage(data: AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer))
                if let image = image {
                    if self.media.count < mediaLimit {
                        self.media.append(image)
                    }
                    self.mediaCollection.reloadData()
//                    SBMediaAlbum.sharedInstance.saveImage(image, completion: { (saved) in
//                        print("Image saved successfully")
//                    })
                }
            }
        }
    }
    
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        
        if error != nil && error._code != videoLimitErrorCode {
            return
        }
        
        let asset = AVURLAsset(url: outputFileURL, options: nil)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        let cgImage = try! imageGenerator.copyCGImage(at: CMTimeMakeWithSeconds(2, 1), actualTime: nil)
        let uiImage = UIImage(cgImage: cgImage)

        switch devicePosition {
        case .front:
            videoAssets.append(asset)
            merge(videoAssets) { (fileURL) in
                self.videoAssets.removeAll()
                self.videoAssets.append(AVURLAsset(url: fileURL!, options: nil))
            }
        case .back:
            videoAssets.append(asset)
        default: ()
        }
    }
}


extension CaptureSessionVC: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
//        cell.mediaImage.image = media.indices.contains(indexPath.item) ? media[indexPath.item] : nil
//        cell.mediaImage.tag = indexPath.item
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        let width = ceil(mediaCollection.frame.size.width / 4)
        return CGSize(width: width - 1, height: mediaCollection.bounds.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
    
}
