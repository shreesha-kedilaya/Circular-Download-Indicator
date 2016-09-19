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
    fileprivate var movieFileOutput: AVCaptureMovieFileOutput?

    fileprivate var coreImageView: CoreImageView?

    fileprivate var fileNumber = 0

    @IBOutlet weak var previewLayerFrameView: UIView!

    var writingFileNumber: Int? {
        get {
            return UserDefaults.standard.value(forKey: "writingFileNumber") as? Int
        }
        set {
            UserDefaults.standard.set(writingFileNumber, forKey: "writingFileNumber")
        }
    }

    @IBOutlet weak var flipButton: UIButton!
    @IBOutlet weak var captureButton: UIButton!
    private var numberOfFrames = 0

    private var coreImageContext: CIContext?

    fileprivate var cgimages = [CGImage]()

    fileprivate var videoFilterHandler: VideoBufferHandler?
    fileprivate lazy var viewModel = CameraCaptureViewModel()

    fileprivate var isrecordingVideo = false

    var videoCreator: VideoCreator?

    override func viewDidLoad() {
        super.viewDidLoad()

        previewLayerFrameView.layoutIfNeeded()
        previewImageView.isHidden = true
        coreImageView = CoreImageView(frame: previewLayerFrameView.frame)
        //coreImageContext = CIContext()

        view.insertSubview(coreImageView!, at: 0)

        videoFilterHandler = VideoBufferHandler()

        videoFilterHandler?.bufferCallBack = handleTheOutputBuffer

        title = "Capture"

        // Do any additional setup after loading the view, typically from a nib.
    }

    func startVideoRecording(withPath path: String) {
        videoCreator = VideoCreator()
        videoCreator?.pixelFormat = kCVPixelFormatType_32ARGB
        videoCreator?.writingQueue = DispatchQueue(label: "mediaInputQueue", attributes: [])
        videoCreator?.videoCreationType = .fromSeparateImages

        videoCreator?.startWrting(atPath: path, size: UIScreen.main.bounds.size, videoFPS: 30)
        isrecordingVideo = true
    }

    func stopVideoRecording(_ handler: @escaping (_ savedUrl: URL) -> ()) {

        isrecordingVideo = false
        guard let videoCreator = videoCreator else {
            return
        }

        //let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        //let documentDirectory = paths.first
        //let dataPath = (documentDirectory)! + "FilterCam \("file").mov"

        //videoCreator.writeImagesAsMovie(cgimages, videoPath: string, videoSize: UIScreen.main.bounds.size, videoFPS: 40)
        if videoCreator.sessionRunning {
            videoCreator.stopWriting({ (url) in
                handler(url as URL)
            })
        }

        cgimages = []
        fileNumber += 1
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        coreImageView?.frame = view.frame

        if let coreImageView = coreImageView {
            view.sendSubview(toBack: coreImageView)
        }

        captureButton.setTitle((viewModel.captureMode == .camera ? "Capture": "Start recording"), for: UIControlState())
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        videoFilterHandler?.startSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        videoFilterHandler?.stopSession()
    }

    @IBAction func flipImageDidTap(_ sender: AnyObject) {
        //TODO: Change the front and back camera
    }

    @IBAction func didTapOnFilter(_ sender: AnyObject) {
        
    }

    @IBAction func settingsDIdTap(_ sender: AnyObject) {
        let settingsVC = storyboard?.instantiateViewController(withIdentifier: "SettingsViewController") as? SettingsViewController
        settingsVC?.viewModel.currentSetting = viewModel.captureMode
        settingsVC?.delegate = self
        present(settingsVC!, animated: true, completion: nil)
    }

    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        coreImageView?.frame = view.frame
    }

    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        coreImageView?.frame = view.frame
    }

    @IBAction func captureTheSession(_ sender: AnyObject) {
        handelCaptureAction()
    }

    fileprivate func handelCaptureAction() {

        switch viewModel.captureMode {
        case .camera:()

        case .video:
            if let videoCreator = videoCreator {
                if !videoCreator.sessionRunning {
                    captureButton.setTitle("Recording....", for: UIControlState())
                } else {
                    captureButton.setTitle("Start recording", for: UIControlState())
                }
            } else {
                captureButton.setTitle("Recording....", for: UIControlState())
            }
            processVideo()
        }
    }

    func processVideo() {

        let outputFilePath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("FilterCam" + "\(Date().timeIntervalSince1970)" + ".mov")

        if let _ = videoCreator {
            if isrecordingVideo{
                self.stopVideoRecording({ (savedUrl) in
                    //self.handleAfterRecordingVideo(savedUrl)
                })
            } else {
                self.startVideoRecording(withPath: outputFilePath.path)
            }
        } else {
            self.startVideoRecording(withPath: outputFilePath.path)
        }
    }

    func handleAfterRecordingVideo(_ saveUrl: URL) {

        Async.main {
            let videoPreviewViewController = self.storyboard?.instantiateViewController(withIdentifier: "VideoPreviewViewController") as! VideoPreviewViewController
            videoPreviewViewController.videoPreviewType = .videoPreview
            videoPreviewViewController.savedTempUrl = saveUrl
            self.navigationController?.pushViewController(videoPreviewViewController, animated: true)
        }
    }

    fileprivate func reloadAllTheInputs() {

    }

    fileprivate func askSaveOrPreview() {
        let alertController = UIAlertController(title: "Video", message: "Video is Recorded", preferredStyle: .actionSheet)

        let saveAction = UIAlertAction(title: "Save", style: .default) { (action) in

        }

        let discardAction = UIAlertAction(title: "Discard", style: .default) { (action) in

        }

        let previewAction = UIAlertAction(title: "Preview", style: .default) { (action) in
            let previewVC = self.storyboard?.instantiateViewController(withIdentifier: "PreviewVideoViewController") as? PreviewVideoViewController

            self.navigationController?.pushViewController(previewVC!, animated: true)
        }

        alertController.addAction(previewAction)
        alertController.addAction(discardAction)
        alertController.addAction(saveAction)

        present(alertController, animated: true, completion: nil)
    }


    fileprivate func handleTheOutputBuffer(_ sampleBuffer: CMSampleBuffer, transform: CGAffineTransform) {
        let ciimage = CIImage(buffer: sampleBuffer).applying(AVCaptureDevicePosition.front.transform)
        let filter = pixellate(5)
        numberOfFrames += 1
        let image = filter(ciimage)
        coreImageView?.image = image
        let cgimage = coreImageView?.coreImageContext.createCGImage(image, from: image.extent)

        debugPrint(numberOfFrames)

        if let cgimage = cgimage {
            if isrecordingVideo {
                print()
                videoCreator?.appendImage(cgimage, inrect: image.extent, completion: { (numberOfFrames) in

                })
            }
        }
    }
}

