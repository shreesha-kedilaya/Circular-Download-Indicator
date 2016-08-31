//
//  CircularProgressView.swift
//  Circular Indicator
//
//  Created by Shreesha on 26/08/16.
//  Copyright © 2016 YML. All rights reserved.
//

import UIKit

@IBDesignable class CircularProgressView: UIView {

    private var circularShapeLayer: CAShapeLayer?

    @IBInspectable var progress: CGFloat = 0.0 {
        didSet {

        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        sharedInit()
    }

    private func sharedInit() {
        backgroundColor = UIColor.brownColor()
        addCircularLayers()
    }

    private func addCircularLayers() {
        circularShapeLayer = CAShapeLayer()
        circularShapeLayer?.frame = bounds
        circularShapeLayer?.backgroundColor = UIColor.blackColor().CGColor

        layer.addSublayer(circularShapeLayer!)
        layer.masksToBounds = true
        addCurcularPath()
    }

    private func addCurcularPath() {

        let startAngle = -90.f.rad
        let endAngle = 270.f.rad

        let path = UIBezierPath(arcCenter: circularShapeLayer!.position, radius: bounds.width / 2 - 20, startAngle: startAngle, endAngle: endAngle, clockwise: true)

        circularShapeLayer?.fillColor = UIColor.clearColor().CGColor
        circularShapeLayer?.lineWidth = 3
        circularShapeLayer?.fillRule = kCAFillRuleNonZero
        circularShapeLayer?.strokeColor = UIColor.cyanColor().CGColor
        circularShapeLayer?.path = path.CGPath

        circularShapeLayer?.strokeEnd = 1
        circularShapeLayer?.strokeStart = 0

        let animation = CABasicAnimation(keyPath: "strokeEnd")

        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = 2
        animation.repeatCount = Float(CGFloat.max)


        let strokeAnimation = CABasicAnimation(keyPath: "strokeEnd")

        strokeAnimation.fromValue = 1
        strokeAnimation.toValue = 0
        strokeAnimation.duration = 2
        strokeAnimation.beginTime = 2

        strokeAnimation.repeatCount = Float(CGFloat.max)

        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.fromValue = 0
        rotationAnimation.toValue = M_PI * 2
        rotationAnimation.duration = 1
        rotationAnimation.repeatCount = Float(CGFloat.max)

        let groupAnimation = CAAnimationGroup()
        groupAnimation.animations = [animation,strokeAnimation,rotationAnimation]
        groupAnimation.duration = 4
        groupAnimation.repeatCount = Float(CGFloat.max)

        circularShapeLayer?.addAnimation(groupAnimation, forKey: "downloadAnimation")
        circularShapeLayer?.strokeEnd = 1
        circularShapeLayer?.strokeStart = 0
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }
}

extension CGFloat{
    var rad: CGFloat{
        return (self * CGFloat(M_PI)) / 180.0
    }

    var ang: CGFloat {
        return (self * 180) / CGFloat(M_PI)
    }
}

extension Int {
    var f: CGFloat  {
        return CGFloat(self)
    }
}

extension Double {
    var f: CGFloat  {
        return CGFloat(self)
    }
}
