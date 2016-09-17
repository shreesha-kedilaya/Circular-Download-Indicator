//
//  Filters.swift
//  FilterCam
//
//  Created by Shreesha on 12/09/16.
//  Copyright © 2016 YML. All rights reserved.
//

import Foundation
import CoreImage

typealias Filter = (CIImage) -> CIImage

func hueAdjust(angleInRadians: Float) -> Filter {
    return { image in
        let parameters = [
            kCIInputAngleKey: angleInRadians,
            kCIInputImageKey: image
        ]
        let filter = CIFilter(name: "CIHueAdjust",
                              withInputParameters: parameters)
        return filter!.outputImage!
    }
}

func pixellate(scale: Float) -> Filter {
    return { image in
        let parameters = [
            kCIInputImageKey:image,
            kCIInputScaleKey:scale
        ]
        return CIFilter(name: "CIPixellate", withInputParameters: parameters)!.outputImage!
    }
}