extension CameraCaptureViewController: SettingsViewControllerDelegate {
    func settingsViewController(_ viewController: SettingsViewController, didDismissWithCaptureMode captureMode: CameraCaptureMode) {
        viewController.dismiss(animated: true) { 

            self.viewModel.captureMode = captureMode
            self.reloadAllTheInputs()
        }
    }
}

extension CGAffineTransform {

    init(rotatingWithAngle angle: CGFloat) {
        let t = CGAffineTransform(rotationAngle: angle)
        self.init(a: t.a, b: t.b, c: t.c, d: t.d, tx: t.tx, ty: t.ty)

    }
    init(scaleX sx: CGFloat, scaleY sy: CGFloat) {
        let t = CGAffineTransform(scaleX: sx, y: sy)
        self.init(a: t.a, b: t.b, c: t.c, d: t.d, tx: t.tx, ty: t.ty)

    }

    func scale(_ sx: CGFloat, sy: CGFloat) -> CGAffineTransform {
        return self.scaledBy(x: sx, y: sy)
    }
    func rotate(_ angle: CGFloat) -> CGAffineTransform {
        return self.rotated(by: angle)
    }
}

extension CIImage {
    convenience init(buffer: CMSampleBuffer) {
        self.init(cvPixelBuffer: CMSampleBufferGetImageBuffer(buffer)!)
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
        case .front:
            return CGAffineTransform(rotatingWithAngle: -CGFloat(M_PI_2)).scale(1, sy: -1)
        case .back:
            return CGAffineTransform(rotatingWithAngle: -CGFloat(M_PI_2))
        default:
            return CGAffineTransform.identity

        }
    }

    var device: AVCaptureDevice? {
        return AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo).filter {
            ($0 as AnyObject).position == self
            }.first as? AVCaptureDevice
    }
}
