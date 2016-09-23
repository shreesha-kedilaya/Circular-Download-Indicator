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

    @IBOutlet weak var previewLayerFrameView: UIView!

    fileprivate var currentFilter: Filter?

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

    fileprivate lazy var viewModel = CameraCaptureViewModel()
    private var currentImage: CIImage?

    fileprivate var filterManager: FilterManager?

    override func viewDidLoad() {
        super.viewDidLoad()

        previewLayerFrameView.layoutIfNeeded()
        previewImageView.isHidden = true
        filterManager = FilterManager(frame: previewLayerFrameView.frame, transForm: AVCaptureDevicePosition.back.transform)

        if let coreImageView = filterManager?.coreImageView(withFrame: nil) {
            self.coreImageView = coreImageView
            view.insertSubview(self.coreImageView!, at: 0)
        }

        title = "Capture"

        // Do any additional setup after loading the view, typically from a nib.
    }

    func startVideoRecording(withPath path: String) {

        filterManager?.startWriting(withPath: path, liveVideo: true, videoAsset: nil, size: view.bounds.size)
    }

    func stopVideoRecording(_ handler: @escaping (_ savedUrl: URL) -> ()) {

        filterManager?.stopWriting(completion: { (url) in
            handler(url)
        })
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
        filterManager?.startCameraSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        filterManager?.stopCameraSession()
    }

    @IBAction func flipImageDidTap(_ sender: AnyObject) {
        //TODO: Change the front and back camera
    }

    @IBAction func didTapOnFilter(_ sender: AnyObject) {
        let filterViewController = storyboard?.instantiateViewController(withIdentifier: "FilterViewController") as? FilterViewController
        if let filterManager = filterManager {

            let cgimage = coreImageView?.coreImageContext?.createCGImage(filterManager.currentImage!, from: filterManager.currentImage!.extent)
            let uiimage = UIImage(cgImage: cgimage!)
            filterViewController?.image = uiimage
            filterViewController?.delegate = self
            self.navigationController?.pushViewController(filterViewController!, animated: true)
        }
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
            if let filterManager = filterManager {
                if !filterManager.isRecordingVideo {
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

        if let filterManager = filterManager {
            if filterManager.isRecordingVideo {
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("---------------------------------------------Recieved Memory warning---------------------------------------------")
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

extension CameraCaptureViewController: FilterViewControllerDelegate {
    func filterViewController(viewController: FilterViewController, didSelectFilter filter: @escaping (CIImage) -> CIImage?) {
        _ = navigationController?.popViewController(animated: true)
        currentFilter = filter
        filterManager?.applyFilter(filter: filter)
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
