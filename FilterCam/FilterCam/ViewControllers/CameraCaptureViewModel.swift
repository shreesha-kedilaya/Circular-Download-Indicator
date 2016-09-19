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
    case video = 0
    case camera
}

class CameraCaptureViewModel {
    var captureMode = CameraCaptureMode.video
    var currentDevicePosition = AVCaptureDevicePosition.back
    var resolutionQuality = AVCaptureSessionPresetPhoto

    func getCameraDevice(_ deviceType: String, devicePosition: AVCaptureDevicePosition) -> AVCaptureDevice {
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

    func getThePermissionForCamera(_ deviceType: String?, completion: @escaping ((_ granted: Bool) -> ())) {
        AVCaptureDevice.requestAccess(forMediaType: deviceType) { (granted) in
            completion(granted)
        }
    }
}
