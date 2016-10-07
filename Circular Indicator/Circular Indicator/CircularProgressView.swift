//
//  CircularProgressView.swift
//  Circular Indicator
//
//  Created by Shreesha on 26/08/16.
//  Copyright © 2016 YML. All rights reserved.
//

import UIKit

@IBDesignable class CircularProgressView: UIView {

    fileprivate var circularShapeLayer: CAShapeLayer?

    @IBInspectable var progress: CGFloat = 0.0 {
        didSet {

        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        sharedInit()
    }

    fileprivate func sharedInit() {
        backgroundColor = UIColor.brown
        addCircularLayers()
    }

    fileprivate func addCircularLayers() {
        circularShapeLayer = CAShapeLayer()
        circularShapeLayer?.frame = bounds
        circularShapeLayer?.backgroundColor = UIColor.clear.cgColor

        layer.addSublayer(circularShapeLayer!)
        layer.masksToBounds = true
        addCurcularPath()
    }

    fileprivate func addCurcularPath() {

        let startAngle = -90.f.rad
        let endAngle = 270.f.rad

        let path = UIBezierPath(arcCenter: circularShapeLayer!.position, radius: bounds.width / 2 - 20, startAngle: startAngle, endAngle: endAngle, clockwise: true)

        circularShapeLayer?.fillColor = UIColor.clear.cgColor
        circularShapeLayer?.lineWidth = 5
        circularShapeLayer?.fillRule = kCAFillRuleNonZero
        circularShapeLayer?.strokeColor = UIColor.cyan.cgColor
        circularShapeLayer?.path = path.cgPath

        circularShapeLayer?.strokeEnd = 1
        circularShapeLayer?.strokeStart = 0

        let animation = CABasicAnimation(keyPath: "strokeEnd")

        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = 1

        let strokeAnimation = CABasicAnimation(keyPath: "strokeStart")

        strokeAnimation.fromValue = 0
        strokeAnimation.toValue = 1
        strokeAnimation.duration = 1
        strokeAnimation.beginTime = 1

        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.fromValue = 0
        rotationAnimation.toValue = M_PI * 2
        rotationAnimation.duration = 2
        rotationAnimation.repeatCount = Float(CGFloat.greatestFiniteMagnitude)

        let groupAnimation = CAAnimationGroup()
        groupAnimation.animations = [animation,strokeAnimation,rotationAnimation]
        groupAnimation.duration = 2
        groupAnimation.repeatCount = Float(CGFloat.greatestFiniteMagnitude)

        circularShapeLayer?.add(groupAnimation, forKey: "downloadAnimation")
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
