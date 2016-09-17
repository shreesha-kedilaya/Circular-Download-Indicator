//
//  VideoFilterHandler.swift
//  FilterCam
//
//  Created by Shreesha on 17/09/16.
//  Copyright © 2016 YML. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

typealias BufferCallBack = (CMSampleBuffer, CGAffineTransform) -> ()

class VideoBufferHandler: NSObject, CaptureDelagateProtocol {

    var currentDevicePosition = AVCaptureDevicePosition.Back
    var resolutionQuality = AVCaptureSessionPresetPhoto

    private lazy var cameraCaptureSession: AVCaptureSession = {
        let session = AVCaptureSession()

        if session.canSetSessionPreset(self.resolutionQuality) {
            session.sessionPreset = self.resolutionQuality
        } else {
            print("Failed to set the preset value")
        }
        return session
    }()

    private lazy var videoCaptureOutput = AVCaptureVideoDataOutput()
    private var inputDevice: AVCaptureDevice?
    private var captureCameraInput: AVCaptureDeviceInput?
    private var captureDelegate: CaptureBufferDelegate?
    private lazy var cameraStillImageOutput = AVCaptureStillImageOutput()

    var outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
    var bufferCallBack: BufferCallBack?
    var videoTransform = CGAffineTransformIdentity
    var videoCreator: VideoCreator?
    var isrecordingVideo = false

    override init() {
        super.init()
        addInputsToCameraSession()
        setTheCameraStillImageOutputs()
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

    private func addInputsToCameraSession() {
        cameraCaptureSession.addObserver(self, forKeyPath: AVCaptureSessionRuntimeErrorNotification, options: NSKeyValueObservingOptions.New, context: nil)

        let devices = AVCaptureDevice.devices()

        for device in devices {
            print((device as! AVCaptureDevice).localizedName)
        }

        inputDevice = getCameraDevice(AVMediaTypeVideo, devicePosition: currentDevicePosition)
        captureCameraInput = try? AVCaptureDeviceInput(device: inputDevice)

        if cameraCaptureSession.canAddInput(captureCameraInput) {
            cameraCaptureSession.addInput(captureCameraInput)
        }
        
        setTheVideoOutput()
    }

    private func setTheCameraStillImageOutputs() {
        cameraStillImageOutput.outputSettings = outputSettings

        if cameraCaptureSession.canAddOutput(cameraStillImageOutput) {
            cameraCaptureSession.addOutput(cameraStillImageOutput)
        }
    }

    private func setTheVideoOutput() {
        videoCaptureOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(unsignedInt: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]

        captureDelegate = CaptureBufferDelegate(delegate: self)

        videoCaptureOutput.setSampleBufferDelegate(captureDelegate, queue: dispatch_get_main_queue())
        cameraCaptureSession.addOutput(videoCaptureOutput)
    }

    private func getCameraDevice(deviceType: String, devicePosition: AVCaptureDevicePosition) -> AVCaptureDevice {
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

    func startSession() {
        let permissionService = PermissionType.Camera.permissionService
        permissionService.requestPermission { (status) in
            switch status {
            case .Authorized:
                self.cameraCaptureSession.startRunning()
            default: ()
            }
        }
    }

    func stopSession() {
        cameraCaptureSession.stopRunning()
        cameraCaptureSession.removeObserver(self, forKeyPath: AVCaptureSessionRuntimeErrorNotification)
    }

    func changeTheDeviceType() {

        cameraCaptureSession.beginConfiguration()
        cameraCaptureSession.removeInput(captureCameraInput)
        switch currentDevicePosition {
        case .Front:
            currentDevicePosition = .Back
            configureMediaInput(currentDevicePosition)
        case .Back:
            currentDevicePosition = .Front
            configureMediaInput(currentDevicePosition)
        default: ()
        }
        cameraCaptureSession.commitConfiguration()
    }

    func captureImage(withFilter filter: Filter?, callBack: (UIImage?) -> ()) {
        if let videoConnection = cameraStillImageOutput.connectionWithMediaType(AVMediaTypeVideo) {
            cameraStillImageOutput.captureStillImageAsynchronouslyFromConnection(videoConnection) {
                (imageDataSampleBuffer, error) -> Void in
                let image = UIImage(data: AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer))
                let ciimage = image?.CIImage

                if let ciimage = ciimage {

                    if let filter = filter {

                        let filteredImage = filter(ciimage)
                        let uiimage = UIImage(CIImage: filteredImage)
                        callBack(uiimage)

                    } else {
                        callBack(image)
                    }
                } else {
                    callBack(nil)
                }
            }
        }
    }

    func startVideoRecording(withPath path: String) {
        videoCreator = VideoCreator()
        videoCreator?.pixelFormat = kCVPixelFormatType_32ARGB
        videoCreator?.writingQueue = dispatch_get_main_queue()

        videoCreator?.startWrting(atPath: path, size: UIScreen.mainScreen().bounds.size, videoFPS: 40)
        isrecordingVideo = true
    }

    func stopVideoRecording(handler: (savedUrl: NSURL) -> ()) {

        isrecordingVideo = false
        guard let videoCreator = videoCreator else {
            return
        }

        if videoCreator.sessionRunning {
            videoCreator.stopWriting { (url: NSURL) -> Void in
                handler(savedUrl: url)
            }
        }
    }

    private func configureMediaInput(devicePosition: AVCaptureDevicePosition) {

        let videoDevice = getCameraDevice(AVMediaTypeVideo, devicePosition: devicePosition)

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

    func didOutput(sampleBuffer: CMSampleBuffer) {
        if let bufferCallBack = bufferCallBack {
            bufferCallBack(sampleBuffer, videoTransform)
        }
    }
}

private class CaptureBufferDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let delegate: CaptureDelagateProtocol?

    init(delegate: CaptureDelagateProtocol) {
        self.delegate = delegate
    }

    @objc func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        delegate?.didOutput(sampleBuffer)
    }
}

protocol CaptureDelagateProtocol{
    func didOutput(sampleBuffer: CMSampleBuffer)
}