//
//  Filters.swift
//  FilterCam
//
//  Created by Shreesha on 12/09/16.
//  Copyright © 2016 YML. All rights reserved.
//

import Foundation
import CoreImage
import UIKit

typealias Filter = (CIImage) -> CIImage


struct FilterGenerator {

    var count = 1

    static func blur(radius: Double) -> Filter {
        return { image in
            let parameters = [
                kCIInputRadiusKey: radius,
                kCIInputImageKey: image
                ] as [String : Any]
            let filter = CIFilter(name: "CIGaussianBlur",
                                  withInputParameters: parameters)
            return filter!.outputImage!
        }
    }

    static func colorGenerator(color: UIColor) -> Filter {
        return { _ in
            let parameters = [kCIInputColorKey: color]
            let filter = CIFilter(name: "CIConstantColorGenerator",
                                  withInputParameters: parameters)
            return filter!.outputImage!
        }
    }

    static func hueAdjust(angleInRadians: Float) -> Filter {
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

    static func pixellate(scale: Float) -> Filter {
        return { image in
            let parameters = [
                kCIInputImageKey:image,
                kCIInputScaleKey:scale
                ] as [String : Any]
            return CIFilter(name: "CIPixellate", withInputParameters: parameters)!.outputImage!
        }
    }

    static func kaleidoscope() -> Filter {
        return { image in
            let parameters = [
                kCIInputImageKey:image,
                ]
            return CIFilter(name: "CITriangleKaleidoscope", withInputParameters: parameters)!.outputImage!.cropping(to: image.extent)
        }
    }


    static func vibrance(amount: Float) -> Filter {
        return { image in
            let parameters = [
                kCIInputImageKey: image,
                "inputAmount": amount
                ] as [String : Any]
            return CIFilter(name: "CIVibrance", withInputParameters: parameters)!.outputImage!
        }
    }

    static func compositeSourceOver(overlay: CIImage) -> Filter {
        return { image in
            let parameters = [
                kCIInputBackgroundImageKey: image,
                kCIInputImageKey: overlay
            ]
            let filter = CIFilter(name: "CISourceOverCompositing",
                                  withInputParameters: parameters)
            let cropRect = image.extent
            return filter!.outputImage!.cropping(to: cropRect)
        }
    }


    static func radialGradient(center: CGPoint, radius: CGFloat) -> Filter {
        return { image in

            let params: [String: Any] = [
                "inputColor0": CIColor(red: 1, green: 1, blue: 1),
                "inputColor1": CIColor(red: 0, green: 0, blue: 0),
                "inputCenter": CIVector(cgPoint: center),
                "inputRadius0": radius,
                "inputRadius1": (radius + 1)
            ]
            return CIFilter(name: "CIRadialGradient", withInputParameters: params)!.outputImage!
        }
    }

    static func blendWithMask(background: CIImage, mask: CIImage) -> Filter {
        return { image in
            let parameters = [
                kCIInputBackgroundImageKey: background,
                kCIInputMaskImageKey: mask,
                kCIInputImageKey: image
            ]
            let filter = CIFilter(name: "CIBlendWithMask",
                                  withInputParameters: parameters)
            
            let cropRect = image.extent
            return filter!.outputImage!.cropping(to: cropRect)
        }
    }
    
    static func colorOverlay(color: UIColor) -> Filter {
        return { image in
            let overlay = colorGenerator(color: color)(image)
            return compositeSourceOver(overlay: overlay)(image)
        }
    }
}

enum Filters {
    case hueAdjust(angleInRadians: Float)
    case pixellate(scale: Float)
    case blur(radius: Double)
    case colorGenerator(color: UIColor)
    case kaleidoscope
    case vibrance(amount: Float)
    case compositeSourceOver(overlay: CIImage)
    case radialGradient(center: CGPoint, radius: CGFloat)
    case blendWithMask(background: CIImage, mask: CIImage)
    case colorOverlay(color: UIColor)

    func filter() -> Filter {

        var filter: Filter
        switch self {
        case let .hueAdjust(angleInRadians):
            filter = FilterGenerator.hueAdjust(angleInRadians: angleInRadians)
        case let .pixellate(scale):
            filter = FilterGenerator.pixellate(scale: scale)
        case let .blur(radius):
            filter = FilterGenerator.blur(radius: radius)
        case let .colorGenerator(color):
            filter = FilterGenerator.colorGenerator(color: color)
        case .kaleidoscope:
            filter = FilterGenerator.kaleidoscope()
        case let .vibrance(amount):
            filter = FilterGenerator.vibrance(amount: amount)
        case let .compositeSourceOver(overlay):
            filter = FilterGenerator.compositeSourceOver(overlay: overlay)
        case let .radialGradient(center, radius):
            filter = FilterGenerator.radialGradient(center: center, radius: radius)
        case let .blendWithMask(background, mask):
            filter = FilterGenerator.blendWithMask(background: background, mask: mask)
        case let .colorOverlay(color):
            filter = FilterGenerator.colorOverlay(color: color)

        }
        return filter
    }
}
