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
                print("Error in getting the image at time \(time)\n\n Error: \(error)")
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
        let ciimage = CIImage(buffer: sampleBuffer).applying(transform)

        let cgimage = coreImageContext?.createCGImage(ciimage, from: rect)

        if let cgimage = cgimage {
            /*appendImage(cgimage) { (numberOfFrames) in
                completion(numberOfFrames)
            }*/
        }
    }


    func saveVideoToLibrary(_ videoURL: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            // Return if unauthorized
            guard status == .authorized else {
                print("Error saving video: unauthorized access")
                return
            }

            // If here, save video to library
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            }) { success, error in
                if !success {
                    print("Error saving video: \(error)")
                }
            }
        }
    }

    func appendImage(_ image: CGImage, inrect rect: CGRect, completion: (_ numberOfFrames: Int) -> ()) {
        guard let assetWriterVideoInput = assetWriterVideoInput else {
            return
        }

        if assetWriterVideoInput.isReadyForMoreMediaData {
            let lastFrameTime = CMTimeMake(Int64(self.numberOfFrames), self.videoFPS)
            let presentationTime = self.numberOfFrames == 0 ? lastFrameTime : CMTimeAdd(lastFrameTime, self.frameDuration)

            assetWriter?.startSession(atSourceTime: presentationTime)

            if !self.appendPixelBufferForImageAtURL(image, pixelBufferAdaptor: self.pixelBufferAdopter!, presentationTime: presentationTime, inrect: rect) {
                print("Error converting images to video: AVAssetWriterInputPixelBufferAdapter failed to append pixel buffer")
                return
            }
            debugPrint("appended the pixel buffer at time \(presentationTime)")
            self.numberOfFrames += 1
            completion(self.numberOfFrames)
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

            print("Created asset writer for \(size.width)x\(size.height) video")
            return newWriter
        } catch {
            print("Error creating asset writer: \(error)")
            return nil
        }
    }

    func appendPixelBufferForImageAtURL(_ image: CGImage, pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor, presentationTime: CMTime, inrect rect: CGRect) -> Bool {
        var appendSucceeded = false

        autoreleasepool {
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
                    print(status)
                    let pxdata = CVPixelBufferGetBaseAddress(pixelBuffer)

                    let height = image.height
                    let width = image.width

                    let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
                    let context = CGContext(data: pxdata, width: Int(width),
                                            height: Int(height), bitsPerComponent: 4, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: rgbColorSpace,
                                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)


                    context?.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
                    
                    let retValue = CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
                    
                    print(retValue)
                    debugPrint("successfully created the pixel buffer")
                    appendSucceeded = pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
                    pixelBufferPointer.deinitialize()
                } else {
                    print("Error: Failed to allocate pixel buffer from pool")
                }

                pixelBufferPointer.deallocate(capacity: 1)
            }
        }

        return appendSucceeded
    }

    func fillPixelBufferFromImage(_ image: CGImage, pixelBuffer: CVPixelBuffer, inrect rect: CGRect) {

        /*CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))

        let height = image.height
        let width = image.width

        let data = CVPixelBufferGetBaseAddress(pixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: data,
                                width: Int(width),
                                height: Int(height),
                                bitsPerComponent: 8,
                                bytesPerRow: width * 8,
                                space: rgbColorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)

        context?.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        let returnValue = CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))

        print(returnValue)*/
    }


    func writeImagesAsMovie(_ allImages: [CGImage], videoPath: String, videoSize: CGSize, videoFPS: Int32) {
        // Create AVAssetWriter to write video
        guard let assetWriter = createAssetWriter(videoPath, size: videoSize) else {
            print("Error converting images to video: AVAssetWriter not created")
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
            print("Asset writer is writing")
        case .failed:
            print("Asset writer is failed")
        case .cancelled:
            print("Asset writer is cancelled")
        case .completed:
            print("Asset writer is completed")
        case .unknown:
            print("Asset writer is unknown")
        }

        print(assetWriter.error)

        if (pixelBufferAdaptor.pixelBufferPool == nil) {
            print("Error converting images to video: pixelBufferPool nil after starting session")
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
                    print("Error converting images to video: AVAssetWriterInputPixelBufferAdapter failed to append pixel buffer")
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
                        print("Error converting images to video: \(assetWriter.error)")
                    } else {
                        //let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
                        //let documentDirectory = paths.first
                        //let dataPath = (documentDirectory)! + "FilterCam_\("filter").mov"
                        self.saveVideoToLibrary(URL(fileURLWithPath: videoPath))
                        print("Converted images to movie @ \(videoPath)")
                    }
                }
            }
        })
    }
}
