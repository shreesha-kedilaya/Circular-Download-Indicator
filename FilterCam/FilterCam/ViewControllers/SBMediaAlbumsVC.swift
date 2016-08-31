////
////  SBMediaAlbumsVC.swift
////  SayBubble
////
////  Created by Ganesh on 25/08/16.
////  Copyright © 2016 Sanjay. All rights reserved.
////
//
//import UIKit
//import Photos
//
//enum Media {
//    case Library
//    case Album
//}
//
//protocol MediaSelectionDelegate: class {
//    func didFinishSelection(selectedImages:[UIImage])
//}
//
//class SBMediaAlbumsVC: UIViewController {
//    
//    let imageManager = PHCachingImageManager()
//    let scale: CGFloat = 2
//    
//    var category = Media.Library
//    var assets = [PHFetchResult]()
//    var medialistView : UICollectionView!
//    var listView : UIView!
//    var mediaCollection = [PHAssetCollection]()
//    var selectedImages = [UIImage]()
//    var media = [UIImage]()
//    
//    var albumAssets = [PHAsset]() {
//        willSet {
//            imageManager.stopCachingImagesForAllAssets()
//        }
//        didSet {
//            imageManager.startCachingImagesForAssets(albumAssets, targetSize: CGSize(width: mediaCollectionItemSize * scale, height: mediaCollectionItemSize * scale), contentMode: .AspectFill, options: nil)
//        }
//    }
//    
//    var mediaCollectionItemSize: CGFloat {
//        let width = CGRectGetWidth(view.bounds) / 4
//        return width
//    }
//    
//    var libraryAssets = [PHAsset]()
//    
//    weak var delegate: MediaSelectionDelegate?
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        //  Do any additional setup after loading the view.
//        
////        medialistView = SBMediaCollectionView(frame: CGRect(x: 0, y: 56, width: 414, height: 736))
//        medialistView.backgroundColor = UIColor.grayColor()
////        medialistView.setCollectionViewDatasourceDelegate(self)
//        view.addSubview(medialistView)
//        
////        listView = SBAlbumsListView(frame: CGRect(x: 0, y: 736, width: 414, height: 736))
////        listView.setTableViewDatasourceDelegate(self)
//        view.addSubview(listView)
//        
//        self.getlibraryAssets()
//    }
//    
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }
//    
//    @IBAction func flipAction(button: UIButton) {
//        
//        switch category {
//        case .Library:
//            
//            UIView.animateWithDuration(0.5, animations: {
//                self.listView.frame = CGRect(x: 0, y: 56, width: 414, height: 736) // remove these values
//            }) { (flag) in
//                self.getAlbums()
////                self.listView.albumListTable.reloadData()
//            }
//            // Flip the category after the button action.
//            category = .Album
//        case .Album:
//            UIView.animateWithDuration(0.5, animations: {
//                self.listView.frame = CGRect(x: 0, y: 736, width: 414, height: 736) // remove these values
//            }) { (flag) in
//                self.getlibraryAssets()
////                self.medialistView.mediaCollectionView.reloadData()
//            }
//            // Flip the category after the button action.
//            category = .Library
//        }
//    }
//    
//
//    @IBAction func doneAction(sender: AnyObject) {
//        delegate?.didFinishSelection(selectedImages)
//        dismissViewControllerAnimated(true, completion: nil)
//    }
//    
//    
//    func getAlbums() {
//        
//        mediaCollection.removeAll()
//        let userAlbums = PHAssetCollection.fetchAssetCollectionsWithType(.SmartAlbum, subtype: .Any, options: nil)
//        
//        userAlbums.enumerateObjectsUsingBlock { (collection, index, stop) in
//            self.mediaCollection.append(collection as! PHAssetCollection)
//            let assets = PHAsset.fetchAssetsInAssetCollection(collection as! PHAssetCollection, options: nil)
//            self.assets.append(assets)
//        }
//    }
//    
//    func getAssetsForAlbum(index: Int) {
//        
//        let asset = assets[index]
//        asset.enumerateObjectsUsingBlock { (collection, index, stop) in
//            if let item = collection as? PHAsset {
//                self.albumAssets.append(item)
//            }
//        }
//    }
//    
//    func getlibraryAssets() {
//        self.libraryAssets.removeAll()
//        let options = PHFetchOptions()
//        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
//        
//        let results = PHAsset.fetchAssetsWithMediaType(.Image, options: options)
//        results.enumerateObjectsUsingBlock { (object, _, _) in
//            if let asset = object as? PHAsset {
//                self.libraryAssets.append(asset)
//            }
//        }
//        
//        let imageOptions = PHImageRequestOptions()
//        imageOptions.synchronous = true
//        imageManager.startCachingImagesForAssets(libraryAssets, targetSize: CGSize(width: mediaCollectionItemSize * scale, height: mediaCollectionItemSize * scale), contentMode: .AspectFill, options: imageOptions)
//    }
//}
//
//extension SBMediaAlbumsVC: UITableViewDataSource, UITableViewDelegate {
//    
//    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
//        return 1
//    }
//    
//    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return mediaCollection.count
//    }
//    
//    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCellWithIdentifier(getClassName(SBMediaAlbumsCell), forIndexPath: indexPath) as! SBMediaAlbumsCell
//        
//        cell.albumName.text = mediaCollection[indexPath.row].localizedTitle!
//        cell.mediaCount.text = String(assets[indexPath.row].count)
//        
//        if assets[indexPath.row].count > 0 {
//            
//            if let asset = assets[indexPath.row][0] as? PHAsset {
//                switch asset.mediaType {
//                case .Image:
//                    let options = PHImageRequestOptions()
//                    options.synchronous = true
//                    imageManager.requestImageForAsset(asset, targetSize: CGSize(width: mediaCollectionItemSize * scale, height: mediaCollectionItemSize * scale), contentMode: .AspectFill, options: options) { (image, info) in
//                        if let image = image {
//                            cell.albumThumbnail.image = image
//                        }
//                    }
//                case .Video:
//                    let options = PHVideoRequestOptions()
//                    options.networkAccessAllowed = true
//                case .Audio:
//                    // code for audio goes here
//                    print("Audio handling should be done")
//                case .Unknown:
//                    break
//                }
//            }
//        }
//        cell.separatorInset = UIEdgeInsetsZero
//        cell.layoutMargins = UIEdgeInsetsZero
//        cell.selectionStyle = .None
//        return cell
//    }
//    
//    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        
//        albumAssets.removeAll()
//        getAssetsForAlbum(indexPath.row)
//        if albumAssets.count > 0 {
//            category = .Album
//            UIView.animateWithDuration(0.5, animations: {
//                self.listView.frame = CGRect(x: 0, y: 736, width: 414, height: 736)
//            }) { (flag) in
//                self.medialistView.mediaCollectionView.reloadData()
//            }
//        }
//    }
//}
//
//extension SBMediaAlbumsVC: UICollectionViewDataSource, UICollectionViewDelegate {
//    
//    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
//        return 1
//    }
//    
//    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        var numberOfItems = 0
//        
//        switch category {
//        case .Library:
//            numberOfItems = libraryAssets.count
//        case .Album:
//            numberOfItems = albumAssets.count
//        }
//        
//        return numberOfItems
//    }
//    
//    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
//        
//        var asset : PHAsset?
//        
//        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(getClassName(SBMediaCollectionCell), forIndexPath: indexPath) as! SBMediaCollectionCell
//        
//        switch category {
//        case .Library:
//            asset = libraryAssets[indexPath.item]
//        case .Album:
//            asset = albumAssets[indexPath.item]
//        }
//        
//        if let asset = asset {
//            switch asset.mediaType {
//            case .Image:
//                let options = PHImageRequestOptions()
//                options.synchronous = true
//                self.imageManager.requestImageForAsset(asset, targetSize: CGSize(width: mediaCollectionItemSize * scale, height: mediaCollectionItemSize * scale), contentMode: .AspectFill, options: options) { (image, info) in
//                    if let image = image {
//                        self.media.append(image)
//                        cell.mediaImage.image = image
//                    }
//                }
//            case .Video:
//                let options = PHVideoRequestOptions()
//                options.networkAccessAllowed = true
//            case .Audio:
//                // code for audio goes here
//                print("Audio handling should be done")
//            case .Unknown:
//                break
//            }
//        }
//        
//        return cell
//    }
//    
//    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
//        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! SBMediaCollectionCell
//        cell.selectionIndicatorImage.image = UIImage(assetIdentifier:CreatePost.SelectionIndicatorImage)
//        selectedImages.append(media[indexPath.item])
//    }
//    
//    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
//        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! SBMediaCollectionCell
//        cell.selectionIndicatorImage.image = UIImage(assetIdentifier:CreatePost.Select)
//        selectedImages.removeObject(media[indexPath.item])
//    }
//    
//    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
//        return CGSize(width: mediaCollectionItemSize - 1, height: mediaCollectionItemSize)
//    }
//    
//    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
//        return 1
//    }
//    
//    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
//        return 1
//    }
//}
