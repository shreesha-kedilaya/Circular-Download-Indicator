//
//  CameraCaptureViewModel.swift
//  FilterCam
//
//  Created by Shreesha on 31/08/16.
//  Copyright © 2016 YML. All rights reserved.
//

import Foundation
import AVFoundation
import Photos
import CoreGraphics

enum CameraCaptureMode: Int {
    case Video = 0
    case Camera
}

class CameraCaptureViewModel {
    var captureMode = CameraCaptureMode.Video
    var currentDevicePosition = AVCaptureDevicePosition.Back
    var resolutionQuality = AVCaptureSessionPresetPhoto

    func getCameraDevice(deviceType: String, devicePosition: AVCaptureDevicePosition) -> AVCaptureDevice {
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

    func getThePermissionForCamera(deviceType: String?, completion: ((granted: Bool) -> ())) {
        AVCaptureDevice.requestAccessForMediaType(deviceType) { (granted) in
            completion(granted: granted)
        }
    }
}