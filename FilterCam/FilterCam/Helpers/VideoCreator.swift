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
    case fromVideo
    case fromSeparateImages
}

class VideoCreator: NSObject {

    fileprivate var assetWriter: AVAssetWriter?
    fileprivate var assetWriterVideoInput: AVAssetWriterInput?
    fileprivate var pixelBufferAdopter: AVAssetWriterInputPixelBufferAdaptor?

    fileprivate var writingPath: String?
    fileprivate var videoFPS: Int32 = 25
    fileprivate var frameDuration: CMTime!

    var pixelFormat: OSType?
    var size: CGSize?
    var writingQueue: DispatchQueue?
    var videoCreationType = CreationType.fromSeparateImages
    fileprivate var coreImageContext: CIContext?

    fileprivate (set) var sessionRunning = false
    fileprivate (set) var numberOfFrames = 0

    func applyFilterTo(_ video: AVAsset, inrect rect: CGRect,videoFPS: Int32, size: CGSize, filter: @escaping Filter, savingUrl: String, completion: @escaping (_ savedUrl: URL) -> ()) {

        startWrting(atPath: savingUrl, size: size, videoFPS: videoFPS)

        let duration = video.duration
        let totalCount = Int32(CMTimeGetSeconds(duration)) * videoFPS
        let imageGenerator = AVAssetImageGenerator(asset: video)
        var times = [NSValue]()

        for frameCount in 1...totalCount {

            let time = NSNumber(value: frameCount as Int32)
            times.append(time)
        }

        var discardedImages = 0
        imageGenerator.generateCGImagesAsynchronously(forTimes: times) { (time, image, secondTime, result, error) in

            if let error = error {
                debugPrint("Error in getting the image at time \(time)\n\n Error: \(error)")
                discardedImages += 1
            } else {

                switch result {
                case .cancelled:
                    discardedImages += 1
                case .succeeded:
                    if let image = image {
                        let ciimage = CIImage(cgImage: image)
                        let filteredImage = filter(ciimage)
                        let cgimage = self.coreImageContext?.createCGImage(filteredImage, from: filteredImage.extent)
                        if let cgimage = cgimage {
                            self.appendImage(cgimage, inrect: rect, completion: { (numberOfFrames) in
                            })
                        }
                    }
                case .failed:
                    discardedImages += 1
                }
            }

            if self.numberOfFrames <= times.count && self.numberOfFrames >= times.count - discardedImages {
                self.stopWriting({ (savedUrl) in
                    completion(savedUrl)
                })
            }
        }
    }

    func startWrting(atPath path: String, size: CGSize, videoFPS: Int32) {
        self.size = size
        writingPath = path
        assetWriter = createAssetWriter(writingPath ?? "", size: size)
        self.videoFPS = videoFPS
        frameDuration = CMTimeMake(1, videoFPS)

        coreImageContext = CIContext(options: nil)

        let sourceBufferAttributes : [String : AnyObject] = [
            kCVPixelBufferPixelFormatTypeKey as String : Int(pixelFormat ?? kCVPixelFormatType_32ARGB) as AnyObject,
            kCVPixelBufferWidthKey as String : size.width as AnyObject,
            kCVPixelBufferHeightKey as String : size.height as AnyObject,
            ]
        if let assetWriterVideoInput = assetWriterVideoInput {
            pixelBufferAdopter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterVideoInput, sourcePixelBufferAttributes: sourceBufferAttributes)
        }

        let success = assetWriter?.startWriting()

        assetWriter?.startSession(atSourceTime: kCMTimeZero)

        if let success = success, !success {
            assetWriter?.cancelWriting()
        }

        debugPrint("started to write to path \(path)")

