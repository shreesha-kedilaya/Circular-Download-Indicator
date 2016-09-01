//
//  ViewController.swift
//  FilterCam
//
//  Created by Shreesha on 30/08/16.
//  Copyright © 2016 YML. All rights reserved.
//

import UIKit
import AVFoundation

private let mediaDataLimit = 4
private let maxTimeLimit : Double = 30
private let timeScaleToGet : Int32 = 10000

class CameraCaptureViewController: UIViewController {

    private lazy var cameraCaptureSession: AVCaptureSession = {
        let session = AVCaptureSession()

        if session.canSetSessionPreset(self.viewModel.resolutionQuality) {
            session.sessionPreset = self.viewModel.resolutionQuality
        } else {
            print("Failed to set the preset value")
        }
        return session
    }()

    @IBOutlet weak var filterButton: UIButton!
    private var inputDevice: AVCaptureDevice?
    private var movieFileOutput: AVCaptureMovieFileOutput?
    private var cameraStillImageOutput = AVCaptureStillImageOutput()
    private var captureCameraInput: AVCaptureDeviceInput?

    private var fileNumber = 0

    private lazy var cameraPreviewLayer = AVCaptureVideoPreviewLayer()

    private lazy var videoCaptureOutput = AVCaptureVideoDataOutput()
//    private lazy var mediaTracks = [AVMutableCompositionTrack]()
//    private lazy var mediaInstructions = [AVMutableVideoCompositionLayerInstruction]()
//    private lazy var videoAssets = [AVURLAsset?]()

    @IBOutlet weak var previewLayerFrameView: UIView!
    @IBOutlet weak var flipButton: UIButton!
    @IBOutlet weak var captureButton: UIButton!

    private lazy var viewModel = CameraCaptureViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        previewLayerFrameView.layoutIfNeeded()
        let frame = previewLayerFrameView.frame
        cameraPreviewLayer.frame = frame

        title = "Capture"

        // Do any additional setup after loading the view, typically from a nib.
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == AVCaptureSessionRuntimeErrorNotification {
            let cameraSession = object as? AVCaptureSession

            guard let captureSession = cameraSession else {
                return
            }

            if captureSession.running {
                print("captureSession running")
            } else if captureSession.interrupted {
                print("captureSession interupted")
            }
        }
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        captureButton.setTitle((viewModel.captureMode == .Camera ? "Capture": "Start recording"), forState: .Normal)

        let permissionService = PermissionType.Camera.permissionService
        permissionService.requestPermission { (status) in
            switch status {
            case .Authorized:
                self.cameraCaptureSession.startRunning()
            default: ()
                //Show some alert
            }
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        cameraCaptureSession.addObserver(self, forKeyPath: AVCaptureSessionRuntimeErrorNotification, options: NSKeyValueObservingOptions.New, context: nil)

        let devices = AVCaptureDevice.devices()

        for device in devices {
            print((device as! AVCaptureDevice).localizedName)
        }

        inputDevice = viewModel.getCameraDevice(AVMediaTypeVideo, devicePosition: viewModel.currentDevicePosition)
        captureCameraInput = try? AVCaptureDeviceInput(device: inputDevice)

        if cameraCaptureSession.canAddInput(captureCameraInput) {
            cameraCaptureSession.addInput(captureCameraInput)
        }

        cameraPreviewLayer.session = cameraCaptureSession
        cameraPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayerFrameView.layer.masksToBounds = true

        previewLayerFrameView.layer.insertSublayer(cameraPreviewLayer, atIndex: 0)

        let permissionService = PermissionType.Camera.permissionService
        permissionService.requestPermission { (status) in
            switch status {
            case .Authorized:
                self.cameraCaptureSession.startRunning()
            default: ()
            }
        }
    }

    private func setTheCameraStillImageOutputs() {
        let outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
        cameraStillImageOutput.outputSettings = outputSettings

        if cameraCaptureSession.canAddOutput(cameraStillImageOutput) {
            cameraCaptureSession.addOutput(cameraStillImageOutput)
        }
    }

