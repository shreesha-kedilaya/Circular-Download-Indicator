//
//  CoreImageView.swift
//  FilterCam
//
//  Created by Shreesha on 17/09/16.
//  Copyright © 2016 YML. All rights reserved.
//

import Foundation
import GLKit

class CoreImageView: GLKView {
    var image: CIImage? {
        didSet {
            glClearColor(0.5, 0.5, 0.5, 1.0);
            glClear(GLbitfield(GL_COLOR_BUFFER_BIT));

            // set the blend mode to "source over" so that CI will use that
            glEnable(GLenum(GL_BLEND));
            glBlendFunc(GLenum(GL_ONE), GLenum(GL_ONE_MINUS_SRC_ALPHA));
            display()
        }
    }
    var coreImageContext: CIContext?
    var cgimage: CGImage?
    fileprivate (set) var eaglContext: EAGLContext?

    override convenience init(frame: CGRect) {
        let eaglContext = EAGLContext(api: EAGLRenderingAPI.openGLES2)
        self.init(frame: frame, context: eaglContext!)
        self.eaglContext = eaglContext
    }

    override init(frame: CGRect, context eaglContext: EAGLContext) {
        coreImageContext = CIContext(eaglContext: eaglContext)
        super.init(frame: frame, context: eaglContext)
        // We will be calling display() directly, hence this needs to be false
        enableSetNeedsDisplay = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        if let img = image {
            let scale = self.window?.screen.scale ?? 1.0
            let destRect = bounds.applying(CGAffineTransform(scaleX: scale, y: scale))
            cgimage = coreImageContext?.createCGImage(img, from: img.extent)
            coreImageContext?.draw(img, in: destRect, from: img.extent)
        }
    }
}
