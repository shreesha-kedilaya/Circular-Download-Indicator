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

    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var filterButton: UIButton!
    private var movieFileOutput: AVCaptureMovieFileOutput?

    private var coreImageView: CoreImageView?

    private var fileNumber = 0

    @IBOutlet weak var previewLayerFrameView: UIView!
    @IBOutlet weak var flipButton: UIButton!
    @IBOutlet weak var captureButton: UIButton!

    private var cgimages = [CGImage]()

    private var videoFilterHandler: VideoBufferHandler?
    private lazy var viewModel = CameraCaptureViewModel()

    private var isrecordingVideo = false

    var videoCreator: VideoCreator?

    override func viewDidLoad() {
        super.viewDidLoad()

        previewLayerFrameView.layoutIfNeeded()
        previewImageView.hidden = true
        coreImageView = CoreImageView(frame: view.frame)
        view.insertSubview(coreImageView!, atIndex: 0)

        videoFilterHandler = VideoBufferHandler()

        videoFilterHandler?.bufferCallBack = handleTheOutputBuffer

        title = "Capture"

        // Do any additional setup after loading the view, typically from a nib.
    }

    func startVideoRecording(withPath path: String) {
        videoCreator = VideoCreator()
//        videoCreator?.pixelFormat = kCVPixelFormatType_32ARGB
//        videoCreator?.writingQueue = dispatch_queue_create("AssetWriterQueue", DISPATCH_QUEUE_SERIAL)
//        videoCreator?.videoCreationType = .FromSeparateImages
//
//        videoCreator?.startWrting(atPath: path, size: UIScreen.mainScreen().bounds.size, videoFPS: 40)
        isrecordingVideo = true
    }

    func stopVideoRecording(handler: (savedUrl: NSURL) -> ()) {

        isrecordingVideo = false
        guard let videoCreator = videoCreator else {
            return
        }

        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let documentDirectory = paths.first
        let dataPath = documentDirectory?.stringByAppendingString("FilterCam \(12).mov")

        videoCreator.writeImagesAsMovie(cgimages, videoPath: dataPath!, videoSize: UIScreen.mainScreen().bounds.size, videoFPS: 40)
//        if videoCreator.sessionRunning {
//            videoCreator.stopWriting { (url: NSURL) -> Void in
//                handler(savedUrl: url)
//            }
//        }

        cgimages = []
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        coreImageView?.frame = view.frame

        if let coreImageView = coreImageView {
            view.sendSubviewToBack(coreImageView)
        }

        captureButton.setTitle((viewModel.captureMode == .Camera ? "Capture": "Start recording"), forState: .Normal)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        videoFilterHandler?.startSession()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
        videoFilterHandler?.stopSession()
    }

    @IBAction func flipImageDidTap(sender: AnyObject) {
        //TODO: Change the front and back camera
    }

    @IBAction func didTapOnFilter(sender: AnyObject) {
        
    }

    @IBAction func settingsDIdTap(sender: AnyObject) {
        let settingsVC = storyboard?.instantiateViewControllerWithIdentifier("SettingsViewController") as? SettingsViewController
        settingsVC?.viewModel.currentSetting = viewModel.captureMode
        settingsVC?.delegate = self
        presentViewController(settingsVC!, animated: true, completion: nil)
    }

    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        coreImageView?.frame = view.frame
    }

    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        coreImageView?.frame = view.frame
    }

    @IBAction func captureTheSession(sender: AnyObject) {
        handelCaptureAction()
    }

    private func handelCaptureAction() {

        switch viewModel.captureMode {
        case .Camera:()

        case .Video:
            if let videoCreator = videoCreator {
                if !videoCreator.sessionRunning {
                    captureButton.setTitle("Recording....", forState: .Normal)
                } else {
                    captureButton.setTitle("Start recording", forState: .Normal)
                }
            } else {
                captureButton.setTitle("Recording....", forState: .Normal)
            }
            processVideo()
        }
    }

    func processVideo() {

        let outputFilePath = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("FilterCam" + String(fileNumber) + ".mov")

        fileNumber = fileNumber + 1

        if let videoCreator = videoCreator {
            if isrecordingVideo{
                self.stopVideoRecording({ (savedUrl) in
//                    self.handleAfterRecordingVideo(savedUrl)
                })
            } else {
                self.startVideoRecording(withPath: outputFilePath.path!)
            }
        } else {
            self.startVideoRecording(withPath: outputFilePath.path!)
        }
    }

    func handleAfterRecordingVideo(saveUrl: NSURL) {

        Async.main {
            let videoPreviewViewController = self.storyboard?.instantiateViewControllerWithIdentifier("VideoPreviewViewController") as! VideoPreviewViewController
            videoPreviewViewController.videoPreviewType = .VideoPreview
            videoPreviewViewController.savedTempUrl = saveUrl
            self.navigationController?.pushViewController(videoPreviewViewController, animated: true)
        }
    }

    private func reloadAllTheInputs() {

    }

    private func handleTheOutputBuffer(sampleBuffer: CMSampleBuffer, transform: CGAffineTransform) {
        let ciimage = CIImage(buffer: sampleBuffer).imageByApplyingTransform(AVCaptureDevicePosition.Front.transform)
        let filter = pixellate(5)
        let image = filter(ciimage)
        coreImageView?.image = image
        let cgimage = coreImageView?.coreImageContext.createCGImage(image, fromRect: UIScreen.mainScreen().bounds)

        if let cgimage = cgimage {
//            videoCreator?.appendImage(cgimage, completion: { (numberOfFrames) in
//
//            })
            if isrecordingVideo {
                   self.cgimages.append(cgimage)
            }
        }
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

extension CGAffineTransform {

    init(rotatingWithAngle angle: CGFloat) {
        let t = CGAffineTransformMakeRotation(angle)
        self.init(a: t.a, b: t.b, c: t.c, d: t.d, tx: t.tx, ty: t.ty)

    }
    init(scaleX sx: CGFloat, scaleY sy: CGFloat) {
        let t = CGAffineTransformMakeScale(sx, sy)
        self.init(a: t.a, b: t.b, c: t.c, d: t.d, tx: t.tx, ty: t.ty)

    }

    func scale(sx: CGFloat, sy: CGFloat) -> CGAffineTransform {
        return CGAffineTransformScale(self, sx, sy)
    }
    func rotate(angle: CGFloat) -> CGAffineTransform {
        return CGAffineTransformRotate(self, angle)
    }
}

extension CIImage {
    convenience init(buffer: CMSampleBuffer) {
        self.init(CVPixelBuffer: CMSampleBufferGetImageBuffer(buffer)!)
    }
}

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}

extension AVCaptureDevicePosition {
    var transform: CGAffineTransform {
        switch self {
        case .Front:
            return CGAffineTransform(rotatingWithAngle: -CGFloat(M_PI_2)).scale(1, sy: -1)
        case .Back:
            return CGAffineTransform(rotatingWithAngle: -CGFloat(M_PI_2))
        default:
            return CGAffineTransformIdentity

        }
    }

    var device: AVCaptureDevice? {
        return AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo).filter {
            $0.position == self
            }.first as? AVCaptureDevice
    }
}