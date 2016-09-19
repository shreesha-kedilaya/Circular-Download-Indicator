//
//  PermissionManager.swift
//  RealSimple
//
//  Created by Y Media Labs on 5/20/16.
//  Copyright © 2016 Y Media Labs. All rights reserved.
//

import Foundation
import AVFoundation
import Photos
//import Contacts

/**
 *  A protocol which any service can conform to.
 */
//MARK:- PermissionService
protocol PermissionService: class {
    
    var requestedPermission: Bool {get set}
    func status() -> PermissionStatus
    func requestPermission(_ completion: PermissionCompletionBlock)
}

typealias PermissionCompletionBlock = ((PermissionStatus) -> Void)?

//MARK:- PermissionType
enum PermissionType: String {
    
    case Notifications
    case Photos
    case Camera
    
    var permissionService: PermissionService {
        var service: PermissionService!
        
        switch self {
        case .Photos:
            service = PhotosPermissionService()
        case .Camera:
            service = CameraPermissionService()
        case .Notifications:
            service = NotificationsPermissionService()
        }
        
        return service
    }
}

enum PermissionStatus: String {
    
    /// User has not yet made a choice with regards to this application
    case NotDetermined
    
    /// User has explicitly denied this application access
    case Unauthorized
    
    /// User has disabled this services at settings level
    case Disabled
    
    /// User has authorized this application
    case Authorized
}

/***************************************************/

/*
/******************/
//MARK:- Contacts
/******************/
class ContactPermissionService: PermissionService {
    
    var requestedPermission: Bool = false
    
    func status() -> PermissionStatus {
        var permissionStatus: PermissionStatus = .NotDetermined
        
        let serviceStatus = CNContactStore.authorizationStatusForEntityType(.Contacts)
        
        switch serviceStatus {
        case .Authorized:
            permissionStatus = .Authorized
        case .Restricted, .Denied:
            permissionStatus = .Unauthorized
        case .NotDetermined:
            permissionStatus = .NotDetermined
        }
        
        return permissionStatus
    }
    
    func requestPermission(completion: PermissionCompletionBlock) {
        let permissionsStatus = status()
        
        switch permissionsStatus {
        case .NotDetermined:
            CNContactStore().requestAccessForEntityType(.Contacts, completionHandler: { (success, error) in
                self.requestedPermission = true
                let status = self.status()
                completion?(status)
            })
        case .Unauthorized:
            //Show some alert
            break
        default:
            break
        }
    }
}
*/

/******************/
//MARK:- Camera
/******************/
class CameraPermissionService: PermissionService {
    
    var requestedPermission: Bool = false
    
    func status() -> PermissionStatus {
        var permissionStatus: PermissionStatus = .NotDetermined
        
        let serviceStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        
        switch serviceStatus {
        case .authorized:
            permissionStatus = .Authorized
        case .restricted, .denied:
            permissionStatus = .Unauthorized
        case .notDetermined:
            permissionStatus = .NotDetermined
        }
        
        return permissionStatus
    }
    
    func requestPermission(_ completion: PermissionCompletionBlock) {
        let permissionsStatus = status()
        
        switch permissionsStatus {
        case .NotDetermined:
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (granted) in
                self.requestedPermission = true
                let status = self.status()
                completion?(status)
            })
        case .Unauthorized:
            //Show some alert
            fallthrough
        default:
            completion?(permissionsStatus)
        }
    }
}

/******************/
//MARK:- Photos
/******************/
class PhotosPermissionService: PermissionService {
    
    var requestedPermission: Bool = false
    
    func status() -> PermissionStatus {
        var permissionStatus: PermissionStatus = .NotDetermined
        
        let serviceStatus = PHPhotoLibrary.authorizationStatus()
        
        switch serviceStatus {
        case .authorized:
            permissionStatus = .Authorized
        case .restricted, .denied:
            permissionStatus = .Unauthorized
        case .notDetermined:
            permissionStatus = .NotDetermined
        }
        
        return permissionStatus
    }
    
    func requestPermission(_ completion: PermissionCompletionBlock) {
        let permissionsStatus = status()
        
        switch permissionsStatus {
        case .NotDetermined:
            PHPhotoLibrary.requestAuthorization({ (status) in
                self.requestedPermission = true
                let status = self.status()
                completion?(status)
            })
        case .Unauthorized:
            //Show some alert
            fallthrough
        default:
            completion?(permissionsStatus)
        }
    }
}

/**********************/
//MARK:- Notifications
/**********************/
class NotificationsPermissionService: PermissionService {
    
    var requestedPermission: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "NotificationPermission")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "NotificationPermission")
        }
    }
    
    func status() -> PermissionStatus {
        var permissionStatus: PermissionStatus = .NotDetermined
        
        let settings = UIApplication.shared.currentUserNotificationSettings
        
        if let settingTypes = settings?.types , settingTypes != UIUserNotificationType() {
            permissionStatus = .Authorized
        } else {
            if requestedPermission {
                permissionStatus = .Unauthorized
            } else {
                permissionStatus = .NotDetermined
            }
        }
        
        return permissionStatus
    }
    
    func requestPermission(_ completion: PermissionCompletionBlock) {
        let permissionsStatus = status()
        
        switch permissionsStatus {
        case .NotDetermined:
            
            let notificationTypes: UIUserNotificationType = [UIUserNotificationType.alert, UIUserNotificationType.badge, UIUserNotificationType.sound]
            
            let pushNotificationSettings = UIUserNotificationSettings(types: notificationTypes, categories: nil)
            
            UIApplication.shared.registerUserNotificationSettings(pushNotificationSettings)
            UIApplication.shared.registerForRemoteNotifications()
            
            requestedPermission = true
            
            let status = self.status()
            completion?(status)
            
        case .Unauthorized:
            //Show some alert
            fallthrough
        default:
            completion?(permissionsStatus)
        }
    }
}

/********************************************/

extension UIAlertController {
    
    class func disabledAlert(_ permissionType: PermissionType) -> UIAlertController {
        let alertController = UIAlertController(title: "Permission Disabled", message: "Please enable access to \(permissionType.rawValue) in Settings.", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) -> Void in
            
        }
        alertController.addAction(okAction)
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (action) in
            if let settingsURL = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.openURL(settingsURL)
            }
        }
        alertController.addAction(settingsAction)
        
        return alertController
    }
    
    class func deniedAlert(_ permissionType: PermissionType) -> UIAlertController {
        let alertController = UIAlertController(title: "\(permissionType) is currently disabled", message: "Please enable access to \(permissionType.rawValue) in Settings.", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) -> Void in
            
        }
        alertController.addAction(okAction)
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (action) in
            if let settingsURL = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.openURL(settingsURL)
            }
        }
        alertController.addAction(settingsAction)
        
        return alertController
    }
}