    private func setTheVideoOutput() {
        let movieFileOutput: AVCaptureMovieFileOutput = AVCaptureMovieFileOutput()
        videoCaptureOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(unsignedInt: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
        videoCaptureOutput.alwaysDiscardsLateVideoFrames = true
        videoCaptureOutput.setSampleBufferDelegate(self, queue: dispatch_queue_create("sample buffer delegate", DISPATCH_QUEUE_SERIAL))

        cameraCaptureSession.addOutput(videoCaptureOutput)
        if cameraCaptureSession.canAddOutput(movieFileOutput){
            cameraCaptureSession.addOutput(movieFileOutput)
            movieFileOutput.maxRecordedDuration = CMTimeMakeWithSeconds(maxTimeLimit, timeScaleToGet)
            self.movieFileOutput = movieFileOutput
        }
    }

    private func changeTheDeviceType() {

        cameraCaptureSession.beginConfiguration()
        cameraCaptureSession.removeInput(captureCameraInput)
        switch viewModel.currentDevicePosition {
        case .Front:
            viewModel.currentDevicePosition = .Back
            configureMediaInput(viewModel.currentDevicePosition)
        case .Back:
            viewModel.currentDevicePosition = .Front
            configureMediaInput(viewModel.currentDevicePosition)
        default: ()
        }
        cameraCaptureSession.commitConfiguration()
    }
    @IBAction func flipImageDidTap(sender: AnyObject) {
        changeTheDeviceType()
    }

    func configureMediaInput(devicePosition: AVCaptureDevicePosition) {

        let videoDevice = viewModel.getCameraDevice(AVMediaTypeVideo, devicePosition: devicePosition)

        if let media : AVCaptureDeviceInput = try! AVCaptureDeviceInput.init(device: videoDevice) {

            captureCameraInput = nil
            captureCameraInput = media

            if cameraCaptureSession.canAddInput(captureCameraInput) {
                cameraCaptureSession.addInput(captureCameraInput)
            } else {
                print("Failed to add media input.")
            }
        } else {
            print("Failed to create media capture device.")
        }
    }

    @IBAction func didTapOnFilter(sender: AnyObject) {
        
    }

    @IBAction func settingsDIdTap(sender: AnyObject) {
        let settingsVC = storyboard?.instantiateViewControllerWithIdentifier("SettingsViewController") as? SettingsViewController
        settingsVC?.viewModel.currentSetting = viewModel.captureMode
        settingsVC?.delegate = self
        presentViewController(settingsVC!, animated: true, completion: nil)
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
        cameraCaptureSession.removeObserver(self, forKeyPath: AVCaptureSessionRuntimeErrorNotification)
        cameraCaptureSession.stopRunning()
    }

    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        
        previewLayerFrameView.layoutIfNeeded()
        let frame = previewLayerFrameView.frame
        cameraPreviewLayer.frame = frame
    }

    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        previewLayerFrameView.layoutIfNeeded()
        let frame = previewLayerFrameView.frame
        cameraPreviewLayer.frame = frame
    }

    @IBAction func captureTheSession(sender: AnyObject) {
        handelCaptureAction()
    }

    private func handelCaptureAction() {

        switch viewModel.captureMode {
        case .Camera:
            processImage()
        case .Video:
            if let movieFileOutput = movieFileOutput {
                if movieFileOutput.recording {
                    captureButton.setTitle("Recording....", forState: .Normal)
                } else {
                    captureButton.setTitle("Start recording", forState: .Normal)
                }
                processVideo()
            }
        }
    }

    func processVideo() {
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)

        let documentDirectory = paths.first
        let dataPath = documentDirectory?.stringByAppendingString("FileCam \(fileNumber).mov")

        if let movieFileOutput = movieFileOutput {
            if !movieFileOutput.recording {
                print("recoding")
                movieFileOutput.connectionWithMediaType(AVMediaTypeVideo).videoOrientation =
                    AVCaptureVideoOrientation(rawValue: cameraPreviewLayer.connection.videoOrientation.rawValue)!
                movieFileOutput.startRecordingToOutputFileURL( NSURL(string: dataPath!), recordingDelegate: self)
            } else {
                print("recoding stopped")
                movieFileOutput.stopRecording()
            }
        }

        fileNumber = fileNumber + 1
    }

    private func processImage() {
        if let videoConnection = cameraStillImageOutput.connectionWithMediaType(AVMediaTypeVideo) {
            cameraStillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection) {
                (imageDataSampleBuffer, error) -> Void in
                let image = UIImage(data: AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer))
                if let image = image {

                }
            }
        }
    }

    private func reloadAllTheInputs() {

    }

    private func askSaveOrPreview() {
        let alertController = UIAlertController(title: "Video", message: "Video is Recorded", preferredStyle: .ActionSheet)

        let saveAction = UIAlertAction(title: "Save", style: .Default) { (action) in

        }

        let discardAction = UIAlertAction(title: "Discard", style: .Default) { (action) in

        }

        let previewAction = UIAlertAction(title: "Preview", style: .Default) { (action) in
            let previewVC = self.storyboard?.instantiateViewControllerWithIdentifier("PreviewVideoViewController") as? PreviewVideoViewController

            self.navigationController?.pushViewController(previewVC!, animated: true)
        }

        alertController.addAction(previewAction)
        alertController.addAction(discardAction)
        alertController.addAction(saveAction)

        presentViewController(alertController, animated: true, completion: nil)
    }
}

extension CameraCaptureViewController: SettingsViewControllerDelegate {
    func settingsViewController(viewController: SettingsViewController, didDismissWithCaptureMode captureMode: CameraCaptureMode) {
        viewController.dismissViewControllerAnimated(true) { 

            self.viewModel.captureMode = captureMode
            self.reloadAllTheInputs()
        }
    }
}


extension CameraCaptureViewController: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate {

    func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {

    }

    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {

    }

    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        
    }
}