        sessionRunning = true
    }

    //MARK: This method to be used when there is only 'CMSampleBuffer' to append with.
    //Avoid this method as far as possible.
    func appendSampleBuffer(_ sampleBuffer: CMSampleBuffer, transform: CGAffineTransform, rect: CGRect, completion: @escaping (_ numberOfFrames: Int) -> ()) {
        //let ciimage = CIImage(buffer: sampleBuffer).applying(transform)

        //let cgimage = coreImageContext?.createCGImage(ciimage, from: rect)

        /*if let cgimage = cgimage {
            /*appendImage(cgimage) { (numberOfFrames) in
                completion(numberOfFrames)
            }*/
        }*/
    }


    func saveVideoToLibrary(_ videoURL: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            // Return if unauthorized
            guard status == .authorized else {
                debugPrint("Error saving video: unauthorized access")
                return
            }

            // If here, save video to library
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            }) { success, error in
                if !success {
                    debugPrint("Error saving video: \(error)")
                }
            }
        }
    }

    func appendImage(_ image: CGImage, inrect rect: CGRect, completion: @escaping (_ numberOfFrames: Int) -> ()) {
        guard let assetWriterVideoInput = assetWriterVideoInput else {
            return
        }

        if assetWriterVideoInput.isReadyForMoreMediaData {
            let lastFrameTime = CMTimeMake(Int64(self.numberOfFrames), self.videoFPS)
            let presentationTime = self.numberOfFrames == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, self.frameDuration)

            assetWriter?.startSession(atSourceTime: presentationTime)

            Async.global(closer: {

                if !self.appendPixelBufferForImageAtURL(image, pixelBufferAdaptor: self.pixelBufferAdopter!, presentationTime: presentationTime, inrect: rect) {
                    debugPrint("Error converting images to video: AVAssetWriterInputPixelBufferAdapter failed to append pixel buffer")
                    return
                }
                debugPrint("appended the pixel buffer at time \(presentationTime)")
                self.numberOfFrames += 1
                completion(self.numberOfFrames)

            })
        }
    }

    func stopWriting(_ completion: @escaping (_ savedUrl: URL) -> Void) {
        assetWriterVideoInput?.markAsFinished()
        assetWriter?.finishWriting {
            self.saveVideoToLibrary(URL(string: self.writingPath!)!)
            completion(URL(string: self.writingPath!)!)
        }
        debugPrint("stopped writing at path \(self.writingPath)")
        sessionRunning = false
    }

    func createAssetWriter(_ path: String, size: CGSize) -> AVAssetWriter? {
        let pathURL = URL(fileURLWithPath: path)

        do {

            let newWriter = try AVAssetWriter(outputURL: pathURL, fileType: AVFileTypeMPEG4)

            let videoSettings: [String : AnyObject] = [
                AVVideoCodecKey  : AVVideoCodecH264 as AnyObject,
                AVVideoWidthKey  : size.width as AnyObject,
                AVVideoHeightKey : size.height as AnyObject,
                ]

            assetWriterVideoInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoSettings)

            if newWriter.canAdd(assetWriterVideoInput!) {
                newWriter.add(assetWriterVideoInput!)
            }
            assetWriterVideoInput?.expectsMediaDataInRealTime = false

            debugPrint("Created asset writer for \(size.width)x\(size.height) video")
            return newWriter
        } catch {
            debugPrint("Error creating asset writer: \(error)")
            return nil
        }
    }

    func appendPixelBufferForImageAtURL(_ image: CGImage, pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor, presentationTime: CMTime, inrect rect: CGRect) -> Bool {
        var appendSucceeded = false

        //WARNING: Have to check why this is crashing
        /*autoreleasepool {
            if let pixelBufferPool = pixelBufferAdaptor.pixelBufferPool {
                let pixelBufferPointer = UnsafeMutablePointer<CVPixelBuffer?>.allocate(capacity: 1)
                let status: CVReturn = CVPixelBufferPoolCreatePixelBuffer(
                    kCFAllocatorDefault,
                    pixelBufferPool,
                    pixelBufferPointer
                )

                if let pixelBuffer = pixelBufferPointer.pointee , status == 0 {
                    //fillPixelBufferFromImage(image, pixelBuffer: pixelBuffer, inrect: rect)

                    let status = CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
                    debugPrint(status)
                    let pxdata = CVPixelBufferGetBaseAddress(pixelBuffer)

                    let height = image.height
                    let width = image.width

                    let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
                    let context = CGContext(data: pxdata, width: Int(width),
                                            height: Int(height), bitsPerComponent: 8, bytesPerRow: image.bytesPerRow, space: rgbColorSpace,
                                            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)

                    let uiimage = UIImage(cgImage: image)
                    context?.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
                    
                    let retValue = CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
                    
                    debugPrint(retValue)
                    debugPrint("successfully created the pixel buffer")
                    appendSucceeded = pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
                    pixelBufferPointer.deinitialize()
                } else {
                    debugPrint("Error: Failed to allocate pixel buffer from pool")
                }

                pixelBufferPointer.deallocate(capacity: 1)
            }
        }
        debugPrint(appendSucceeded)
        return appendSucceeded*/

        if let pixelBuffer = pixelBufferFromImage(image) {
            appendSucceeded = pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
        }

        return appendSucceeded
    }

    func pixelBufferFromImage(_ image: CGImage) -> CVPixelBuffer? {

            // This again was just our utility class for the height & width of the
            // incoming video (640 height x 480 width)

        let options: [NSObject: AnyObject] = [
            kCVPixelBufferCGImageCompatibilityKey : true as AnyObject,
            kCVPixelBufferCGBitmapContextCompatibilityKey : true as AnyObject
        ]

        let width = image.width
        let height = image.height

        var pxbuffer: CVPixelBuffer? = nil

        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, (options as CFDictionary), &pxbuffer)

        debugPrint(status)

        if let pxbuffer = pxbuffer {

            let statusBefore = CVPixelBufferLockBaseAddress(pxbuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
            debugPrint(statusBefore)

            let pxdata = CVPixelBufferGetBaseAddress(pxbuffer)
            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            let context = CGContext(data: pxdata, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 4 * width, space: rgbColorSpace,bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue )
            context?.concatenate(CGAffineTransform(rotationAngle: 0))
            context?.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        }

        return pxbuffer
    }

    /*
    func writeImagesAsMovie(_ allImages: [CGImage], videoPath: String, videoSize: CGSize, videoFPS: Int32) {
        // Create AVAssetWriter to write video
        guard let assetWriter = createAssetWriter(videoPath, size: videoSize) else {
            debugPrint("Error converting images to video: AVAssetWriter not created")
            return
        }

        // If here, AVAssetWriter exists so create AVAssetWriterInputPixelBufferAdaptor
        let writerInput = assetWriterVideoInput!
        let sourceBufferAttributes : [String : AnyObject] = [
            kCVPixelBufferPixelFormatTypeKey as String : Int(kCVPixelFormatType_32ARGB) as AnyObject,
            kCVPixelBufferWidthKey as String : videoSize.width as AnyObject,
            kCVPixelBufferHeightKey as String : videoSize.height as AnyObject,
            ]
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: sourceBufferAttributes)

        // Start writing session

        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: kCMTimeZero)

        switch assetWriter.status {
        case .writing:
            debugPrint("Asset writer is writing")
        case .failed:
            debugPrint("Asset writer is failed")
        case .cancelled:
            debugPrint("Asset writer is cancelled")
        case .completed:
            debugPrint("Asset writer is completed")
        case .unknown:
            debugPrint("Asset writer is unknown")
        }

        debugPrint(assetWriter.error)

        if (pixelBufferAdaptor.pixelBufferPool == nil) {
            debugPrint("Error converting images to video: pixelBufferPool nil after starting session")
            return
        }

        // -- Create queue for <requestMediaDataWhenReadyOnQueue>
        let mediaQueue = DispatchQueue(label: "mediaInputQueue", attributes: [])

        // -- Set video parameters
        let frameDuration = CMTimeMake(1, videoFPS)
        var frameCount = 0

        // -- Add images to video
        let numImages = allImages.count
        writerInput.requestMediaDataWhenReady(on: mediaQueue, using: { () -> Void in
            // Append unadded images to video but only while input ready
            while (writerInput.isReadyForMoreMediaData && frameCount < numImages) {
                let lastFrameTime = CMTimeMake(Int64(frameCount), videoFPS)
                let presentationTime = frameCount == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, frameDuration)

                /*if !self.appendPixelBufferForImageAtURL(allImages[frameCount], pixelBufferAdaptor: pixelBufferAdaptor, presentationTime: presentationTime) {
                    debugPrint("Error converting images to video: AVAssetWriterInputPixelBufferAdapter failed to append pixel buffer")
                    return
                }*/

                frameCount += 1
            }

            // No more images to add? End video.
            if (frameCount >= numImages) {
                self.sessionRunning = false
                writerInput.markAsFinished()
                assetWriter.finishWriting {
                    if (assetWriter.error != nil) {
                        debugPrint("Error converting images to video: \(assetWriter.error)")
                    } else {
                        //let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
                        //let documentDirectory = paths.first
                        //let dataPath = (documentDirectory)! + "FilterCam_\("filter").mov"
                        self.saveVideoToLibrary(URL(fileURLWithPath: videoPath))
                        debugPrint("Converted images to movie @ \(videoPath)")
                    }
                }
            }
        })
    }
 */
}
