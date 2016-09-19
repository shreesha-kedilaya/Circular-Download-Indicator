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

enum CreationType {
    case FromVideo
    case FromSeparateImages
}

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
    var videoCreationType = CreationType.FromSeparateImages
    private var coreImageContext: CIContext?

    private (set) var sessionRunning = false
    private (set) var numberOfFrames = 0

    func applyFilterTo(video: AVAsset, videoFPS: Int32, size: CGSize, filter: Filter, savingUrl: String, completion: (savedUrl: NSURL) -> ()) {

        startWrting(atPath: savingUrl, size: size, videoFPS: videoFPS)

        let duration = video.duration
        let totalCount = Int32(CMTimeGetSeconds(duration)) * videoFPS
        let imageGenerator = AVAssetImageGenerator(asset: video)
        var times = [NSValue]()

        for frameCount in 1...totalCount {

            let time = NSNumber(int: frameCount)
            times.append(time)
        }

        var discardedImages = 0
        imageGenerator.generateCGImagesAsynchronouslyForTimes(times) { (time, image, secondTime, result, error) in

            if let error = error {
                print("Error in getting the image at time \(time)\n\n Error: \(error)")
                discardedImages += 1
            } else {

                switch result {
                case .Cancelled:
                    discardedImages += 1
                case .Succeeded:
                    if let image = image {
                        let ciimage = CIImage(CGImage: image)
                        let filteredImage = filter(ciimage)
                        let cgimage = self.coreImageContext?.createCGImage(filteredImage, fromRect: filteredImage.extent)
                        if let cgimage = cgimage {
                            self.appendImage(cgimage, completion: { (numberOfFrames) in
                            })
                        }
                    }
                case .Failed:
                    discardedImages += 1
                }
            }

            if self.numberOfFrames <= times.count && self.numberOfFrames >= times.count - discardedImages {
                self.stopWriting({ (savedUrl) in
                    completion(savedUrl: savedUrl)
                })
            }
        }
    }

    func startWrting(atPath path: String, size: CGSize, videoFPS: Int32) {
        self.size = size
        writingPath = path
        assetWriter = createAssetWriter(writingPath ?? "", size: size ?? CGSizeZero)
        self.videoFPS = videoFPS
        frameDuration = CMTimeMake(1, videoFPS)

        coreImageContext = CIContext(options: nil)

        let sourceBufferAttributes : [String : AnyObject] = [
            kCVPixelBufferPixelFormatTypeKey as String : Int(pixelFormat ?? kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String : size.width,
            kCVPixelBufferHeightKey as String : size.height,
            ]
        if let assetWriterVideoInput = assetWriterVideoInput {
            pixelBufferAdopter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterVideoInput, sourcePixelBufferAttributes: sourceBufferAttributes)
        }

        assetWriter?.startWriting()
        assetWriter?.startSessionAtSourceTime(kCMTimeZero)

        assetWriterVideoInput?.requestMediaDataWhenReadyOnQueue(writingQueue ?? dispatch_get_main_queue(), usingBlock: {

        })

        sessionRunning = true
    }

    //MARK: This method to be used when there is only 'CMSampleBuffer' to append with.
    //Avoid this method as far as possible.
    func appendSampleBuffer(sampleBuffer: CMSampleBuffer, transform: CGAffineTransform, rect: CGRect, completion: (numberOfFrames: Int) -> ()) {
        let ciimage = CIImage(buffer: sampleBuffer).imageByApplyingTransform(transform)

        let cgimage = coreImageContext?.createCGImage(ciimage, fromRect: rect)

        if let cgimage = cgimage {
            appendImage(cgimage) { (numberOfFrames) in
                completion(numberOfFrames: numberOfFrames)
            }
        }
    }

    func writeImagesAsMovie(allImages: [CGImage], videoPath: String, videoSize: CGSize, videoFPS: Int32) {
        // Create AVAssetWriter to write video
        guard let assetWriter = createAssetWriter(videoPath, size: videoSize) else {
            print("Error converting images to video: AVAssetWriter not created")
            return
        }

        // If here, AVAssetWriter exists so create AVAssetWriterInputPixelBufferAdaptor
        let writerInput = assetWriter.inputs.filter{ $0.mediaType == AVMediaTypeVideo }.first!
        let sourceBufferAttributes : [String : AnyObject] = [
            kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String : videoSize.width,
            kCVPixelBufferHeightKey as String : videoSize.height,
            ]
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: sourceBufferAttributes)

        // Start writing session
        assetWriter.startWriting()
        assetWriter.startSessionAtSourceTime(kCMTimeZero)

        switch assetWriter.status {
        case .Writing:
            print("Asset writer is writing")
        default:
            print("Error converting images to video: assetWriter is not writing:- \(assetWriter.status)")
        }

        if (pixelBufferAdaptor.pixelBufferPool == nil) {
            print("Error converting images to video: pixelBufferPool nil after starting session")
            return
        }

        // -- Create queue for <requestMediaDataWhenReadyOnQueue>
        let mediaQueue = dispatch_queue_create("mediaInputQueue", DISPATCH_QUEUE_SERIAL)

        // -- Set video parameters
        let frameDuration = CMTimeMake(1, videoFPS)
        var frameCount = 0

        // -- Add images to video
        let numImages = allImages.count
        writerInput.requestMediaDataWhenReadyOnQueue(mediaQueue, usingBlock: { () -> Void in
            // Append unadded images to video but only while input ready
            while (writerInput.readyForMoreMediaData && frameCount < numImages) {
                let lastFrameTime = CMTimeMake(Int64(frameCount), videoFPS)
                let presentationTime = frameCount == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, frameDuration)

                if !self.appendPixelBufferForImageAtURL(allImages[frameCount], pixelBufferAdaptor: pixelBufferAdaptor, presentationTime: presentationTime) {
                    print("Error converting images to video: AVAssetWriterInputPixelBufferAdapter failed to append pixel buffer")
                    return
                }

                frameCount += 1
            }

            // No more images to add? End video.
            if (frameCount >= numImages) {
                self.sessionRunning = false
                writerInput.markAsFinished()
                assetWriter.finishWritingWithCompletionHandler {
                    if (assetWriter.error != nil) {
                        print("Error converting images to video: \(assetWriter.error)")
                    } else {
                        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
                        let documentDirectory = paths.first
                        let dataPath = documentDirectory?.stringByAppendingString("FilterCam \(12).mov")
                        self.saveVideoToLibrary(NSURL(fileURLWithPath: dataPath!))
                        print("Converted images to movie @ \(videoPath)")
                    }
                }
            }
        })
    }

    func saveVideoToLibrary(videoURL: NSURL) {
        PHPhotoLibrary.requestAuthorization { status in
            // Return if unauthorized
            guard status == .Authorized else {
                print("Error saving video: unauthorized access")
                return
            }

            // If here, save video to library
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(videoURL)
            }) { success, error in
                if !success {
                    print("Error saving video: \(error)")
                }
            }
        }
    }

    func appendImage(image: CGImage, completion: (numberOfFrames: Int) -> ()) {
        guard let assetWriterVideoInput = assetWriterVideoInput else {
            return
        }

        if assetWriterVideoInput.readyForMoreMediaData {
            let lastFrameTime = CMTimeMake(Int64(self.numberOfFrames), self.videoFPS)
            let presentationTime = self.numberOfFrames == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, self.frameDuration)

            if !self.appendPixelBufferForImageAtURL(image, pixelBufferAdaptor: self.pixelBufferAdopter!, presentationTime: presentationTime) {
                print("Error converting images to video: AVAssetWriterInputPixelBufferAdapter failed to append pixel buffer")
                return
            }
            self.numberOfFrames += 1
            completion(numberOfFrames: self.numberOfFrames)
        }
    }

    func stopWriting(completion: (savedUrl: NSURL) -> Void) {
        assetWriterVideoInput?.markAsFinished()
        assetWriter?.finishWritingWithCompletionHandler {
            completion(savedUrl: NSURL(string: self.writingPath!)!)
        }
        sessionRunning = false
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
            if let pixelBufferPool = pixelBufferAdaptor.pixelBufferPool {
                let pixelBufferPointer = UnsafeMutablePointer<CVPixelBuffer?>.alloc(1)
                let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(
                    kCFAllocatorDefault,
                    pixelBufferPool,
                    pixelBufferPointer
                )

                if let pixelBuffer = pixelBufferPointer.memory where status == 0 {
//                    fillPixelBufferFromImage(image, pixelBuffer: pixelBuffer)
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
            width * 8,
            rgbColorSpace,
            CGImageAlphaInfo.PremultipliedFirst.rawValue
        )

        CGContextDrawImage(context, CGRectMake(0, 0, CGFloat(width), CGFloat(height)), image)
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0)
    }
}