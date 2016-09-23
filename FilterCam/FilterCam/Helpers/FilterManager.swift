//
//  FilterManager.swift
//  FilterCam
//
//  Created by Shreesha on 22/09/16.
//  Copyright © 2016 YML. All rights reserved.
//

import Foundation
import CoreImage
import AVFoundation
import UIKit
import Photos

class FilterManager {

    private var videoCreator: VideoCreator?
    private var videoBufferHandler: VideoBufferHandler?
    private var coreImageView: CoreImageView?
    private var coreImageContext: CIContext?
    private var eaglContext: EAGLContext?

    fileprivate (set) var currentImage: CIImage?
    fileprivate (set) var numberOfFrames = 0
    fileprivate (set) var isRecordingVideo = false
    fileprivate (set) var currentFilter: Filter?

    var transForm = CGAffineTransform.identity {
        didSet {
            videoBufferHandler?.videoTransform = transForm
        }
    }

    func startCameraSession() {
        videoBufferHandler?.startSession()
    }

    func stopCameraSession() {
        videoBufferHandler?.stopSession()
    }

    func removeObservers(){
        videoBufferHandler?.removeObservers()
    }

    init(frame: CGRect, transForm: CGAffineTransform) {
        videoBufferHandler = VideoBufferHandler()
        videoBufferHandler?.bufferCallBack = handleTheOutputBuffer
        self.transForm = transForm
        videoBufferHandler?.videoTransform = self.transForm

        coreImageView = CoreImageView(frame: frame)
        eaglContext = coreImageView?.eaglContext
        coreImageContext = coreImageView?.coreImageContext
    }

    func startWriting(withPath path: String, liveVideo: Bool, videoAsset: AVAsset?, size: CGSize) {
        if let videoFilterHandler = videoBufferHandler {
            videoCreator = VideoCreator(FilterGenerator.hueAdjust(angleInRadians: 0.5), bufferHandler: videoFilterHandler)
            videoCreator?.pixelFormat = kCVPixelFormatType_32ARGB
            videoCreator?.writingQueue = DispatchQueue(label: "mediaInputQueue", attributes: [])
            videoCreator?.videoCreationType = .fromSeparateImages

            videoCreator?.startWrting(atPath: path, size: UIScreen.main.bounds.size, videoFPS: 20)
            isRecordingVideo = true
        }
    }

    func stopWriting(completion: @escaping (URL) -> Void) {

        if isRecordingVideo {
            videoCreator?.stopWriting({ (url) in
                completion(url)
            })
            isRecordingVideo = false
        }
    }


    func applyFilter(filter: @escaping Filter) {
        currentFilter = filter
    }

    func abortWriting() {
        videoCreator?.abortWriting()
    }

    func coreImageView(withFrame frame: CGRect? = nil) -> CoreImageView? {
        guard let frame = frame else {
            return coreImageView
        }
        coreImageView?.frame = frame
        return coreImageView
    }

    private func handleTheOutputBuffer(_ sampleBuffer: CMSampleBuffer, transform: CGAffineTransform) {
        let ciimage = CIImage(buffer: sampleBuffer).applying(AVCaptureDevicePosition.back.transform)
        currentImage = ciimage

        numberOfFrames += 1
        var image: CIImage? = ciimage
        if let filter = currentFilter {
            image = filter(ciimage)
        }

        coreImageView?.bindDrawable()
        coreImageView?.image = image

        if isRecordingVideo {
            let cgimage = coreImageView?.cgimage
            videoCreator?.appendImage(cgimage!, inrect: coreImageView!.image!.extent, completion: { (numberOfFrames) in

            })
        }
    }
}
