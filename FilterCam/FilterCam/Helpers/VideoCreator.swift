//
//  VideoCreator.swift
//  FilterCam
//
//  Created by Shreesha on 16/09/16.
//  Copyright © 2016 YML. All rights reserved.
//

import Foundation
import CoreImage
import AVFoundation
import UIKit
import Photos

class VideoCreator: NSObject {

    private var assetWriter: AVAssetWriter?
    private var assetWriterVideoInput: AVAssetWriterInput?
    private var pixelBufferAdopter: AVAssetWriterInputPixelBufferAdaptor?

    private var writingPath: String?
    private var videoFPS: Int32 = 25
    private var frameDuration: CMTime!

    var pixelFormat: OSType?
    var size: CGSize?
    var writingQueue: dispatch_queue_t?

    private (set) var sessionRunning = false
    private (set) var numberOfFrames = 0

    func startWrting(atPath path: String, size: CGSize, videoFPS: Int32) {
        self.size = size
        writingPath = path
        assetWriter = createAssetWriter(writingPath ?? "", size: size ?? CGSizeZero)
        self.videoFPS = videoFPS
        frameDuration = CMTimeMake(1, videoFPS)

        assetWriter?.startWriting()
        assetWriter?.startSessionAtSourceTime(kCMTimeZero)

        let sourceBufferAttributes : [String : AnyObject] = [
            kCVPixelBufferPixelFormatTypeKey as String : Int(pixelFormat ?? kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String : size.width,
            kCVPixelBufferHeightKey as String : size.height,
            ]
        if let assetWriterVideoInput = assetWriterVideoInput {
            pixelBufferAdopter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterVideoInput, sourcePixelBufferAttributes: sourceBufferAttributes)
        }

        sessionRunning = true
    }

    func appendImage(image: CGImage) {
        guard let assetWriterVideoInput = assetWriterVideoInput else {
            return
        }
        assetWriterVideoInput.requestMediaDataWhenReadyOnQueue(writingQueue ?? dispatch_queue_create("writingQueue", nil), usingBlock: {

            if assetWriterVideoInput.readyForMoreMediaData {
                let lastFrameTime = CMTimeMake(Int64(self.numberOfFrames), self.videoFPS)
                let presentationTime = self.numberOfFrames == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, self.frameDuration)

                if !self.appendPixelBufferForImageAtURL(image, pixelBufferAdaptor: self.pixelBufferAdopter!, presentationTime: presentationTime) {
                    print("Error converting images to video: AVAssetWriterInputPixelBufferAdapter failed to append pixel buffer")
                    return
                }
                self.numberOfFrames += 1
            }
        })
    }

    func stopWriting(completion: (savedUrl: NSURL) -> Void) {
        assetWriterVideoInput?.markAsFinished()
        assetWriter?.finishWritingWithCompletionHandler {
            completion(savedUrl: NSURL(string: self.writingPath!)!)
        }
    }

    func createAssetWriter(path: String, size: CGSize) -> AVAssetWriter? {
        let pathURL = NSURL(fileURLWithPath: path)

        do {

            let newWriter = try AVAssetWriter(URL: pathURL, fileType: AVFileTypeMPEG4)

            let videoSettings: [String : AnyObject] = [
                AVVideoCodecKey  : AVVideoCodecH264,
                AVVideoWidthKey  : size.width,
                AVVideoHeightKey : size.height,
                ]

            assetWriterVideoInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoSettings)
            newWriter.addInput(assetWriterVideoInput!)

            print("Created asset writer for \(size.width)x\(size.height) video")
            return newWriter
        } catch {
            print("Error creating asset writer: \(error)")
            return nil
        }
    }

    func appendPixelBufferForImageAtURL(image: CGImage, pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor, presentationTime: CMTime) -> Bool {
        var appendSucceeded = false

        autoreleasepool {
            if  let pixelBufferPool = pixelBufferAdaptor.pixelBufferPool {
                let pixelBufferPointer = UnsafeMutablePointer<CVPixelBuffer?>.alloc(1)
                let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(
                    kCFAllocatorDefault,
                    pixelBufferPool,
                    pixelBufferPointer
                )

                if let pixelBuffer = pixelBufferPointer.memory where status == 0 {
                    fillPixelBufferFromImage(image, pixelBuffer: pixelBuffer)
                    appendSucceeded = pixelBufferAdaptor.appendPixelBuffer(pixelBuffer, withPresentationTime: presentationTime)
                    pixelBufferPointer.destroy()
                } else {
                    print("Error: Failed to allocate pixel buffer from pool")
                }

                pixelBufferPointer.dealloc(1)
            }
        }

        return appendSucceeded
    }


    func fillPixelBufferFromImage(image: CGImage, pixelBuffer: CVPixelBufferRef) {
        CVPixelBufferLockBaseAddress(pixelBuffer, 0)

        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        let height = CGImageGetHeight(image)
        let width = CGImageGetWidth(image)

        let context = CGBitmapContextCreate(
            pixelData,
            Int(width),
            Int(height),
            8,
            CVPixelBufferGetBytesPerRow(pixelBuffer),
            rgbColorSpace,
            CGImageAlphaInfo.PremultipliedFirst.rawValue
        )

        CGContextDrawImage(context, CGRectMake(0, 0, CGFloat(width), CGFloat(height)), image)
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0)
    }
}