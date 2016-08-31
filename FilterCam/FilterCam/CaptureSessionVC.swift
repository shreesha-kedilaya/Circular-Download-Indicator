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
    
    case StillImage
    case Video
    case CameraRoll
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
    var captureMode = CaptureMode.Video
    var devicePosition = AVCaptureDevicePosition.Back
    
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
        
        leftSwipe.direction = .Left
        rightSwipe.direction = .Right
        
        view.addGestureRecognizer(leftSwipe)
        view.addGestureRecognizer(rightSwipe)
    }
    
    func configurePreviewLayer() {
        
        sceneView = UIImageView(image: UIImage.init(named: "Mic"))
        sceneView?.contentMode = .ScaleAspectFill
        sceneView?.contentMode = UIViewContentMode.ScaleAspectFill
        view.insertSubview(sceneView!, atIndex: 0)
        sceneView?.hidden = true
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.insertSublayer(previewLayer, atIndex: 0)
    }
    
    func managePreviewLayer() {
        
        if devicePosition == .Front {
            sceneView?.hidden = false
        } else {
            sceneView?.hidden = true
        }
    }
    
    func didSwipeForPositionChange(recognizer: UISwipeGestureRecognizer) {
        
        captureSession.beginConfiguration()
        switch devicePosition {
        case .Front:
            captureSession.removeInput(captureFrontCameraInput)
            configureMediaInput(.Back)
            devicePosition = .Back
            managePreviewLayer()
        case .Back:
            captureSession.removeInput(captureBackCameraInput)
            configureMediaInput(.Front)
            devicePosition = .Front
            managePreviewLayer()
        default: ()
        }
        captureSession.commitConfiguration()
    }
    
    func configureMediaInput(devicePosition: AVCaptureDevicePosition) {
        
        let videoDevice = getCaptureDevice(AVMediaTypeVideo, devicePosition: devicePosition)
        
        if let media : AVCaptureDeviceInput = try! AVCaptureDeviceInput.init(device: videoDevice) {
            
            if devicePosition == .Back {
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
        videoCaptureOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(unsignedInt: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
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
    
    func getCaptureDevice(deviceType: String, devicePosition: AVCaptureDevicePosition) -> AVCaptureDevice {
        var device = AVCaptureDevice.defaultDeviceWithMediaType(deviceType)
        let devices : NSArray = AVCaptureDevice.devicesWithMediaType(deviceType)
        
        for dev in devices {
            if dev.position == devicePosition {
                device = dev as! AVCaptureDevice
                break;
            }
        }
        
        return device
    }
    
    @IBAction func record(sender: AnyObject) {
        
        switch captureMode {
        case .Video:
            processVideo()
        case .StillImage:
            processImage()
        case .CameraRoll:
            break
        }
    }
    
    @IBAction func captureImage(sender: AnyObject) {
        
        switch captureMode {
        case .Video:
            captureMode = .StillImage
            mediaCollection.hidden = false
        case .StillImage:
            captureMode = .Video
        default: ()
        }
    }
    
    @IBAction func didEndSession(sender: AnyObject) {
        merge(videoAssets) { (fileURL) in
//            SBMediaAlbum.sharedInstance.saveVideo(fileURL!, completion: { (saved) in
//                print("Success, video merged and saved to Photo Album")
//            })
        }
    }
    
    func merge(assets: [AVURLAsset?], completion: (fileURL: NSURL?) -> ()) {
        if let firstAsset = assets[0] {
            self.mediaTracks.removeAll()
            let mixComposition = AVMutableComposition()
            
            
            let firstTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
            do {
                try firstTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, firstAsset.duration), ofTrack: firstAsset.tracksWithMediaType(AVMediaTypeVideo)[0], atTime: kCMTimeZero)
            } catch _ {
                print("Failed to load first track")
            }
            
            mediaTracks.append(firstTrack)
            var previousDuration = kCMTimeZero
            
            for i in 1..<videoAssets.count {
                if let currentAsset = videoAssets[i], previousAsset = videoAssets[i-1] {
                    previousDuration = CMTimeAdd(previousDuration, previousAsset.duration)
                    let track = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
                    do {
                        try track.insertTimeRange(CMTimeRangeMake(kCMTimeZero, currentAsset.duration), ofTrack: currentAsset.tracksWithMediaType(AVMediaTypeVideo)[0], atTime: previousDuration)
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
            mainComposition.renderSize = CGSize(width: UIScreen.mainScreen().bounds.width, height: UIScreen.mainScreen().bounds.height)
            
            if devicePosition == .Front {
                let overlayLayer: CALayer = CALayer()
                let overlayImage: UIImage? = UIImage(named: "Mic")
                
                overlayLayer.contents = (overlayImage!.CGImage as! AnyObject)
                overlayLayer.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height)
                overlayLayer.masksToBounds = true
                
                let parentLayer: CALayer = CALayer()
                let videoLayer: CALayer = CALayer()
                parentLayer.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height)
                videoLayer.frame = CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height)
                parentLayer.addSublayer(videoLayer)
                parentLayer.addSublayer(overlayLayer)
                
                mainComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, inLayer: parentLayer)
            }
            
            let documentDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = .LongStyle
            dateFormatter.timeStyle = .ShortStyle
            let date = dateFormatter.stringFromDate(NSDate())
            let savePath = (documentDirectory as NSString).stringByAppendingPathComponent("mergeVideo-\(date).mov")
            let url = NSURL(fileURLWithPath: savePath)
            
            
            guard let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else {
                return
            }
            exporter.outputURL = url
            exporter.outputFileType = AVFileTypeQuickTimeMovie
            exporter.shouldOptimizeForNetworkUse = true
            exporter.videoComposition = mainComposition
            
            exporter.exportAsynchronouslyWithCompletionHandler() {
                dispatch_async(dispatch_get_main_queue()) { _ in
                    completion(fileURL: exporter.outputURL)
                }
            }
        }
    }
    
    func videoCompositionInstructionForTrack(track: AVCompositionTrack, asset: AVURLAsset) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let assetTrack = asset.tracksWithMediaType(AVMediaTypeVideo)[0]
        
        let transform = assetTrack.preferredTransform
        let assetInfo = orientationFromTransform(transform)
        var scaleToFitRatio = UIScreen.mainScreen().bounds.width / assetTrack.naturalSize.width
        if assetInfo.isPortrait {
            scaleToFitRatio = UIScreen.mainScreen().bounds.width / assetTrack.naturalSize.height
            let scaleFactor = CGAffineTransformMakeScale(scaleToFitRatio, scaleToFitRatio)
            instruction.setTransform(CGAffineTransformConcat(assetTrack.preferredTransform, scaleFactor),
                                     atTime: kCMTimeZero)
        } else {
            scaleToFitRatio = UIScreen.mainScreen().bounds.width / assetTrack.naturalSize.width
            let scaleFactor = CGAffineTransformMakeScale(scaleToFitRatio, scaleToFitRatio)
            instruction.setTransform(CGAffineTransformConcat(assetTrack.preferredTransform, scaleFactor),
                                     atTime: kCMTimeZero)
        }
        
        return instruction
    }
    
    func orientationFromTransform(transform: CGAffineTransform) -> (orientation: UIImageOrientation, isPortrait: Bool) {
        var assetOrientation = UIImageOrientation.Up
        var isPortrait = false
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .Right
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .Left
            isPortrait = true
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .Up
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .Down
        }
        return (assetOrientation, isPortrait)
    }
    
    func processVideo() {
        let outputFilePath  = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("SBMov" + String(fileNumber) + ".mov")
        if let movieFileOutput = movieFileOutput {
            if !movieFileOutput.recording {
                print("recoding")
                movieFileOutput.connectionWithMediaType(AVMediaTypeVideo).videoOrientation =
                    AVCaptureVideoOrientation(rawValue: (previewLayer).connection.videoOrientation.rawValue)!
                movieFileOutput.startRecordingToOutputFileURL( outputFilePath, recordingDelegate: self)
            } else {
                print("recoding stopped")
                movieFileOutput.stopRecording()
            }
        }
        fileNumber = fileNumber + 1
    }
    
    func processImage() {
        if let videoConnection = stillImageOutput.connectionWithMediaType(AVMediaTypeVideo) {
            stillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection) {
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
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        
        if error != nil && error.code != videoLimitErrorCode {
            return
        }
        
        let asset = AVURLAsset(URL: outputFileURL, options: nil)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        let cgImage = try! imageGenerator.copyCGImageAtTime(CMTimeMakeWithSeconds(2, 1), actualTime: nil)
        let uiImage = UIImage(CGImage: cgImage)

        switch devicePosition {
        case .Front:
            videoAssets.append(asset)
            merge(videoAssets) { (fileURL) in
                self.videoAssets.removeAll()
                self.videoAssets.append(AVURLAsset(URL: fileURL!, options: nil))
            }
        case .Back:
            videoAssets.append(asset)
        default: ()
        }
    }
}


extension CaptureSessionVC: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath)
//        cell.mediaImage.image = media.indices.contains(indexPath.item) ? media[indexPath.item] : nil
//        cell.mediaImage.tag = indexPath.item
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let width = ceil(mediaCollection.frame.size.width / 4)
        return CGSize(width: width - 1, height: CGRectGetHeight(mediaCollection.bounds))
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1
    }
    
}