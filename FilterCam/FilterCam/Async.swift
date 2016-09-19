//
//  Async.swift
//  FilterCam
//
//  Created by Shreesha on 01/09/16.
//  Copyright © 2016 YML. All rights reserved.
//

import Foundation
typealias AsyncCloser = () -> ()

/** For handling Asynchronise API calls

 - Customized methods to handle API response

 */
final class Async {
    /// Asynchronous execution on a dispatch queue and returns immediately
    class func main(_ closer: @escaping AsyncCloser) {
        DispatchQueue.main.async(execute: closer)
    }
    /// Asynchronous execution on a global queue and returns immediately
    class func global(_ priority: DispatchQoS.QoSClass = .default,  closer: @escaping AsyncCloser) {
        DispatchQueue.global(qos: priority).async(execute: closer)
    }
    /// Asynchronous execution on a dispatch queue and returns after specified time interval
    class func after(_ interval: Double, closer: @escaping AsyncCloser) {
        let time = DispatchTime.now() + Double(Int64(Double(NSEC_PER_SEC) * interval)) / Double(NSEC_PER_SEC)

        DispatchQueue.main.asyncAfter(deadline: time, execute: closer)
    }

}
