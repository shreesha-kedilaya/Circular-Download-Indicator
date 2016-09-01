//
//  GaleryCollectionViewModel.swift
//  FilterCam
//
//  Created by Shreesha on 31/08/16.
//  Copyright © 2016 YML. All rights reserved.
//

import Foundation
import Photos
import AVFoundation

typealias libraryInfoTupple = (PHAsset, NSURL)

class GaleryCollectionViewModel {

    var libraryAssets = [PHAsset]()
    var libraryUrls = [NSURL]()

    var libraryInfo = [libraryInfoTupple]()


    let imageCachingManager = PHCachingImageManager()

    private func getURLofMedia(mPhasset: PHAsset, completionHandler : ((responseURL : NSURL?) -> Void)){

        if mPhasset.mediaType == .Image {
            let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()

            options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
                return true
            }
            mPhasset.requestContentEditingInputWithOptions(options, completionHandler: {(contentEditingInput: PHContentEditingInput?, info: [NSObject : AnyObject]) -> Void in
                completionHandler(responseURL : contentEditingInput!.fullSizeImageURL)
            })
        } else if mPhasset.mediaType == .Video {
            let options: PHVideoRequestOptions = PHVideoRequestOptions()
            options.version = .Original
            options.deliveryMode = .FastFormat
            PHImageManager.defaultManager().requestAVAssetForVideo(mPhasset, options: options, resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [NSObject : AnyObject]?) -> Void in

                if let urlAsset = asset as? AVURLAsset {
                    let localVideoUrl : NSURL = urlAsset.URL
                    completionHandler(responseURL : localVideoUrl)
                } else {
                    completionHandler(responseURL : nil)
                }
            })
        }
    }

    private func storeAllUrls(completion: () -> ())  {
        libraryUrls.removeAll()
        for asset in libraryAssets.enumerate() {
            getURLofMedia(asset.element, completionHandler: { (responseURL) in
                
                if let responseURL = responseURL {
                    self.libraryUrls.append(responseURL)
                    let library = (asset.element, responseURL)
                    self.libraryInfo.append(library)
                }

                if self.libraryAssets.count == self.libraryUrls.count {
                    completion()
                }
            })
        }
    }

    func fetchLibraryAssets(completion: () -> ()) {
        fetchAlllibraryAssets {

            let cacheoptions = PHImageRequestOptions()
            cacheoptions.synchronous = true
            cacheoptions.version = .Original
            cacheoptions.resizeMode = .Exact
            self.imageCachingManager.startCachingImagesForAssets(self.libraryAssets, targetSize: CGSize(width:UIScreen.mainScreen().bounds.size.width * UIScreen.mainScreen().scale,height:UIScreen.mainScreen().bounds.size.height * UIScreen.mainScreen().scale), contentMode: .AspectFit, options: cacheoptions)

            self.storeAllUrls{
                completion()
            }
        }
    }

    private func fetchAlllibraryAssets(completion: ()->()){

        self.imageCachingManager.stopCachingImagesForAllAssets()
        libraryAssets.removeAll()
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

        let results = PHAsset.fetchAssetsWithMediaType(.Video, options: options)
        results.enumerateObjectsUsingBlock { (object, index, _) in
            if let asset = object as? PHAsset {
                self.libraryAssets.append(asset)
            }
            if self.libraryAssets.count == results.count {
                completion()
            }
        }
    }
}