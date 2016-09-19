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

func hueAdjust(_ angleInRadians: Float) -> Filter {
    return { image in
        let parameters = [
            kCIInputAngleKey: angleInRadians,
            kCIInputImageKey: image
        ] as [String : Any]
        let filter = CIFilter(name: "CIHueAdjust",
                              withInputParameters: parameters)
        return filter!.outputImage!
    }
}

func pixellate(_ scale: Float) -> Filter {
    return { image in
        let parameters = [
            kCIInputImageKey:image,
            kCIInputScaleKey:scale
        ] as [String : Any]
        return CIFilter(name: "CIPixellate", withInputParameters: parameters)!.outputImage!
    }
}
