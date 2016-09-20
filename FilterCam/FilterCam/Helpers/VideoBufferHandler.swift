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

    var currentDevicePosition = AVCaptureDevicePosition.back
    var resolutionQuality = AVCaptureSessionPresetPhoto

    fileprivate lazy var cameraCaptureSession: AVCaptureSession = {
        let session = AVCaptureSession()

        if session.canSetSessionPreset(self.resolutionQuality) {
            session.sessionPreset = self.resolutionQuality
        } else {
            print("Failed to set the preset value")
        }
        return session
    }()

    fileprivate lazy var videoCaptureOutput = AVCaptureVideoDataOutput()
    fileprivate var inputDevice: AVCaptureDevice?
    fileprivate var captureCameraInput: AVCaptureDeviceInput?
    fileprivate var captureDelegate: CaptureBufferDelegate?
    fileprivate lazy var cameraStillImageOutput = AVCaptureStillImageOutput()

    var outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
    var bufferCallBack: BufferCallBack?
    var videoTransform = CGAffineTransform.identity
    var videoCreator: VideoCreator?
    var isrecordingVideo = false
    var numberOfFrames = 0

    override init() {
        super.init()
        addInputsToCameraSession()
        setTheCameraStillImageOutputs()
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath else {
            return
        }
        if NSNotification.Name(keyPath) == NSNotification.Name.AVCaptureSessionRuntimeError {
            let cameraSession = object as? AVCaptureSession

            guard let captureSession = cameraSession else {
                return
            }

            if captureSession.isRunning {
                print("captureSession running")
            } else if captureSession.isInterrupted {
                print("captureSession interupted")
            }
        }
    }

    fileprivate func addInputsToCameraSession() {

        cameraCaptureSession.addObserver(self, forKeyPath: NSNotification.Name.AVCaptureSessionRuntimeError.rawValue, options: NSKeyValueObservingOptions.new, context: nil)

        let devices = AVCaptureDevice.devices()

        for device in devices! {
            print((device as! AVCaptureDevice).localizedName)
        }

        inputDevice = getCameraDevice(AVMediaTypeVideo, devicePosition: currentDevicePosition)
        captureCameraInput = try? AVCaptureDeviceInput(device: inputDevice)

        if cameraCaptureSession.canAddInput(captureCameraInput) {
            cameraCaptureSession.addInput(captureCameraInput)
        }
        
        setTheVideoOutput()
    }

    fileprivate func setTheCameraStillImageOutputs() {
        cameraStillImageOutput.outputSettings = outputSettings

        if cameraCaptureSession.canAddOutput(cameraStillImageOutput) {
            cameraCaptureSession.addOutput(cameraStillImageOutput)
        }
    }

    fileprivate func setTheVideoOutput() {
        videoCaptureOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange as UInt32)]

        captureDelegate = CaptureBufferDelegate(delegate: self)

        videoCaptureOutput.setSampleBufferDelegate(captureDelegate, queue: DispatchQueue.main)
        cameraCaptureSession.addOutput(videoCaptureOutput)
    }

    fileprivate func getCameraDevice(_ deviceType: String, devicePosition: AVCaptureDevicePosition) -> AVCaptureDevice {
        var device = AVCaptureDevice.defaultDevice(withMediaType: deviceType)
        let devices : NSArray = AVCaptureDevice.devices(withMediaType: deviceType) as NSArray

        for dev in devices {
            if (dev as AnyObject).position == devicePosition {
                device = dev as? AVCaptureDevice
                break;
            }
        }

        return device!
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
    }

    func removeObservers() {
        cameraCaptureSession.removeObserver(self, forKeyPath: NSNotification.Name.AVCaptureSessionRuntimeError.rawValue)
    }

    func changeTheDeviceType() {

        cameraCaptureSession.beginConfiguration()
        cameraCaptureSession.removeInput(captureCameraInput)
        switch currentDevicePosition {
        case .front:
            currentDevicePosition = .back
            configureMediaInput(currentDevicePosition)
        case .back:
            currentDevicePosition = .front
            configureMediaInput(currentDevicePosition)
        default: ()
        }
        cameraCaptureSession.commitConfiguration()
    }

    func captureImage(withFilter filter: Filter?, callBack: @escaping (UIImage?) -> ()) {
        if let videoConnection = cameraStillImageOutput.connection(withMediaType: AVMediaTypeVideo) {
            cameraStillImageOutput.captureStillImageAsynchronously(from: videoConnection) {
                (imageDataSampleBuffer, error) -> Void in
                let image = UIImage(data: AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer))
                let ciimage = image?.ciImage

                if let ciimage = ciimage {

                    if let filter = filter {

                        let filteredImage = filter(ciimage)
                        let uiimage = UIImage(ciImage: filteredImage)
                        callBack(uiimage)

                    } else {
                        callBack(image)
                    }
                } else {
                    callBack(image)
                }
            }
        }
    }

    fileprivate func configureMediaInput(_ devicePosition: AVCaptureDevicePosition) {

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

    func didOutput(_ sampleBuffer: CMSampleBuffer) {
        numberOfFrames += 1
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

    @objc func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        delegate?.didOutput(sampleBuffer)
    }
}

protocol CaptureDelagateProtocol{
    func didOutput(_ sampleBuffer: CMSampleBuffer)
}
