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

typealias libraryInfoTupple = (PHAsset, URL)

class GaleryCollectionViewModel {

    var libraryAssets = [PHAsset]()
    var libraryUrls = [URL]()

    var libraryInfo = [libraryInfoTupple]()


    let imageCachingManager = PHCachingImageManager()

    fileprivate func getURLofMedia(_ mPhasset: PHAsset, completionHandler : @escaping ((_ responseURL : URL?) -> Void)){

        if mPhasset.mediaType == .image {
            let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()

            options.canHandleAdjustmentData = {(adjustmeta: PHAdjustmentData) -> Bool in
                return true
            }
            mPhasset.requestContentEditingInput(with: options, completionHandler: {(contentEditingInput: PHContentEditingInput?, info: [AnyHashable: Any]) -> Void in
                completionHandler(contentEditingInput!.fullSizeImageURL)
            })
        } else if mPhasset.mediaType == .video {
            let options: PHVideoRequestOptions = PHVideoRequestOptions()
            options.version = .original
            options.deliveryMode = .fastFormat
            PHImageManager.default().requestAVAsset(forVideo: mPhasset, options: options, resultHandler: {(asset: AVAsset?, audioMix: AVAudioMix?, info: [AnyHashable: Any]?) -> Void in

                if let urlAsset = asset as? AVURLAsset {
                    let localVideoUrl : URL = urlAsset.url
                    completionHandler(localVideoUrl)
                } else {
                    completionHandler(nil)
                }
            })
        }
    }

    fileprivate func storeAllUrls(_ completion: @escaping () -> ())  {
        libraryUrls.removeAll()
        for asset in libraryAssets.enumerated() {
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

    func fetchLibraryAssets(_ completion: @escaping () -> ()) {
        fetchAlllibraryAssets {

            let cacheoptions = PHImageRequestOptions()
            cacheoptions.isSynchronous = true
            cacheoptions.version = .original
            cacheoptions.resizeMode = .exact
            self.imageCachingManager.startCachingImages(for: self.libraryAssets, targetSize: CGSize(width:UIScreen.main.bounds.size.width * UIScreen.main.scale,height:UIScreen.main.bounds.size.height * UIScreen.main.scale), contentMode: .aspectFit, options: cacheoptions)

            self.storeAllUrls{
                completion()
            }
        }
    }

    fileprivate func fetchAlllibraryAssets(_ completion: @escaping ()->()){

        self.imageCachingManager.stopCachingImagesForAllAssets()
        libraryAssets.removeAll()
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

        let results = PHAsset.fetchAssets(with: .video, options: options)
        /*results.enumerateObjects { (object, index, _) in
            if let asset = object as? PHAsset {
                self.libraryAssets.append(asset)
            }
            if self.libraryAssets.count == results.count {
                completion()
            }
        }*/

        results.enumerateObjects ({ (object, index, _) in
            self.libraryAssets.append(object)
            if self.libraryAssets.count == results.count {
                completion()
            }
        })
    }
}
